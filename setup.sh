#!/usr/bin/env bash
# Ensure Mise is installed, then install repository tools (including Nushell),
# and finally run Mise tasks (bootstrap by default).
set -euo pipefail

# Colors
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
NC=$'\033[0m'

log()    { printf "%b[INFO] %b%s%b\n" "${GREEN}" "" "$*" "${NC}"; }
warn()   { printf "%b[WARN] %b%s%b\n"  "${YELLOW}" "" "$*" "${NC}"; }
error()  { printf "%b[ERROR] %b%s%b\n" "${RED}" "" "$*" "${NC}"; }

# Default task
TASK="${1:-bootstrap}"
if [ "${TASK:-}" = "--skip-run" ] || [ "${TASK:-}" = "-n" ]; then
  SKIP_RUN=1
  TASK=""
else
  SKIP_RUN=0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$SCRIPT_DIR"

prepend_local_bin() {
  if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
    log "Prepended \$HOME/.local/bin to PATH for current session"
  fi
}

has_mise() {
  command -v mise >/dev/null 2>&1
}

install_mise() {
  if has_mise; then
    log "mise already installed: $(command -v mise)"
    return 0
  fi

  if command -v curl >/dev/null 2>&1; then
    log "Installing Mise via curl..."
    curl -fsSL https://mise.run | sh
  elif command -v wget >/dev/null 2>&1; then
    log "Installing Mise via wget..."
    wget -qO- https://mise.run | sh
  else
    error "Neither curl nor wget available. Cannot install Mise automatically."
    return 1
  fi

  prepend_local_bin

  if has_mise; then
    log "Mise installed: $(command -v mise)"
    return 0
  else
    error "Mise installer finished but 'mise' is not on PATH."
    return 2
  fi
}

main() {
  log "Starting setup..."

  ensure_mise_available() {
      prepend_local_bin
      if ! has_mise; then
        log "mise not found, attempting installation..."
        install_mise
      fi
  }
  ensure_mise_available

  # Work from the repository directory
  if [ -d "$REPO_ROOT" ]; then
    pushd "$REPO_ROOT" >/dev/null || true
  fi

  log "Ensuring Nushell and Chezmoi are installed via Mise (from mise.toml)..."
  # This step is crucial: it reads [tools] from mise.toml and installs Nushell + Chezmoi
  if ! mise install; then
    error "Failed to install required tools (Nushell/Chezmoi). Aborting."
    exit 1
  fi

  if [ "$SKIP_RUN" -eq 1 ]; then
    log "Skipping mise task execution as requested (--skip-run)."
    exit 0
  fi

  if [ -n "${TASK:-}" ]; then
    shift_allowed_args=()
    if [ "$#" -gt 0 ]; then
      shift_allowed_args=("$@")
    fi

    log "Running mise task: $TASK"
    # Nushell should now be available for mise to use as the task shell
    mise run "$TASK" "${shift_allowed_args[@]}"
  else
    log "No task specified; done."
  fi

  if [ -d "$REPO_ROOT" ]; then
    popd >/dev/null || true
  fi
}

main "$@"
