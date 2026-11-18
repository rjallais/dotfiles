# Homebrew configuration for fish shell
if test -d /home/linuxbrew/.linuxbrew
    eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
else if test -d /opt/homebrew
    eval (/opt/homebrew/bin/brew shellenv)
end
