package rpc

import (
	"context"
	"encoding/json"
	"strings"

	"github.com/Ansh1902396/chain"
	"google.golang.org/grpc"
	codes "google.golang.org/grpc/codes"
	status "google.golang.org/grpc/status"
)

type BlockSrv struct {
	UnimplementedBlockServer
	blockStoreDir string
}

func (s *BlockSrv) BlockSearch(
	req *BlockSearchReq, stream grpc.ServerStreamingServer[BlockSearchRes],
) error {
	blocks, closeBlocks, err := chain.ReadBlocks(s.blockStoreDir)
	if err != nil {
		return status.Errorf(codes.NotFound, err.Error())
	}

	defer closeBlocks()

	prefix := strings.HasPrefix
	for err, blk := range blocks {
		if err != nil {
			return status.Errorf(codes.Internal, err.Error())
		}

		if req.Number != 0 && blk.Number == req.Number || len(req.Hash) > 0 && prefix(blk.Hash().String(), req.Hash) ||
			len(req.Parent) > 0 && prefix(blk.Parent.String(), req.Parent) {
			jblk, err := json.Marshal(blk)

			if err != nil {
				return status.Errorf(codes.Internal, err.Error())
			}

			res := &BlockSearchRes{Block: jblk}

			err = stream.Send(res)
			if err != nil {
				return status.Errorf(codes.Internal, err.Error())
			}
			break
		}
	}
	return nil
}

func (s *BlockSrv) GenesisSync(
	_ context.Context, req *GenesisSyncReq,
) (*GenesisSyncRes, error) {
	jgen, err := chain.ReadGenesisBytes(s.blockStoreDir)
	if err != nil {
		return nil, status.Errorf(codes.Internal, err.Error())
	}
	res := &GenesisSyncRes{Genesis: jgen}
	return res, nil
}

func (s *BlockSrv) BlockSync(
	req *BlockSyncReq, stream grpc.ServerStreamingServer[BlockSyncRes],
) error {
	blocks, closeBlocks, err := chain.ReadBlocksBytes(s.blockStoreDir)

	if err != nil {
		return status.Errorf(codes.NotFound, err.Error())
	}
	defer closeBlocks()

	num, i := int(req.Number), 1

	for err, jblk := range blocks {
		if err != nil {
			return status.Errorf(codes.Internal, err.Error())
		}
		if i >= num {
			res := &BlockSyncRes{Block: jblk}
			err = stream.Send(res)
			if err != nil {
				return status.Errorf(codes.Internal, err.Error())
			}
		}
		i++
	}

	return nil
}
