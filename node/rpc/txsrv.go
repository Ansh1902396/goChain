package rpc

import (
	"context"
	"encoding/json"
	"path/filepath"
	"strings"

	"github.com/Ansh1902396/chain"
	"google.golang.org/grpc"
	codes "google.golang.org/grpc/codes"
	status "google.golang.org/grpc/status"
)

type TxApplier interface {
	Nonce(acc chain.Address) uint64
}

type TxSrv struct {
	UnimplementedTxServer
	keyStoreDir   string
	blockStoreDir string
	txApplier     TxApplier
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
