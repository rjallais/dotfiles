# ~/.bashrc - Bash configuration

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# History settings
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth
shopt -s histappend

# Check window size after each command
shopt -s checkwinsize

# Enable color support
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
fi

# Modern CLI tool aliases (if available via mise/brew)
if command -v lsd &> /dev/null; then
    alias ls='lsd'
    alias ll='ls -lgh'
    alias la='ls -a'
    alias lla='ls -lgha'
    alias lt='ls --tree'
fi

if command -v bat &> /dev/null; then
    alias cat='bat'
fi

if command -v rg &> /dev/null; then
    alias grep='rg'
fi

if command -v fd &> /dev/null; then
    alias find='fd'
fi

# Common aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph'
alias gd='git diff'

# Prompt
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# User local binaries
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

# Load mise
if command -v mise &> /dev/null; then
    export SHELL_TYPE=bash
    eval "$(mise activate bash)"
fi

# Add mise shims to PATH (idempotent)
_mise_shims_dir="$HOME/.local/share/mise/shims"
case ":$PATH:" in
  *":$_mise_shims_dir:") :;;
  *)
    if [ -d "$_mise_shims_dir" ]; then
      export PATH="$_mise_shims_dir:$PATH"
    fi
    ;;
esac

# Load Rust environment only when installed.
if [ -f "$HOME/.cargo/env" ]; then
  . "$HOME/.cargo/env"
fi

# nanobrew (guarded — only if mounted/present)
if [ -d "/opt/nanobrew/prefix/bin" ]; then
  case ":$PATH:" in
    *":/opt/nanobrew/prefix/bin:") ;;
    *) export PATH="/opt/nanobrew/prefix/bin:$PATH" ;;
  esac
fi

# ubrew (guarded)
_ubrew_bin_dir="/opt/ubrew/prefix/bin"
case ":$PATH:" in
  *":$_ubrew_bin_dir:") :;;
  *)
    if [ -d "$_ubrew_bin_dir" ]; then
      export PATH="$_ubrew_bin_dir:$PATH"
    fi
    ;;
esac

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac

# Bluefin CLI / Starship prompt
# bluefin-cli MOTD suppressed to prevent terminal query hang in PTY wrappers
# (bluefin-cli motd show sends ESC]11;? and ESC[6n that blocks ~10s)
if command -v bluefin-cli &> /dev/null; then
    eval "$(BLUEFIN_SHELL_ENABLE_MOTD=0 bluefin-cli init bash | sed 's/export BLUEFIN_SHELL_ENABLE_MOTD=1/export BLUEFIN_SHELL_ENABLE_MOTD=0/')"
elif command -v starship &> /dev/null; then
    eval "$(starship init bash)"
fi

# DigitalOcean Inference API key (for Grok CLI custom DO models)
if [ -f "$HOME/.hermes/.env" ]; then
    _openai_key="$(grep -m1 '^OPENAI_API_KEY=' "$HOME/.hermes/.env" 2>/dev/null | cut -d= -f2- | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")"
    if [ -n "$_openai_key" ]; then
        export OPENAI_API_KEY="$_openai_key"
    fi
    unset _openai_key
fi

# 9Router gateway
export NINEROUTER_URL="http://localhost:20128"

# Load encrypted API keys via fnox when age identity is available
if command -v fnox &> /dev/null && [ -f "$HOME/.config/fnox/config.toml" ] && { [ -f "$HOME/.config/fnox/age.txt" ] || [ -n "${FNOX_AGE_KEY:-}" ] || [ -n "${FNOX_AGE_KEY_FILE:-}" ]; }; then
    eval "$(fnox -c "$HOME/.config/fnox/config.toml" export -f shell --if-missing ignore ARTIFICIAL_ANALYSIS_API_KEY NINEROUTER_KEY 2>/dev/null || true)"
fi
