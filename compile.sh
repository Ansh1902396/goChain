#!/bin/bash

# Prerequisites:
# brew install protobuf
# go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
# go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

compile() {
    local proto="$1"
    local import=$(dirname "$proto")
    local out=$(dirname "$import")
    
    echo "Compiling $proto..."
    protoc --proto_path="$import" --go_out="$out" --go-grpc_out="$out" "$proto"
    
    if [ $? -eq 0 ]; then
        echo "✅ Successfully compiled $proto"
    else
        echo "❌ Failed to compile $proto"
        exit 1
    fi
}

echo "🔨 Compiling Protocol Buffer files..."

# Define proto files
node_proto="node/rpc/node.proto"
acc_proto="node/rpc/account.proto"
tx_proto="node/rpc/tx.proto"
blk_proto="node/rpc/block.proto"

# Compile all proto files
compile "$node_proto"
compile "$acc_proto"
compile "$tx_proto"
compile "$blk_proto"

echo "🎉 All Protocol Buffer files compiled successfully!"
