# ~/.profile - POSIX shell profile configuration

# Fix bare "UTF-8" locale (invalid in glibc — needs language prefix)
if [ "${LC_CTYPE:-}" = "UTF-8" ]; then
    export LC_CTYPE="${LANG:-en_US.UTF-8}"
fi

# Add user's private bin to PATH if it exists
if [ -d "$HOME/.local/bin" ]; then
    case ":$PATH:" in
        *":$HOME/.local/bin:"*) ;;
        *) PATH="$HOME/.local/bin:$PATH" ;;
    esac
fi

if [ -d "$HOME/bin" ]; then
    case ":$PATH:" in
        *":$HOME/bin:"*) ;;
        *) PATH="$HOME/bin:$PATH" ;;
    esac
fi

# Added by Toolbox App
if [ -d "$HOME/.local/share/JetBrains/Toolbox/scripts" ]; then
    case ":$PATH:" in
        *":$HOME/.local/share/JetBrains/Toolbox/scripts:"*) ;;
        *) export PATH="$PATH:$HOME/.local/share/JetBrains/Toolbox/scripts" ;;
    esac
fi

# Flatpak XDG directories
export XDG_DATA_DIRS="$HOME/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"

# Homebrew (Linuxbrew / macOS) — add to PATH before .bashrc checks tools
if [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [ -x "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Load mise shims if available
if command -v mise > /dev/null 2>&1; then
    export SHELL_TYPE=bash
    eval "$(mise activate bash --shims)"
fi

if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

# ubrew (guarded)
if [ -d "/opt/ubrew/prefix/bin" ]; then
    case ":$PATH:" in
        *":/opt/ubrew/prefix/bin:"*) ;;
        *) export PATH="/opt/ubrew/prefix/bin:$PATH" ;;
    esac
fi

# Source .bashrc if running bash
if [ -n "${BASH_VERSION:-}" ]; then
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi

# Source Gemini environment variables (project/location)
if [ -f "$HOME/.gemini/.env" ]; then
    set -a
    . "$HOME/.gemini/.env"
    set +a
fi

# Load encrypted API keys via fnox when age identity is available
if command -v fnox > /dev/null 2>&1 && [ -f "$HOME/.config/fnox/config.toml" ] && { [ -f "$HOME/.config/fnox/age.txt" ] || [ -n "${FNOX_AGE_KEY:-}" ] || [ -n "${FNOX_AGE_KEY_FILE:-}" ]; }; then
    if [ -z "${FNOX_AGE_KEY:-}" ]; then
        eval "$(env -u FNOX_AGE_KEY FNOX_AGE_KEY_FILE="${FNOX_AGE_KEY_FILE:-$HOME/.config/fnox/age.txt}" fnox -c "$HOME/.config/fnox/config.toml" export -f shell --if-missing ignore ARTIFICIAL_ANALYSIS_API_KEY NINEROUTER_KEY 2>/dev/null || true)"
    else
        eval "$(fnox -c "$HOME/.config/fnox/config.toml" export -f shell --if-missing ignore ARTIFICIAL_ANALYSIS_API_KEY NINEROUTER_KEY 2>/dev/null || true)"
    fi
fi
