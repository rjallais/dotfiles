# config.nu
#
# Installed by:
# version = "0.117.0"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# Note: The env.nu/config.nu separation has been deprecated.
# All configuration (including environment variables) should be in config.nu
use std/util "path add"
$env.SYSEXTS_CONFIG_PATH = ($env.CURRENT_FILE? | default $nu.config-path)

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

if $env.SYSEXTS_LOCKED? != "1" {
    mkdir ($nu.data-dir | path join "vendor" "autoload")
}

const vendor_autoload = ($nu.data-dir | path join "vendor" "autoload")
const mise_init = ($vendor_autoload | path join "mise.nu")
const starship_init = ($vendor_autoload | path join "starship.nu")
const uutils_prefer_path = ($nu.default-config-dir | path join "uutils-prefer.nu")
const uutils_prefer = if ($uutils_prefer_path | path exists) { $uutils_prefer_path } else { null }
const argc_completions_root = ($nu.home-dir | path join ".local" "share" "argc-completions")
const argc_completions_init = ($vendor_autoload | path join "argc-completions.nu")

def write-atomic-nu [target: path, content: string] {
    let tmp = $"($target).tmp.($nu.pid)"
    $content | save --force $tmp
    mv --force $tmp $target
}

def ensure_mise_activation [] {
    if ((which mise | length) == 0) {
        return
    }

    if (not ($mise_init | path exists)) {
        let out = (^mise activate nu | complete)
        if $out.exit_code == 0 and ($out.stdout | str trim | is-not-empty) {
            write-atomic-nu $mise_init $out.stdout
        }
    }
}

def resolve_starship_bin [starship_path: string] {
    if ($starship_path | str contains "mise/shims") and (which mise | is-not-empty) {
        let mw = (^mise which starship | complete)
        if $mw.exit_code == 0 and ($mw.stdout | str trim | is-not-empty) {
            return ($mw.stdout | str trim | path expand)
        }
    }
    $starship_path | path expand
}

def ensure_starship_activation [] {
    let starship_path = (which starship | get path.0?)
    if $starship_path == null {
        return
    }

    let real_starship = (resolve_starship_bin $starship_path)
    # Regenerate the autoload when the binary path is missing or when the
    # currently-generated script still references a different install location.
    let needs_regen = (
        (not ($starship_init | path exists))
        or (try { (open --raw $starship_init | str contains $real_starship) or (open --raw $starship_init | str contains $starship_path) } catch { false } | not $in)
    )
    if $needs_regen {
        let out = (^$starship_path init nu | complete)
        if $out.exit_code == 0 and ($out.stdout | str trim | is-not-empty) {
            write-atomic-nu $starship_init $out.stdout
        }
    }
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

source $uutils_prefer

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
    let home = ($env.HOME? | default $nu.home-dir)
    let mise_installs = (($env.MISE_DATA_DIR? | default ($home | path join ".local" "share" "mise")) | path join "installs")
    let path_list = ($env.PATH)
    let mise_active = ($path_list | where {|p| $p | str starts-with $"($mise_installs)/" })
    let usr_bin = '/usr/bin'
    let mise_shims = $"($home)/.local/share/mise/shims"
    let ubrew_bin = '/opt/ubrew/prefix/bin'
    let brew_bin = '/home/linuxbrew/.linuxbrew/bin'
    let brew_sbin = '/home/linuxbrew/.linuxbrew/sbin'

    # Priority: keep active mise-installed tool paths first, then system /usr/bin,
    # mise shims, Homebrew's linked bin/sbin, and ubrew's registry mirror.
    let priority = (
        [$usr_bin $mise_shims $brew_bin $brew_sbin $ubrew_bin]
        | where {|p| $p | path exists }
    )
    let rest_path = ($path_list | where {|p| ($p not-in $mise_active) and ($p not-in $priority) })

    $env.PATH = ($mise_active | append $priority | append $rest_path | uniq)
}
normalize_path

def --wrapped cat [...files: path]: [nothing -> string, any -> string] {
    if ($files | is-empty) {
        $in | to text
    } else {
        $files
        | each { |file| open --raw $file | to text }
        | str join ""
    }
}

if $env.SYSEXTS_LOCKED? != "1" {
    ensure_mise_activation
    ensure_starship_activation
}

