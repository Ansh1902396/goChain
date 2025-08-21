# RuChain CLI

RuChain is a comprehensive command-line interface for managing blockchain nodes, accounts, transactions, and blocks.

## 🚀 Installation

### Quick Install

Run the installation script to install RuChain globally:

```bash
./install-ruchain.sh
```

After installation, restart your terminal or source your shell configuration:

```bash
# For zsh users
source ~/.zshrc

# For bash users  
source ~/.bashrc
```

### Manual Installation

1. Build the binary:
   ```bash
   go build -o RuChain .
   ```

2. Move to a directory in your PATH:
   ```bash
   cp RuChain /usr/local/bin/RuChain
   # or
   cp RuChain ~/bin/RuChain
   ```

## ⚡ Quick Start

### 30-Second Demo

```bash
# 1. Install RuChain
./install-ruchain.sh

# 2. Start bootstrap node (Terminal 1)
RuChain node start --node localhost:1122 --bootstrap --chain ruddychain --authpass password123 --ownerpass password123 --balance 1000 --keystore .keystore1122 --blockstore .blockstore1122

# 3. In another terminal, create account and send transaction
ACC2=$(RuChain account create --node localhost:1122 --ownerpass mypass123)
GENESIS_ACC="d0c31231f81744e7e48848f22ed16f07c16466dce30bd169d4ae87a18fa39df3"

# 4. Send 100 tokens
TX=$(RuChain tx sign --node localhost:1122 --from $GENESIS_ACC --to $ACC2 --value 100 --ownerpass password123)
RuChain tx send --node localhost:1122 --sigtx "$TX"

# 5. Check balance
RuChain account balance --node localhost:1122 --account $ACC2
```

## 📖 Usage

Once installed, you can use `RuChain` from anywhere in your terminal.

### General Syntax

```bash
RuChain [command] [subcommand] [flags]
```

### Global Flags

- `--node string`: Target node address (host:port) - **Required for most commands**
- `--help`: Show help information
- `--version`: Show version information

## 🔧 Command Reference

### Node Commands

| Command | Description | Example |
|---------|-------------|---------|
| `RuChain node start` | Start a blockchain node | `RuChain node start --node localhost:1122 --bootstrap ...` |
| `RuChain node subscribe` | Subscribe to node events | `RuChain node subscribe --node localhost:1122` |

#### Node Start Flags
- `--bootstrap`: Start as bootstrap/authority node
- `--seed string`: Connect to existing node (host:port)
- `--chain string`: Blockchain name (default: "blockchain")
- `--authpass string`: Authority account password (required for bootstrap)
- `--ownerpass string`: Owner account password
- `--balance uint64`: Initial balance for owner account
- `--keystore string`: Keystore directory path
- `--blockstore string`: Blockstore directory path

### Account Commands

| Command | Description | Example |
|---------|-------------|---------|
| `RuChain account create` | Create new account | `RuChain account create --node localhost:1122 --ownerpass mypass` |
| `RuChain account balance` | Check account balance | `RuChain account balance --node localhost:1122 --account <address>` |

#### Account Flags
- `--ownerpass string`: Password for account creation
- `--account string`: Account address for balance check

### Transaction Commands

| Command | Description | Example |
|---------|-------------|---------|
| `RuChain tx sign` | Sign a transaction | `RuChain tx sign --node localhost:1122 --from <addr> --to <addr> --value 100 --ownerpass mypass` |
| `RuChain tx send` | Send signed transaction | `RuChain tx send --node localhost:1122 --sigtx <signed-tx>` |
| `RuChain tx prove` | Generate Merkle proof | `RuChain tx prove --node localhost:1122 --hash <tx-hash>` |
| `RuChain tx verify` | Verify Merkle proof | `RuChain tx verify --node localhost:1122 --hash <tx-hash> --mrkproof <proof> --mrkroot <root>` |

#### Transaction Flags
- `--from string`: Sender account address
- `--to string`: Recipient account address
- `--value uint64`: Amount to transfer
- `--ownerpass string`: Sender's account password
- `--sigtx string`: Signed transaction data
- `--hash string`: Transaction hash
- `--mrkproof string`: Merkle proof
- `--mrkroot string`: Merkle root

### Block Commands

| Command | Description | Example |
|---------|-------------|---------|
| `RuChain block get` | Get block information | `RuChain block get --node localhost:1122` |
| `RuChain block genesis` | Sync genesis block | `RuChain block genesis --node localhost:1122` |

#### Block Flags
- `--number uint64`: Get block by number
- `--hash string`: Get block by hash
- (no flags): Get latest block

## 🏗️ Commands

### Node Management

#### Start a Bootstrap Node
```bash
RuChain node start --node localhost:1122 --bootstrap --chain ruddychain --authpass password123 --ownerpass password123 --balance 1000 --keystore .keystore1122 --blockstore .blockstore1122
```

#### Start a Regular Node
```bash
RuChain node start --node localhost:1123 --seed localhost:1122 --keystore .keystore1123 --blockstore .blockstore1123
```

#### Subscribe to Node Events
```bash
RuChain node subscribe --node localhost:1122
```

