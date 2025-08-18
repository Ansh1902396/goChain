package node

import (
	"context"
	"fmt"

	"github.com/Ansh1902396/chain"
)

type StateSync struct {
	// Define the fields for the StateSync struct
	cfg        NodeCfg
	ctx        context.Context
	state      *chain.State
	peerReader PeerReader
}

func NewStateSync(
	ctx context.Context, cfg NodeCfg, peerReader PeerReader,
) *StateSync {
	return &StateSync{
		ctx:        ctx,
		cfg:        cfg,
		peerReader: peerReader,
	}

}

func (s *StateSync) SyncState() (*chain.State, error) {
	gen, err := chain.ReadGenesis(s.cfg.BlockStoreDir)
	if err != nil {
		if s.cfg.Bootstrap {
			gen, err = s.createGenesis()
			if err != nil {
				return nil, err
			}
		} else {
			gen, err := s.syncGenesis()
			if err != nil {
				return nil, err
			}
		}
	}

	valid, err := chain.VerifyGen(gen)
	if err != nil {
		return nil, err
	}
	if !valid {
		return nil, fmt.Errorf("invalid genesis signature")
	}
	s.state = chain.NewState(&gen)
	err = chain.InitBlockStore(s.cfg.BlockStoreDir)
	if err != nil {
		return nil, err
	}

	err = s.readBlocks()

	if err != nil {
		return nil, err
	}

	err = s.syncBlocks()

	if err != nil {
		return nil, err
	}

	fmt.Printf("=== Sync state \n %v", s.state)
	return s.state, nil

}

func (s *StateSync) createGenesis() (chain.SigGenesis, error) {
	authPass := []byte(s.cfg.AuthorityPass)
	if len(authPass) < 5 {
		return chain.SigGenesis{}, fmt.Errorf("authority password must be at least 5 characters long")
	}
	auth, err := chain.NewAccount()

	if err != nil {
		return chain.SigGenesis{}, err
	}

	ownerPass := []byte(s.cfg.OwnerPass)
	if len(ownerPass) < 5 {
		return chain.SigGenesis{}, fmt.Errorf("owner password must be at least 5 characters long")
	}

	if s.cfg.Balance == 0 {
		return chain.SigGenesis{}, fmt.Errorf("balance must be greater than 0")
	}

	acc, err := chain.NewAccount()
	if err != nil {
		return chain.SigGenesis{}, err
	}

	err = acc.Write(s.cfg.KeyStoreDir, ownerPass)
	s.cfg.OwnerPass = "erase"

	if err != nil {
		return chain.SigGenesis{}, err
	}

	gen := chain.NewGenesis(
		s.cfg.Chain , auth.Address() , acc.Address() , s.cfg.Balance
	)

	sgen, err := auth.SignGen(gen)
	if err != nil {
		return chain.SigGenesis{}, err
	}

	err = sgen.Write(s.cfg.BlockStoreDir)
	if err != nil {
		return chain.SigGenesis{}, err
	}

	return sgen, nil

}
