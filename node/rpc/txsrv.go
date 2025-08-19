package rpc

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"path/filepath"
	"strings"

	"github.com/Ansh1902396/chain"
	"google.golang.org/grpc"
	codes "google.golang.org/grpc/codes"
	status "google.golang.org/grpc/status"
)

type TxApplier interface {
	ApplyTx(tx chain.SigTx) error
	Nonce(acc chain.Address) uint64
}

type TxRelayer interface {
	RelayTx(tx chain.SigTx) error
}

type TxSrv struct {
	UnimplementedTxServer
	keyStoreDir   string
	blockStoreDir string
	txApplier     TxApplier
	txRelayer     TxRelayer
}

func sendTxSearchRes(
	blk chain.SigBlock, tx chain.SigTx,
	stream grpc.ServerStreamingServer[TxSearchRes],
) error {
	stx := chain.NewSearchTx(tx, blk.Number, blk.Hash(), blk.MerkleRoot)
	jtx, err := json.Marshal(stx)

	if err != nil {
		return err
	}
	res := &TxSearchRes{Tx: jtx}
	err = stream.Send(res)
	if err != nil {
		return err
	}
	return nil
}

func (s *TxSrv) TxSign(_ context.Context, req *TxSignReq) (*TxSignRes, error) {
	path := filepath.Join(s.keyStoreDir, req.From)
	acc, err := chain.ReadAccount(path, []byte(req.Password))
	if err != nil {
		return nil, status.Errorf(codes.InvalidArgument, err.Error())
	}
	tx := chain.NewTx(
		chain.Address(req.From), chain.Address(req.To), req.Value,
		s.txApplier.Nonce(chain.Address(req.From))+1,
	)
	stx, err := acc.SignTx(tx)
	if err != nil {
		return nil, status.Errorf(codes.Internal, err.Error())
	}
	jtx, err := json.Marshal(stx)
	if err != nil {
		return nil, status.Errorf(codes.Internal, err.Error())
	}
	res := &TxSignRes{Tx: jtx}
	return res, nil
}

func (s *TxSrv) TxSearch(
	req *TxSearchReq, stream grpc.ServerStreamingServer[TxSearchRes],
) error {
	blocks, closeBlocks, err := chain.ReadBlocks(s.blockStoreDir)
	if err != nil {
		return status.Errorf(codes.NotFound, err.Error())
	}
	defer closeBlocks()
	prefix := strings.HasPrefix
block:
	for err, blk := range blocks {
		if err != nil {
			return status.Errorf(codes.Internal, err.Error())
		}
		for _, tx := range blk.Txs {
			if len(req.Hash) > 0 && prefix(tx.Hash().String(), req.Hash) {
				err = sendTxSearchRes(blk, tx, stream)
				if err != nil {
					return status.Errorf(codes.Internal, err.Error())
				}
				break block
			}
			if len(req.From) > 0 && prefix(string(tx.From), req.From) ||
				len(req.To) > 0 && prefix(string(tx.To), req.To) ||
				len(req.Account) > 0 &&
					(prefix(string(tx.From), req.From) || prefix(string(tx.To), req.To)) {
				err := sendTxSearchRes(blk, tx, stream)
				if err != nil {
					return status.Errorf(codes.Internal, err.Error())
				}
			}
		}
	}
	return nil
}

func (s *TxSrv) TxSend(_ context.Context, req *TxSendReq) (*TxSendRes, error) {
	var tx chain.SigTx
	err := json.Unmarshal(req.Tx, &tx)

	if err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "Invalid transaction format: %v", err)
	}
	err = s.txApplier.ApplyTx(tx)
	if err != nil {
		return nil, status.Errorf(codes.FailedPrecondition, err.Error())
	}

	if s.txRelayer != nil {
		s.txRelayer.RelayTx(tx)
	}
	res := &TxSendRes{Hash: tx.Hash().String()}
	return res, nil
}

func (s *TxSrv) TxProve(_ context.Context, req *TxProveReq) (*TxProveRes, error) {
	blocks, closeBlocks, err := chain.ReadBlocks(s.blockStoreDir)

	if err != nil {
		return nil, status.Errorf(codes.NotFound, err.Error())
	}

	defer closeBlocks()

	for err != nil {
		return nil, status.Errorf(codes.Internal, err.Error())
	}

	for err, blk := range blocks {
		if err != nil {
			return nil, status.Errorf(codes.Internal, err.Error())
		}

		for _, tx := range blk.Txs {
			if tx.Hash().String() == req.Hash {
				merkleTree, err := chain.MerkleHash(
					blk.Txs, chain.TxHash, chain.TxPairHash,
				)

				if err != nil {
					return nil, status.Errorf(codes.Internal, err.Error())
				}

				merkleProof, err := chain.MerkleProve(tx.Hash(), merkleTree)

				if err != nil {
					return nil, status.Errorf(codes.Internal, err.Error())
				}

				jmp, err := json.Marshal(merkleProof)

				if err != nil {
					return nil, status.Errorf(codes.Internal, err.Error())
				}
				res := &TxProveRes{MerkleProof: jmp}

				return res, nil

			}
		}
	}

	return nil, status.Errorf(
		codes.NotFound, fmt.Sprintf("Transaction not found: %v", req.Hash),
	)

}

func (s *TxSrv) TxVerify(
	_ context.Context, req *TxVerifyReq,
) (*TxVerifyRes, error) {
	txh, err := chain.DecodeHash(req.Hash)

	if err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "Invalid transaction hash: %v", err)
	}

	var merkleProof []chain.Proof[chain.Hash]
	err = json.Unmarshal(req.MerkleProof, &merkleProof)

	if err != nil {
		return nil, status.Errorf(codes.InvalidArgument, err.Error())
	}

	merkleRoot, err := chain.DecodeHash(req.MerkleRoot)
	if err != nil {
		return nil, status.Errorf(codes.InvalidArgument, err.Error())
	}

	valid := chain.MerkleVerify(txh, merkleProof, merkleRoot, chain.TxPairHash)
	res := &TxVerifyRes{Valid: valid}
	return res, nil
}

func (s *TxSrv) TxReceive(
	stream grpc.ClientStreamingServer[TxReceiveReq, TxReceiveRes],
) error {
	for {
		req, err := stream.Recv()
		if err == io.EOF {
			res := &TxReceiveRes{}
			return stream.SendAndClose(res)
		}

		if err != nil {
			return status.Errorf(codes.Internal, err.Error())
		}

		var tx chain.SigTx

		err = json.Unmarshal(req.Tx, &tx)

		if err != nil {
			fmt.Println(err)
			continue
		}

		fmt.Printf("<== Tx receive: %v\n", tx)

		err = s.txApplier.ApplyTx(tx)

		if err != nil {
			fmt.Println(err)
			continue
		}

		if s.txRelayer != nil {
			s.txRelayer.RelayTx(tx)
		}

	}
}
