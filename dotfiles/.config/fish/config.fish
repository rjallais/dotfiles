# 1) Ensure user-local binaries are in PATH
fish_add_path $HOME/.local/bin

# --- CUDA Toolkit (guarded) ---
if test -d /usr/local/cuda-12.9/bin
    fish_add_path /usr/local/cuda-12.9/bin
end
if test -d /usr/local/cuda-12.9/lib64
    set -gx LD_LIBRARY_PATH /usr/local/cuda-12.9/lib64 $LD_LIBRARY_PATH
end

if command -q mise
    mise activate fish | source
end

# Initialize starship if it's installed (version-independent)
if command -q starship
    starship init fish | source
end

# 2) Only in interactive sessions…
if status is-interactive
    # Initialize atuin if it's installed
    if command -q atuin
        atuin init fish | source
    end

    set -Ux EGET_BIN $HOME/.local/bin
    if not contains $EGET_BIN $fish_user_paths
        set -Ux fish_user_paths $EGET_BIN $fish_user_paths
    end

    # Ensure XDG_CONFIG_HOME falls back to ~/.config
    set -l config_home $XDG_CONFIG_HOME
    if test -z "$config_home"
        set config_home $HOME/.config
    end

    # Export AQUA_GLOBAL_CONFIG (use existing value or empty, then append the default path)
    set -gx AQUA_GLOBAL_CONFIG "$AQUA_GLOBAL_CONFIG:$config_home/aquaproj-aqua/aqua.yaml"

    if command -q zoxide
        zoxide init fish | source
    end
end

# add ~/.pixi/bin to your PATH if it exists
if test -d $HOME/.pixi/bin
    fish_add_path $HOME/.pixi/bin
end

# add /opt/nanobrew/prefix/bin to your PATH if it exists
if test -d /opt/nanobrew/prefix/bin
    fish_add_path /opt/nanobrew/prefix/bin
end

# add /opt/ubrew/prefix/bin to your PATH if it exists
if test -d /opt/ubrew/prefix/bin
    fish_add_path /opt/ubrew/prefix/bin
end

# Initialize pixi completion if it's installed
if command -q pixi
    pixi completion --shell fish | source
end

# --- Homebrew Performance Optimizations ---
if test -d /home/linuxbrew/.linuxbrew
    set -gx HOMEBREW_NO_ANALYTICS 1
    set -gx HOMEBREW_NO_AUTO_UPDATE 1
    set -gx HOMEBREW_NO_INSTALL_CLEANUP TRUE
    set -gx HOMEBREW_DEVELOPER 1
    set -gx HOMEBREW_DOWNLOAD_CONCURRENCY 16
    set -gx HOMEBREW_PREFIX /home/linuxbrew/.linuxbrew
    set -gx HOMEBREW_CELLAR /home/linuxbrew/.linuxbrew/Cellar

    if test -d $HOMEBREW_PREFIX/bin
        fish_add_path $HOMEBREW_PREFIX/bin
    end
    if test -d $HOMEBREW_PREFIX/sbin
        fish_add_path $HOMEBREW_PREFIX/sbin
    end
end

# Deduplicate PATH while keeping non-empty entries in first-seen order
set -l unique_paths
for path_item in $PATH
    if test -n "$path_item"; and not contains -- "$path_item" $unique_paths
        set unique_paths $unique_paths $path_item
    end
end
set -gx PATH $unique_paths

# Fallback GITHUB_TOKEN lookup after PATH, Mise activation, and Homebrew setup
if not set -q GITHUB_TOKEN; or test -z "$GITHUB_TOKEN"
    if test -f "$__fish_config_dir/conf.d/github-token.fish"
        source "$__fish_config_dir/conf.d/github-token.fish"
    end
end

# 9Router gateway
set -gx NINEROUTER_URL "http://localhost:20128"

# Load encrypted API keys via fnox when age identity is available
if command -q fnox; and test -f "$HOME/.config/fnox/config.toml"; and begin test -f "$HOME/.config/fnox/age.txt"; or test -n "$FNOX_AGE_KEY"; or test -n "$FNOX_AGE_KEY_FILE"; end
    set -l _fnox_age_file "$HOME/.config/fnox/age.txt"
    if test -n "$FNOX_AGE_KEY_FILE"
        set _fnox_age_file "$FNOX_AGE_KEY_FILE"
    end
    for _key in ARTIFICIAL_ANALYSIS_API_KEY NINEROUTER_KEY
        set -l _val ""
        if test -z "$FNOX_AGE_KEY"
            set _val (env -u FNOX_AGE_KEY FNOX_AGE_KEY_FILE="$_fnox_age_file" fnox -c "$HOME/.config/fnox/config.toml" get --if-missing ignore $_key 2>/dev/null)
        else
            set _val (fnox -c "$HOME/.config/fnox/config.toml" get --if-missing ignore $_key 2>/dev/null)
        end
        if test -n "$_val"
            set -gx $_key "$_val"
        end
    end
end

# Bluefin MOTD & shell integration
if status is-interactive; and type -q bluefin-cli
    bluefin-cli motd show
    bluefin-cli init fish | source # bluefin-cli shell-config
end
