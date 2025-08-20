package rpc

import (
	"context"

	"github.com/Ansh1902396/chain"
	codes "google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type BalanceChecker interface {
	Balance(acc chain.Address) (uint64, bool)
}

type AccountSrv struct {
	UnimplementedAccountServer
	keyStoreDir string
	balChecker  BalanceChecker
}

func NewAccountSrv(keyStoreDir string, balChecker BalanceChecker) *AccountSrv {
	return &AccountSrv{
		keyStoreDir: keyStoreDir,
		balChecker:  balChecker,
	}
}

func (s *AccountSrv) AccountCreate(ctx context.Context, req *AccountCreateReq) (*AccountCreateRes, error) {
	// Implement account creation logic here
	pass := []byte(req.Password)

	if len(pass) < 5 {
		return nil, status.Errorf(codes.InvalidArgument, "Password must be at least 5 characters long")
	}

	acc, err := chain.NewAccount()
	if err != nil {
		return nil, status.Errorf(codes.Internal, "Failed to create account: %v", err)
	}

	err = acc.Write(s.keyStoreDir, pass)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "Failed to write account to keystore: %v", err)
	}

	return &AccountCreateRes{Address: string(acc.Address())}, nil
}

func (s *AccountSrv) AccountBalance(ctx context.Context, req *AccountBalanceReq) (*AccountBalanceRes, error) {
	if s.balChecker == nil {
		return nil, status.Errorf(codes.Unimplemented, "Balance checker not implemented")
	}

	acc := chain.Address(req.Address)
	balance, ok := s.balChecker.Balance(acc)
	if !ok {
		return nil, status.Errorf(codes.NotFound, "Account not found: %s", acc)
	}

	return &AccountBalanceRes{Balance: balance}, nil
}