# argc-completions setup (replaces carapace; auto-loaded from vendor/autoload)
def --env ensure_argc_completions [] {
    if not ($argc_completions_root | path exists) {
        return
    }
    $env.ARGC_COMPLETIONS_ROOT = $argc_completions_root
    $env.ARGC_COMPLETIONS_PATH = ($argc_completions_root + '/completions/linux:' + $argc_completions_root + '/completions')
    $env.PATH = ($env.PATH | prepend ($argc_completions_root + '/bin'))
    let argc_missing_or_stub = (
        (not ($argc_completions_init | path exists))
        or (try { (open --raw $argc_completions_init | str trim | str starts-with "#") and not (open --raw $argc_completions_init | str contains "extern ") } catch { false })
    )
    if $argc_missing_or_stub and (which argc | is-not-empty) {
        let out = (^argc --argc-completions nushell | complete)
        if $out.exit_code == 0 and ($out.stdout | str trim | is-not-empty) {
            write-atomic-nu $argc_completions_init $out.stdout
        }
    }
}

if $env.SYSEXTS_LOCKED? != "1" {
    ensure_argc_completions
    normalize_path
}

$env.config = (
    $env.config?
    | default {}
    | upsert hooks { default {} }
    | upsert hooks.pre_prompt { default [] }
)
if $env.WSL_DISTRO_NAME? != null {
    $env.config.hooks.pre_prompt = (
        $env.config.hooks.pre_prompt
        | append { code: { normalize_wsl_mise_paths } }
    )
}

$env.config.hooks.pre_prompt = (
    $env.config.hooks.pre_prompt
    | append { code: { normalize_path } }
)

