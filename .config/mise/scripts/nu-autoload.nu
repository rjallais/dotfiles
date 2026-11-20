#!/usr/bin/env nu
# Generate Nushell vendor/autoload integration scripts safely.

let autoload_dir = ($nu.data-dir | path join "vendor" "autoload")
mkdir $autoload_dir

def write-atomic [target: path, content: string] {
    let tmp = $"($target).tmp.($nu.pid)"
    $content | save --force $tmp
    mv --force $tmp $target
}

def render-init [
    name: string
    bin_name: string
    mise_spec: string
    cmd_args: list<string>
    target: path
] {
    let resolved = (
        which $bin_name
        | get -o 0.path
        | default (
            ["/home/linuxbrew/.linuxbrew/bin" "/opt/homebrew/bin"]
            | each {|d| $d | path join $bin_name }
            | where {|p| $p | path exists }
            | get -o 0
        )
    )
    let resolved_out = if $resolved != null {
        try { ^$resolved ...$cmd_args | complete } catch {|err| { exit_code: 1, stdout: "", stderr: $err.msg } }
    } else {
        { exit_code: 1, stdout: "", stderr: "tool unavailable" }
    }

    let out = if $resolved_out.exit_code == 0 and ($resolved_out.stdout | str trim | is-not-empty) {
        $resolved_out
    } else if (which mise | is-not-empty) {
        ^mise exec $mise_spec -- $bin_name ...$cmd_args | complete
    } else {
        $resolved_out
    }

    if $out.exit_code == 0 and ($out.stdout | str trim | is-not-empty) {
        write-atomic $target $out.stdout
        return true
    }

    let detail = ($out.stderr | default "" | str trim)
    print -e $"Warning: failed to generate ($name) autoload; keeping any existing ($target). ($detail)"
    false
}

print "Generating Nushell autoload scripts..."

let mise_out = if (which mise | is-not-empty) {
    ^mise activate nu | complete
} else {
    { exit_code: 1, stdout: "", stderr: "mise not found" }
}
if $mise_out.exit_code == 0 and ($mise_out.stdout | str trim | is-not-empty) {
    write-atomic ($autoload_dir | path join "mise.nu") $mise_out.stdout
} else {
    let detail = ($mise_out.stderr | default "" | str trim)
    print -e $"Error: failed to generate required mise autoload; keeping any existing mise.nu. ($detail)"
    exit 1
}

render-init "starship" "starship" "aqua:starship/starship" ["init" "nu"] ($autoload_dir | path join "starship.nu") | ignore
render-init "zoxide" "zoxide" "github:ajeetdsouza/zoxide" ["init" "nushell"] ($autoload_dir | path join "zoxide.nu") | ignore
render-init "atuin" "atuin" "atuin" ["init" "nu"] ($autoload_dir | path join "atuin.nu") | ignore
render-init "carapace" "carapace" "aqua:carapace-sh/carapace-bin" ["_carapace" "nushell"] ($autoload_dir | path join "carapace.nu") | ignore

let brew_target = ($autoload_dir | path join "brew.nu")
if ("/home/linuxbrew/.linuxbrew/bin" | path exists) {
    write-atomic $brew_target "# Homebrew PATH setup\nif '/home/linuxbrew/.linuxbrew/bin' not-in $env.PATH {\n    $env.PATH = ($env.PATH | append '/home/linuxbrew/.linuxbrew/bin' | append '/home/linuxbrew/.linuxbrew/sbin')\n}\n"
} else if ("/opt/homebrew/bin" | path exists) {
    write-atomic $brew_target "# Homebrew PATH setup\nif '/opt/homebrew/bin' not-in $env.PATH {\n    $env.PATH = ($env.PATH | append '/opt/homebrew/bin' | append '/opt/homebrew/sbin')\n}\n"
} else {
    write-atomic $brew_target "# Homebrew not present on this platform\n"
}

let home = ($env.HOME? | default $env.USERPROFILE?)
if $home != null {
    let argc_root = ($home | path join ".local" "share" "argc-completions")
    if ($argc_root | path exists) {
        with-env {
            ARGC_COMPLETIONS_ROOT: $argc_root
            ARGC_COMPLETIONS_PATH: $"($argc_root)/completions/linux:($argc_root)/completions"
        } {
            render-init "argc-completions" "argc" "argc" ["--argc-completions" "nushell"] ($autoload_dir | path join "argc-completions.nu") | ignore
        }
    }
}

print "Nushell autoload scripts refreshed"