### Account Management

#### Create a New Account
```bash
RuChain account create --node localhost:1122 --ownerpass mypassword
```

#### Check Account Balance
```bash
RuChain account balance --node localhost:1122 --account <account-address>
```

### Transaction Management

#### Sign a Transaction
```bash
RuChain tx sign --node localhost:1122 --from <from-address> --to <to-address> --value 100 --ownerpass mypassword
```

#### Send a Signed Transaction
```bash
RuChain tx send --node localhost:1122 --sigtx <signed-transaction>
```

#### Prove Transaction in Merkle Tree
```bash
RuChain tx prove --node localhost:1122 --hash <transaction-hash>
```

#### Verify Transaction Proof
```bash
RuChain tx verify --node localhost:1122 --hash <tx-hash> --mrkproof <merkle-proof> --mrkroot <merkle-root>
```

### Block Management

#### Get Latest Block
```bash
RuChain block get --node localhost:1122
```

#### Get Block by Number
```bash
RuChain block get --node localhost:1122 --number 1
```

#### Get Block by Hash
```bash
RuChain block get --node localhost:1122 --hash <block-hash>
```

#### Sync Genesis Block
```bash
RuChain block genesis --node localhost:1122
```

## 🌐 Complete Workflow Examples

### Example 1: Single Node Setup with Transactions

#### Step 1: Start Bootstrap Node
```bash
# Clean up any existing data (optional)
rm -rf .keystore1122 .blockstore1122

# Start the bootstrap node
RuChain node start --node localhost:1122 --bootstrap --chain ruddychain --authpass password123 --ownerpass password123 --balance 1000 --keystore .keystore1122 --blockstore .blockstore1122
```

#### Step 2: Create New Accounts
```bash
# In a new terminal, create recipient account
ACC2=$(RuChain account create --node localhost:1122 --ownerpass mypassword123)
echo "New account created: $ACC2"

# The genesis account (sender) already exists with 1000 balance
ACC1="d0c31231f81744e7e48848f22ed16f07c16466dce30bd169d4ae87a18fa39df3"
```

#### Step 3: Check Balances
```bash
# Check sender balance
RuChain account balance --node localhost:1122 --account $ACC1

# Check recipient balance (should be 0)
RuChain account balance --node localhost:1122 --account $ACC2
```

#### Step 4: Send Transaction
```bash
# Sign a transaction (sending 100 tokens from ACC1 to ACC2)
TX=$(RuChain tx sign --node localhost:1122 --from $ACC1 --to $ACC2 --value 100 --ownerpass password123)
echo "Signed transaction: $TX"

# Send the transaction
RuChain tx send --node localhost:1122 --sigtx "$TX"
```

#### Step 5: Verify Transaction
```bash
# Check balances after transaction
echo "Checking balances after transaction..."
RuChain account balance --node localhost:1122 --account $ACC1  # Should be 900
RuChain account balance --node localhost:1122 --account $ACC2  # Should be 100

# Get latest block to see the transaction
RuChain block get --node localhost:1122
```

### Example 2: Multi-Node Setup

#### Step 1: Start Bootstrap Node
```bash
# Terminal 1: Start bootstrap node
RuChain node start --node localhost:1122 --bootstrap --chain ruddychain --authpass password123 --ownerpass password123 --balance 1000 --keystore .keystore1122 --blockstore .blockstore1122
```

#### Step 2: Start Additional Nodes
```bash
# Terminal 2: Start second node
RuChain node start --node localhost:1123 --seed localhost:1122 --keystore .keystore1123 --blockstore .blockstore1123

# Terminal 3: Start third node
RuChain node start --node localhost:1124 --seed localhost:1122 --keystore .keystore1124 --blockstore .blockstore1124
```

#### Step 3: Create Accounts on Different Nodes
```bash
# Create account on node 1122
ACC1=$(RuChain account create --node localhost:1122 --ownerpass password123)

# Create account on node 1123
ACC2=$(RuChain account create --node localhost:1123 --ownerpass password123)

# Create account on node 1124
ACC3=$(RuChain account create --node localhost:1124 --ownerpass password123)
```

#### Step 4: Cross-Node Transactions
```bash
# Use the genesis account (with initial balance)
GENESIS_ACC="d0c31231f81744e7e48848f22ed16f07c16466dce30bd169d4ae87a18fa39df3"

# Send from genesis to ACC1 via node 1122
TX1=$(RuChain tx sign --node localhost:1122 --from $GENESIS_ACC --to $ACC1 --value 100 --ownerpass password123)
RuChain tx send --node localhost:1122 --sigtx "$TX1"

# Send from ACC1 to ACC2 via node 1123
TX2=$(RuChain tx sign --node localhost:1123 --from $ACC1 --to $ACC2 --value 50 --ownerpass password123)
RuChain tx send --node localhost:1123 --sigtx "$TX2"

# Send from ACC2 to ACC3 via node 1124
TX3=$(RuChain tx sign --node localhost:1124 --from $ACC2 --to $ACC3 --value 25 --ownerpass password123)
RuChain tx send --node localhost:1124 --sigtx "$TX3"
```

