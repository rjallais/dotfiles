# Contributing to Dotfiles

Thank you for your interest in improving this dotfiles repository!

## How to Customize for Your Own Use

1. **Fork this repository** to your own GitHub account
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/dotfiles.git
   cd dotfiles
   ```
3. **Make your changes** to the dotfiles
4. **Test locally** using Chezmoi:
   ```bash
   chezmoi init --apply /path/to/your/dotfiles
   ```
5. **Commit and push** your changes
6. **Update the install script URL** in README.md to point to your fork

## Adding New Dotfiles

To add a new dotfile:

1. Add the file using Chezmoi naming convention:
   - For `~/.config/app/config`, create: `dot_config/app/config`
   - For templated files, add `.tmpl` extension
   
2. If it contains sensitive data, use Chezmoi's template variables:
   ```
   api_key = {{ .api_key }}
   ```

3. Add the variable to `.chezmoi.toml.tmpl` if needed

## Adding New Tools

To add a new tool via Mise:

1. Edit `.mise.toml`:
   ```toml
   [tools]
   newtool = "version"
   ```

2. Test the installation:
   ```bash
   mise install
   ```

## Project Structure

```
dotfiles/
├── .chezmoi.toml.tmpl        # Chezmoi config template
├── .chezmoiignore            # Files Chezmoi should ignore
├── .mise.toml                # Mise tool versions
├── install.sh                # Bootstrap script
├── dot_*                     # Dotfiles (dot_ becomes .)
└── README.md                 # Documentation
```

## Testing Your Changes

Before committing:

1. Test the installation script in a clean environment (VM or container)
2. Verify all dotfiles are correctly applied
3. Check that Mise installs all tools successfully
4. Ensure no sensitive information is committed

## Submitting Changes

If you have improvements that would benefit others:

1. Create a new branch: `git checkout -b feature/improvement`
2. Make your changes
3. Commit with clear messages
4. Push to your fork
5. Open a Pull Request with a description of your changes

## Best Practices

- Keep the repository minimal - only essential dotfiles
- Use templates for machine-specific configurations
- Document any system dependencies
- Test on multiple Linux distributions if possible
- Keep tools in `.mise.toml` up to date

## Questions?

Open an issue if you have questions or suggestions!
