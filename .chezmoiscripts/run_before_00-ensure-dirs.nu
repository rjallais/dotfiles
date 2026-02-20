#!/usr/bin/env nu
# Creates necessary directories BEFORE externals are applied

let home = $env.HOME? | default $env.USERPROFILE?
let os = ($nu.os-info.name | str downcase)

if $home == null {
    print "ERROR: Could not determine home directory"
    exit 1
}

if ($os | str contains "windows") {
    let appdata = $env.APPDATA? | default ($home | path join "AppData" "Roaming")
    let localappdata = $env.LOCALAPPDATA? | default ($home | path join "AppData" "Local")

    mkdir ($appdata | path join "nushell")
    mkdir ($localappdata | path join "nushell")
    mkdir ($home | path join ".config" "mise")
} else {
    mkdir ($home | path join ".local" "bin")
    mkdir ($home | path join ".config")
    mkdir ($home | path join ".local" "share")
    mkdir ($home | path join ".cache")
}

print $"Created required directories for ($nu.os-info.name)"
