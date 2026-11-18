# config.nu
#
# Installed by:
# version = "0.108.0"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# Note: The env.nu/config.nu separation has been deprecated.
# All configuration (including environment variables) should be in config.nu
use std/util "path add"

$env.config = {
    show_banner: false
    table: {
        mode: "rounded"
        index_mode: "auto"
        show_empty: true
        padding: { left: 1, right: 1 }
        trim: { methodology: "wrapping", wrapping_try_keep_words: true }
    }
    history: {
        max_size: 100_000
        sync_on_enter: true
        file_format: "sqlite"
        isolation: false
    }
    completions: {
        case_sensitive: false
        quick: true
        partial: true
        algorithm: "fuzzy"
        use_ls_colors: true
    }
    color_config: { shape_ghost_text: "dark_gray" }
    cursor_shape: { emacs: "line", vi_insert: "line", vi_normal: "block" }
    edit_mode: "emacs"
    float_precision: 2
    use_ansi_coloring: true
    bracketed_paste: true
    footer_mode: "auto"
    menus: [
        {
            name: completion_menu
            only_buffer_difference: false
            marker: "| "
            type: {
                layout: ide
                min_completion_width: 0
                max_completion_width: 50
                max_completion_height: 10
                padding: 0
                cursor_offset: 0
                description_mode: "prefer_right"
                min_description_width: 0
                max_description_width: 50
                max_description_height: 10
                description_offset: 1
                correct_cursor_pos: false
            }
            style: {
                text: "#cdd6f4"
                selected_text: { attr: r }
                description_text: "#9399b2"
                match_text: { attr: u }
                selected_match_text: { attr: ur }
            }
        }
    ]
    keybindings: [
        { name: accept_ghost_text, modifier: none, keycode: right, mode: [emacs, vi_normal, vi_insert], event: { send: HistoryHintComplete } }
        { name: accept_ghost_word, modifier: control, keycode: right, mode: [emacs, vi_normal, vi_insert], event: { send: HistoryHintWordComplete } }
        { name: accept_ghost_word_alt, modifier: alt, keycode: right, mode: [emacs, vi_normal, vi_insert], event: { send: HistoryHintWordComplete } }
        { name: history_up, modifier: none, keycode: up, mode: [emacs, vi_normal, vi_insert], event: { until: [{ send: menu name: history_menu } { send: up }] } }
    ]
}

mkdir ($nu.data-dir | path join "vendor" "autoload")

const vendor_autoload = ($nu.data-dir | path join "vendor" "autoload")
const mise_init = ($vendor_autoload | path join "mise.nu")
const starship_init = ($vendor_autoload | path join "starship.nu")
const zoxide_init = ($vendor_autoload | path join "zoxide.nu")
const atuin_init = ($vendor_autoload | path join "atuin.nu")
const brew_init = ($vendor_autoload | path join "brew.nu")
const uutils_prefer = ($nu.default-config-dir | path join "uutils-prefer.nu")
const argc_completions_root = ($nu.home-dir | path join ".local" "share" "argc-completions")
const argc_completions_init = ($vendor_autoload | path join "argc-completions.nu")

def --env ensure_mise_activation [] {
    if ((which mise | length) == 0) {
        return
    }

    if (not ($mise_init | path exists)) {
        ^mise activate nu | save --force $mise_init
    }

    source $mise_init
}

def --env ensure_starship_activation [] {
    let starship_path = (which starship | get path.0?)
    if $starship_path == null {
        return
    }

    # Regenerate the autoload when the binary path is missing or when the
    # currently-generated script still references a different install location
    # (e.g. an old mise install).
    let needs_regen = (
        (not ($starship_init | path exists))
        or (try { open --raw $starship_init | str contains $starship_path } catch { false } | not $in)
    )
    if $needs_regen {
        try {
            ^$starship_path init nu | save --force $starship_init
        } catch {
            return
        }
    }

    source $starship_init
}

def --env normalize_wsl_mise_paths [] {
    if $env.WSL_DISTRO_NAME? == null {
        return
    }

    $env.PATH = (
        $env.PATH
        | where { |p| (not ($p | str contains "/AppData/Local/mise/shims")) and (not ($p | str contains "/scoop/apps/mise/current/bin")) and (not ($p | str contains "/AppData/Local/mise/installs")) }
        | uniq
    )

    let local_home = $env.HOME? | default $env.USERPROFILE?
    if $local_home != null {
        path add ($local_home | path join ".local" "share" "mise" "shims")
    }
}

