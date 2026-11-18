# env.nu is loaded BEFORE config.nu and BEFORE the autoload files
# under vendor/autoload/. Adding /opt/ubrew/prefix/bin here ensures
# binaries installed by ubrew are discoverable early in startup.
if ('/opt/ubrew/prefix/bin' | path exists) {
    $env.PATH = (
        $env.PATH
        | append '/opt/ubrew/prefix/bin'
        | uniq
    )
}

# Aqua global config (for standalone `aqua g`)
$env.AQUA_GLOBAL_CONFIG = ($nu.home-dir | path join "aqua.yaml")

# DigitalOcean Inference API key (for Grok CLI custom DO models)
# Mirrors bashrc: source OPENAI_API_KEY from ~/.hermes/.env
let hermes_env = ($nu.home-dir | path join '.hermes' '.env')
if ($hermes_env | path exists) {
    let line = (
        open --raw $hermes_env
        | lines
        | where {|l| $l | str starts-with 'OPENAI_API_KEY='}
        | get --optional 0
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

# 9Router gateway
$env.NINEROUTER_URL = "http://localhost:20128"

# Load encrypted API keys via fnox when age identity is available
let fnox_cfg = ($nu.home-dir | path join '.config' 'fnox' 'config.toml')
let fnox_age = ($nu.home-dir | path join '.config' 'fnox' 'age.txt')
if (which fnox | is-not-empty) and ($fnox_cfg | path exists) and (($fnox_age | path exists) or ($env.FNOX_AGE_KEY? != null) or ($env.FNOX_AGE_KEY_FILE? != null)) {
    let res = (^fnox -c $fnox_cfg export -f json --if-missing ignore ARTIFICIAL_ANALYSIS_API_KEY NINEROUTER_KEY | complete)
    if $res.exit_code == 0 and ($res.stdout | str trim | is-not-empty) {
        let parsed = (try { $res.stdout | from json } catch { {} })
        let secrets = ($parsed.secrets? | default {})
        if ($secrets | describe | str starts-with "record") and ($secrets | is-not-empty) {
            load-env $secrets
        }
    }
}
