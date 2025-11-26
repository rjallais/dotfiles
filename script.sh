#!/bin/bash

# 1. Create directory structure
mkdir -p dot_config/mise

# 2. Write 'mise.toml' (FIXED: Removed --config flags)
cat <<'EOF' > mise.toml
# Mise task definitions for chezmoi repository (Nushell version)
#
# Tasks are interpreted by Nushell (installed via Aqua in [tools]).
#
# High-level flow:
#   mise run bootstrap
#
# Note: `mise` automatically installs tools in [tools] before running tasks.

[tools]
"aqua:nushell/nushell" = "latest"
chezmoi = "latest"

[tasks."detect:shell-profile"]
description = "Detect a suitable interactive shell profile file and print its path"
run = '''
#!/usr/bin/env nu
# Checks for fish, then falls back to bashrc/zshrc/profile
if (which fish | is-not-empty) {
    print $"($env.HOME)/.config/fish/config.fish"
} else if ($env.BASH_VERSION? != null) {
    print $"($env.HOME)/.bashrc"
} else if ($env.ZSH_VERSION? != null) {
    print $"($env.HOME)/.zshrc"
} else {
    print $"($env.HOME)/.profile"
}
'''

[tasks."inject:mise-activation"]
description = "Add Mise activation to an interactive shell profile (idempotent). Skipped in CI."
run = '''
#!/usr/bin/env nu
# CI-aware: don't modify user profiles in CI environments
if ($env.CI? != null) {
    print "CI environment detected; skipping profile modification"
    exit 0
}

# Ensure mise binary present
if (which mise | is-empty) {
    print -e "ERROR: mise not found in PATH."
    exit 1
}

# Determine target profile
let profile = (
    if (which fish | is-not-empty) {
        $"($env.HOME)/.config/fish/config.fish"
    } else {
        if ($env.ZSH_VERSION? != null) { $"($env.HOME)/.zshrc" } else { $"($env.HOME)/.bashrc" }
    }
)

let line = (
    if ($profile | str ends-with "fish") {
        'eval (mise activate fish)'
    } else {
        'eval "$(mise activate bash)"'
    }
)

# Create directory if missing
mkdir ($profile | path dirname)
if not ($profile | path exists) {
    touch $profile
}

# Idempotency check
let content = (open $profile)
if ($content | str contains $line) {
    print $"Mise activation already present in ($profile)"
    exit 0
}

# Append activation
print $"\n# Activate Mise for interactive sessions\n($line)" | save --append $profile
print $"Appended mise activation to ($profile)"
'''

[tasks."activate:mise-now"]
description = "Activate Mise in the current shell (best-effort)"
run = '''
#!/usr/bin/env nu
# In Nushell tasks, we are already running inside the mise environment 
# if tools are installed. We can't easily modify the *parent* shell's 
# environment from here, but we can verify mise is working.

if (which mise | is-empty) {
    print -e "ERROR: 'mise' not found on PATH."
    exit 1
}

print "Mise is available and active for tasks."
'''

[tasks."install:tools:local"]
description = "Install tools from repository-local dot_config/mise/config.toml"
run = '''
#!/usr/bin/env nu
let ci_fail = ($env.CI? != null)
let local_conf = "dot_config/mise/config.toml"

if ($local_conf | path exists) {
    print "Installing tools from dot_config/mise/config.toml..."
    try {
        # Trick: Point MISE_GLOBAL_CONFIG_FILE to the local file to force install
        with-env { MISE_GLOBAL_CONFIG_FILE: $local_conf } {
            ^mise install
        }
        print "Local tools installed successfully."
    } catch {
        if $ci_fail {
            print -e "ERROR: mise install failed (CI mode)"
            exit 1
        } else {
            print "WARNING: mise install reported failures (continuing)"
        }
    }
} else {
    print "No dot_config/mise/config.toml found; skipping local mise install"
}
'''

[tasks."run:chezmoi"]
description = "Run Chezmoi; prefer local checkout when available."
run = '''
#!/usr/bin/env nu
# Since we added chezmoi to [tools], it should be in PATH
if (which chezmoi | is-empty) {
    print -e "ERROR: 'chezmoi' not found. It should have been installed by mise."
    exit 1
}

# Default repo URL if argument not provided
let repo_url = "https://github.com/rjallais/dotfiles.git" 

# Check for local repo markers
if ((".git" | path exists) or (".chezmoi.toml.tmpl" | path exists)) {
    print $"Initializing chezmoi from local checkout "
    # We use ^ to explicitly call the external command 'chezmoi'
    ^chezmoi init --apply --source .
} else {
    print $"Initializing chezmoi from remote repository: ($repo_url)"
    ^chezmoi init --apply $repo_url
}
'''

