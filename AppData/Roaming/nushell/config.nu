use std/util "path add"

mkdir ($nu.data-dir | path join "vendor/autoload")

let home = $env.HOME? | default $env.USERPROFILE?
if $home != null {
    path add ($home | path join ".local" "bin")
}

const mise_autoload = ($nu.data-dir | path join "vendor" "autoload" "mise.nu")
const starship_autoload = ($nu.data-dir | path join "vendor" "autoload" "starship.nu")
const zoxide_autoload = ($nu.data-dir | path join "vendor" "autoload" "zoxide.nu")
const atuin_autoload = ($nu.data-dir | path join "vendor" "autoload" "atuin.nu")
const carapace_autoload = ($nu.data-dir | path join "vendor" "autoload" "carapace.nu")

if ($mise_autoload | path exists) { source $mise_autoload }
if ($starship_autoload | path exists) { source $starship_autoload }
source $zoxide_autoload
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
