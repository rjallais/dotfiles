# Dotfiles (Mise Bootstrap)

Cross-platform workstation and dotfiles setup powered solely by [Mise](https://mise.jdx.dev/) (`mise bootstrap` + `mise dotfiles`) and [fnox](https://fnox.jdx.dev/) across **Bazzite / Fedora Atomic Linux**, **Windows**, and **WSL**.

## Quick Start

### Preview / Dry Run (Recommended First)

```bash
# On an existing checkout at ~/dotfiles:
MISE_CONFIG_DIR="$PWD/.config/mise" mise bootstrap --dry-run --skip-dirty
MISE_CONFIG_DIR="$PWD/.config/mise" mise bootstrap plan
MISE_CONFIG_DIR="$PWD/.config/mise" mise dot diff
```

### Fresh Machine Bootstrap

#### Linux / macOS

```bash
curl https://mise.run | sh && ~/.local/bin/mise bootstrap \
  --from https://github.com/rjallais/dotfiles.git \
  --from-dir ~/dotfiles \
  --config-dir .config/mise \
  --prompt-vars \
  --skip-dirty
```

#### Windows (PowerShell)

```powershell
$v = (irm https://api.github.com/repos/jdx/mise/releases/latest).tag_name
irm "https://github.com/jdx/mise/releases/download/$v/mise-$v-windows-x64.zip" -OutFile "$env:TEMP\mise.zip"
Expand-Archive "$env:TEMP\mise.zip" -Dest "$env:LOCALAPPDATA\mise" -Force
& "$env:LOCALAPPDATA\mise\mise.exe" bootstrap `
  --from https://github.com/rjallais/dotfiles.git `
  --from-dir "$HOME\dotfiles" `
  --config-dir .config/mise `
  --prompt-vars `
  --skip-dirty
```

> **Windows Note:** `mise dotfiles` uses symlinks on Unix (`dotfiles.default_mode = "symlink"`), and automatically falls back to copying on Windows unless Developer Mode is enabled (`dotfiles.windows_symlinks = true`).

## Layout

| Path | Purpose |
|---|---|
| `.config/mise/miserc.toml` | Enables `auto_env = true` so OS overlays (`unix`, `linux`, `windows`) load automatically |
| `.config/mise/config.toml` | Shared `[vars]`, `[tools]`, `[settings]`, cross-platform `[dotfiles]`, and `nu-autoload` task |
| `.config/mise/config.unix.toml` | Unix shell configs, `[bootstrap.repos]` (`argc-completions`), Zsh activation, `post-tools` hook |
| `.config/mise/config.linux.toml` | Linux desktop configs, `/etc/sysexts-manager` files (`[bootstrap.files]`), Homebrew formulae/casks, Flatpaks |
| `.config/mise/config.windows.toml` | Windows `AppData/Roaming/nushell` dotfiles and `winget` packages |
| `.config/mise/scripts/nu-autoload.nu` | Generates `$nu.data-dir/vendor/autoload/*.nu` integrations |
| `dotfiles/` | Managed dotfile sources (plain paths + `.gitconfig.tera`) |
| `system/` | System-level configuration files managed via `[bootstrap.files]` |
| `Brewfile` | Reference Homebrew bundle (mirrors `[bootstrap.packages]` in `config.linux.toml`) |

## Secrets (`fnox` + `age`)

Encrypted secrets live in `dotfiles/.config/fnox/config.toml` (ciphertext only). Your private key (`~/.config/fnox/age.txt`) stays outside the repository; shell startup files load encrypted variables only when `fnox` and an `age` identity are present.

## Daily Usage

```bash
mise bootstrap --update --skip-dirty   # Pull latest repo updates & apply everything
mise bootstrap status                  # Check status of packages, files, repos, tools
mise dot diff                          # Preview dotfile symlink/template diffs
mise dot apply                         # Deploy dotfiles
mise install                           # Sync Mise tools
mise run brew-ublue                    # Install ublue-os/tap casks (custom cask DSL)
```
