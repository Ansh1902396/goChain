#!/bin/bash

# Multi-Node Blockchain Client Script
# Supports operations with 3 nodes simultaneously

# Get script directory for finding the binary
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BCN_BINARY="$SCRIPT_DIR/bcn"

# Configuration for 3 nodes
BOOTSTRAP="localhost:1122"  # Node 1
NODE2="localhost:1123"      # Node 2  
NODE3="localhost:1124"      # Node 3
AUTHPASS="password"
OWNERPASS="password"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_operation() {
    echo -e "${PURPLE}[OP]${NC} $1"
}

print_result() {
    echo -e "${CYAN}[RESULT]${NC} $1"
}

# Check if binary exists
if [ ! -f "$BCN_BINARY" ]; then
    echo "❌ Blockchain binary not found at $BCN_BINARY"
    echo "Run 'go build -o bcn .' first"
    exit 1
fi

# Function to sign and send transactions
txSignAndSend() {
    local node="$1"
    local from="$2"
    local to="$3"
    local value="$4"
    local ownerpass="$5"
    
    print_operation "Signing transaction: $from -> $to (value: $value) via $node"
    local tx=$($BCN_BINARY tx sign --node "$node" --from "$from" --to "$to" --value "$value" --ownerpass "$ownerpass" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$tx" ]; then
        print_result "SigTx: $tx"
        
        print_operation "Sending transaction via $node..."
        local result=$($BCN_BINARY tx send --node "$node" --sigtx "$tx" 2>/dev/null)
        
        if [ $? -eq 0 ]; then
            print_result "✅ Transaction sent successfully!"
            [ -n "$result" ] && print_result "Response: $result"
        else
            echo "❌ Failed to send transaction"
        fi
    else
        echo "❌ Failed to sign transaction"
    fi
    echo ""
}

# Function to prove and verify transactions
txProveAndVerify() {
    local prover="$1"
    local verifier="$2"
    local hash="$3"
    local mrkroot="$4"
    
    print_operation "Proving transaction: $hash via $prover"
    local mrkproof=$($BCN_BINARY tx prove --node "$prover" --hash "$hash" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$mrkproof" ]; then
        print_result "MerkleProof: $mrkproof"
        print_result "MerkleRoot: $mrkroot"
        
        print_operation "Verifying transaction via $verifier..."
        local result=$($BCN_BINARY tx verify --node "$verifier" --hash "$hash" --mrkproof "$mrkproof" --mrkroot "$mrkroot" 2>/dev/null)
        
        if [ $? -eq 0 ]; then
            print_result "✅ Transaction verification successful!"
            [ -n "$result" ] && print_result "Response: $result"
        else
            echo "❌ Transaction verification failed"
        fi
    else
        echo "❌ Failed to generate proof"
    fi
    echo ""
}

# Function to check node connectivity
checkNodeConnectivity() {
    local node="$1"
    local node_name="$2"
    
    print_operation "Checking connectivity to $node_name ($node)..."
    # Try a simple command to test connectivity
    local result=$($BCN_BINARY account list --node "$node" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        print_result "✅ $node_name is accessible"
        return 0
    else
        echo "❌ $node_name is not accessible"
        return 1
    fi
}

# Function to create accounts on all nodes
createAccountsOnAllNodes() {
    print_step "Creating accounts on all nodes..."
    
    for i in 1 2 3; do
        case $i in
            1) node="$BOOTSTRAP"; name="Bootstrap" ;;
            2) node="$NODE2"; name="Node2" ;;
            3) node="$NODE3"; name="Node3" ;;
        esac
        
        print_operation "Creating account on $name ($node)..."
        local result=$($BCN_BINARY account create --node "$node" --ownerpass "$OWNERPASS" 2>/dev/null)
        
        if [ $? -eq 0 ]; then
            print_result "✅ Account created on $name"
            [ -n "$result" ] && print_result "Address: $result"
        else
            echo "❌ Failed to create account on $name"
        fi
    done
    echo ""
}

# Function to list accounts on all nodes
listAccountsOnAllNodes() {
    print_step "Listing accounts on all nodes..."
    
    for i in 1 2 3; do
        case $i in
            1) node="$BOOTSTRAP"; name="Bootstrap" ;;
            2) node="$NODE2"; name="Node2" ;;
            3) node="$NODE3"; name="Node3" ;;
        esac
        
        print_operation "Accounts on $name ($node):"
        local result=$($BCN_BINARY account list --node "$node" 2>/dev/null)
        
        if [ $? -eq 0 ]; then
            if [ -n "$result" ]; then
                print_result "$result"
            else
                print_result "No accounts found"
            fi
        else
            echo "❌ Failed to list accounts on $name"
        fi
        echo ""
    done
}

# Account addresses (from original script)
ACC1="231c83f0a857cfb1e88f8adb92371e01aa1bdc80ef88ea443a2fccf02f444720"
ACC2="cb68e5de26f72110e13e47b2519fcd48ca941a0f4f572bd9751654d01499b910"

