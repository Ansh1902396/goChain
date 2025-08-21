#!/bin/bash

# Quick start script for the Go blockchain
# This script sets up everything needed to run the blockchain

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo "🚀 Go Blockchain Quick Start"
echo "============================="

# Step 1: Check prerequisites
print_step "1. Checking prerequisites..."

if ! command -v protoc &> /dev/null; then
    print_warning "protoc not found. Please install it with: brew install protobuf"
    exit 1
fi

if ! command -v protoc-gen-go &> /dev/null; then
    print_warning "protoc-gen-go not found. Please install it with: go install google.golang.org/protobuf/cmd/protoc-gen-go@latest"
    exit 1
fi

if ! command -v protoc-gen-go-grpc &> /dev/null; then
    print_warning "protoc-gen-go-grpc not found. Please install it with: go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest"
    exit 1
fi

print_status "✅ All prerequisites are installed!"

# Step 2: Compile protobuf files
print_step "2. Compiling Protocol Buffer files..."
./compile.sh || {
    echo "❌ Protobuf compilation failed!"
    exit 1
}

# Step 3: Build the Go application
print_step "3. Building the Go application..."
go build -o bcn . || {
    echo "❌ Go build failed!"
    exit 1
}

print_status "✅ Application built successfully!"

# Step 4: Start the blockchain network
print_step "4. Starting the blockchain network..."
./run-node.sh start-all

# Step 5: Show status
print_step "5. Checking node status..."
sleep 3  # Give nodes time to start
./run-node.sh status

echo ""
echo "🎉 Blockchain network is ready!"
echo ""
echo "Next steps:"
echo "1. Edit client.sh to uncomment the operations you want to run"
echo "2. Run ./client.sh to perform blockchain operations"
echo "3. Use ./run-node.sh status to check node health"
echo "4. Use ./run-node.sh stop to stop the network when done"
echo ""
echo "Useful commands:"
echo "  ./run-node.sh status    # Check node status"
echo "  ./run-node.sh stop      # Stop all nodes"
echo "  ./run-node.sh restart   # Restart all nodes"
echo "  ./client.sh             # Run blockchain operations"
