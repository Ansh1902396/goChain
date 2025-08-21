#!/bin/bash

# Multi-Node Blockchain Management Script
# Supports running from anywhere and managing up to 3 nodes simultaneously

# Get the script directory to find the blockchain binary
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BCN_BINARY="$SCRIPT_DIR/bcn"

# Check if binary exists, if not try to build it
if [ ! -f "$BCN_BINARY" ]; then
    echo "🔨 Binary not found, building..."
    cd "$SCRIPT_DIR" && go build -o bcn . || {
        echo "❌ Failed to build binary!"
        exit 1
    }
fi

# Configuration
AUTHPASS="password"
OWNERPASS="password"  # Required for bootstrap node
BALANCE=1000          # Required for bootstrap node
CHAIN_NAME="blockchain"

# Node configurations - using simple variables for better compatibility
get_node_port() {
    case "$1" in
        1) echo "1122" ;;
        2) echo "1123" ;;
        3) echo "1124" ;;
        *) echo "" ;;
    esac
}

get_node_name() {
    case "$1" in
        1) echo "bootstrap" ;;
        2) echo "node2" ;;
        3) echo "node3" ;;
        *) echo "" ;;
    esac
}

get_node_type() {
    case "$1" in
        1) echo "bootstrap" ;;
        2) echo "regular" ;;
        3) echo "regular" ;;
        *) echo "" ;;
    esac
}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_node() {
    echo -e "${PURPLE}[NODE-$1]${NC} $2"
}

print_success() {
    echo -e "${CYAN}[SUCCESS]${NC} $1"
}

# Function to check if a port is in use
check_port() {
    local port="$1"
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0  # Port is in use
    else
        return 1  # Port is free
    fi
}

# Function to kill process on port
kill_port() {
    local port="$1"
    print_warning "Killing process on port $port..."
    lsof -ti:$port | xargs kill -9 2>/dev/null || true
    sleep 1
}

# Function to get PID file path
get_pid_file() {
    local node_num="$1"
    echo "$SCRIPT_DIR/.node${node_num}.pid"
}

# Function to get data directories
get_keystore_dir() {
    local node_num="$1"
    local port=$(get_node_port $node_num)
    echo "$SCRIPT_DIR/.keystore${port}"
}

get_blockstore_dir() {
    local node_num="$1"
    local port=$(get_node_port $node_num)
    echo "$SCRIPT_DIR/.blockstore${port}"
}

# Function to start a specific node
start_node() {
    local node_num="$1"
    local port=$(get_node_port $node_num)
    local name=$(get_node_name $node_num)
    local type=$(get_node_type $node_num)
    local pid_file=$(get_pid_file $node_num)
    local keystore_dir=$(get_keystore_dir $node_num)
    local blockstore_dir=$(get_blockstore_dir $node_num)
    
    print_step "Starting $name (Node $node_num) on localhost:$port..."
    
    # Check if port is already in use
    if check_port $port; then
        print_warning "Port $port is already in use. Killing existing process..."
        kill_port $port
    fi
    
    # Clean up old data if requested
    if [ "$CLEAN_DATA" = "true" ]; then
        print_warning "Cleaning data directories for node $node_num..."
        rm -rf "$keystore_dir" "$blockstore_dir" 2>/dev/null || true
    fi
    
    # Prepare command based on node type
    local cmd="$BCN_BINARY node start --node localhost:$port --chain $CHAIN_NAME"
    
    if [ "$type" = "bootstrap" ]; then
        cmd="$cmd --bootstrap --authpass $AUTHPASS"
        # Only add owner account if both ownerpass and balance are specified
        if [ -n "$OWNERPASS" ] && [ "$BALANCE" -gt 0 ]; then
            cmd="$cmd --ownerpass $OWNERPASS --balance $BALANCE"
        fi
    else
        # Regular node connects to bootstrap (node 1)
        local bootstrap_port=$(get_node_port 1)
        cmd="$cmd --seed localhost:${bootstrap_port}"
        # Only add owner account if both ownerpass and balance are specified
        if [ -n "$OWNERPASS" ] && [ "$BALANCE" -gt 0 ]; then
            cmd="$cmd --ownerpass $OWNERPASS --balance $BALANCE"
        fi
    fi
    
    # Add keystore and blockstore directories
    cmd="$cmd --keystore $keystore_dir --blockstore $blockstore_dir"
    
    print_node $node_num "Command: $cmd"
    
    # Start the node in background
    nohup $cmd > "$SCRIPT_DIR/.node${node_num}.log" 2>&1 &
    local node_pid=$!
    
    # Save PID
    echo $node_pid > "$pid_file"
    
    print_node $node_num "Started with PID: $node_pid"
    
    # Wait a bit and check if it's still running
    sleep 2
    if kill -0 $node_pid 2>/dev/null; then
        print_success "✅ $name is running successfully!"
        return 0
    else
        print_error "❌ $name failed to start!"
        rm -f "$pid_file"
        return 1
    fi
}

