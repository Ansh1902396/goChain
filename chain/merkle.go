package chain

import (
	"fmt"
	"math"
)

func MerkleHash[T any, H comparable](
	txs []T, typeHash func(T) H, pairHash func(H, H) H,
) ([]H, error) {
	if len(txs) == 0 {
		return nil, fmt.Errorf("merkle: no transactions to create a merkle tree")
	}
	htxs := make([]H, len(txs))
	for i, tx := range txs {
		htxs[i] = typeHash(tx)
	}
	l := int(math.Pow(2, math.Ceil(math.Log2(float64(len(htxs))))+1) - 1)
	merkleTree := make([]H, l)
	chd := l / 2
	for i, j := 0, chd; i < len(htxs); i, j = i+1, j+1 {
		merkleTree[j] = htxs[i]
	}

	l, par := chd*2, chd/2

	for chd > 0 {
		for i, j := chd, par; i < l; i, j = i+2, j+1 {
			merkleTree[j] = pairHash(merkleTree[i], merkleTree[i+1])
		}
		chd /= 2
		l, par = chd*2, chd/2
	}

	return merkleTree, nil
}