[tasks."install:tools:applied"]
description = "Install tools from the user-wide Mise config after chezmoi apply."
depends = ["run:chezmoi"]
run = '''
#!/usr/bin/env nu
let ci_fail = ($env.CI? != null)
let user_config = $"($env.HOME)/.config/mise/config.toml"

if ($user_config | path exists) {
    print $"Installing tools from user-wide Mise config: ($user_config)"
    try {
        # FIXED: Removed --config flag. 
        # mise automatically loads ~/.config/mise/config.toml as global config.
        ^mise install
        print "User-wide tools installed successfully."
    } catch {
        if $ci_fail {
            print -e "ERROR: mise install (user-wide) failed (CI mode)"
            exit 1
        } else {
            print "WARNING: mise install reported failures"
        }
    }
} else {
    print $"User-wide Mise config not found at ($user_config); skipping"
}
'''

[tasks."set:fish-login-shell"]
description = "Attempt to set fish as the login shell."
run = '''
#!/usr/bin/env nu
if ($env.CI? != null) {
    print "CI environment detected; skipping change of login shell"
    exit 0
}

if (which fish | is-empty) {
    print "fish not installed; skipping change of login shell"
    exit 0
}

if (which sudo | is-not-empty) {
    print "Attempting to set fish as login shell..."
    let user = (whoami)
    let fish_path = (which fish | path expand)
    try {
        ^sudo chsh -s $fish_path $user
    } catch {
        print "Failed to change login shell (continuing)"
    }
} else {
    print "sudo not available; cannot change login shell automatically"
}
'''

[tasks.bootstrap]
description = "Full Mise-centric bootstrap using Nushell."
run = [
  { task = "inject:mise-activation" },
  { task = "run:chezmoi" },
  { task = "install:tools:applied" }
]

[tasks."bootstrap:with-fish"]
description = "Run bootstrap and try to set fish as login shell"
run = [
  { task = "bootstrap" },
  { task = "set:fish-login-shell" }
]

# ----------------------
# Validation tasks
# ----------------------
[tasks."validate:files"]
description = "Check critical repository files exist."
run = '''
#!/usr/bin/env nu
let files = [
    ".chezmoi.toml.tmpl", 
    ".chezmoiignore", 
    "README.md", 
    "dot_config/mise/config.toml"
]
let missing = ($files | filter {|f| not ($f | path exists) })

if ($missing | is-empty) {
    print "OK: All critical files exist."
    exit 0
} else {
    print -e $"ERR: Missing files: ($missing)"
    exit 1
}
'''

[tasks."validate:mise"]
description = "Check for Mise availability."
run = '''
#!/usr/bin/env nu
if (which mise | is-not-empty) {
    print $"OK: mise found at (which mise | path expand)"
    exit 0
}

if ($env.CI? != null) {
    print -e "ERROR: mise not found in PATH (CI mode)"
    exit 1
}

print "WARN: mise not found in PATH"
'''

[tasks."validate:all"]
description = "Run all validation checks"
run = [
  { task = "validate:files" },
  { task = "validate:mise" }
]
EOF

# 3. Write 'setup.sh'
cat <<'EOF' > setup.sh
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
EOF

# 4. Make setup.sh executable
chmod +x setup.sh

# 5. Write 'dot_config/mise/config.toml'
cat <<'EOF' > dot_config/mise/config.toml
[tools]
"aqua:nushell/nushell" = "latest"
"aqua:Wilfred/difftastic" = "latest"
"aqua:charmbracelet/crush" = "latest"
"aqua:exercism/cli" = "latest"
"aqua:iawia002/lux" = "latest"
"aqua:microsoft/edit" = "1.2.0"
"aqua:nats-io/natscli" = "latest"
"aqua:sst/opencode" = "latest"
"aqua:tealdeer-rs/tealdeer" = "latest"
"aqua:topgrade-rs/topgrade" = "latest"
"aqua:twistedpair/google-cloud-sdk" = "latest"
"aqua:zyedidia/micro" = "latest"
bat = "latest"
bottom = "latest"
bun = "latest"
chezmoi = "latest"
cmake = "latest"
conan = "latest"
dust = "latest"
fastfetch = "latest"
fd = "latest"
fzf = "latest"
github-cli = "latest"
go = "latest"
hyperfine = "latest"
lsd = "latest"
node = "latest"
"npm:@github/copilot" = "latest"
"npm:@google/gemini-cli" = "latest"
ripgrep = "latest"
sd = "latest"
sqlite = "latest"
starship = "latest"
"ubi:danielmiessler/fabric" = "latest"
"ubi:xmake-io/xmake" = "latest"
usage = "latest"
uv = "latest"
yt-dlp = "latest"

[settings]
experimental = true
idiomatic_version_file_enable_tools = []

[settings.npm]
bun = true

[settings.python]
compile = false
EOF

echo "Files generated successfully. You can now run ./setup.sh"
