package chain

import (
	"encoding/hex"
	"encoding/json"
	"fmt"
	"time"

	"github.com/dustinxie/ecc"
	"golang.org/x/crypto/sha3"
)

type Hash [32]byte

type Tx struct {
	From  Address   `json:"from"`
	To    Address   `json:"to"`
	Value uint64    `json:"value"`
	Nonce uint64    `json:"nonce"`
	Time  time.Time `json:"time"`
}

type SigTx struct {
	Tx
	Sig []byte `json:"sig"`
}

func NewHash(val any) Hash {
	jval, _ := json.Marshal(val)
	state := sha3.NewLegacyKeccak256()
	_, _ = state.Write(jval)
	hash := state.Sum(nil)
	return Hash(hash)
}

func (h Hash) String() string {

	return hex.EncodeToString(h[:])
}

func (h Hash) Bytes() []byte {
	hash := [32]byte(h)
	return hash[:]
}

func (h Hash) MarshalText() ([]byte, error) {
	return []byte(hex.EncodeToString((h[:]))), nil
}

func (h *Hash) UnmarshalText(hash []byte) error {
	_, err := hex.Decode(h[:], hash)
	return err
}

func DecodeHash(str string) (Hash, error) {
	var hash Hash
	_, err := hex.Decode(hash[:], []byte(str))
	return hash, err
}

func NewTx(from, to Address, value, nonce uint64) Tx {
	return Tx{
		From:  from,
		To:    to,
		Value: value,
		Nonce: nonce,
		Time:  time.Now(),
	}
}

func (t Tx) Hash() Hash {
	return NewHash(t)
}

func NewSigTx(tx Tx, sig []byte) SigTx {
	return SigTx{
		Tx:  tx,
		Sig: sig,
	}
}

func (t SigTx) Hash() Hash {
	return NewHash(t)
}

func TxHash(tx Tx) Hash {
	return NewHash(tx)
}

func (t SigTx) String() string {
	return fmt.Sprintf(
		"tx %.7s: %.7s -> %.7s %8d %8d", t.Hash(), t.From, t.To, t.Value, t.Nonce,
	)
}

func TxPairHash(l, r Hash) Hash {
	var nilHash Hash
	if r == nilHash {
		return l
	}
	return NewHash(l.String() + r.String())
}

func (a Account) SignTx(tx Tx) (SigTx, error) {
	hash := tx.Hash().Bytes()
	sig, err := ecc.SignBytes(a.prv, hash, ecc.LowerS|ecc.RecID)
	if err != nil {
		return SigTx{}, err
	}

	stx := NewSigTx(tx, sig)

	return stx, nil
}

func VerifyTx(tx SigTx) (bool, error) {
	hash := tx.Hash().Bytes()
	pub, err := ecc.RecoverPubkey("P-256k1", hash, tx.Sig)
	if err != nil {
		return false, err
	}
	acc := NewAddress(pub)
	return acc == tx.From, nil
}

func pairHashStr(l, r string) string {
	if r == "" {
		return l
	}
	return l + r
}
