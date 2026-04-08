# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Project Is

BLACK-ICE ARCH is a two-phase automated installer that transforms a bare Arch Linux ISO into a hardened pentesting/security workstation with Hyprland. It is **not a traditional software project** — there is no build step, no package.json, no tests to run locally unless you have the target environment.

## Two-Phase Architecture

**Phase 1 — Base System (`install.sh` → `src/modules/`)**
Run as root from the Arch Linux LiveCD. Sources modules sequentially:
- `00_environment.sh` — NTP sync, network, keyring repair
- `01_disk.sh` — partitioning, LUKS/LVM, filesystem (btrfs/ext4/xfs/f2fs)
- `02_base.sh` — `pacstrap`, kernel selection (linux/linux-zen/linux-hardened)
- `03_config.sh` — locale, timezone, hostname, mkinitcpio
- `04_user.sh` — user creation, sudoers
- `05_bootloader.sh` — GRUB with LUKS support
- `06_power.sh` — NVMe APST, power profiles
- `99_final.sh` — stamp `/etc/black-ice-release`, cleanup

**Phase 2 — User Environment (`deploy_hyprland.sh` → `src/deploy/`)**
Run as the normal user after first boot. Sources modules sequentially:
- `00_repositories.sh` — yay (AUR helper), chaotic-aur, BlackArch repos, reflector mirrors
- `01_hyprland_base.sh` — Hyprland, Waybar, wofi, swaync, kitty, hyprlock
- `02_security_tools.sh` — nmap, metasploit, and category-based pentesting suite
- `03_terminal_config.sh` — Zsh, Oh-My-Zsh, powerlevel10k, aliases
- `04_theme_setup.sh` — GTK/Qt themes, icon pack, fonts
- `05_software_suite.sh` — interactive checklist (whiptail) for optional software
- `06_sddm_setup.sh` — CyberSec SDDM theme
- `07_neovim_setup.sh` — Neovim with LazyVim
- `08_ai_tools.sh` — Claude CLI, Gemini CLI, Qwen CLI
- `99_finalization.sh` — dotfiles symlinks, final message

## Shared Libraries (`src/lib/`)

All scripts source these three libs before doing anything:
- `colors.sh` — ANSI color variables (`NEON_CYAN`, `NEON_PURPLE`, `RED`, etc.)
- `logging.sh` — `log_info`, `log_warn`, `log_error`, `log_success`, `banner`, `print_step`, `print_line`. Also defines `LOG_FILE` (`~/black_ice_install.log` or `/tmp/`)
- `utils.sh` — `check_root`, `check_boot_mode`, `ask_option`, `retry_command`

## Config & Automation

Copy `config/install.conf.example` to `config/install.conf` for unattended install. Key vars: `TARGET_DISK`, `ENABLE_LUKS`, `FILESYSTEM`, `KERNEL`, `USERNAME`, `TIMEZONE`. When present, `AUTO_MODE=true` skips all interactive prompts. **Never commit `install.conf` with real passwords.**

## Testing

```bash
# Pre-install: validates UEFI, internet, keyring (run from LiveCD)
bash tests/pre-install-check.sh

# Post-deploy: validates binaries and config files exist
bash tests/post-install-validate.sh
```

Tests use `exit 1` on any `FAIL=1`. No test framework — pure bash with `check_bin`/`check_file` helpers.

## Coding Conventions

- All scripts: `set -uo pipefail` at top (note: `install.sh` uses `-uo` not `-euo` intentionally, to allow custom error traps per module)
- Use `log_info`/`log_warn`/`log_error` — never raw `echo` for status messages
- Use `banner "TITLE" "subtitle"` at the start of each deploy module
- Idempotency: check for existing state (`command -v`, `[ -f ]`, `[ -d ]`) before installing/creating
- Interactive input must read from `/dev/tty` explicitly (stdout/stderr are redirected to log)
- `$SCRIPT_DIR` = repo root, `$DOTFILES_DIR` = `$SCRIPT_DIR/dotfiles`, `$USER_HOME` = `/home/$CURRENT_USER`

## Security Rules

Every script change must comply with the standards already documented in `docs/SECURITY.md`. The non-negotiables:

