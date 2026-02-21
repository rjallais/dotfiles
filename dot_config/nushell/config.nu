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

let home = $env.HOME? | default $env.USERPROFILE?
if $home != null {
    path add ($home | path join ".local" "bin")
}

if $env.WSL_DISTRO_NAME? != null {
    $env.PATH = (
        $env.PATH
        | where { |p| (not ($p | str contains "/AppData/Local/mise/shims")) and (not ($p | str contains "/scoop/apps/mise/current/bin")) and (not ($p | str contains "/AppData/Local/mise/installs")) }
        | uniq
    )
}

const mise_autoload = ($nu.data-dir | path join "vendor" "autoload" "mise.nu")
const starship_autoload = ($nu.data-dir | path join "vendor" "autoload" "starship.nu")
const zoxide_autoload = ($nu.data-dir | path join "vendor" "autoload" "zoxide.nu")
const atuin_autoload = ($nu.data-dir | path join "vendor" "autoload" "atuin.nu")
const carapace_autoload = ($nu.data-dir | path join "vendor" "autoload" "carapace.nu")

if ($mise_autoload | path exists) { source $mise_autoload }
if ($starship_autoload | path exists) { source $starship_autoload }
if ($zoxide_autoload | path exists) { source $zoxide_autoload }
if ($atuin_autoload | path exists) { source $atuin_autoload }
if ($carapace_autoload | path exists) { source $carapace_autoload }

if $env.MISE_GITHUB_TOKEN? == null {
    if ((which gh | length) > 0) {
        let gh_token = (do -i { ^gh auth token } | default "" | str trim)
        if $gh_token != "" {
            $env.MISE_GITHUB_TOKEN = $gh_token
        }
    }
}

# Custom aliases or functions can go here
# For example:
# alias ls = lsd
# alias cat = bat
