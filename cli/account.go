package cli

import (
	"context"
	"fmt"

	"github.com/Ansh1902396/node/rpc"
	"github.com/spf13/cobra"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

func accountCmd(ctx context.Context) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "account",
		Short: "Manage accounts on the blockchain",
	}
	cmd.AddCommand(AccountCreateCmd(ctx), accountBalanceCmd(ctx))
	return cmd
}

func grpcAccountCreate(
	ctx context.Context,
	addr, ownerPass string,
) (string, error) {
	conn, err := grpc.NewClient(
		addr,
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)

	if err != nil {
		return "", err
	}

	defer conn.Close()

	cln := rpc.NewAccountClient(conn)
	req := &rpc.AccountCreateReq{Password: ownerPass}
	res, err := cln.AccountCreate(ctx, req)
	if err != nil {
		return "", err
	}

	return res.Address, nil
}

func AccountCreateCmd(ctx context.Context) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "create",
		Short: "Creates an account protected with the password",
		RunE: func(cmd *cobra.Command, args []string) error {
			addr, _ := cmd.Flags().GetString("node")
			ownerPass, _ := cmd.Flags().GetString("ownerpass")
			acc, err := grpcAccountCreate(ctx, addr, ownerPass)
			if err != nil {
				return err
			}

			fmt.Println("acc %v\n", acc)
			return nil
		},
	}

	cmd.Flags().String("ownerpass", "", "owner password")
	_ = cmd.MarkFlagRequired("ownerpass")
	return cmd
}

func grpcAccountBalance(ctx context.Context, addr, acc string) (uint64, error) {
	conn, err := grpc.NewClient(
		addr, grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	if err != nil {
		return 0, err
	}
	defer conn.Close()
	cln := rpc.NewAccountClient(conn)
	req := &rpc.AccountBalanceReq{Address: acc}
	res, err := cln.AccountBalance(ctx, req)
	if err != nil {
		return 0, err
	}
	return res.Balance, nil
}

func accountBalanceCmd(ctx context.Context) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "balance",
		Short: "Returns the balance of an account",
		RunE: func(cmd *cobra.Command, _ []string) error {
			addr, _ := cmd.Flags().GetString("node")
			acc, _ := cmd.Flags().GetString("account")
			balance, err := grpcAccountBalance(ctx, addr, acc)
			if err != nil {
				return err
			}
			fmt.Printf("acc %v: %v\n", acc, balance)
			return nil
		},
	}
	cmd.Flags().String("account", "", "account address")
	_ = cmd.MarkFlagRequired("account")
	return cmd
}
