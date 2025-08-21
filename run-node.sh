#!/bin/bash

# Configuration
AUTHPASS="password"
OWNERPASS="password"
BALANCE=1000
CHAIN_NAME="blockchain"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
    sleep 2
}

# Function to start bootstrap node
start_bootstrap() {
    print_step "Starting bootstrap node on localhost:1122..."
    
    # Check if port is already in use
    if check_port 1122; then
        print_warning "Port 1122 is already in use. Killing existing process..."
        kill_port 1122
    fi
    
    # Clean up old data
    rm -rf .keystore1122 .blockstore1122 2>/dev/null || true
    
    print_status "Building the project..."
    go build -o bcn . || {
        print_error "Build failed!"
        exit 1
    }
    
    print_status "Starting bootstrap node..."
    ./bcn node start \
        --node localhost:1122 \
        --bootstrap \
        --chain "$CHAIN_NAME" \
        --authpass "$AUTHPASS" \
        --ownerpass "$OWNERPASS" \
        --balance $BALANCE &
    
    local bootstrap_pid=$!
    print_status "Bootstrap node started with PID: $bootstrap_pid"
    
    # Wait a bit for the bootstrap node to start
    sleep 5
    
    # Check if the process is still running
    if kill -0 $bootstrap_pid 2>/dev/null; then
        print_status "✅ Bootstrap node is running successfully!"
        echo $bootstrap_pid > .bootstrap.pid
    else
        print_error "❌ Bootstrap node failed to start!"
        exit 1
    fi
}

# Function to start regular node
start_node() {
    print_step "Starting regular node on localhost:1123..."
    
    # Check if port is already in use
    if check_port 1123; then
        print_warning "Port 1123 is already in use. Killing existing process..."
        kill_port 1123
    fi
    
    # Clean up old data
    rm -rf .keystore1123 .blockstore1123 2>/dev/null || true
    
    print_status "Starting regular node..."
    ./bcn node start \
        --node localhost:1123 \
        --seed localhost:1122 \
        --chain "$CHAIN_NAME" \
        --ownerpass "$OWNERPASS" \
        --balance $BALANCE &
    
    local node_pid=$!
    print_status "Regular node started with PID: $node_pid"
    
    # Wait a bit for the node to start
    sleep 3
    
    # Check if the process is still running
    if kill -0 $node_pid 2>/dev/null; then
        print_status "✅ Regular node is running successfully!"
        echo $node_pid > .node.pid
    else
        print_error "❌ Regular node failed to start!"
        exit 1
    fi
}

# Function to stop all nodes
stop_nodes() {
    print_step "Stopping all blockchain nodes..."
    
    # Stop regular node
    if [ -f .node.pid ]; then
        local node_pid=$(cat .node.pid)
        if kill -0 $node_pid 2>/dev/null; then
            print_status "Stopping regular node (PID: $node_pid)..."
            kill $node_pid
            rm -f .node.pid
        fi
    fi
    
    # Stop bootstrap node
    if [ -f .bootstrap.pid ]; then
        local bootstrap_pid=$(cat .bootstrap.pid)
        if kill -0 $bootstrap_pid 2>/dev/null; then
            print_status "Stopping bootstrap node (PID: $bootstrap_pid)..."
            kill $bootstrap_pid
            rm -f .bootstrap.pid
        fi
    fi
    
    # Force kill any remaining processes on the ports
    kill_port 1122
    kill_port 1123
    
    print_status "✅ All nodes stopped!"
}

# Function to check node status
check_status() {
    print_step "Checking node status..."
    
    local bootstrap_running=false
    local node_running=false
    
    # Check bootstrap node
    if [ -f .bootstrap.pid ]; then
        local bootstrap_pid=$(cat .bootstrap.pid)
        if kill -0 $bootstrap_pid 2>/dev/null; then
            print_status "✅ Bootstrap node is running (PID: $bootstrap_pid, Port: 1122)"
            bootstrap_running=true
        else
            print_warning "❌ Bootstrap node is not running"
            rm -f .bootstrap.pid
        fi
    else
        print_warning "❌ Bootstrap node is not running"
    fi
    
    # Check regular node
    if [ -f .node.pid ]; then
        local node_pid=$(cat .node.pid)
        if kill -0 $node_pid 2>/dev/null; then
            print_status "✅ Regular node is running (PID: $node_pid, Port: 1123)"
            node_running=true
        else
            print_warning "❌ Regular node is not running"
            rm -f .node.pid
        fi
    else
        print_warning "❌ Regular node is not running"
    fi
    
    if [ "$bootstrap_running" = true ] && [ "$node_running" = true ]; then
        print_status "🎉 Both nodes are running successfully!"
    elif [ "$bootstrap_running" = true ]; then
        print_warning "⚠️  Only bootstrap node is running"
    elif [ "$node_running" = true ]; then
        print_warning "⚠️  Only regular node is running (this won't work without bootstrap)"
    else
        print_error "❌ No nodes are running"
    fi
}

# Function to show logs
show_logs() {
    print_step "Showing recent logs..."
    print_status "Note: Logs are shown in the terminal where nodes were started"
    print_status "Bootstrap node logs: check terminal or use 'jobs' command"
    print_status "Regular node logs: check terminal or use 'jobs' command"
}

# Function to show help
show_help() {
    echo "🔗 Blockchain Node Management Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start-bootstrap    Start only the bootstrap node (localhost:1122)"
    echo "  start-node         Start only the regular node (localhost:1123)"
    echo "  start-all          Start both bootstrap and regular nodes"
    echo "  stop               Stop all running nodes"
    echo "  restart            Stop and restart all nodes"
    echo "  status             Check the status of running nodes"
    echo "  logs               Show recent logs"
    echo "  help               Show this help message"
    echo ""
    echo "Configuration:"
    echo "  Chain Name: $CHAIN_NAME"
    echo "  Auth Password: $AUTHPASS"
    echo "  Owner Password: $OWNERPASS"
    echo "  Initial Balance: $BALANCE"
    echo ""
    echo "Node Addresses:"
    echo "  Bootstrap Node: localhost:1122"
    echo "  Regular Node: localhost:1123"
}

# Main script logic
case "${1:-help}" in
    "start-bootstrap")
        start_bootstrap
        ;;
    "start-node")
        start_node
        ;;
    "start-all")
        start_bootstrap
        sleep 2
        start_node
        print_status "🎉 Both nodes started successfully!"
        print_status "Bootstrap node: localhost:1122"
        print_status "Regular node: localhost:1123"
        ;;
    "stop")
        stop_nodes
        ;;
    "restart")
        stop_nodes
        sleep 2
        start_bootstrap
        sleep 2
        start_node
        print_status "🎉 Nodes restarted successfully!"
        ;;
    "status")
        check_status
        ;;
    "logs")
        show_logs
        ;;
    "help"|*)
        show_help
        ;;
esac
