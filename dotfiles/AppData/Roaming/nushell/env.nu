# env.nu - Windows Nushell environment configuration

$env.NINEROUTER_URL = "http://localhost:20128"

let home = ($env.HOME? | default ($env.USERPROFILE? | default ($nu.home-dir? | default $nu.home-path?)))
if $home != null {
    let early_bins = (
        [
            ($home | path join ".local" "share" "mise" "shims")
            ($home | path join "AppData" "Local" "mise" "shims")
            ($home | path join ".local" "bin")
        ]
        | where {|p| $p | path exists }
    )
    if ($early_bins | is-not-empty) {
        $env.PATH = ($env.PATH | append $early_bins | uniq)
    }

    let fnox_cfg = ($home | path join ".config" "fnox" "config.toml")
    let fnox_age = ($home | path join ".config" "fnox" "age.txt")
    let has_age_key = (($env.FNOX_AGE_KEY? | default "" | str trim) | is-not-empty)
    let has_age_key_file = (($env.FNOX_AGE_KEY_FILE? | default "" | str trim) | is-not-empty)
    if (which fnox | is-not-empty) and ($fnox_cfg | path exists) and (($fnox_age | path exists) or $has_age_key or $has_age_key_file) {
        let fnox_env = if (not $has_age_key) and (not $has_age_key_file) and ($fnox_age | path exists) {
            { FNOX_AGE_KEY: null, FNOX_AGE_KEY_FILE: $fnox_age }
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
