# Dotfiles

Cross-platform dotfiles using [Chezmoi](https://www.chezmoi.io/) and [Mise](https://mise.jdx.dev/). All bootstrap scripts are written in [Nushell](https://www.nushell.sh/) for Windows/macOS/Linux compatibility.

## Quick Start

### macOS / Linux

```bash
curl https://mise.run | sh && sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply rjallais
```

### Windows (PowerShell - Run as Administrator)

```powershell
$v = (irm https://api.github.com/repos/jdx/mise/releases/latest).tag_name; $arch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x64" }; irm "https://github.com/jdx/mise/releases/download/$v/mise-$v-windows-$arch.zip" -OutFile "$env:TEMP\mise.zip"; Expand-Archive "$env:TEMP\mise.zip" -Dest "$env:LOCALAPPDATA\mise" -Force; $env:Path = "$env:LOCALAPPDATA\mise;$env:Path"; [Environment]::SetEnvironmentVariable("Path", "$env:LOCALAPPDATA\mise;$([Environment]::GetEnvironmentVariable('Path', 'User'))", 'User'); irm get.chezmoi.io/ps1 | powershell -c -; chezmoi init --apply rjallais
```

That's it! These one-liners:
1. Download and install mise (with self-update capability)
2. Download and install chezmoi
3. Clone this repository
4. Prompt for your name and email
5. Apply all dotfiles
6. Run `mise install` to install all development tools

## What Gets Installed

### Dotfiles
- Shell configs: `.bashrc`, `.profile`, `.bash_profile`
- Git config with delta diff viewer
- Nushell configuration
- Fish shell configuration
- Starship prompt

### Development Tools (via Mise)

See `dot_config/mise/config.toml` for the full list. Highlights:

| Category | Tools |
|----------|-------|
| **Shell** | Nushell, Starship, Atuin, Zoxide, Carapace |
| **Languages** | Go, Node.js, Bun, Python (via uv) |
| **CLI Tools** | ripgrep, fd, bat, lsd, fzf, delta, dust, bottom |
| **Dev Tools** | GitHub CLI, chezmoi, cmake, sqlite |

## Daily Usage

### Updating Dotfiles

```bash
chezmoi update        # Pull latest and apply
chezmoi diff          # See what would change
chezmoi apply         # Apply changes
```

### Managing Tools

```bash
mise ls               # List installed tools
mise install          # Install/update tools from config
mise outdated         # Check for updates
mise use node@22      # Switch to specific version
mise self-update      # Update mise itself
```

### Editing Dotfiles

```bash
chezmoi edit ~/.bashrc   # Edit source, then apply
chezmoi cd               # Go to source directory
```

## How It Works

### Bootstrap Flow

```
One-liner installs mise + chezmoi, then:

chezmoi init --apply
    │
    ├── 1. run_before_00-ensure-dirs.nu (creates ~/.local/bin via mise x nu --)
    ├── 2. Dotfiles applied (configs, shell rc files)
    └── 3. run_onchange_after_50-mise-install.nu.tmpl (mise install)
```

### Key Files

| File | Purpose |
|------|---------|
| `.chezmoi.toml.tmpl` | Prompts for name/email, configures nu interpreter |
| `.chezmoiscripts/run_before_*.nu` | Pre-apply setup (directories) |
| `.chezmoiscripts/run_onchange_*.nu.tmpl` | Post-apply actions (mise install) |
| `dot_config/mise/config.toml` | Tool versions managed by mise |

### Why Nushell Scripts?

All chezmoi scripts use Nushell (`.nu`) instead of Bash/PowerShell because:
- **Cross-platform**: Same syntax on Windows, macOS, and Linux
- **Modern**: Structured data, better error handling
- **No system dependency**: Nushell is provided by mise via `mise x nu --`

The interpreter configuration in `.chezmoi.toml.tmpl`:
```toml
[interpreters.nu]
    command = "mise"
    args = ["x", "aqua:nushell/nushell", "--"]
```

This means chezmoi runs `.nu` scripts through mise, which provides Nushell on-demand.

## Alternative Installation

If you prefer to install mise via a package manager (note: `mise self-update` won't work):

### macOS
```bash
brew install mise
```

### Windows
```powershell
scoop install mise    # or: winget install jdx.mise
```

### Linux (various)
```bash
# Fedora/RHEL
dnf copr enable jdxcode/mise && dnf install mise

# Arch
pacman -S mise

# Alpine
apk add mise
```

Then run chezmoi separately:
```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply rjallais
```

## Supported Systems

| Platform | Status |
|----------|--------|
| macOS (Intel/ARM) | ✅ Tested |
| Linux (x64/ARM) | ✅ Tested |
| Windows 10/11 (x64) | ✅ Tested |
| Bazzite/Bluefin | ✅ Tested |

## Customization

- Edit `.chezmoi.toml.tmpl` to change prompted variables
- Edit `dot_config/mise/config.toml` to change which tools are installed
- Edit `dot_config/nushell/config.nu` for Nushell configuration
