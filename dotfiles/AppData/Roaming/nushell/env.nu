# env.nu - Windows Nushell environment configuration

$env.NINEROUTER_URL = "http://localhost:20128"

let home = ($env.HOME? | default $env.USERPROFILE?)
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
    if (which fnox | is-not-empty) and ($fnox_cfg | path exists) and (($fnox_age | path exists) or ($env.FNOX_AGE_KEY? != null) or ($env.FNOX_AGE_KEY_FILE? != null)) {
        let fnox_env = if ($env.FNOX_AGE_KEY? == null) and ($env.FNOX_AGE_KEY_FILE? == null) and ($fnox_age | path exists) {
            { FNOX_AGE_KEY_FILE: $fnox_age }
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
