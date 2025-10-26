#!/usr/bin/env bash
# Ensure Mise is installed and then run Mise tasks (bootstrap by default).
#
# This script's responsibilities:
#  - Verify the `mise` binary is available (install it non-interactively if missing)
#  - Ensure $HOME/.local/bin is on PATH for the remainder of this process
#  - Change to the repository directory (this script's parent) so mise picks up the local mise.toml
#  - Run a requested Mise task (defaults to `bootstrap`)
#
# Usage:
#   ./setup.sh              # ensures mise, then runs `mise run bootstrap`
#   ./setup.sh validate:all # ensures mise, then runs `mise run validate:all`
#   ./setup.sh --skip-run   # ensures mise but does not run any mise task
#
# Notes:
#  - This script attempts a non-interactive install of Mise using curl or wget.
#  - If neither curl nor wget are available, the script will exit with an error.
#  - The script is intentionally minimal: it only installs/validates the `mise` binary and
#    delegates the rest of the bootstrap/validation work to mise tasks defined in mise.toml.
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
# Allow a simple flag to skip running the task (useful for just ensuring mise)
if [ "${TASK:-}" = "--skip-run" ] || [ "${TASK:-}" = "-n" ]; then
  SKIP_RUN=1
  TASK=""
else
  SKIP_RUN=0
fi

# Compute script and repo directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$SCRIPT_DIR"   # this script lives in chezmoi/; using that as config root is intentional

# Ensure $HOME/.local/bin is on PATH for this process
prepend_local_bin() {
  if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
    log "Prepended \$HOME/.local/bin to PATH for current session"
  fi
}

# Check for mise binary
has_mise() {
  command -v mise >/dev/null 2>&1
}

# Try to install mise using the official one-liner
install_mise() {
  if has_mise; then
    log "mise already installed: $(command -v mise)"
    return 0
  fi

  if command -v curl >/dev/null 2>&1; then
    log "Installing Mise via curl..."
    # Non-interactive installer; rely on the upstream script
    curl -fsSL https://mise.run | sh
  elif command -v wget >/dev/null 2>&1; then
    log "Installing Mise via wget..."
    wget -qO- https://mise.run | sh
  else
    error "Neither curl nor wget available. Cannot install Mise automatically."
    return 1
  fi

  # ensure PATH contains local bin for the current process
  prepend_local_bin

  if has_mise; then
    log "Mise installed: $(command -v mise)"
    return 0
  else
    error "Mise installer finished but 'mise' is not on PATH. Make sure $HOME/.local/bin is on your PATH."
    return 2
  fi
}

# Verify prerequisites and install mise if needed
ensure_mise_available() {
  prepend_local_bin

  if has_mise; then
    log "Found mise at $(command -v mise)"
    return 0
  fi

  log "mise not found, attempting installation..."
  if ! install_mise; then
    error "Failed to install Mise. Aborting."
    exit 1
  fi
}

# Run a mise task from REPO_ROOT
run_mise_task() {
  local task_name="$1"
  shift
  if [ -z "$task_name" ]; then
    warn "No task requested; skipping mise run."
    return 0
  fi

  # Work from the repository directory so mise finds mise.toml in this repo
  if [ -d "$REPO_ROOT" ]; then
    pushd "$REPO_ROOT" >/dev/null || true
  fi

  # Provide an informative message
  log "Running mise task: $task_name"
  # Use mise to run the requested task. Propagate exit code.
  if mise run "$task_name" "$@"; then
    log "Mise task '$task_name' completed successfully."
    RET=0
  else
    error "Mise task '$task_name' failed."
    RET=$?
  fi

  if [ -d "$REPO_ROOT" ]; then
    popd >/dev/null || true
  fi

  return $RET
}

# Main flow
main() {
  log "Starting setup: ensure mise is available, then run mise tasks (if requested)."

  ensure_mise_available

  if [ "$SKIP_RUN" -eq 1 ]; then
    log "Skipping mise task execution as requested (--skip-run)."
    exit 0
  fi

  # Run the requested task (default: bootstrap)
  # Accept additional args as parameters to mise run if they follow the task name
  # e.g. ./setup.sh 'run:chezmoi' arg1 arg2  -> but common usage remains simple
  if [ -n "${TASK:-}" ]; then
    shift_allowed_args=()
    # If the first parameter is the task then positional args $2.. are additional to the task.
    # Because we already consumed $1 into TASK, rebuild args from $2.. if present.
    # Note: the script accepted only $1 originally; additional args will be passed to mise run.
    if [ "$#" -gt 0 ]; then
      # rebuild additional args preserving quoting
      shift_allowed_args=("$@")
    fi

    run_mise_task "$TASK" "${shift_allowed_args[@]}"
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
      error "Mise task exited with code $exit_code"
      exit $exit_code
    fi
  else
    log "No task specified and skipping is false; nothing to run."
  fi

  log "Setup script finished successfully."
}

main "$@"