# Function to stop a specific node
stop_node() {
    local node_num="$1"
    local port=$(get_node_port $node_num)
    local name=$(get_node_name $node_num)
    local pid_file=$(get_pid_file $node_num)
    
    print_step "Stopping $name (Node $node_num)..."
    
    # Stop using PID if available
    if [ -f "$pid_file" ]; then
        local node_pid=$(cat "$pid_file")
        if kill -0 $node_pid 2>/dev/null; then
            print_node $node_num "Stopping process (PID: $node_pid)..."
            kill $node_pid
            sleep 2
            
            # Force kill if still running
            if kill -0 $node_pid 2>/dev/null; then
                print_warning "Force killing $name..."
                kill -9 $node_pid 2>/dev/null
            fi
        fi
        rm -f "$pid_file"
    fi
    
    # Also kill by port
    kill_port $port
    
    print_success "✅ $name stopped!"
}

# Function to check status of a specific node
check_node_status() {
    local node_num="$1"
    local port=$(get_node_port $node_num)
    local name=$(get_node_name $node_num)
    local pid_file=$(get_pid_file $node_num)
    
    if [ -f "$pid_file" ]; then
        local node_pid=$(cat "$pid_file")
        if kill -0 $node_pid 2>/dev/null; then
            print_success "✅ $name is running (PID: $node_pid, Port: $port)"
            return 0
        else
            print_warning "❌ $name is not running (stale PID file)"
            rm -f "$pid_file"
            return 1
        fi
    else
        print_warning "❌ $name is not running"
        return 1
    fi
}

# Function to show logs for a specific node
show_node_logs() {
    local node_num="$1"
    local log_file="$SCRIPT_DIR/.node${node_num}.log"
    local name=$(get_node_name $node_num)
    
    print_step "Showing logs for $name (Node $node_num)..."
    
    if [ -f "$log_file" ]; then
        echo "==================== $name LOGS ===================="
        tail -n 50 "$log_file"
        echo "=================================================="
    else
        print_warning "No log file found for $name"
    fi
}

# Function to start all nodes
start_all_nodes() {
    print_step "Starting all blockchain nodes..."
    
    # Start bootstrap node first
    start_node 1 || {
        print_error "Failed to start bootstrap node!"
        return 1
    }
    
    # Wait a bit for bootstrap to be ready
    sleep 3
    
    # Start other nodes
    for node_num in 2 3; do
        start_node $node_num
        sleep 2
    done
    
    print_success "🎉 All nodes started successfully!"
    show_network_status
}

# Function to stop all nodes
stop_all_nodes() {
    print_step "Stopping all blockchain nodes..."
    
    # Stop in reverse order
    for node_num in 3 2 1; do
        stop_node $node_num
    done
    
    print_success "🎉 All nodes stopped successfully!"
}

# Function to show network status
show_network_status() {
    print_step "Blockchain Network Status..."
    echo ""
    
    local running_count=0
    for node_num in 1 2 3; do
        if check_node_status $node_num; then
            ((running_count++))
        fi
    done
    
    echo ""
    if [ $running_count -eq 3 ]; then
        print_success "🎉 All 3 nodes are running perfectly!"
    elif [ $running_count -gt 0 ]; then
        print_warning "⚠️  $running_count out of 3 nodes are running"
    else
        print_error "❌ No nodes are running"
    fi
    
    echo ""
    echo "Network Configuration:"
    echo "  Bootstrap Node (Node 1): localhost:$(get_node_port 1)"
    echo "  Regular Node (Node 2):   localhost:$(get_node_port 2)"
    echo "  Regular Node (Node 3):   localhost:$(get_node_port 3)"
}

