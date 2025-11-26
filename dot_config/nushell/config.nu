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

# Source mise configuration (already present)
use ($nu.default-config-dir | path join mise.nu)

# Starship prompt
if (which starship | is-not-empty) {
    starship init nu | save -f ~/.config/nushell/starship_init.nu
    source ~/.config/nushell/starship_init.nu
}

# Atuin history
if (which atuin | is-not-empty) {
    atuin init nu | save -f ~/.config/nushell/atuin_init.nu
    source ~/.config/nushell/atuin_init.nu
}

# Zoxide directory jumper
if (which zoxide | is-not-empty) {
    zoxide init nu | save -f ~/.config/nushell/zoxide_init.nu
    source ~/.config/nushell/zoxide_init.nu
}

# Custom aliases or functions can go here
# For example:
# alias ls = lsd
# alias cat = bat
