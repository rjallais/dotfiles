# Dotfiles Repository Summary

This repository has been scaffolded with a complete setup for managing dotfiles using Chezmoi and development tools using Mise.

## What Was Created

### Core Files

1. **`.chezmoi.toml.tmpl`** - Chezmoi configuration template
   - Prompts for user email and name during initialization
   - Configures editor and diff pager preferences

2. **`.chezmoiignore`** - Files to exclude from deployment
   - Prevents repository metadata from being copied to home directory

3. **`.mise.toml`** - Development tool version management
   - Python 3.12, Node 20, Go 1.21
   - Modern CLI tools: eza, bat, ripgrep, fd, delta

### Dotfiles (Chezmoi Format)

1. **`dot_bashrc`** - Bash shell configuration
   - Modern CLI tool aliases
   - Git aliases
   - Mise integration

2. **`dot_bash_profile`** - Bash login shell
   - Sources .bashrc
   - Sets up PATH

3. **`dot_profile`** - POSIX shell profile
   - Compatible with multiple shells

4. **`dot_gitconfig.tmpl`** - Git configuration template
   - Uses Chezmoi variables for email/name
   - Delta integration for better diffs
   - Useful aliases

5. **`dot_vimrc`** - Vim editor configuration
   - Sensible defaults
   - Line numbers, syntax highlighting
   - Modern editing features

6. **`dot_config/git/ignore`** - Global git ignore patterns
   - IDE files, OS files, build artifacts

### Setup Scripts

1. **`install.sh`** - One-command bootstrap script
   - Installs Chezmoi and Mise
   - Initializes dotfiles from repository
   - Installs all tools defined in .mise.toml

2. **`validate.sh`** - Repository validation script
   - Checks file structure
   - Validates shell script syntax
   - Verifies Chezmoi naming conventions

### Documentation

1. **`README.md`** - Comprehensive documentation
   - Quick start guide
   - Usage instructions for Chezmoi and Mise
   - Troubleshooting section
   - Directory structure explanation

2. **`CONTRIBUTING.md`** - Contribution guidelines
   - How to customize for personal use
   - How to add new dotfiles and tools
   - Best practices

3. **`LICENSE`** - MIT License

### Examples

1. **`.chezmoi.toml.example`** - Example configurations
2. **`.mise.toml.example`** - Tool configuration variations

## How to Use

### Quick Start (New System)

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/rjallais/dotfiles/main/install.sh)"
```

### Manual Setup

```bash
git clone https://github.com/rjallais/dotfiles.git
cd dotfiles
./install.sh
```

## Key Features

✅ **One-command setup** - Run install.sh to set up everything
✅ **Template support** - Use variables for multi-machine configs
✅ **Tool management** - Mise handles all development tools
✅ **Modern CLI tools** - Includes eza, bat, ripgrep, fd, delta
✅ **Version controlled** - All changes tracked in git
✅ **Validation** - Built-in validation script

## Architecture

### Chezmoi Workflow
```
Repository (dot_bashrc)
    ↓ chezmoi apply
Home Directory (~/.bashrc)
```

### Mise Workflow
```
.mise.toml defines versions
    ↓ mise install
Tools installed to ~/.local/share/mise
    ↓ mise activate
Tools available in shell
```

## Next Steps

1. **Customize** - Edit dotfiles to match your preferences
2. **Add tools** - Add more tools to .mise.toml
3. **Test** - Run validate.sh to check changes
4. **Deploy** - Use install.sh on new systems

## File Naming Convention

Chezmoi uses special naming conventions:
- `dot_` → `.` (e.g., `dot_bashrc` → `~/.bashrc`)
- `.tmpl` → Template processing (e.g., `dot_gitconfig.tmpl` → `~/.gitconfig`)
- `dot_config` → `~/.config` directory

## Dependencies

- **curl** or **wget** - For downloading installers
- **git** - For cloning repository
- **bash** - For running scripts
- Internet connection for initial setup

## Troubleshooting

If Chezmoi or Mise aren't found after installation:
```bash
export PATH="$HOME/.local/bin:$PATH"
```

To update shell integration:
```bash
eval "$(mise activate bash)"
```

## Resources

- [Chezmoi Documentation](https://www.chezmoi.io/)
- [Mise Documentation](https://mise.jdx.dev/)
- [Repository on GitHub](https://github.com/rjallais/dotfiles)