# Function to show help
show_help() {
    echo "🔗 Multi-Node Blockchain Management Script"
    echo "=========================================="
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  start <node>         Start a specific node (1, 2, or 3)"
    echo "  start-all            Start all 3 nodes"
    echo "  stop <node>          Stop a specific node (1, 2, or 3)"
    echo "  stop-all             Stop all nodes"
    echo "  restart <node>       Restart a specific node"
    echo "  restart-all          Restart all nodes"
    echo "  status               Show status of all nodes"
    echo "  logs <node>          Show logs for a specific node"
    echo "  clean-start          Start all nodes with clean data"
    echo "  help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start 1           # Start bootstrap node"
    echo "  $0 start-all         # Start all 3 nodes"
    echo "  $0 status            # Check all nodes"
    echo "  $0 logs 1            # Show bootstrap node logs"
    echo "  $0 stop-all          # Stop everything"
    echo ""
    echo "Node Configuration:"
    echo "  Node 1 (Bootstrap): localhost:$(get_node_port 1) - Authority node"
    echo "  Node 2 (Regular):   localhost:$(get_node_port 2) - Connects to Node 1"
    echo "  Node 3 (Regular):   localhost:$(get_node_port 3) - Connects to Node 1"
    echo ""
    echo "Settings:"
    echo "  Chain Name: $CHAIN_NAME"
    echo "  Auth Password: $AUTHPASS"
    echo "  Owner Password: $OWNERPASS"
    echo "  Initial Balance: $BALANCE"
    echo ""
    echo "Note: This script can be run from anywhere on your system!"
}

# Main script logic
case "${1:-help}" in
    "start")
        if [ -z "$2" ]; then
            print_error "Please specify node number (1, 2, or 3)"
            echo "Usage: $0 start <node>"
            exit 1
        fi
        node_num="$2"
        if [[ "$node_num" =~ ^[1-3]$ ]]; then
            start_node $node_num
        else
            print_error "Invalid node number. Use 1, 2, or 3"
            exit 1
        fi
        ;;
    "start-all")
        start_all_nodes
        ;;
    "stop")
        if [ -z "$2" ]; then
            print_error "Please specify node number (1, 2, or 3)"
            echo "Usage: $0 stop <node>"
            exit 1
        fi
        node_num="$2"
        if [[ "$node_num" =~ ^[1-3]$ ]]; then
            stop_node $node_num
        else
            print_error "Invalid node number. Use 1, 2, or 3"
            exit 1
        fi
        ;;
    "stop-all")
        stop_all_nodes
        ;;
    "restart")
        if [ -z "$2" ]; then
            print_error "Please specify node number (1, 2, or 3)"
            echo "Usage: $0 restart <node>"
            exit 1
        fi
        node_num="$2"
        if [[ "$node_num" =~ ^[1-3]$ ]]; then
            stop_node $node_num
            sleep 2
            start_node $node_num
        else
            print_error "Invalid node number. Use 1, 2, or 3"
            exit 1
        fi
        ;;
    "restart-all")
        stop_all_nodes
        sleep 3
        start_all_nodes
        ;;
    "status")
        show_network_status
        ;;
    "logs")
        if [ -z "$2" ]; then
            print_error "Please specify node number (1, 2, or 3)"
            echo "Usage: $0 logs <node>"
            exit 1
        fi
        node_num="$2"
        if [[ "$node_num" =~ ^[1-3]$ ]]; then
            show_node_logs $node_num
        else
            print_error "Invalid node number. Use 1, 2, or 3"
            exit 1
        fi
        ;;
    "clean-start")
        CLEAN_DATA="true"
        stop_all_nodes
        sleep 2
        start_all_nodes
        ;;
    "help"|*)
        show_help
        ;;
esac
