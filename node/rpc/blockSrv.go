package rpc

import (
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
