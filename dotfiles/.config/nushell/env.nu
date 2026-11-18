# env.nu is loaded BEFORE config.nu and BEFORE the autoload files
# under vendor/autoload/. Adding user local bins, mise shims, and
# /opt/ubrew/prefix/bin here ensures CLI tools are discoverable early.
let home = (
    [$env.HOME? ($nu.home-dir? | default $nu.home-path?)]
    | where {|p| ($p | default "" | str trim) | is-not-empty }
    | get --optional 0
)
let early_bins = if $home != null {
    [
        ($home | path join '.local' 'bin')
        ($home | path join '.local' 'share' 'mise' 'shims')
        '/opt/ubrew/prefix/bin'
    ]
    | where {|p| $p | path exists }
} else {
    ['/opt/ubrew/prefix/bin'] | where {|p| $p | path exists }
}
if ($early_bins | is-not-empty) {
    $env.PATH = (
        $env.PATH
        | append $early_bins
        | uniq
    )
}

# 9Router gateway
$env.NINEROUTER_URL = "http://localhost:20128"

if $home != null {
    # Aqua global config (for standalone `aqua g`)
    $env.AQUA_GLOBAL_CONFIG = ($home | path join "aqua.yaml")

    # DigitalOcean Inference API key (for Grok CLI custom DO models)
    # Mirrors bashrc: source OPENAI_API_KEY from ~/.hermes/.env
    let hermes_env = ($home | path join '.hermes' '.env')
    if ($hermes_env | path exists) {
        let line = (
            try {
                open --raw $hermes_env
                | lines
                | where {|l| $l | str starts-with 'OPENAI_API_KEY='}
                | get --optional 0
            } catch { null }
        )
        if $line != null {
            let key = (
                $line
                | str replace --regex '^OPENAI_API_KEY=' ''
                | str trim --char '"'
                | str trim --char "'"
            )
            if not ($key | is-empty) {
                $env.OPENAI_API_KEY = $key
            }
        }
    }

    # Load encrypted API keys via fnox when age identity is available
    let fnox_cfg = ($home | path join '.config' 'fnox' 'config.toml')
    let fnox_age = ($home | path join '.config' 'fnox' 'age.txt')
    let has_age_key = (($env.FNOX_AGE_KEY? | default "" | str trim) | is-not-empty)
    let has_age_key_file = (($env.FNOX_AGE_KEY_FILE? | default "" | str trim) | is-not-empty)
    if (which fnox | is-not-empty) and ($fnox_cfg | path exists) and (($fnox_age | path exists) or $has_age_key or $has_age_key_file) {
        let fnox_env = if (not $has_age_key) and (not $has_age_key_file) and ($fnox_age | path exists) {
            { FNOX_AGE_KEY: null, FNOX_AGE_KEY_FILE: $fnox_age }
        } else if (not $has_age_key) and $has_age_key_file {
            { FNOX_AGE_KEY: null }
        } else if $has_age_key and (not $has_age_key_file) {
            { FNOX_AGE_KEY_FILE: null }
        } else { {} }
        let res = (with-env $fnox_env { ^fnox -c $fnox_cfg export -f json --if-missing ignore ARTIFICIAL_ANALYSIS_API_KEY NINEROUTER_KEY | complete })
        if $res.exit_code == 0 and ($res.stdout | str trim | is-not-empty) {
            let parsed = (try { $res.stdout | from json } catch { {} })
            let secrets = ($parsed.secrets? | default {})
            if ($secrets | describe | str starts-with "record") and ($secrets | is-not-empty) {
                load-env $secrets
            }
        }
    }
}