- **No hardcoded credentials** — passwords, tokens, API keys go into `install.conf` (gitignored) or env vars only
- **Input sanitization** — sanitize any variable that comes from user input before using in commands: `VAR=$(echo "$INPUT" | tr -cd '[:alnum:]-')`
- **Privilege validation** — `install.sh` always calls `check_root`; `deploy_hyprland.sh` always rejects root (`$EUID -eq 0` → exit)
- **Destructive operations** — disk wipe, LUKS format, `pacstrap` must be gated behind an explicit user confirmation read from `/dev/tty`
- **`trap cleanup EXIT`** — every script that touches disk or system state must register a cleanup trap that logs the exit state
- **AUR packages** — always install via `yay` with `--noconfirm` only for packages already in the vetted list in `src/deploy/02_security_tools.sh`; new packages require explicit review
- **ShellCheck** — before committing any `.sh` change, run `shellcheck <file>`. Fix all SC2 (logic errors) and SC1 (syntax) warnings. SC2086 (quoting) is mandatory

```bash
# Audit the whole codebase
shellcheck src/**/*.sh dotfiles/bin/*.sh *.sh
```

## Optimization Rules

- **`retry_command`** — use the existing helper from `src/lib/utils.sh` for any network operation (pacman, yay, curl, git clone). Never raw-call with a manual sleep loop
- **Parallel installs** — group related pacman/yay calls into a single invocation; don't install packages one by one in separate calls
- **Reflector** — mirror optimization is already handled in `src/deploy/00_repositories.sh`; don't add redundant reflector calls in other modules
- **Idempotent checks before heavy ops** — before any `pacstrap`, `git clone`, or theme install, check if the result already exists to allow re-runs without full reinstall
- **`awww` (not `swww`)** — wallpaper daemon is `awww`/`awww-daemon` since v3.1.0. Never reintroduce `swww` references

## Continuous Improvement Protocol

When fixing a bug or adding a feature:

1. **Root-cause first** — read the failing module top-to-bottom before changing anything. The error message and `$LOG_FILE` are the primary evidence
2. **One change at a time** — each commit must be atomic: one module, one concern
3. **Update tests** — if `tests/post-install-validate.sh` doesn't cover the new binary or config, add it
4. **CHANGELOG is mandatory** — every PR/commit that changes user-facing behavior must prepend an entry to `CHANGELOG.md` following the existing format: `## [X.Y.Z] - YYYY-MM-DD (Edition)` with subsections `🚀 Novedades`, `🛠️ Fixes`, `🛡️ Seguridad`
5. **Version bump** — bump the version string in `src/lib/logging.sh` (`banner()`) and `bootstrap.sh` to match the new CHANGELOG entry

## Documentation — Mandatory Update Policy

**Any change that affects user-visible behavior MUST update all relevant docs in the same commit.** This includes:

| Change type | Files to update |
|---|---|
| New feature / new module | `README.md`, `README.en.md`, `docs/MODULES.md`, `CHANGELOG.md` |
| New security measure or risk | `docs/SECURITY.md`, `CHANGELOG.md` |
| Architecture change | `docs/ARCHITECTURE.md`, `docs/DIAGRAMS.md`, `CHANGELOG.md` |
| New dotfile or `bin/` script | `docs/TOOLS_CATALOG.md`, `docs/KEYBOARD_SHORTCUTS.md` (if keybind), `CHANGELOG.md` |
| Bug fix | `CHANGELOG.md` |
| New `install.conf` variable | `config/install.conf.example` (with comment), `README.md` install section |

**README rules:**
- `README.md` is the Spanish version; `README.en.md` is the English mirror — both must stay in sync
- The "Key Features" and "Installation" sections of the README must reflect the current version in `CHANGELOG.md`
- Do not leave stale version numbers (`v3.0.0` text while CHANGELOG says `v3.1.1`)

**`docs/SECURITY.md` update trigger:** any time a new script is added, update the audit table and component risk table. Update `Última Auditoría` date.

## Dotfiles Layout

`dotfiles/` contains configs deployed via symlinks to `~/.config/`:
- `hypr/` → `~/.config/hypr/` (hyprland.conf, hyprlock.conf, monitors.conf, workspaces.conf)
- `waybar/` → `~/.config/waybar/`
- `kitty/` → `~/.config/kitty/`
- `wofi/`, `swaync/`, `wlogout/` → respective `~/.config/` dirs
- `bin/` → `~/.local/bin/` (Waybar status scripts, VPN connect/disconnect, KVM/Docker menus, power menu)

## Bootstrap (One-Liner Install)

`bootstrap.sh` is for `curl | bash` usage from a LiveCD — it clones the repo to `/tmp/black-ice-arch` then calls `install.sh`. It embeds its own color vars (does not source libs) because the libs don't exist yet.