if ($env.SYSEXTS_LOCKED? != "1") and ($env.MISE_GITHUB_TOKEN? == null) {
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
def sysext-priv-runner [] {
    if ((^id -u | complete).stdout | str trim) == "0" {
        "/usr/bin/env"
    } else if (which run0 | is-not-empty) {
        "run0"
    } else if (which sudo | is-not-empty) {
        "sudo"
    } else {
        error make { msg: "run0 or sudo is required for privileged sysext operations" }
    }
}

def sudo-download-install [url: string, dest: path] {
    let runner = (sysext-priv-runner)
    let tmp = (^mktemp | str trim)
    let staged = $"($dest).new.($nu.pid)"
    let cleanup = {
        ^rm -f $tmp | complete | ignore
        ^$runner rm -f $staged | complete | ignore
    }
    try {
        let res = (^curl --silent --fail --location $url -o $tmp | complete)
        if $res.exit_code != 0 or (^test -s $tmp | complete).exit_code != 0 {
            error make { msg: $"Failed to download ($url): ($res.stderr | str trim)" }
        }
        ^$runner install -m 0644 -o 0 -g 0 $tmp $staged
        ^$runner mv -f $staged $dest
    } catch { |err|
        do $cleanup
        error make $err
    }
    do $cleanup
}

def host-os-version-id [] {
    if not ("/etc/os-release" | path exists) {
        return ""
    }
    try {
        open --raw "/etc/os-release"
        | lines
        | where {|l| $l | str starts-with "VERSION_ID=" }
        | get --optional 0
        | default ""
        | str replace "VERSION_ID=" ""
        | str trim --char '"'
    } catch { "" }
}

def sysext-extract-version [sname: string, full_path: string] {
    let stem = ($full_path | path basename | str replace $"($sname)-" "" | str replace --regex '\.raw$' '')
    $stem | str replace --regex '-(?:\d+|rawhide)-(?:x86-64|x86_64|aarch64|arm64|riscv64)$' ''
}

def sysext-version-key [sname: string, full_path: string] {
    let ver = (sysext-extract-version $sname $full_path)
    let parts = ($ver | split row "~")
    let main_ver = ($parts | get --optional 0 | default "")
    let pre_ver = ($parts | skip 1 | str join "~")
    let pad_ver = {|s|
        $s
        | str replace --all --regex '(\d+|[A-Za-z]+|[^A-Za-z0-9]+)' '|$1|'
        | split row '|'
        | where {|t| $t | is-not-empty }
        | each {|t|
            if ($t =~ '^\d+$') {
                $"2($t | fill -a r -c '0' -w 12)"
            } else if ($t =~ '^[A-Za-z]+$') {
                $"1($t)"
            } else {
                $"0($t)"
            }
        }
        | str join ''
    }
    let pre_tag = if ($parts | length) > 1 { $"0(do $pad_ver $pre_ver)" } else { "1" }
    $"(do $pad_ver $main_ver)!($pre_tag)!($full_path | path basename)"
}

def sysext-is-older [sname: string, rel_tag: string, a: string, b: string] {
    if ($rel_tag | is-not-empty) {
        let a_compat = ($a | path basename | str contains $rel_tag)
        let b_compat = ($b | path basename | str contains $rel_tag)
        if $a_compat != $b_compat {
            return (not $a_compat)
        }
    }
    let va = (sysext-extract-version $sname $a)
    let vb = (sysext-extract-version $sname $b)
    if (which systemd-analyze | is-not-empty) {
        if (^systemd-analyze compare-versions $va eq $vb | complete).exit_code == 0 {
            return (($a | path basename) < ($b | path basename))
        }
        return ((^systemd-analyze compare-versions $va lt $vb | complete).exit_code == 0)
    }
    (sysext-version-key $sname $a) < (sysext-version-key $sname $b)
}

def sort-sysext-paths [sname: string, rel_tag: string, paths: list<string>] {
    $paths | reduce --fold [] {|item, acc|
        let before = ($acc | where {|x| sysext-is-older $sname $rel_tag $x $item })
        let after = ($acc | where {|x| not (sysext-is-older $sname $rel_tag $x $item) })
        ($before ++ [$item] ++ $after)
    }
}

def host-sysext-arch-tags [] {
    let machine = ((^uname -m | complete).stdout | str trim | str lowercase)
    match $machine {
        "x86_64" | "amd64" => ["x86-64"]
        "aarch64" | "arm64" => ["arm64"]
        _ => [($machine | str replace "_" "-")]
    }
}

def sysext-owner [full_path: string, names: list<string>] {
    let base = ($full_path | path basename)
    $names
    | where {|n| $base | str starts-with $"($n)-" }
    | sort-by {|n| $n | str length }
    | reverse
    | get --optional 0
}

def sysext-active-targets [sname: string] {
    [
        $"/var/lib/extensions/($sname).raw"
        $"/etc/extensions/($sname).raw"
        $"/run/extensions/($sname).raw"
    ]
    | where {|lnk| ($lnk | path type) == "symlink" }
    | each {|lnk| try { $lnk | path expand } catch { "" } }
    | where {|p| $p | is-not-empty }
    | uniq
}

def sysext-all-active-targets [skip_links: list<string> = []] {
    (glob "/var/lib/extensions/*.raw")
    | append (glob "/etc/extensions/*.raw")
    | append (glob "/run/extensions/*.raw")
    | where {|lnk| ($lnk not-in $skip_links) and (($lnk | path type) == "symlink") }
    | each {|lnk| try { $lnk | path expand } catch { "" } }
    | where {|p| $p | is-not-empty }
    | uniq
}

def _dispatch-locked-sysext [] {
    let args = ($env.SYSEXTS_LOCK_ARGS | from json)
    match $env.SYSEXTS_LOCK_CALL {
        "install-sysexts-manager" => {
            install-sysexts-manager $args.version $args.version_id $args.arch
        }
        "sysexts-update-all" => {
            sysexts-update-all --keep $args.keep --dry-run=($args.dry_run) --verbose=($args.verbose)
        }
        _ => {
            error make { msg: $"Unknown locked sysext call: ($env.SYSEXTS_LOCK_CALL)" }
        }
    }
}

def run-sysext-locked [call_name: string, call_args: record] {
    let cfg = ($env.SYSEXTS_CONFIG_PATH? | default $nu.config-path)
    let runner = (sysext-priv-runner)
    let uid = ((^id -u | complete).stdout | str trim)
    let gid = ((^id -g | complete).stdout | str trim)
    let lock_file = "/run/lock/sysexts-manage/lock"
    let lock_sh = 'command -v flock >/dev/null 2>&1 || { echo "flock is required to serialize sysext operations" >&2; exit 127; }; install -d -m 0700 -o 0 -g 0 /run/lock/sysexts-manage && if [ "$5" != "0" ]; then command -v setpriv >/dev/null 2>&1 || { echo "setpriv is required to drop privileges" >&2; exit 127; }; exec flock -E 75 -n /run/lock/sysexts-manage/lock setpriv --reuid="$5" --regid="$6" --init-groups /usr/bin/env SYSEXTS_LOCKED=1 SYSEXTS_LOCK_CALL="$1" SYSEXTS_LOCK_ARGS="$2" "$3" --no-config-file -c "$4"; else exec flock -E 75 -n /run/lock/sysexts-manage/lock /usr/bin/env SYSEXTS_LOCKED=1 SYSEXTS_LOCK_CALL="$1" SYSEXTS_LOCK_ARGS="$2" "$3" --no-config-file -c "$4"; fi'
    let nu_cmd = $"source ($cfg | to json); _dispatch-locked-sysext"
    try {
        ^$runner -- /bin/sh -c $lock_sh sysexts-lock $call_name ($call_args | to json --raw) $nu.current-exe $nu_cmd $uid $gid
    } catch {
        if $env.LAST_EXIT_CODE == 75 {
            error make { msg: $"Another sysext management operation is already running \(lock: ($lock_file)\)" }
        }
        error make { msg: $"Sysext operation failed with exit code ($env.LAST_EXIT_CODE)" }
    }
}

def install-sysext-from [sysext: string, url: string] {
    let dir = $"/etc/sysupdate.($sysext).d"
    let conf = $"($dir)/($sysext).conf"

    ^sudo install -d -m 0755 -o 0 -g 0 $dir
    ^sudo restorecon -RFv $dir
    sudo-download-install $"($url)/($sysext).conf" $conf
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
    if $env.SYSEXTS_LOCKED? != "1" {
        run-sysext-locked "install-sysexts-manager" { version: $version, version_id: $version_id, arch: $arch }
        return
    }

    let runner = (sysext-priv-runner)
    let url = "https://github.com/travier/sysexts-manager/releases/download/sysexts-manager"
    let name = $"sysexts-manager-($version)-($version_id)-($arch).raw"
    let target = $"/var/lib/extensions.d/($name)"
    let mgr_link = "/var/lib/extensions/sysexts-manager.raw"

    ^$runner install -d -m 0755 -o 0 -g 0 /var/lib/extensions /var/lib/extensions.d /run/extensions

    let had_prev_link = (($mgr_link | path type) == "symlink")
    if (not $had_prev_link) and ($mgr_link | path exists) {
        error make { msg: $"Refusing to overwrite non-symlink manager path: ($mgr_link)" }
    }
    let prev_target = if $had_prev_link {
        let rl = (^readlink $mgr_link | complete)
        if $rl.exit_code != 0 or ($rl.stdout | str trim | is-empty) {
            error make { msg: $"Failed to read existing manager symlink ($mgr_link)" }
        }
        $rl.stdout | str trim
    } else {
        ""
    }

    let backup_target = if ($target | path exists) {
        let bak = $"($target).bak.($nu.pid)"
        ^$runner cp -a $target $bak
        $bak
    } else {
        ""
    }

    try {
        sudo-download-install $"($url)/($name)" $target
        ^$runner ln -snf $target $mgr_link
        ^$runner restorecon -RFv /var/lib/extensions /var/lib/extensions.d /run/extensions
        ^$runner systemctl enable systemd-sysext.service
        ^$runner systemctl restart systemd-sysext.service
    } catch { |err|
        mut rollback_errs = []
        if ($backup_target | is-not-empty) and ($backup_target | path exists) {
            let rb_img = (^$runner mv -f $backup_target $target | complete)
            if $rb_img.exit_code != 0 {
                $rollback_errs = ($rollback_errs | append $"manager image rollback failed: ($rb_img.stderr | str trim)")
            }
        } else if ($backup_target | is-empty) and ($target | path exists) {
            let rb_new = (^$runner rm -f $target | complete)
            if $rb_new.exit_code != 0 {
                $rollback_errs = ($rollback_errs | append $"new manager image removal failed: ($rb_new.stderr | str trim)")
            }
        }
        if $had_prev_link {
            let rb_ln = (^$runner ln -snf $prev_target $mgr_link | complete)
            if $rb_ln.exit_code != 0 {
                $rollback_errs = ($rollback_errs | append $"manager link rollback failed: ($rb_ln.stderr | str trim)")
            }
        } else {
            let rb_rm = (^$runner rm -f $mgr_link | complete)
            if $rb_rm.exit_code != 0 {
                $rollback_errs = ($rollback_errs | append $"manager link removal failed: ($rb_rm.stderr | str trim)")
            }
        }
        let rb_merge = (^$runner systemctl restart systemd-sysext.service | complete)
        if $rb_merge.exit_code != 0 {
            $rollback_errs = ($rollback_errs | append $"recovery merge failed: ($rb_merge.stderr | str trim)")
        }
        let msg = if ($rollback_errs | is-not-empty) {
            $"($err.msg); ($rollback_errs | str join '; ')"
        } else {
            $err.msg
        }
        error make { msg: $msg }
    }
    if ($backup_target | is-not-empty) {
        ^$runner rm -f $backup_target | complete | ignore
    }
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
    if $keep < 1 {
        error make { msg: "--keep must be at least 1" }
    }
    if (not $dry_run) and ($env.SYSEXTS_LOCKED? != "1") {
        run-sysext-locked "sysexts-update-all" { keep: $keep, dry_run: $dry_run, verbose: $verbose }
        return
    }

    let runner = if $dry_run { if (which run0 | is-not-empty) { "run0" } else { "sudo" } } else { sysext-priv-runner }
    let vflag = if $verbose { ["-v"] } else { [] }
    let service_exists = ((^systemctl list-unit-files sysexts-manager.service | complete).exit_code == 0)
    let unit_state = if $service_exists {
        ((^systemctl is-enabled sysexts-manager.service | complete).stdout | str trim)
    } else { "" }
    let was_masked = ($unit_state | str starts-with "masked")
    let was_active = if $service_exists {
        ((^systemctl is-active --quiet sysexts-manager.service | complete).exit_code == 0)
    } else { false }
    let should_manage_service = (not $dry_run) and $service_exists and (not $was_masked)
    let did_mask = if $should_manage_service {
        let mask_res = (^$runner systemctl mask --now --runtime sysexts-manager.service | complete)
        if $mask_res.exit_code != 0 {
            let now_masked = (((^systemctl is-enabled sysexts-manager.service | complete).stdout | str trim) | str starts-with "masked")
            if $now_masked {
                ^$runner systemctl unmask --runtime sysexts-manager.service | complete | ignore
            }
            error make { msg: $"Failed to quiesce sysexts-manager.service: ($mask_res.stderr | str trim)" }
        }
        true
    } else {
        false
    }

    let restore_service = {
        if not $did_mask {
            return []
        }
        mut errs = []
        let unmask_res = (^$runner systemctl unmask --runtime sysexts-manager.service | complete)
        if $unmask_res.exit_code != 0 {
            $errs = ($errs | append $"unmask failed: ($unmask_res.stderr | str trim)")
        } else if $was_active {
            let start_res = (^$runner systemctl start sysexts-manager.service | complete)
            if $start_res.exit_code != 0 {
                $errs = ($errs | append $"start failed: ($start_res.stderr | str trim)")
            }
        }
        $errs
    }

    let os_ver = (host-os-version-id)
    let rel_tag = if ($os_ver | is-not-empty) { $"-($os_ver)-" } else { "" }
    let arch_tags = (host-sysext-arch-tags)
    let mgr_link = "/var/lib/extensions/sysexts-manager.raw"

    let planned_mgr_target = try {
        print $"==> step 1 updating sysexts via ($runner)"
        if $dry_run {
            print $"[dry-run] would run: ($runner) sysexts-manager update"
        } else {
            ^$runner sysexts-manager ...$vflag update
        }

        let pre_run_links = if $dry_run {
            []
        } else {
            glob "/run/extensions/*.raw"
            | where {|p| ($p | path type) == "symlink" }
            | each {|p| { link: $p, target: ((^readlink $p | complete).stdout | str trim) } }
            | where {|item| $item.target | is-not-empty }
        }
        if not $dry_run {
            let non_symlinks = (glob "/run/extensions/*.raw" | where {|p| ($p | path type) != "symlink" })
            if ($non_symlinks | is-not-empty) {
                error make { msg: $"Refusing to run sysexts-manager enable with non-symlink runtime images in /run/extensions: ($non_symlinks | str join ', ')" }
            }
        }

        let prev_mgr = if (not $dry_run) and (($mgr_link | path type) == "symlink") {
            ((^readlink $mgr_link | complete).stdout | str trim)
        } else { "" }
        try {
            print $"==> step 2 enabling newest images via ($runner)"
            if $dry_run {
                print $"[dry-run] would run: ($runner) sysexts-manager enable"
            } else {
                ^$runner sysexts-manager ...$vflag enable
            }

            let mgr_matches = (glob "/var/lib/extensions.d/sysexts-manager-*.raw")
            let compat_mgr = (
                $mgr_matches
                | where {|p|
                    let base = ($p | path basename)
                    let suffix_prefix = if ($rel_tag | is-not-empty) { $rel_tag } else { "-" }
                    $arch_tags | any {|a| $base | str ends-with $"($suffix_prefix)($a).raw" }
                }
            )
            let planned = if ($mgr_link | path type) == "symlink" and ($compat_mgr | is-not-empty) {
                let newest_mgr = (sort-sysext-paths "sysexts-manager" $rel_tag $compat_mgr | last)
                let cur_mgr = (try { $mgr_link | path expand } catch { "" })
                let compat_expanded = ($compat_mgr | each {|p| $p | path expand })
                let needs_switch = ($cur_mgr | is-empty) or ($cur_mgr not-in $compat_expanded) or (($newest_mgr | path expand) != $cur_mgr)
                let next_planned = ($newest_mgr | path expand)
                if $needs_switch {
                    if $dry_run {
                        print $"[dry-run] would link: ($newest_mgr) -> ($mgr_link)"
                    } else {
                        ^$runner ln -snf $newest_mgr $mgr_link
                    }
                }
                $next_planned
            } else {
                ""
            }

            print $"==> step 3 refreshing merge via ($runner)"
            if $dry_run {
                print $"[dry-run] would run: ($runner) systemctl restart systemd-sysext.service"
            } else {
                ^$runner systemctl restart systemd-sysext.service
            }
            $planned
        } catch { |err|
            if $dry_run {
                error make $err
            }
            mut rollback_errs = []
            if ($prev_mgr | is-not-empty) {
                let rb_ln = (^$runner ln -snf $prev_mgr $mgr_link | complete)
                if $rb_ln.exit_code != 0 {
                    $rollback_errs = ($rollback_errs | append $"manager link rollback failed: ($rb_ln.stderr | str trim)")
                }
            }
            let saved_paths = if ($pre_run_links | is-not-empty) { $pre_run_links | get link } else { [] }
            for cur in (glob "/run/extensions/*.raw") {
                if ($cur | path type) == "symlink" and ($cur not-in $saved_paths) {
                    let rm_res = (^$runner rm -f $cur | complete)
                    if $rm_res.exit_code != 0 {
                        $rollback_errs = ($rollback_errs | append $"runtime link removal failed ($cur): ($rm_res.stderr | str trim)")
                    }
                }
            }
            for item in $pre_run_links {
                let rb_run = (^$runner ln -snf $item.target $item.link | complete)
                if $rb_run.exit_code != 0 {
                    $rollback_errs = ($rollback_errs | append $"runtime link rollback failed ($item.link): ($rb_run.stderr | str trim)")
                }
            }
            let rb_merge = (^$runner systemctl restart systemd-sysext.service | complete)
            if $rb_merge.exit_code != 0 {
                $rollback_errs = ($rollback_errs | append $"recovery merge failed: ($rb_merge.stderr | str trim)")
            }
            let msg = if ($rollback_errs | is-not-empty) {
                $"($err.msg); ($rollback_errs | str join '; ')"
            } else {
                $err.msg
            }
            error make { msg: $msg }
        }
    } catch { |err|
        let rerrs = (do $restore_service)
        let msg = if ($rerrs | is-not-empty) {
            $"($err.msg); restore errors: ($rerrs | str join '; ')"
        } else {
            $err.msg
        }
        error make { msg: $msg }
    }
    let rerrs = (do $restore_service)
    if ($rerrs | is-not-empty) {
        error make { msg: $"sysexts-manager restore failed: ($rerrs | str join '; ')" }
    }

    print $"==> pruning old images, keep ($keep) newest per sysext..."

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

    let all_images = (glob "/var/lib/extensions.d/*.raw")
    if $dry_run {
        print "[dry-run] preview based on currently downloaded images (remote updates not fetched)"
    }
    let dry_plans = if $dry_run {
        $names | each {|sname|
            if $sname == "sysexts-manager" {
                let skip = if ($planned_mgr_target | is-not-empty) { $mgr_link } else { "" }
                { name: $sname, planned: $planned_mgr_target, skip_link: $skip }
            } else {
                let compat = (
                    $all_images
                    | where {|p| (sysext-owner $p $names) == $sname }
                    | where {|p|
                        let base = ($p | path basename)
                        let suffix_prefix = if ($rel_tag | is-not-empty) { $rel_tag } else { "-" }
                        $arch_tags | any {|a| $base | str ends-with $"($suffix_prefix)($a).raw" }
                    }
                )
                let planned = if ($compat | is-not-empty) {
                    (sort-sysext-paths $sname $rel_tag $compat | last | path expand)
                } else { "" }
                let skip = if ($planned | is-not-empty) { $"/run/extensions/($sname).raw" } else { "" }
                { name: $sname, planned: $planned, skip_link: $skip }
            }
        }
    } else { [] }
    let dry_skip_links = if ($dry_plans | is-not-empty) {
        $dry_plans | get skip_link | where {|p| $p | is-not-empty }
    } else { [] }
    let dry_planned_targets = if ($dry_plans | is-not-empty) {
        $dry_plans | get planned | where {|p| $p | is-not-empty }
    } else { [] }
    let global_active = ((sysext-all-active-targets $dry_skip_links) ++ $dry_planned_targets | uniq)

    for sname in $names {
        let matches = ($all_images | where {|p| (sysext-owner $p $names) == $sname })
        let live_targets = (sysext-active-targets $sname)
        let plan_entry = ($dry_plans | where {|r| $r.name == $sname } | get --optional 0)
        let planned_target = ($plan_entry | get --optional planned | default "")
        let skip_link = ($plan_entry | get --optional skip_link | default "")
        let active_targets = if $dry_run and ($planned_target | is-not-empty) {
            let kept_live = (
                [$"/var/lib/extensions/($sname).raw" $"/etc/extensions/($sname).raw" $"/run/extensions/($sname).raw"]
                | where {|lnk| ($lnk != $skip_link) and (($lnk | path type) == "symlink") }
                | each {|lnk| try { $lnk | path expand } catch { "" } }
                | where {|p| $p | is-not-empty }
            )
            ([$planned_target] ++ $kept_live | uniq)
        } else {
            $live_targets
        }
        let protected_set = ($active_targets ++ $global_active | uniq)
        let protected = ($matches | where {|p| ($p | path expand) in $protected_set })
        let pool = ($matches | where {|p| ($p | path expand) not-in $protected_set })
        let extra_keep = ([0 ($keep - ($protected | length))] | math max)
        let n_pool = ($pool | length)
        if $n_pool > $extra_keep {
            let ranked = (sort-sysext-paths $sname $rel_tag $pool)
            let stale = ($ranked | take ($n_pool - $extra_keep))
            for full in $stale {
                if $dry_run {
                    if ($planned_target | is-not-empty) {
                        print $"[dry-run] prune candidate \(based on current disk images\): ($full)"
                    } else {
                        print $"[dry-run] preview only \(planned activation unknown; current links kept\): ($full)"
                    }
                } else if ($full | path expand) in (sysext-all-active-targets) {
                    print $"Skipping active image: ($full)"
                } else {
                    print $"Deleting old image: ($full)"
                    ^$runner rm -f $full
                }
            }
        } else {
            print $"($sname): ($matches | length) images, nothing to prune"
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
def --env fcd [] {
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
if $nu.is-interactive and ($env.SYSEXTS_LOCKED? != "1") {
    try { bluefin-cli motd show }
}
