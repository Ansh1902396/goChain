#!/bin/bash

# RuChain Global Installation Script
# This script installs RuChain CLI globally so you can use it from anywhere

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🚀 RuChain Global Installation"
echo "============================="

# Check if Go is installed
if ! command -v go &> /dev/null; then
    print_error "Go is not installed. Please install Go first."
    exit 1
fi

print_status "Building RuChain CLI..."

# Build the binary
go build -o RuChain .

if [ $? -ne 0 ]; then
    print_error "Failed to build RuChain CLI"
    exit 1
fi

print_success "RuChain CLI built successfully!"

# Determine installation directory
INSTALL_DIR="/usr/local/bin"
HOME_BIN_DIR="$HOME/bin"

# Check if we can write to /usr/local/bin, otherwise use ~/bin
if [ -w "$INSTALL_DIR" ]; then
    TARGET_DIR="$INSTALL_DIR"
    print_status "Installing to system directory: $TARGET_DIR"
else
    TARGET_DIR="$HOME_BIN_DIR"
    print_warning "No write access to $INSTALL_DIR, installing to user directory: $TARGET_DIR"
    
    # Create ~/bin if it doesn't exist
    mkdir -p "$TARGET_DIR"
    
    # Add ~/bin to PATH if not already there
    if [[ ":$PATH:" != *":$TARGET_DIR:"* ]]; then
        print_status "Adding $TARGET_DIR to your PATH..."
        
        # Add to appropriate shell profile
        if [ -f "$HOME/.zshrc" ]; then
            echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.zshrc"
            print_status "Added to ~/.zshrc"
        elif [ -f "$HOME/.bashrc" ]; then
            echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
            print_status "Added to ~/.bashrc"
        elif [ -f "$HOME/.bash_profile" ]; then
            echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bash_profile"
            print_status "Added to ~/.bash_profile"
        fi
        
        print_warning "You'll need to restart your terminal or run 'source ~/.zshrc' (or appropriate shell config)"
    fi
fi

print_status "Installing RuChain CLI to $TARGET_DIR..."

# Install the binary
cp RuChain "$TARGET_DIR/RuChain"
chmod +x "$TARGET_DIR/RuChain"

if [ $? -eq 0 ]; then
    print_success "RuChain CLI installed successfully!"
    print_status "You can now use 'RuChain' command from anywhere!"
    
    echo
    echo "Available commands:"
    echo "  RuChain node     - Manage blockchain nodes"
    echo "  RuChain account  - Manage accounts"
    echo "  RuChain tx       - Manage transactions"
    echo "  RuChain block    - Manage blocks"
    echo
    
    if [ "$TARGET_DIR" = "$HOME_BIN_DIR" ]; then
        print_warning "Please restart your terminal or run 'source ~/.zshrc' to use RuChain"
    else
        print_status "Try running: ${GREEN}RuChain --help${NC}"
    fi
else
    print_error "Failed to install RuChain CLI"
    exit 1
fi

# Clean up local binary
rm -f RuChain

print_success "Installation complete! 🎉"
