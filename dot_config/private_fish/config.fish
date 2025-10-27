# 1) Ensure user‐local binaries are in PATH
set -gx PATH $HOME/.local/bin $PATH

# --- CUDA Toolkit ---
# Use fish_add_path for PATH (prevents duplicates)
fish_add_path /usr/local/cuda-12.9/bin
# Use set -gx to prepend and export LD_LIBRARY_PATH
set -gx LD_LIBRARY_PATH /usr/local/cuda-12.9/lib64 $LD_LIBRARY_PATH

mise activate fish | source

# Initialize starship if it's installed (version-independent)
if command -q starship
    starship init fish | source
end

# 2) Only in interactive sessions…
if status is-interactive
    # Commands to run in interactive sessions can go here
    set -Ux EGET_BIN $HOME/.local/bin
    set -Ux fish_user_paths $EGET_BIN $fish_user_paths

    # 2a) Initialize mise if it’s installed
    # if test -x $HOME/.local/bin/mise
        # ~/.local/bin/mise activate fish | source
        # mise completion fish > ~/.config/fish/completions/mise.fish
    # end


    # Ensure XDG_CONFIG_HOME falls back to ~/.config
    set -l config_home $XDG_CONFIG_HOME; or set config_home $HOME/.config
    
    # Export AQUA_GLOBAL_CONFIG (use existing value or empty, then append the default path)
    set -x AQUA_GLOBAL_CONFIG "$AQUA_GLOBAL_CONFIG:$config_home/aquaproj-aqua/aqua.yaml"

    # set -Ux fish_user_paths $HOME/.local/share/aquaproj-aqua/bin $fish_user_paths
end

# >>> mamba initialize >>>
# !! Contents within this block are managed by 'mamba shell init' !!
# set -gx MAMBA_EXE "/home/rjallais/miniforge3/bin/mamba"
# set -gx MAMBA_ROOT_PREFIX "/home/rjallais/.local/share/mamba"
# $MAMBA_EXE shell hook --shell fish --root-prefix $MAMBA_ROOT_PREFIX | source
# <<< mamba initialize <<<

# conda config --set auto_activate_base false
# conda activate /home/rjallais/.local/share/mamba/envs/global-env

# add ~/.pixi/bin to your PATH if it isn’t already there
fish_add_path $HOME/.pixi/bin
pixi completion --shell fish | source

set -l unique_paths
for path_item in $PATH
    # Check if path exists and is not already in unique_paths
    if test -d $path_item; and not contains $path_item $unique_paths
        set unique_paths $unique_paths $path_item
    end
end
set -gx PATH $unique_paths
