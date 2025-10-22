#!/usr/bin/env bash
# Bootstrap script for setting up dotfiles on a new Linux system
# This script installs Chezmoi and Mise, then applies the dotfiles

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on Linux
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    log_error "This script is designed for Linux systems"
    exit 1
fi

log_info "Starting dotfiles setup..."

# Install Chezmoi if not already installed
if ! command -v chezmoi &> /dev/null; then
    log_info "Installing Chezmoi..."
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
    export PATH="$HOME/.local/bin:$PATH"
else
    log_info "Chezmoi is already installed"
fi

# Install Mise if not already installed
if ! command -v mise &> /dev/null; then
    log_info "Installing Mise..."
    curl https://mise.run | sh
    export PATH="$HOME/.local/bin:$PATH"
    
    # Activate mise for this session
    eval "$(~/.local/bin/mise activate bash)"
else
    log_info "Mise is already installed"
fi

# Initialize Chezmoi with this repository
REPO_URL="${1:-https://github.com/rjallais/dotfiles.git}"
log_info "Initializing Chezmoi with repository: $REPO_URL"

if [ -d "$HOME/.local/share/chezmoi" ]; then
    log_warn "Chezmoi directory already exists. Updating..."
    chezmoi update
else
    chezmoi init --apply "$REPO_URL"
fi

# Install tools defined in .mise.toml
log_info "Installing tools via Mise..."
cd "$HOME/.local/share/chezmoi"
mise install

log_info "Setting up shell integration..."

# Add mise activation to shell profile if not already present
SHELL_CONFIG=""
if [ -n "$BASH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
elif [ -n "$ZSH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
fi

if [ -n "$SHELL_CONFIG" ] && [ -f "$SHELL_CONFIG" ]; then
    if ! grep -q "mise activate" "$SHELL_CONFIG"; then
        log_info "Adding mise activation to $SHELL_CONFIG"
    fi
fi

log_info "✓ Dotfiles setup complete!"
log_info ""
log_info "Next steps:"
log_info "  1. Restart your shell or run: source ~/.bashrc"
log_info "  2. Run 'chezmoi edit <file>' to modify dotfiles"
log_info "  3. Run 'chezmoi apply' to apply changes"
log_info "  4. Run 'mise use <tool>@<version>' to add more tools"
log_info ""
log_info "Useful commands:"
log_info "  - chezmoi status     # Check which dotfiles have changed"
log_info "  - chezmoi diff       # See differences"
log_info "  - chezmoi update     # Pull and apply latest changes"
log_info "  - mise ls            # List installed tools"
log_info "  - mise outdated      # Check for tool updates"
