# config.nu
#
# Installed by:
# version = "0.108.0"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# Nushell sets "sensible defaults" for most configuration settings,
# so your `config.nu` only needs to override these defaults if desired.
#
# You can open this file in your default editor using:
#     config nu
#
# You can also pretty-print and page through the documentation for configuration
# options using:
#     config nu --doc | nu-highlight | less -R
use std/util "path add"

mkdir ($nu.data-dir | path join "vendor/autoload")

path add "~/.local/bin"

# Mise (mise-en-place)
^mise activate nu | save -f ($nu.data-dir | path join "vendor/autoload/mise.nu")

# Starship
mise x starship -- starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")

# Zoxide
mise x zoxide -- zoxide init nushell | save -f ($nu.data-dir | path join "vendor/autoload/zoxide.nu")

# Atuin
mise x atuin -- atuin init nu | save -f ($nu.data-dir | path join "vendor/autoload/atuin.nu")

# Carapace
mise x carapace -- carapace _carapace nushell | save -f ($nu.data-dir | path join "vendor/autoload/carapace.nu")

# Custom aliases or functions can go here
# For example:
# alias ls = lsd
# alias cat = bat
