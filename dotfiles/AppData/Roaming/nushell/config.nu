use std/util "path add"

mkdir ($nu.data-dir | path join "vendor/autoload")

const vendor_autoload = ($nu.data-dir | path join "vendor" "autoload")
const mise_init = ($vendor_autoload | path join "mise.nu")

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

let home = $env.HOME? | default $env.USERPROFILE?
if $home != null {
    path add ($home | path join ".local" "bin")
    path add ($home | path join ".local" "share" "mise" "shims")
}

# pnpm - use AppData on Windows
if $env.APPDATA? != null {
    $env.PNPM_HOME = $"($env.APPDATA)/pnpm"
} else {
    $env.PNPM_HOME = $"($home)/.local/share/pnpm"
}
$env.PATH = ($env.PATH | split row (char esep) | prepend ($env.PNPM_HOME | path join "bin"))

def --wrapped cat [...files: path]: [nothing -> string, any -> string] {
    if ($files | is-empty) {
        $in | to text
    } else {
        $files
        | each { |file| open --raw $file | to text }
        | str join ""
    }
}

ensure_mise_activation

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

# $env.ANTHROPIC_BASE_URL = ""
# $env.ANTHROPIC_AUTH_TOKEN = ""
# $env.ANTHROPIC_MODEL = ""
$env.CLAUDE_CODE_USE_VERTEX = 1
$env.CLOUD_ML_REGION = "global"
$env.ANTHROPIC_VERTEX_PROJECT_ID = "gen-lang-client-0448119314"

$env.GOOGLE_CLOUD_PROJECT = "gen-lang-client-0448119314"
$env.GOOGLE_CLOUD_LOCATION = "global"

# Custom aliases or functions can go here
# For example:
# alias ls = lsd
# alias cat = bat
