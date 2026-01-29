#!/usr/bin/env nu
# Creates necessary directories BEFORE externals are applied

let home = $env.HOME? | default $env.USERPROFILE?

if $home == null {
    print "ERROR: Could not determine home directory"
    exit 1
}

# Ensure ~/.local/bin exists for mise binary
mkdir ($home | path join ".local" "bin")

# Ensure XDG directories exist
mkdir ($home | path join ".config")
mkdir ($home | path join ".local" "share")
mkdir ($home | path join ".cache")

print "Created required directories"
