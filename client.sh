#!/bin/bash

# Configuration
BOOT="localhost:1122"
NODE="localhost:1123"
AUTHPASS="password"
OWNERPASS="password"

# Build the project first
echo "🔨 Building the blockchain node..."
go build -o bcn .

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build successful!"

# Function to sign and send transactions
txSignAndSend() {
    local node="$1"
    local from="$2"
    local to="$3"
    local value="$4"
    local ownerpass="$5"
    
    echo "🔐 Signing transaction: $from -> $to (value: $value)"
    local tx=$(./bcn tx sign --node "$node" --from "$from" --to "$to" --value "$value" --ownerpass "$ownerpass")
    echo "📝 SigTx: $tx"
    
    echo "📤 Sending transaction..."
    ./bcn tx send --node "$node" --sigtx "$tx"
}

# Function to prove and verify transactions
txProveAndVerify() {
    local prover="$1"
    local verifier="$2"
    local hash="$3"
    local mrkroot="$4"
    
    echo "🔍 Proving transaction: $hash"
    local mrkproof=$(./bcn tx prove --node "$prover" --hash "$hash")
    echo "🌳 MerkleProof: $mrkproof"
    echo "🌳 MerkleRoot: $mrkroot"
    
    echo "✅ Verifying transaction..."
    ./bcn tx verify --node "$verifier" --hash "$hash" --mrkproof "$mrkproof" --mrkroot "$mrkroot"
}

# Account addresses
ACC1="231c83f0a857cfb1e88f8adb92371e01aa1bdc80ef88ea443a2fccf02f444720"
ACC2="cb68e5de26f72110e13e47b2519fcd48ca941a0f4f572bd9751654d01499b910"

# Transaction hashes and merkle roots
TX1="6040ff5315af566ed974a737dbf460f04e73c9a713ef494e9baacfe7dd5dc8f1"
MRK1="6040ff5315af566ed974a737dbf460f04e73c9a713ef494e9baacfe7dd5dc8f1"
TX2="b87703f6bf0035613f638657293da795bc771ff414c000da894b05d22f5a70b8"
MRK2="b87703f6bf0035613f638657293da795bc771ff414c000da894b05d22f5a70b8"

echo "🚀 Starting blockchain client operations..."

# Uncomment the lines below to run specific operations:

# Send transactions
# echo "💰 Sending transactions..."
# txSignAndSend "$BOOT" "$ACC1" "$ACC2" 2 "$OWNERPASS"
# txSignAndSend "$BOOT" "$ACC2" "$ACC1" 1 "$OWNERPASS"

# Prove and verify transactions on bootstrap node
# echo "🔍 Proving and verifying on bootstrap node..."
# txProveAndVerify "$BOOT" "$BOOT" "$TX1" "$MRK1"
# txProveAndVerify "$BOOT" "$BOOT" "$TX2" "$MRK2"

# Prove and verify transactions between nodes
# echo "🔍 Cross-node verification..."
# txProveAndVerify "$NODE" "$BOOT" "$TX1" "$MRK1"
# txProveAndVerify "$NODE" "$BOOT" "$TX2" "$MRK2"
# txProveAndVerify "$NODE" "$BOOT" "$TX1" "$MRK2"

echo "✅ Client script ready! Uncomment the operations you want to run."