#### Step 5: Verify Synchronization
```bash
# Check that all nodes have the same latest block
echo "Node 1122 latest block:"
RuChain block get --node localhost:1122

echo "Node 1123 latest block:"
RuChain block get --node localhost:1123

echo "Node 1124 latest block:"
RuChain block get --node localhost:1124
```

### Example 3: Transaction Proof and Verification

#### Step 1: Send a Transaction and Get Hash
```bash
# Send transaction and capture the transaction hash from output
TX=$(RuChain tx sign --node localhost:1122 --from $ACC1 --to $ACC2 --value 50 --ownerpass password123)
RuChain tx send --node localhost:1122 --sigtx "$TX"

# Replace with actual transaction hash from the output
TX_HASH="your_transaction_hash_here"
```

#### Step 2: Generate Merkle Proof
```bash
# Generate proof for the transaction
PROOF=$(RuChain tx prove --node localhost:1122 --hash $TX_HASH)
echo "Merkle Proof: $PROOF"
```

#### Step 3: Get Merkle Root
```bash
# Get the latest block to extract merkle root
LATEST_BLOCK=$(RuChain block get --node localhost:1122)
# Extract merkle root from the block (you'll need to parse this)
MERKLE_ROOT="your_merkle_root_here"
```

#### Step 4: Verify Proof
```bash
# Verify the transaction proof
RuChain tx verify --node localhost:1122 --hash $TX_HASH --mrkproof "$PROOF" --mrkroot $MERKLE_ROOT
```

### Example 4: Node Event Monitoring

#### Subscribe to Events
```bash
# In a separate terminal, subscribe to node events
RuChain node subscribe --node localhost:1122
```

This will show real-time events like:
- New transactions
- Block creation
- Node connections
- State changes

### Example 5: Batch Operations Script

Create a script for automated testing:

```bash
#!/bin/bash
# batch_transactions.sh

NODE="localhost:1122"
GENESIS_ACC="d0c31231f81744e7e48848f22ed16f07c16466dce30bd169d4ae87a18fa39df3"

echo "Creating 5 accounts and sending transactions..."

# Create multiple accounts
for i in {1..5}; do
    ACC=$(RuChain account create --node $NODE --ownerpass "password$i")
    echo "Account $i: $ACC"
    
    # Send 10 tokens to each account
    TX=$(RuChain tx sign --node $NODE --from $GENESIS_ACC --to $ACC --value 10 --ownerpass password123)
    RuChain tx send --node $NODE --sigtx "$TX"
    
    echo "Sent 10 tokens to account $i"
    sleep 1
done

echo "Batch operations completed!"
```

### Example 6: Network Stress Test

```bash
#!/bin/bash
# stress_test.sh

NODE="localhost:1122"
SENDER="d0c31231f81744e7e48848f22ed16f07c16466dce30bd169d4ae87a18fa39df3"

# Create recipient account
RECIPIENT=$(RuChain account create --node $NODE --ownerpass testpass)

echo "Starting stress test with 100 transactions..."

for i in {1..100}; do
    TX=$(RuChain tx sign --node $NODE --from $SENDER --to $RECIPIENT --value 1 --ownerpass password123)
    RuChain tx send --node $NODE --sigtx "$TX" &
    
    if [ $((i % 10)) -eq 0 ]; then
        echo "Sent $i transactions..."
        wait  # Wait for batch to complete
    fi
done

wait
echo "Stress test completed!"

# Check final balances
echo "Final recipient balance:"
RuChain account balance --node $NODE --account $RECIPIENT
```

## 🔧 Configuration

### Default Ports
- Bootstrap Node: `localhost:1122`
- Node 2: `localhost:1123`
- Node 3: `localhost:1124`

### Default Passwords
- Authority Password: `password123`
- Owner Password: `password123`

### Storage Directories
- Keystore: `.keystore<port>` (e.g., `.keystore1122`)
- Blockstore: `.blockstore<port>` (e.g., `.blockstore1122`)

## 🛠️ Development

### Building from Source
```bash
git clone <repository-url>
cd go-blockchain
go build -o RuChain .
```

### Running Tests
```bash
go test ./...
```

## 📁 Project Structure

```
├── RuChain                 # Main CLI binary
├── cli/                    # CLI command implementations
│   ├── account.go         # Account management commands
│   ├── block.go           # Block management commands
│   ├── chain.go           # Main CLI setup
│   ├── node.go            # Node management commands
│   └── tx.go              # Transaction management commands
├── chain/                  # Core blockchain logic
├── node/                   # Node implementation
└── install-ruchain.sh     # Global installation script
```

## 🆘 Troubleshooting

### Command Not Found
If you get "command not found" error:
1. Make sure RuChain is in your PATH
2. Restart your terminal
3. Run `source ~/.zshrc` or `source ~/.bashrc`

### Connection Errors
- Ensure the target node is running
- Check the node address and port
- Verify firewall settings

### Permission Errors
- Make sure you have write permissions to keystore/blockstore directories
- Use appropriate passwords for account operations

## 📄 License

[Your License Here]

## 🤝 Contributing

[Contributing Guidelines Here]