let home = $env.HOME? | default $env.USERPROFILE?
if $home != null {
    path add ($home | path join ".local" "bin")
    path add ($home | path join ".local" "share" "mise" "shims")
}
if ('/opt/ubrew/prefix/bin' | path exists) {
    path add '/opt/ubrew/prefix/bin'
}
normalize_wsl_mise_paths

if ($uutils_prefer | path exists) { source $uutils_prefer }

# Homebrew/Linuxbrew performance optimizations (non-Windows)
if (sys host | get name) != "Windows" {
    $env.HOMEBREW_NO_ANALYTICS = 1            # no telemetry, faster commands
    $env.HOMEBREW_NO_AUTO_UPDATE = 1          # no auto-update on every brew install
    $env.HOMEBREW_NO_INSTALL_CLEANUP = "TRUE" # skip cleanup after install (saves I/O on OSTree)
    $env.HOMEBREW_DEVELOPER = 1               # access --HEAD formulae, extra options
    $env.HOMEBREW_DOWNLOAD_CONCURRENCY = 16   # parallel downloads
    $env.HOMEBREW_PREFIX = "/home/linuxbrew/.linuxbrew"
    $env.HOMEBREW_CELLAR = "/home/linuxbrew/.linuxbrew/Cellar"
}

# pnpm
$env.PNPM_HOME = ($nu.home-dir | path join ".local" "share" "pnpm")
$env.PATH = ($env.PATH | split row (char esep) | prepend ($env.PNPM_HOME | path join "bin"))

def --env ensure_homebrew_path [] {
    if (sys host | get name) == "Windows" {
        return
    }
    if ('/home/linuxbrew/.linuxbrew/bin' | path exists) {
        path add '/home/linuxbrew/.linuxbrew/bin'
        path add '/home/linuxbrew/.linuxbrew/sbin'
    }
}

def --env ensure_ubrew_path [] {
    if (sys host | get name) == "Windows" {
        return
    }
    if ('/opt/ubrew/prefix/bin' | path exists) {
        path add '/opt/ubrew/prefix/bin'
    }
}

def --env normalize_path [] {
    if (sys host | get name) == "Windows" {
        return
    }
    ensure_homebrew_path
    ensure_ubrew_path
    let path_list = ($env.PATH)
    let usr_bin = '/usr/bin'
    let mise_shims = $"($env.HOME)/.local/share/mise/shims"
    let ubrew_bin = '/opt/ubrew/prefix/bin'
    let brew_bin = '/home/linuxbrew/.linuxbrew/bin'
    let brew_sbin = '/home/linuxbrew/.linuxbrew/sbin'

    # Priority: system /usr/bin first, then mise shims, then Homebrew's linked
    # bin/sbin, then ubrew's registry mirror. brew's links always track the keg
    # brew itself upgrades, so they never go stale; ubrew's mirror can lag when
    # brew bumps a formula, so it must stay *after* brew's bin to avoid shadowing.
    let priority = (
        [$usr_bin $mise_shims $brew_bin $brew_sbin $ubrew_bin]
        | where {|p| $p | path exists }
    )
    let rest_path = ($path_list | where {|p| $p not-in $priority})

    $env.PATH = ($priority | append $rest_path | uniq)
}
normalize_path

def --wrapped cat [...files: path]: [nothing -> string, any -> string] {
    if ($files | is-empty) {
        $in | to text
    } else {
        $files
        | each { |file| open $file | to text }
        | str join ""
    }
}

ensure_mise_activation
ensure_starship_activation
if ($zoxide_init | path exists) { source $zoxide_init }
if ($atuin_init | path exists) { source $atuin_init }
if ($brew_init | path exists) { source $brew_init }

# argc-completions setup (replaces carapace; auto-loaded from vendor/autoload)
def --env ensure_argc_completions [] {
    if not ($argc_completions_root | path exists) {
        return
    }
    $env.ARGC_COMPLETIONS_ROOT = $argc_completions_root
    $env.ARGC_COMPLETIONS_PATH = ($argc_completions_root + '/completions/linux:' + $argc_completions_root + '/completions')
    $env.PATH = ($env.PATH | prepend ($argc_completions_root + '/bin'))
    if (not ($argc_completions_init | path exists)) and (which argc | is-not-empty) {
        try { ^argc --argc-completions nushell | save --force $argc_completions_init }
    }
}

ensure_argc_completions
normalize_path

