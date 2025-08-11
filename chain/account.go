package chain

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/ecdsa"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"math/big"
	"os"
	"path/filepath"

	"github.com/dustinxie/ecc"
	"golang.org/x/crypto/argon2"
	"golang.org/x/crypto/sha3"
)

type p256k1PublicKey struct {
	Curve string   `json:"curve"`
	X     *big.Int `json:"x"`
	Y     *big.Int `json:"y"`
}

type p256k1PrivateKey struct {
	p256k1PublicKey `json:"publicKey"`
	D               *big.Int `json:"d"`
}

type Account struct {
	prv  *ecdsa.PrivateKey
	addr Address
}

type Address string

const enckeyLen = uint32(32)

func newP256k1PublicKey(pub *ecdsa.PublicKey) p256k1PublicKey {
	return p256k1PublicKey{
		Curve: pub.Curve.Params().Name,
		X:     pub.X,
		Y:     pub.Y,
	}
}

func newP256k1PrivateKey(priv *ecdsa.PrivateKey) p256k1PrivateKey {
	return p256k1PrivateKey{
		p256k1PublicKey: newP256k1PublicKey(&priv.PublicKey),
		D:               priv.D,
	}
}

func (k *p256k1PrivateKey) publicKey() *ecdsa.PublicKey {
	return &ecdsa.PublicKey{Curve: ecc.P256k1(), X: k.X, Y: k.Y}
}

func (k *p256k1PrivateKey) privateKey() *ecdsa.PrivateKey {
	return &ecdsa.PrivateKey{PublicKey: *k.publicKey(), D: k.D}
}

func NewAddress(pub *ecdsa.PublicKey) Address {
	jpub, _ := json.Marshal(newP256k1PublicKey(pub))
	hash := make([]byte, 64)
	sha3.ShakeSum256(hash, jpub)
	return Address(hex.EncodeToString(hash[:32]))
}

func NewAccount() (Account, error) {
	priv, err := ecdsa.GenerateKey(ecc.P256k1(), rand.Reader)
	if err != nil {
		return Account{}, err
	}

	addr := NewAddress(&priv.PublicKey)
	return Account{prv: priv, addr: addr}, nil
}

func (a Account) Address() Address {
	return a.addr
}

func (a Account) encodePrivateKey() ([]byte, error) {
	jprv, err := json.Marshal(newP256k1PrivateKey(a.prv))
	if err != nil {
		return nil, err
	}
	return jprv, nil
}

func encryptWithPassword(msg, pass []byte) ([]byte, error) {
	salt := make([]byte, enckeyLen)
	_, err := rand.Read(salt)
	if err != nil {
		return nil, err
	}

	key := argon2.IDKey(pass, salt, 1, 256, 1, enckeyLen)

	blk, err := aes.NewCipher(key)
	if err != nil {
		return nil, err
	}

	gcm, err := cipher.NewGCM(blk)
	if err != nil {
		return nil, err
	}

	nonce := make([]byte, gcm.NonceSize())
	_, err = rand.Read(nonce)
	if err != nil {
		return nil, err
	}

	ciph := gcm.Seal(nonce, nonce, msg, nil)

	ciph = append(salt, ciph...)
	return ciph, nil
}

func decryptWithPassword(ciph, pass []byte) ([]byte, error) {
	salt, ciph := ciph[:enckeyLen], ciph[enckeyLen:]
	key := argon2.IDKey(pass, salt, 1, 256, 1, enckeyLen)
	blk, err := aes.NewCipher(key)

	if err != nil {
		return nil, err
	}

	gcm, err := cipher.NewGCM(blk)
	if err != nil {
		return nil, err
	}

	nonceLen := gcm.NonceSize()
	nonce, ciph := ciph[:nonceLen], ciph[nonceLen:]

	msg, err := gcm.Open(nil, nonce, ciph, nil)
	if err != nil {
		return nil, err
	}
	return msg, nil

}

func decodePrivateKey(jprv []byte) (Account, error) {
	var privKey p256k1PrivateKey
	if err := json.Unmarshal(jprv, &privKey); err != nil {
		return Account{}, err
	}
	pubKey := privKey.publicKey()
	addr := NewAddress(pubKey)
	return Account{prv: privKey.privateKey(), addr: addr}, nil
}

func (a Account) Write(dir string, pass []byte) error {
	jprv, err := a.encodePrivateKey()
	if err != nil {
		return err
	}

	cprv, err := encryptWithPassword(jprv, pass)

	if err != nil {
		return err
	}

	err = os.MkdirAll(dir, 0700)

	if err != nil {
		return err
	}

	// Write cprv to a file in the specified directory
	path := filepath.Join(dir, string(a.Address()))
	return os.WriteFile(path, cprv, 0600)
}

func ReadAccount(path string, pass []byte) (Account, error) {
	cprv, err := os.ReadFile(path)
	if err != nil {
		return Account{}, err
	}
	jprv, err := decryptWithPassword(cprv, pass)
	if err != nil {
		return Account{}, err
	}
	return decodePrivateKey(jprv)
}
