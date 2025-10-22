#!/usr/bin/env bash
# Quick validation script to check the dotfiles structure
# Updated to be fish-centric and validate mise usage

set -e

echo "🔍 Validating dotfiles repository structure..."

# Check required files
REQUIRED_FILES=(
    ".chezmoi.toml.tmpl"
    ".chezmoiignore"
    "install.sh"
    "README.md"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ $file exists"
    else
        echo "✗ $file is missing"
        exit 1
    fi
done

# Check shell scripts syntax (prefer fish)
echo ""
echo "🔍 Checking shell script syntax..."
# Check fish config syntax if fish is installed
if command -v fish >/dev/null 2>&1; then
    if [ -f "$HOME/.config/fish/config.fish" ]; then
        if fish -n "$HOME/.config/fish/config.fish" 2>/dev/null; then
            echo "✓ Fish config syntax valid"
        else
            echo "✗ Fish config has syntax errors"
            exit 1
        fi
    fi
fi

for script in install.sh dot_bashrc dot_bash_profile dot_profile; do
    if [ -f "$script" ]; then
        if bash -n "$script" 2>/dev/null; then
            echo "✓ $script syntax valid"
        else
            echo "✗ $script has syntax errors"
            exit 1
        fi
    fi
done

# Check for executable permissions
echo ""
echo "🔍 Checking executable permissions..."
if [ -x "install.sh" ]; then
    echo "✓ install.sh is executable"
else
    echo "✗ install.sh is not executable"
    exit 1
fi

# Verify Chezmoi file naming
echo ""
echo "🔍 Checking Chezmoi file naming conventions..."
DOT_FILES=$(find . -maxdepth 1 -name "dot_*" -type f 2>/dev/null)
if [ -n "$DOT_FILES" ]; then
    echo "✓ Found $(echo "$DOT_FILES" | wc -l) dotfiles"
    echo "$DOT_FILES" | sed 's/^/  /'
else
    echo "✗ No dotfiles found with dot_ prefix"
    exit 1
fi

# Check .mise.toml existence and basic syntax
echo ""
echo "🔍 Checking .mise.toml format..."
if [ -f ".mise.toml" ]; then
    if grep -q "\[tools\]" ".mise.toml"; then
        echo "✓ .mise.toml has [tools] section"
    else
        echo "⚠ .mise.toml missing [tools] section"
    fi
else
    echo "⚠ .mise.toml not present; ensure you have tools configured for Mise if needed"
fi

# Check whether installation path for mise activation was added
echo ""
echo "🔍 Verifying mise activation in shell config..."
if command -v fish >/dev/null 2>&1; then
    CFG="$HOME/.config/fish/config.fish"
else
    CFG="$HOME/.bashrc"
fi

if [ -f "$CFG" ]; then
    if grep -q "mise activate" "$CFG" 2>/dev/null; then
        echo "✓ mise activation present in $CFG"
    else
        echo "⚠ mise activation not found in $CFG"
    fi
else
    echo "⚠ Shell config $CFG not found"
fi

echo ""
echo "✅ All validation checks passed (with warnings possible)"