$env.config = (
    $env.config?
    | default {}
    | upsert hooks { default {} }
    | upsert hooks.pre_prompt { default [] }
)
$env.config.hooks.pre_prompt = (
    $env.config.hooks.pre_prompt
    | append { code: { normalize_path } }
)

if $env.WSL_DISTRO_NAME? != null {
    $env.config.hooks.pre_prompt = (
        $env.config.hooks.pre_prompt
        | append { code: { normalize_wsl_mise_paths } }
    )
}

if $env.MISE_GITHUB_TOKEN? == null {
    if ((which gh | length) > 0) {
        let gh_auth = (^gh auth token | complete)
        if $gh_auth.exit_code == 0 {
            let gh_token = ($gh_auth.stdout | default "" | str trim)
            if $gh_token != "" {
                $env.MISE_GITHUB_TOKEN = $gh_token
            }
        }
    }
}

$env.CLAUDE_CODE_USE_VERTEX = 1
$env.CLOUD_ML_REGION = "global"
$env.ANTHROPIC_VERTEX_PROJECT_ID = "gen-lang-client-0448119314"

$env.GOOGLE_CLOUD_PROJECT = "gen-lang-client-0448119314"
$env.GOOGLE_CLOUD_LOCATION = "global"

# Linux-only: Fedora CoreOS system extension management
# These functions require sudo, systemctl, and Linux paths
def install-sysext-from [sysext: string, url: string] {
    let dir = $"/etc/sysupdate.($sysext).d"
    let conf = $"/($dir)/($sysext).conf"

    ^sudo install -d -m 0755 -o 0 -g 0 $dir
    ^sudo restorecon -RFv $dir
    ^curl --silent --fail --location $"($url)/($sysext).conf" | ^sudo tee $conf | ignore
    ^sudo /usr/lib/systemd/systemd-sysupdate update --component $sysext
}

def install-sysext [sysext: string] {
    install-sysext-from $sysext "https://extensions.fcos.fr/fedora"
}

def install-sysext-community [sysext: string] {
    install-sysext-from $sysext "https://extensions.fcos.fr/community"
}

def uninstall-sysext [sysext: string] {
    let link = $"/var/lib/extensions/($sysext).raw"
    let image_glob = $"/var/lib/extensions.d/($sysext)-*.raw"
    let conf = $"/etc/sysupdate.($sysext).d/($sysext).conf"
    let dir = $"/etc/sysupdate.($sysext).d"

    ^sudo rm -i $link
    glob $image_glob | each { |image| ^sudo rm -i $image }
    ^sudo rm -i $conf
    ^sudo rmdir $dir
}

def install-sysexts-manager [
    version: string = "0.3.4"
    version_id: string = "45"
    arch: string = "x86-64"
] {
    let url = "https://github.com/travier/sysexts-manager/releases/download/sysexts-manager"
    let name = $"sysexts-manager-($version)-($version_id)-($arch).raw"
    let target = $"/var/lib/extensions.d/($name)"

    ^sudo install -d -m 0755 -o 0 -g 0 /var/lib/extensions /var/lib/extensions.d /run/extensions
    ^curl --silent --fail --location $"($url)/($name)" | ^sudo tee $target | ignore
    ^sudo ln -snf $target /var/lib/extensions/sysexts-manager.raw
    ^sudo restorecon -RFv /var/lib/extensions /var/lib/extensions.d /run/extensions
    ^sudo systemctl enable systemd-sysext.service
    ^sudo systemctl restart systemd-sysext.service
}

