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

If `~/.config/mise` already contains files (for example from a prior Chezmoi or local Mise setup), back up and move it aside first because `--config-dir .config/mise` requires `~/.config/mise` to be missing, empty, or already linked to the checkout:

```bash
# Optional migration step if ~/.config/mise already exists and is not yet linked:
# mv ~/.config/mise ~/.config/mise.bak

curl https://mise.run | sh && ~/.local/bin/mise bootstrap \
  --from https://github.com/rjallais/dotfiles.git \
  --from-dir ~/dotfiles \
  --config-dir .config/mise \
  --prompt-vars \
  --skip-dirty

# Optional on Linux/Bazzite once Homebrew is installed:
~/.local/bin/mise run brew-ublue

# Optional for Fish users (installs Fisher & plugins from fish_plugins):
~/.local/bin/mise run fish-plugins
```

> **Existing Dotfiles Note:** `mise bootstrap` stops rather than overwriting conflicting regular files (such as a starter `~/.bashrc` or `~/.profile`), while `--skip-dirty` applies only to Git repositories under `[bootstrap.repos]`. Review conflicts with `MISE_CONFIG_DIR="$HOME/dotfiles/.config/mise" mise dot diff`, back up and move conflicting files aside before re-running bootstrap (and merge back any local settings from `~/.config/mise.bak`), or pass `--force-dotfiles` intentionally after backing them up. Nushell configuration targets **Nushell 0.110.0+** (`config.nu` header `0.117.0`), and `zen-filter.service` runs only when `~/.local/bin/zen-filter-bg` exists.

#### Windows (PowerShell)

```powershell
$v = (irm https://api.github.com/repos/jdx/mise/releases/latest).tag_name
irm "https://github.com/jdx/mise/releases/download/$v/mise-$v-windows-x64.zip" -OutFile "$env:TEMP\mise.zip"
Expand-Archive "$env:TEMP\mise.zip" -Dest "$env:LOCALAPPDATA\mise" -Force
$miseBin = "$env:LOCALAPPDATA\mise\mise\bin"
$env:Path = "$miseBin;$env:Path"
& "$miseBin\mise.exe" bootstrap `
  --from https://github.com/rjallais/dotfiles.git `
  --from-dir "$HOME\dotfiles" `
  --config-dir .config/mise `
  --prompt-vars `
  --skip-dirty
```

> **Windows Note:** `mise dotfiles` uses symlinks on Unix (`dotfiles.default_mode = "symlink"`), and automatically falls back to copying on Windows unless Developer Mode is enabled (`dotfiles.windows_symlinks = true`). Windows `[dotfiles]` mappings assume standard `%USERPROFILE%\AppData\Roaming` and `%USERPROFILE%\AppData\Local` profile locations (set `XDG_CONFIG_HOME` or copy manually if `LOCALAPPDATA` was relocated). Add `$env:LOCALAPPDATA\mise\mise\bin` to your user `PATH` (or install via `irm https://mise.jdx.dev/install.ps1 | iex`). When `mise bootstrap --update --skip-dirty` stops on a changed copied dotfile, review differences with `mise dot diff`, force-apply only the reviewed target(s) (e.g. `mise dot apply --force "~/AppData/Local/television/config/config.toml"`), and then re-run `mise bootstrap --update --skip-dirty` to resume any remaining steps.

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
mise run fish-plugins                  # Sync Fish plugins via Fisher
```
