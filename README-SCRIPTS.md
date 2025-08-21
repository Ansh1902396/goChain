# Go Blockchain Node Scripts

This repository contains shell scripts to manage your Go blockchain project on macOS.

## Prerequisites

Before running the scripts, make sure you have the following installed:

```bash
# Install Protocol Buffers compiler
brew install protobuf

# Install Go protobuf plugins
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# Make sure Go is installed and GOPATH is set correctly
go version
```

## Scripts Overview

### 1. `compile.sh` - Protocol Buffer Compilation
Compiles all the `.proto` files in the `node/rpc/` directory.

```bash
./compile.sh
```

**What it does:**
- Compiles `node.proto`, `account.proto`, `tx.proto`, and `block.proto`
- Generates Go files for gRPC communication
- Shows success/failure status for each file

### 2. `run-node.sh` - Node Management
Manages blockchain nodes (bootstrap and regular nodes).

```bash
# Show help
./run-node.sh help

# Start bootstrap node only
./run-node.sh start-bootstrap

# Start regular node only (requires bootstrap to be running)
./run-node.sh start-node

# Start both nodes
./run-node.sh start-all

# Check status of running nodes
./run-node.sh status

# Stop all nodes
./run-node.sh stop

# Restart all nodes
./run-node.sh restart
```

**Node Configuration:**
- **Bootstrap Node**: `localhost:1122` (authority node)
- **Regular Node**: `localhost:1123` (connects to bootstrap)
- **Chain Name**: `blockchain`
- **Passwords**: `password` (both auth and owner)
- **Initial Balance**: `1000`

### 3. `client.sh` - Blockchain Operations
Performs blockchain operations like transactions, proofs, and verifications.

```bash
./client.sh
```

**What it includes:**
- Transaction signing and sending functions
- Merkle proof generation and verification
- Pre-configured account addresses and transaction hashes
- Example operations (commented out by default)

## Getting Started

### Step 1: Compile Protocol Buffers
```bash
./compile.sh
```

### Step 2: Start the Blockchain Nodes
```bash
# Start both nodes
./run-node.sh start-all

# Or start them individually
./run-node.sh start-bootstrap
sleep 5  # Wait for bootstrap to be ready
./run-node.sh start-node
```

### Step 3: Check Node Status
```bash
./run-node.sh status
```

### Step 4: Run Client Operations
Edit `client.sh` to uncomment the operations you want to run:

```bash
# Edit the script
nano client.sh

# Uncomment desired operations, then run
./client.sh
```

## Example Workflow

1. **Compile protobuf files:**
   ```bash
   ./compile.sh
   ```

2. **Start the blockchain network:**
   ```bash
   ./run-node.sh start-all
   ```

3. **Verify nodes are running:**
   ```bash
   ./run-node.sh status
   ```

4. **Perform blockchain operations:**
   ```bash
   # Edit client.sh to uncomment desired operations
   ./client.sh
   ```

5. **Stop the network when done:**
   ```bash
   ./run-node.sh stop
   ```

## Configuration

### Default Settings
- **Bootstrap Node**: `localhost:1122`
- **Regular Node**: `localhost:1123`
- **Authority Password**: `password`
- **Owner Password**: `password`
- **Initial Balance**: `1000`
- **Chain Name**: `blockchain`

### Accounts (from original Fish scripts)
- **Account 1**: `231c83f0a857cfb1e88f8adb92371e01aa1bdc80ef88ea443a2fccf02f444720`
- **Account 2**: `cb68e5de26f72110e13e47b2519fcd48ca941a0f4f572bd9751654d01499b910`

### Sample Transactions
- **TX1**: `6040ff5315af566ed974a737dbf460f04e73c9a713ef494e9baacfe7dd5dc8f1`
- **TX2**: `b87703f6bf0035613f638657293da795bc771ff414c000da894b05d22f5a70b8`

## Troubleshooting

### Port Already in Use
If you get port conflicts:
```bash
# Kill processes on specific ports
lsof -ti:1122 | xargs kill -9
lsof -ti:1123 | xargs kill -9

# Or use the stop command
./run-node.sh stop
```

### Build Failures
Make sure you have all dependencies:
```bash
go mod tidy
go build .
```

### Protocol Buffer Issues
Ensure protobuf tools are installed:
```bash
protoc --version
which protoc-gen-go
which protoc-gen-go-grpc
```

## File Structure

```
go-blockchain/
├── compile.sh          # Compiles .proto files
├── run-node.sh         # Manages blockchain nodes
├── client.sh           # Blockchain operations
├── main.go             # Main Go application
├── go.mod              # Go module file
├── node/
│   └── rpc/
│       ├── *.proto     # Protocol buffer definitions
│       └── *.pb.go     # Generated Go files
├── cli/                # CLI commands
└── chain/              # Blockchain logic
```

## Notes

- The scripts are designed to work with macOS and zsh shell
- Make sure ports 1122 and 1123 are available
- The bootstrap node must be started before the regular node
- Data directories (`.keystore*` and `.blockstore*`) are created automatically
- Process IDs are stored in `.bootstrap.pid` and `.node.pid` files for management