# All-in-one: update all sysexts, enable newest, refresh merge, prune old images.
# Usage:
#   sysexts-update-all            # keep 1 newest per sysext, auto-prune rest (needs sudo/run0)
#   sysexts-update-all --keep 2   # keep 2 newest (matches InstancesMax=2 default)
#   sysexts-update-all --dry-run  # show what would be pruned, change nothing
def sysexts-update-all [
    --keep: int = 1        # how many newest images to keep per sysext
    --dry-run             # only show, don't change anything
    --verbose (-v)        # pass -v to sysexts-manager
] {
    let runner = if (which run0 | is-not-empty) { "run0" } else { "sudo" }
    let vflag = if $verbose { ["-v"] } else { [] }
    let service_exists = ((^systemctl list-unit-files sysexts-manager.service | complete).exit_code == 0)

    if (not $dry_run) and $service_exists {
        ^$runner systemctl mask --now --runtime sysexts-manager.service | complete | ignore
    }

    try {
        print $"==> step 1 updating sysexts via ($runner)"
        if $dry_run {
            print $"[dry-run] would run: ($runner) sysexts-manager update"
        } else {
            ^$runner sysexts-manager ...$vflag update
        }

        print $"==> step 2 enabling newest images via ($runner)"
        if $dry_run {
            print $"[dry-run] would run: ($runner) sysexts-manager enable"
        } else {
            ^$runner sysexts-manager ...$vflag enable
        }

        print $"==> step 3 refreshing merge via ($runner)"
        if $dry_run {
            print $"[dry-run] would run: ($runner) systemctl restart systemd-sysext.service"
        } else {
            ^$runner systemctl restart systemd-sysext.service
        }
    } finally {
        if (not $dry_run) and $service_exists {
            ^$runner systemctl unmask --runtime sysexts-manager.service | complete | ignore
            ^$runner systemctl start sysexts-manager.service | complete | ignore
        }
    }

    print $"==> pruning old images, keep ($keep) newest per sysext..."
    if (not $dry_run) and (("/var/lib/extensions/sysexts-manager.raw" | path type) == "symlink") {
        let mgr_matches = (glob "/var/lib/extensions.d/sysexts-manager-*.raw")
        if ($mgr_matches | is-not-empty) {
            let newest_mgr = (ls ...$mgr_matches | sort-by modified | get name | last)
            ^$runner ln -snf $newest_mgr /var/lib/extensions/sysexts-manager.raw
        }
    }

    let conf_files = (glob "/etc/sysexts-manager/*.conf")
    let names: list<string> = (
        (if ($conf_files | is-not-empty) {
            $conf_files | path basename | str replace '.conf' ''
        } else {
            []
        })
        ++ ["sysexts-manager"]
        | sort
        | uniq
    )

    for sname in $names {
        let matches = (glob $"/var/lib/extensions.d/($sname)-*.raw")
        let files = if ($matches | is-not-empty) {
            ls ...$matches | sort-by modified | get name | path basename
        } else {
            []
        }
        let n = ($files | length)
        if $n > $keep {
            let stale = ($files | take ($n - $keep))
            for f in $stale {
                let full = $"/var/lib/extensions.d/($f)"
                if $dry_run {
                    print $"[dry-run] would delete: ($full)"
                } else {
                    print $"Deleting old image: ($full)"
                    ^$runner rm -f $full
                }
            }
        } else {
            print $"($sname): ($n) images, nothing to prune"
        }
    }

    if not $dry_run {
        print "==> Verifying..."
        sysexts-manager status
        print ""
        systemd-sysext status
    }
}

# Re-apply after autoloads (starship/etc. merge $env.config).
# Also works around broken default display_output hooks in some distro packages.
$env.config.hooks.display_output = { if (term size).columns >= 100 { table -e } else { table } }

# Ergonomic CLI helpers
def --wrapped b [...args: string] {
    if (which bat | is-not-empty) { ^bat --paging=auto ...$args } else { open ...$args }
}
def fcd [] {
    if (which fd | is-not-empty) and (which fzf | is-not-empty) {
        let target = (^fd --type d --hidden --exclude .git | ^fzf --preview '^eza --tree --level=2 {}' | str trim)
        if ($target | is-not-empty) { cd $target }
    }
}
def gst [] {
    if (which git | is-not-empty) {
        ^git status --short | lines | where { is-not-empty } | parse "{status} {file}" | str trim
    }
}
def --wrapped uu [cmd: string, ...args: string] {
    if (which coreutils | is-not-empty) { ^coreutils $cmd ...$args } else { error make {msg: $"Coreutils command not found: ($cmd)"} }
}
def sha256 [...files: string] {
    if (which sha256sum | is-not-empty) { ^sha256sum ...$files | lines | where { is-not-empty } | parse "{hash}  {file}" | str trim }
    else if (which coreutils | is-not-empty) { ^coreutils sha256sum ...$files | lines | where { is-not-empty } | parse "{hash}  {file}" | str trim }
}
def md5 [...files: string] {
    if (which md5sum | is-not-empty) { ^md5sum ...$files | lines | where { is-not-empty } | parse "{hash}  {file}" | str trim }
    else if (which coreutils | is-not-empty) { ^coreutils md5sum ...$files | lines | where { is-not-empty } | parse "{hash}  {file}" | str trim }
}

# Bluefin MOTD
if $nu.is-interactive {
    try { bluefin-cli motd show }
}