# Transaction hashes and merkle roots (from original script)
TX1="6040ff5315af566ed974a737dbf460f04e73c9a713ef494e9baacfe7dd5dc8f1"
MRK1="6040ff5315af566ed974a737dbf460f04e73c9a713ef494e9baacfe7dd5dc8f1"
TX2="b87703f6bf0035613f638657293da795bc771ff414c000da894b05d22f5a70b8"
MRK2="b87703f6bf0035613f638657293da795bc771ff414c000da894b05d22f5a70b8"

echo "🚀 Multi-Node Blockchain Client Operations"
echo "=========================================="

print_step "Checking node connectivity..."

# Check if all nodes are accessible
bootstrap_ok=false
node2_ok=false
node3_ok=false

checkNodeConnectivity "$BOOTSTRAP" "Bootstrap Node" && bootstrap_ok=true
checkNodeConnectivity "$NODE2" "Node 2" && node2_ok=true
checkNodeConnectivity "$NODE3" "Node 3" && node3_ok=true

echo ""

if [ "$bootstrap_ok" = false ]; then
    echo "❌ Bootstrap node is not running. Start it with: blockchain-nodes start 1"
    exit 1
fi

# Show available operations
echo "📋 Available Operations:"
echo "======================="
echo ""

if [ "$1" = "connectivity" ]; then
    print_step "Connectivity check completed."
    exit 0
fi

if [ "$1" = "accounts" ]; then
    listAccountsOnAllNodes
    exit 0
fi

if [ "$1" = "create-accounts" ]; then
    createAccountsOnAllNodes
    exit 0
fi

# Default operations (commented out - uncomment what you want to run)
echo "💡 Uncomment the operations below that you want to run:"
echo ""

# Example 1: Send transactions between different nodes
echo "# Cross-node transactions:"
echo "# txSignAndSend \"$BOOTSTRAP\" \"$ACC1\" \"$ACC2\" 2 \"$OWNERPASS\""
echo "# txSignAndSend \"$NODE2\" \"$ACC2\" \"$ACC1\" 1 \"$OWNERPASS\""
echo "# txSignAndSend \"$NODE3\" \"$ACC1\" \"$ACC2\" 3 \"$OWNERPASS\""

# Uncomment these to run cross-node transactions:
# txSignAndSend "$BOOTSTRAP" "$ACC1" "$ACC2" 2 "$OWNERPASS"
# txSignAndSend "$NODE2" "$ACC2" "$ACC1" 1 "$OWNERPASS"
# txSignAndSend "$NODE3" "$ACC1" "$ACC2" 3 "$OWNERPASS"

echo ""
echo "# Proof and verification operations:"
echo "# txProveAndVerify \"$BOOTSTRAP\" \"$BOOTSTRAP\" \"$TX1\" \"$MRK1\""
echo "# txProveAndVerify \"$NODE2\" \"$BOOTSTRAP\" \"$TX2\" \"$MRK2\""
echo "# txProveAndVerify \"$NODE3\" \"$NODE2\" \"$TX1\" \"$MRK1\""

# Uncomment these to run proof and verification:
# txProveAndVerify "$BOOTSTRAP" "$BOOTSTRAP" "$TX1" "$MRK1"
# txProveAndVerify "$NODE2" "$BOOTSTRAP" "$TX2" "$MRK2" 
# txProveAndVerify "$NODE3" "$NODE2" "$TX1" "$MRK1"

echo ""
echo "📖 Usage Examples:"
echo "=================="
echo ""
echo "1. Check node connectivity:"
echo "   ./client.sh connectivity"
echo ""
echo "2. List all accounts:"
echo "   ./client.sh accounts"
echo ""
echo "3. Create accounts on all nodes:"
echo "   ./client.sh create-accounts"
echo ""
echo "4. Run custom operations:"
echo "   Edit this script and uncomment the operations you want"
echo ""

# Interactive mode
if [ "$1" = "interactive" ]; then
    echo "🎮 Interactive Mode"
    echo "=================="
    echo ""
    echo "Choose an operation:"
    echo "1) Send transaction from Bootstrap to Node2"
    echo "2) Send transaction from Node2 to Node3" 
    echo "3) Send transaction from Node3 to Bootstrap"
    echo "4) Prove and verify transaction"
    echo "5) List accounts on all nodes"
    echo "6) Exit"
    echo ""
    read -p "Enter your choice (1-6): " choice
    
    case $choice in
        1)
            txSignAndSend "$BOOTSTRAP" "$ACC1" "$ACC2" 5 "$OWNERPASS"
            ;;
        2)
            txSignAndSend "$NODE2" "$ACC2" "$ACC1" 3 "$OWNERPASS"
            ;;
        3)
            txSignAndSend "$NODE3" "$ACC1" "$ACC2" 2 "$OWNERPASS"
            ;;
        4)
            txProveAndVerify "$BOOTSTRAP" "$NODE2" "$TX1" "$MRK1"
            ;;
        5)
            listAccountsOnAllNodes
            ;;
        6)
            echo "👋 Goodbye!"
            exit 0
            ;;
        *)
            echo "❌ Invalid choice"
            exit 1
            ;;
    esac
fi

print_status "✅ Client script ready!"
print_status "Node status: Bootstrap: $($bootstrap_ok && echo "✅" || echo "❌"), Node2: $($node2_ok && echo "✅" || echo "❌"), Node3: $($node3_ok && echo "✅" || echo "❌")"
