# Dotfiles — Mise-centric bootstrap

A modern dotfiles repository using [Chezmoi](https://www.chezmoi.io/) for dotfile management and [Mise](https://mise.jdx.dev/) for development tool version management.

This repository uses a Mise-first approach:

- A minimal `setup.sh` (in this repo) ensures the `mise` binary is available on the host (installing it if necessary).
- After `mise` is available, all bootstrap and validation work is performed by small, focused Mise tasks defined in `chezmoi/mise.toml`.
- Chezmoi is run via `mise exec chezmoi` so the version of Chezmoi can be controlled through Mise if desired.
- Tool installation is driven by `dot_config/mise/config.toml` (repository-controlled).

This README documents the new flow and how to use the `setup.sh` + Mise tasks approach.

## Quick start

Recommended local flow (developer machine)

1. Ensure you have `git` and either `curl` or `wget` available.
2. From this repository's `chezmoi` directory, run the setup script. By default it ensures `mise` is present and runs the high-level `bootstrap` task:

```chezmoi/README.md#L1-6
./setup.sh
```

3. To run a specific Mise task (for example, validation), pass the task name:

```chezmoi/README.md#L7-10
./setup.sh validate:all
```

Direct Mise usage (if you already have `mise` installed)

- Run the bootstrap task directly:

```chezmoi/README.md#L11-13
mise run bootstrap
```

- Run all validations:

```chezmoi/README.md#L14-16
mise run validate:all
```

## What the bootstrap does

The `bootstrap` flow (implemented as Mise tasks) performs these steps:

- Injects Mise activation into a likely interactive shell profile (idempotent; skipped in CI).
- Activates Mise for the running shell (best-effort).
- Installs tools declared in the repository-local `dot_config/mise/config.toml` (if present).
- Runs Chezmoi (via `mise exec chezmoi`) to initialize and apply dotfiles.
- Installs tools declared in the applied copy of the repository (the chezmoi data in `~/.local/share/chezmoi`).

Tool installation is performed using Mise and can be strict (fail-fast) in CI mode.

## Key files

- `chezmoi/setup.sh` — minimal bootstrap that ensures `mise` binary is present and then runs Mise tasks
- `chezmoi/mise.toml` — Mise task definitions (small, composable tasks, plus `bootstrap` and validation tasks)
- `dot_config/mise/config.toml` — repository-controlled Mise tool version configuration (if present)
- Chezmoi dotfiles in this repo (prefixed with `dot_` and templates with `.tmpl`)

## Directory structure (relevant subset)

``chezmoi/README.md#L1-14
.
├── chezmoi/
│   ├── mise.toml                # Mise task definitions
│   ├── setup.sh                 # Ensures mise is present, runs mise tasks
│   └── README.md                # This file
├── dot_config/
│   └── mise/
│       └── config.toml          # Tools and versions managed by Mise
└── dot_*                        # Dotfiles (Chezmoi source files)
```

## Usage: Chezmoi commands (after bootstrap)

You can use the Chezmoi binary (either globally installed or managed by Mise) as usual:

``chezmoi/README.md#L15-22
chezmoi status     # Check which dotfiles have changed
chezmoi diff       # See differences
chezmoi edit <file>  # Edit a dotfile's source
chezmoi apply      # Apply changes managed by chezmoi
```

If you prefer the Mise-provided Chezmoi:

``chezmoi/README.md#L23-25
mise exec chezmoi -- status
mise exec chezmoi -- apply
```

## Usage: Mise commands

Manage tools with Mise. Examples:

``chezmoi/README.md#L26-31
mise ls                       # List installed tools
mise install --config="dot_config/mise/config.toml"  # Install repository tools
mise outdated                 # Check for outdated tools
mise use node@20              # Install/use a specific version
```

## CI guidance

This repository's Mise tasks are CI-aware. In CI:

- Set `CI=1` or let your CI system set it.
- When `CI` is set, tasks:
  - Fail fast on mise tool-install errors.
  - Avoid mutating user shell profiles (activation injection is skipped).
  - Treat missing `mise` or `chezmoi` as hard errors (so your CI can fail early).

A minimal GitHub Actions example:

``chezmoi/README.md#L32-48
name: bootstrap

on: [push]

jobs:
  bootstrap:
    runs-on: ubuntu-latest
    env:
      CI: 1
    steps:
      - uses: actions/checkout@v4
      - name: Install prerequisites
        run: sudo apt-get update && sudo apt-get install -y curl git
      - name: Ensure Mise (installer will be used by setup.sh)
        run: ./chezmoi/setup.sh --skip-run
      - name: Run bootstrap
        run: ./chezmoi/setup.sh bootstrap
```

Notes:
- You can pre-install `mise` in the CI image and skip the installer, but `setup.sh` will install Mise automatically if missing.
- The `--skip-run` option is useful to only ensure `mise` exists in a step separate from running tasks; it is optional.

## Customization and configuration

- To change tool versions, edit `dot_config/mise/config.toml` in the repository.
- Chezmoi template variables and the `chezmoi` configuration template are in the repository to support multi-machine customization. Use `chezmoi edit-config` or edit `.chezmoi.toml.tmpl` as appropriate.

## Troubleshooting

- Mise not found after installation:
``chezmoi/README.md#L49-50
export PATH="$HOME/.local/bin:$PATH"
```

- Mise not activating in your shell:
``chezmoi/README.md#L51-56
# Fish
eval (mise activate fish)

# Bash
eval "$(mise activate bash)"

# Zsh
eval "$(mise activate zsh)"
```

- If a tool fails to install via Mise, check the tool's system dependencies and install them via your package manager (examples for Ubuntu/Debian shown below):

``chezmoi/README.md#L57-62
sudo apt-get install -y build-essential libssl-dev
```

## Removing old scripts

This repository no longer uses the previous installer/validator scripts. The new flow centralizes `mise` installation verification in `chezmoi/setup.sh`, and delegates all orchestration to Mise tasks defined in `chezmoi/mise.toml`. Any references to older top-level installer scripts have been removed.





## Resources

- Chezmoi: https://www.chezmoi.io/
- Mise docs and tasks: https://mise.jdx.dev/
- Mise tasks file in this repo: `chezmoi/mise.toml`

If you'd like, I can also:
- Add a short README section showing common Mise task names and a recommended local development sequence.
- Add a GitHub Actions workflow file to the repo as an example.