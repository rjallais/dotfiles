#!/usr/bin/env bash
# Quick validation script to check the dotfiles structure

set -e

echo "🔍 Validating dotfiles repository structure..."

# Check required files
REQUIRED_FILES=(
    ".chezmoi.toml.tmpl"
    ".chezmoiignore"
    ".mise.toml"
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

# Check shell scripts syntax
echo ""
echo "🔍 Checking shell script syntax..."
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
DOT_FILES=$(find . -maxdepth 1 -name "dot_*" -type f)
if [ -n "$DOT_FILES" ]; then
    echo "✓ Found $(echo "$DOT_FILES" | wc -l) dotfiles"
    echo "$DOT_FILES" | sed 's/^/  /'
else
    echo "✗ No dotfiles found with dot_ prefix"
    exit 1
fi

# Check .mise.toml syntax
echo ""
echo "🔍 Checking .mise.toml format..."
if [ -f ".mise.toml" ]; then
    # Basic check - just ensure it's not empty and has [tools] section
    if grep -q "\[tools\]" ".mise.toml"; then
        echo "✓ .mise.toml has [tools] section"
    else
        echo "⚠ .mise.toml missing [tools] section"
    fi
fi

echo ""
echo "✅ All validation checks passed!"
echo ""
echo "Next steps:"
echo "  1. Test the install script in a clean environment"
echo "  2. Verify Chezmoi can parse the templates"
echo "  3. Check that Mise can install the defined tools"
