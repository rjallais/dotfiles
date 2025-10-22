# dotfiles

A modern dotfiles repository using [Chezmoi](https://www.chezmoi.io/) for dotfile management and [Mise](https://mise.jdx.dev/) for development tool version management.

## Features

- 🔧 **Chezmoi** - Secure, flexible dotfile management with templating support
- 🛠️ **Mise** - Fast, polyglot tool version manager (successor to asdf/rtx)
- 🚀 **One-command setup** - Bootstrap a new system quickly
- 📦 **Pre-configured tools** - Modern CLI replacements (eza, bat, ripgrep, fd, delta)
- 🎨 **Customizable** - Template-based configuration for multi-machine setups

## Quick Start

### Fresh System Setup

Run this one-liner to set up everything on a new Linux system:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/rjallais/dotfiles/main/install.sh)"
```

Or clone and run manually:

```bash
git clone https://github.com/rjallais/dotfiles.git
cd dotfiles
./install.sh
```

### What Gets Installed

**Configuration Files:**
- `.bashrc` - Bash shell configuration with modern aliases
- `.bash_profile` - Bash login shell configuration
- `.profile` - POSIX shell profile
- `.gitconfig` - Git configuration with delta integration
- `.vimrc` - Vim editor configuration

**Development Tools (via Mise):**
- Python 3.12
- Node.js 20
- Go 1.21
- Modern CLI tools: eza, bat, ripgrep, fd, delta

## Usage

### Managing Dotfiles with Chezmoi

```bash
# Check which dotfiles have changed
chezmoi status

# See differences between source and target
chezmoi diff

# Edit a dotfile (opens in your editor)
chezmoi edit ~/.bashrc

# Apply changes
chezmoi apply

# Pull and apply latest changes from repository
chezmoi update

# Add a new file to be managed
chezmoi add ~/.config/newfile
```

### Managing Tools with Mise

```bash
# List installed tools
mise ls

# Install a specific tool version
mise use python@3.11

# Install all tools from .mise.toml
mise install

# Check for outdated tools
mise outdated

# Update all tools
mise upgrade

# Show active tool versions
mise current
```

### Customization

When you first run the install script, Chezmoi will prompt you for:
- **Email address** - Used in git configuration
- **Full name** - Used in git configuration

These values are stored securely and used to populate templates.

To change these values later:

```bash
chezmoi edit-config
```

## Directory Structure

```
.
├── .chezmoi.toml.tmpl       # Chezmoi configuration template
├── .chezmoiignore           # Files to ignore when applying
├── .mise.toml               # Mise tool version configuration
├── install.sh               # Bootstrap installation script
├── dot_bashrc               # ~/.bashrc
├── dot_bash_profile         # ~/.bash_profile
├── dot_profile              # ~/.profile
├── dot_gitconfig.tmpl       # ~/.gitconfig (template)
├── dot_vimrc                # ~/.vimrc
└── README.md                # This file
```

## How It Works

1. **Chezmoi** manages your dotfiles in a Git repository (this one)
   - Files prefixed with `dot_` become hidden files (`.`)
   - Files suffixed with `.tmpl` are processed as templates
   - Templates can use variables defined in `.chezmoi.toml.tmpl`

2. **Mise** manages development tool versions
   - Tools defined in `.mise.toml` are automatically installed
   - Each project can have its own tool versions
   - Activates the right versions automatically when you `cd` into a directory

## Requirements

- Linux system (Ubuntu, Debian, Fedora, Arch, etc.)
- curl or wget
- git
- Internet connection (for initial setup)

## Troubleshooting

### Chezmoi not found after installation
```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Mise not activating
Add this to your shell configuration:
```bash
eval "$(mise activate bash)"  # for bash
eval "$(mise activate zsh)"   # for zsh
```

### Tools not installing via Mise
Some tools require system dependencies. Install them with your package manager:
```bash
# Ubuntu/Debian
sudo apt-get install build-essential libssl-dev

# Fedora
sudo dnf install @development-tools openssl-devel

# Arch
sudo pacman -S base-devel openssl
```

## Contributing

Feel free to fork this repository and customize it for your own use. To contribute improvements:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT License - feel free to use this as a starting point for your own dotfiles.

## Resources

- [Chezmoi Documentation](https://www.chezmoi.io/)
- [Mise Documentation](https://mise.jdx.dev/)
- [Dotfiles Guide](https://dotfiles.github.io/)