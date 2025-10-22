#!/usr/bin/env bash
# Bootstrap script for setting up dotfiles on a new Linux system
# This script installs Mise and uses Mise to run Chezmoi, then applies the dotfiles

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

log_info "Starting dotfiles setup (Fish-centric)..."

# Determine preferred shell and config file (prefer fish)
SHELL_NAME=""
SHELL_CONFIG=""
if command -v fish >/dev/null 2>&1; then
    SHELL_NAME="fish"
    SHELL_CONFIG="$HOME/.config/fish/config.fish"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_NAME="bash"
    SHELL_CONFIG="$HOME/.bashrc"
elif [ -n "$ZSH_VERSION" ]; then
    SHELL_NAME="zsh"
    SHELL_CONFIG="$HOME/.zshrc"
fi

# Install Mise if not already installed
if ! command -v mise &> /dev/null; then
    log_info "Installing Mise..."
    curl https://mise.run | sh
    export PATH="$HOME/.local/bin:$PATH"
else
    log_info "Mise is already installed"
fi

# Add mise activation to shell profile if not already present
if [ -n "$SHELL_CONFIG" ]; then
    if [ ! -f "$SHELL_CONFIG" ]; then
        # create parent directories if needed
        mkdir -p "$(dirname "$SHELL_CONFIG")"
        touch "$SHELL_CONFIG"
    fi

    case "$SHELL_NAME" in
        fish)
            if ! grep -q "mise activate fish" "$SHELL_CONFIG" 2>/dev/null; then
                log_info "Adding mise activation to $SHELL_CONFIG"
                echo "# Activate Mise for interactive fish sessions" >> "$SHELL_CONFIG"
                echo "eval (mise activate fish)" >> "$SHELL_CONFIG"
            fi
            ;;
        bash)
            if ! grep -q "mise activate bash" "$SHELL_CONFIG" 2>/dev/null; then
                log_info "Adding mise activation to $SHELL_CONFIG"
                echo "# Activate Mise for interactive bash sessions" >> "$SHELL_CONFIG"
                echo 'eval "$(mise activate bash)"' >> "$SHELL_CONFIG"
            fi
            ;;
        zsh)
            if ! grep -q "mise activate zsh" "$SHELL_CONFIG" 2>/dev/null; then
                log_info "Adding mise activation to $SHELL_CONFIG"
                echo "# Activate Mise for interactive zsh sessions" >> "$SHELL_CONFIG"
                echo 'eval "$(mise activate zsh)"' >> "$SHELL_CONFIG"
            fi
            ;;
        *)
            log_warn "Unknown shell; skipping mise activation injection"
            ;;
    esac
fi

# Initialize Chezmoi with this repository using Mise to run it (fallback to curl installer)
REPO_URL="${1:-https://github.com/rjallais/dotfiles.git}"

# If fish is available, attempt to make it the user's login shell
if command -v fish >/dev/null 2>&1; then
    if command -v sudo >/dev/null 2>&1; then
        log_info "Setting fish as login shell for user $USER"
        sudo chsh -s "$(command -v fish)" "$USER" || log_warn "Failed to change login shell to fish"
    else
        log_warn "sudo not available; cannot change login shell to fish"
    fi
fi

# Prefer using the current repository as the Chezmoi source when running from a checkout
USE_PWD_SOURCE=0
if [ -d "$PWD/.git" ] || [ -f "$PWD/.chezmoi.toml.tmpl" ] || [ -f ".chezmoi.toml.tmpl" ]; then
    USE_PWD_SOURCE=1
fi

if [ "$USE_PWD_SOURCE" -eq 1 ]; then
    log_info "Initializing Chezmoi from local source: $PWD"
else
    log_info "Initializing Chezmoi with repository: $REPO_URL"
fi

if command -v chezmoi &> /dev/null; then
    log_info "Chezmoi already installed locally; updating..."
    chezmoi update || true
else
    # Try to run Chezmoi via Mise so there's no global installer curl
    if command -v mise &> /dev/null; then
        log_info "Running Chezmoi via Mise (no global install)..."
        if [ "$USE_PWD_SOURCE" -eq 1 ]; then
            if mise exec chezmoi -- init --apply --source "$PWD"; then
                log_info "Chezmoi ran via Mise successfully from local source"
            else
                log_warn "Mise failed to run Chezmoi from local source; falling back to official installer"
                sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
                export PATH="$HOME/.local/bin:$PATH"
                chezmoi init --apply --source "$PWD"
            fi
        else
            if mise exec chezmoi -- init --apply "$REPO_URL"; then
                log_info "Chezmoi ran via Mise successfully"
            else
                log_warn "Mise failed to run Chezmoi; falling back to official installer"
                sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
                export PATH="$HOME/.local/bin:$PATH"
                chezmoi init --apply "$REPO_URL"
            fi
        fi
    else
        log_warn "Mise not available; using official Chezmoi installer"
        sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
        export PATH="$HOME/.local/bin:$PATH"
        if [ "$USE_PWD_SOURCE" -eq 1 ]; then
            chezmoi init --apply --source "$PWD"
        else
            chezmoi init --apply "$REPO_URL"
        fi
    fi
fi

# If chezmoi directory exists, ensure we are in it for mise installs
if [ -d "$HOME/.local/share/chezmoi" ]; then
    log_info "Installing tools defined in dot_config/mise/config.toml via Mise..."
    cd "$HOME/.local/share/chezmoi"
    if command -v mise &> /dev/null; then
        # Use the repository's Mise config under dot_config/mise/config.toml
        mise install --config="dot_config/mise/config.toml" || log_warn "Mise install reported failures"
    fi
fi

log_info "✓ Dotfiles setup complete!"
log_info ""
log_info "Next steps:"
if [ "$SHELL_NAME" = "fish" ]; then
    log_info "  1. Restart your shell or run: source ~/.config/fish/config.fish"
else
    log_info "  1. Restart your shell or run: source $SHELL_CONFIG"
fi
log_info "  2. Run 'chezmoi edit <file>' to modify dotfiles"
log_info "  3. Run 'chezmoi apply' to apply changes"
log_info "  4. Use 'mise use <tool>@<version>' or edit .mise.toml to manage tools"
log_info ""
log_info "Useful commands:"
log_info "  - chezmoi status     # Check which dotfiles have changed"
log_info "  - chezmoi diff       # See differences"
log_info "  - chezmoi update     # Pull and apply latest changes"
log_info "  - mise ls            # List installed tools"
log_info "  - mise outdated      # Check for tool updates"
