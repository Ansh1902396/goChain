package node

import (
	"context"
	"os/signal"
	"sync"
	"syscall"

	"github.com/Ansh1902396/chain"
	"google.golang.org/grpc"
)

type NodeCfg struct {
	Chain         string
	Balance       uint64
	KeyStoreDir   string
	NodeAddr      string
	Bootstrap     bool
	SeedAddr      string
	BlockStoreDir string
	AuthorityPass string
	OwnerPass     string
}

type Node struct {
	cfg       NodeCfg
	ctx       context.Context
	ctxCancel func()
	wg        *sync.WaitGroup
	chErr     chan error

	evStream  *EventStream
	state     *chain.State
	StateSync *StateSync
	grpcSrv   *grpc.Server
	peerDisc  *PeerDiscovery
	txRelay   *MsgRelay[chain.SigTx, GRPCMsgRelay[chain.SigTx]]
	blockProp *BlockProposer
	blkRelay  *MsgRelay[chain.SigBlock, GRPCMsgRelay[chain.SigBlock]]
}

func NewNode(cfg NodeCfg) *Node {
	ctx, cancel := signal.NotifyContext(
		context.Background(), syscall.SIGINT, syscall.SIGTERM, syscall.SIGKILL,
	)

	wg := new(sync.WaitGroup)
	evStream := NewEventStream(ctx, wg, 100)
	peerDiscCfg := PeerDiscoveryCfg{
		NodeAddr:  cfg.NodeAddr,
		Bootstrap: cfg.Bootstrap,
		SeedAddr:  []string{cfg.SeedAddr},
	}

	peerDisc := NewPeerDiscovery(ctx, wg, peerDiscCfg)
	stateSync := NewStateSync(ctx, cfg, peerDisc)
	txRelay := NewMsgRelay(ctx, wg, 100, GRPCTxRelay, false, peerDisc)
	blkRelay := NewMsgRelay(ctx, wg, 100, GRPCBlkRelay, false, peerDisc)
	blockProp := NewBlockProposer(ctx, wg, blkRelay)

	return &Node{
		cfg:       cfg,
		ctx:       ctx,
		ctxCancel: cancel,
		wg:        wg,
		chErr:     make(chan error),
		evStream:  evStream,
		StateSync: stateSync,
		peerDisc:  peerDisc,
		txRelay:   txRelay,
		blockProp: blockProp,
		blkRelay:  blkRelay,
	}

}
