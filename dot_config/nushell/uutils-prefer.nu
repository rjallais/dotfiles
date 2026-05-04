# Conservative profile:
# - Keep Nushell-native workflows primary.
# - Route only a focused set of POSIX-style helper commands to uutils.
# - Avoid aliasing high-impact commands like ls/cp/mv/rm/env/install/chmod/chown.
def --wrapped uucmd [name: string, ...rest] {
    if ((which coreutils | length) > 0) {
        ^coreutils $name ...$rest
    } else {
        run-external $name ...$rest
    }
}

alias arch = uucmd arch
alias b2sum = uucmd b2sum
alias base32 = uucmd base32
alias base64 = uucmd base64
alias basename = uucmd basename
alias basenc = uucmd basenc
alias cksum = uucmd cksum
alias comm = uucmd comm
alias csplit = uucmd csplit
alias cut = uucmd cut
alias dir = uucmd dir
alias dircolors = uucmd dircolors
alias dirname = uucmd dirname
alias expand = uucmd expand
alias expr = uucmd expr
alias factor = uucmd factor
alias fmt = uucmd fmt
alias fold = uucmd fold
alias head = uucmd head
alias hostid = uucmd hostid
alias logname = uucmd logname
alias md5sum = uucmd md5sum
alias nl = uucmd nl
alias nproc = uucmd nproc
alias numfmt = uucmd numfmt
alias od = uucmd od
alias paste = uucmd paste
alias pathchk = uucmd pathchk
alias pinky = uucmd pinky
alias pr = uucmd pr
alias printenv = uucmd printenv
alias printf = uucmd printf
alias ptx = uucmd ptx
alias readlink = uucmd readlink
alias realpath = uucmd realpath
alias sha1sum = uucmd sha1sum
alias sha224sum = uucmd sha224sum
alias sha256sum = uucmd sha256sum
alias sha384sum = uucmd sha384sum
alias sha512sum = uucmd sha512sum
alias shred = uucmd shred
alias shuf = uucmd shuf
alias sum = uucmd sum
alias tac = uucmd tac
alias tail = uucmd tail
alias timeout = uucmd timeout
alias tr = uucmd tr
alias truncate = uucmd truncate
alias tsort = uucmd tsort
alias tty = uucmd tty
alias unexpand = uucmd unexpand
alias uptime = uucmd uptime
alias users = uucmd users
alias vdir = uucmd vdir
alias wc = uucmd wc
alias who = uucmd who
alias yes = uucmd yes
