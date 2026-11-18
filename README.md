# Dotfiles

Cross-platform dotfiles using [Chezmoi](https://www.chezmoi.io/), [Mise](https://mise.jdx.dev/), and [fnox](https://fnox.jdx.dev/) across **Bazzite / Fedora Atomic Linux**, **Windows**, and **WSL**. Bootstrap scripts are written in [Nushell](https://www.nushell.sh/).

## Quick Start

### macOS / Linux

```bash
curl https://mise.run | sh && ~/.local/bin/mise exec chezmoi@latest -- chezmoi --use-builtin-git=on init --apply rjallais
```

Optional Homebrew bundle restore on Linux/macOS:

```bash
brew bundle --file ~/dotfiles/Brewfile
```

### Windows (PowerShell)

```powershell
$v = (irm https://api.github.com/repos/jdx/mise/releases/latest).tag_name
$arch = "x64"
irm "https://github.com/jdx/mise/releases/download/$v/mise-$v-windows-$arch.zip" -OutFile "$env:TEMP\mise.zip"
Expand-Archive "$env:TEMP\mise.zip" -Dest "$env:LOCALAPPDATA\mise" -Force
$env:Path = "$env:LOCALAPPDATA\mise;$env:Path"
& "$env:LOCALAPPDATA\mise\mise.exe" exec chezmoi@latest -- chezmoi --use-builtin-git=on init --apply rjallais
```

## What Is Managed

### Shells & Core Configs
- **Nushell**: `~/.config/nushell/{config.nu,env.nu,uutils-prefer.nu}` on Unix, `%APPDATA%\nushell\{config.nu,env.nu}` on Windows
- **Fish**: `~/.config/fish/config.fish`, `conf.d/{brew,github-token,rustup}.fish`, `fish_plugins`
- **Bash / POSIX**: `~/.bashrc`, `~/.profile` (with `~/.bash_profile` intentionally omitted so `.profile` is sourced cleanly)
- **Git**: `~/.gitconfig`, `~/.gitconfig.{github,gitlab,codefloe}`, `~/.config/git/ignore`
- **Prompt & Updates**: `~/.config/starship.toml`, `~/.config/topgrade.toml`

### Workstation & Desktop Configs (Linux)
- **Terminals & Editors**: Ghostty (`~/.config/ghostty/`), Zed (`~/.config/zed/settings.json`), Micro (`~/.config/micro/`), Delta (`~/.config/delta/settings.json`), Television (`~/.config/television/config.toml`)
- **Bazzite / Bluefin / System**: `bluefin-cli`, `brew.env`, `environment.d/*`, portable `systemd/user/` units (`syncthing.service`, `zen-filter.service`), curated `Brewfile`, and reference sysext manifests under `system/etc/`

### Tools & Secrets
- **Mise (`~/.config/mise/config.toml`)**: Global CLI tools, language toolchains, and AI CLIs
- **Secrets (`~/.config/fnox/config.toml`)**: Encrypted with `age` (`[providers.age]`). Private key (`~/.config/fnox/age.txt`) is **never** committed; shells export encrypted secrets only when an `age` identity is present locally.

## Daily Usage

```bash
chezmoi status          # Inspect drift against live $HOME
chezmoi diff            # Preview differences
chezmoi apply           # Apply tracked changes
mise install            # Install/sync global mise tools
fnox -c ~/.config/fnox/config.toml check   # Verify age secret decryption
```
