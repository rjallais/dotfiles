# Summary — Mise-centric dotfiles (chezmoi)

This repository uses Chezmoi to manage your dotfiles and Mise to manage development tools and task orchestration. The workflow has been refactored so that a minimal bootstrap script ensures the `mise` binary is present, and all setup steps are implemented as small Mise tasks in `chezmoi/mise.toml`.

This SUMMARY documents the current structure, the primary files, and the recommended flows for local and CI environments.

---

## What changed (high level)

- The previous top-level installer/validator scripts (`install.sh`, `validate.sh`) have been removed.
- Contribution and license documents were removed since this is a personal dotfiles repository.
- A small, single-purpose script `chezmoi/setup.sh` now ensures `mise` exists, then delegates orchestration to Mise tasks.
- Mise tasks live in `chezmoi/mise.toml` and implement the stepwise bootstrap and validation flows.
- Tool installation now happens from the user-wide Mise config (e.g. `~/.config/mise/config.toml`) after `chezmoi apply` places that config in the user's home.

---

## Key files (current)

- `chezmoi/setup.sh` — minimal bootstrapper:
  - Ensures `mise` binary exists (installs via `curl`/`wget` if missing).
  - Prepends `$HOME/.local/bin` to PATH for the running process.
  - Delegates orchestration to Mise tasks (default: `bootstrap`).

- `chezmoi/mise.toml` — Mise task definitions:
  - Small composable tasks: activation injection, local checks, running `chezmoi`, and installing tools from the user-wide config.
  - Composite tasks:
    - `bootstrap` — high-level setup (inject activation, activate mise for the session, run chezmoi apply, install tools from `~/.config/mise/config.toml`).
    - `bootstrap:with-fish` — bootstrap + attempt to set fish as login shell (non-fatal; skipped in CI).
    - `validate:all` — run repository validation tasks.

- `dot_config/mise/config.toml` — repository-scoped tool list for Mise (optional).
  - Usually used to define project-level tools; in this flow it can be applied before/after depending on preference.
  - The canonical tool installation for your user is expected at `~/.config/mise/config.toml` after `chezmoi apply`.

- `dot_*` files — dotfiles tracked by Chezmoi (top-level `dot_` prefix becomes `.` in the home).

---

## Quick start — local (developer)

1. Ensure `git` and either `curl` or `wget` are installed.
2. From this repository's `chezmoi/` directory, run the setup script:
   - `./chezmoi/setup.sh`  
     This will:
     - Install `mise` if needed.
     - Activate `mise` for the current shell (best-effort).
     - Run the Mise `bootstrap` task which runs `chezmoi apply` and then installs tools from the user-wide Mise config (if present).

3. Alternatively, if you already have `mise` installed:
   - `mise run bootstrap`
   - Or run a validation: `mise run validate:all`

---

## Quick start — CI

Recommended patterns for CI runners:

- Option A: Pre-install `mise` in the runner image, then run:
  - `CI=1 mise run bootstrap`  
    - `CI=1` instructs tasks to be strict: fail-fast for tool installs and avoid mutating runner profiles.

- Option B: Use the repo script to install `mise` then run bootstrap:
  - `CI=1 ./chezmoi/setup.sh bootstrap`  
    - `setup.sh` will install `mise` if needed and then run the requested Mise task in CI-aware mode.

Example (GitHub Actions style):
```yaml
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
      - name: Ensure Mise (install only)
        run: ./chezmoi/setup.sh --skip-run
      - name: Run bootstrap
        run: ./chezmoi/setup.sh bootstrap
```

Notes:
- In CI mode (`CI=1`), Mise tasks:
  - Fail fast on tool-install errors.
  - Skip mutating user shell profiles (activation injection is skipped).
  - Treat missing `mise`/`chezmoi` as errors so CI can fail early.

---

## How the bootstrap flow works now (detailed)

1. `chezmoi/setup.sh` ensures the `mise` binary is available. It is the only place in the repo that installs `mise`.
2. `mise run bootstrap` (or `setup.sh` delegating to it) performs:
   - Optionally inject Mise activation into an interactive shell profile (skipped in CI).
   - Activate Mise for the current shell so `mise exec` works in the same session.
   - Run `mise exec chezmoi -- init --source <local-repo>` (if run from a checkout) and then `mise exec chezmoi -- apply`. This places the repository-managed files into the user's home (including `~/.config/mise/config.toml` if present).
   - Install tools from the user-wide `~/.config/mise/config.toml` using `mise install --config=...`. In CI this step is fail-fast.

---

## Validation tasks

Mise tasks also include validation helpers:
- `validate:files` — check critical repository files exist (e.g. `.chezmoi.toml.tmpl`, `dot_config/mise/config.toml`).
- `validate:syntax` — lightweight shell syntax checks for repo scripts (best-effort).
- `validate:mise` — check for `mise` binary (in CI this is an error if missing).
- `validate:chezmoi` — check for `chezmoi` availability (or via `mise exec`).
- `validate:all` — runs the above validations.

---

## Removed / deprecated items

- `install.sh`, `validate.sh` — removed. `chezmoi/setup.sh` + `chezmoi/mise.toml` replace their functionality.
- `CONTRIBUTING.md`, `LICENSE` — removed (personal project).
- README references to the removed scripts have been updated to point at the new `setup.sh` / `mise` task flow.

---

## Notes & tips

- Ensure `$HOME/.local/bin` is on your PATH so `mise` and other user-local binaries are discoverable:
  ```bash
  export PATH="$HOME/.local/bin:$PATH"
  ```
- If you want to use the Mise-managed `chezmoi` binary explicitly:
  ```bash
  mise exec chezmoi -- status
  mise exec chezmoi -- apply
  ```
- To change which tools are installed for your user, update the configuration that Chezmoi applies to `~/.config/mise/config.toml` (or edit `dot_config/mise/config.toml` in the repo and let Chezmoi place it).

---

## Resources

- Chezmoi docs: https://www.chezmoi.io/
- Mise docs and tasks: https://mise.jdx.dev/
