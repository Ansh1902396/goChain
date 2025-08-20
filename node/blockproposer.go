package node

import (
	"context"
	"crypto/rand"
	"encoding/json"
	"fmt"
	"math/big"
	"sync"
	"time"

	"github.com/Ansh1902396/chain"
	"github.com/Ansh1902396/node/rpc"
	"google.golang.org/grpc"
)

type BlockProposer struct {
	ctx        context.Context
	wg         *sync.WaitGroup
	authority  chain.Account
	state      *chain.State
	blkRelayer rpc.BlockRelayer
}

func NewBlockProposer(
	ctx context.Context, wg *sync.WaitGroup, blkRelayer rpc.BlockRelayer,
) *BlockProposer {
	return &BlockProposer{ctx: ctx, wg: wg, blkRelayer: blkRelayer}
}

func randPeriod(maxPeriod time.Duration) time.Duration {
	minPeriod := maxPeriod / 2
	randSpan, _ := rand.Int(rand.Reader, big.NewInt(int64(maxPeriod)))
	return time.Duration(randSpan.Int64()) + minPeriod
}

func (p *BlockProposer) ProposeBlock(maxPeriod time.Duration) {
	defer p.wg.Done()

	randPropose := time.NewTimer(randPeriod(maxPeriod))
	for {
		select {
		case <-p.ctx.Done():
			randPropose.Stop()
			return
		case <-randPropose.C:
			randPropose.Reset(randPeriod(maxPeriod))
			clone := p.state.Clone()
			blk, err := clone.CreateBlock(p.authority)
			if err != nil {
				continue
			}

			if len(blk.Txs) == 0 {
				continue
			}
			clone = p.state.Clone()
			err = clone.ApplyBlock(blk)
			if err != nil {
				fmt.Println(err)
				continue
			}
			if p.blkRelayer != nil {
				p.blkRelayer.RelayBlock(blk)
			}

			fmt.Printf("==> Block Propose \n%v\n", blk)
		}
	}
}

var GRPCBlockRelay GRPCMsgRelay[chain.SigBlock] = func(
	ctx context.Context, conn *grpc.ClientConn, chRelay chan chain.SigBlock,
) error {
	cln := rpc.NewBlockClient(conn)
	stream, err := cln.BlockReceive(ctx)

	if err != nil {
		return err
	}

	defer stream.CloseAndRecv()

	for {
		select {
		case <-ctx.Done():
			return nil
		case blk, open := <-chRelay:
			if !open {
				return nil
			}

			jblk, err := json.Marshal(blk)

			if err != nil {
				fmt.Println(err)
				continue
			}
			req := &rpc.BlockReceiveReq{Block: jblk}

			err = stream.Send(req)
			if err != nil {
				fmt.Println(err)
				continue
			}
		}
	}
}
