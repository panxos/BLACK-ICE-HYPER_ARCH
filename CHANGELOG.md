# Changelog

All notable changes to the BLACK-ICE HYPER_ARCH project will be documented in this file.

## [Unreleased] - 2026-02-12

### Fixed (Community Bugs)

1. **Dolphin File Associations**
    * Fixed `keditfiletype` error by adding `kde-cli-tools` to the base installation.
    * Ensured consistent behavior for "Open with" and file type editing in Dolphin.

2. **Neovim Professional Setup**
    * Implemented **NvChad v2.5** as the default professional Neovim configuration.
    * Added automated setup for Python, C/C++, Docker, and Java LSPs.
    * Integrated **Auto-format on save** (conform.nvim) and **Debugging** (DAP).
    * Created comprehensive keymap documentation in `docs/NVIM_KEYMAPS.md`.

3. **Hostname Configuration**
    * Added interactive hostname prompt in `install.sh` (Attended Mode).
    * Implemented hostname validation (RFC 1123 compliant) in `utils.sh`.
    * Added auto-detection for Unattended Mode via `install.conf`.

4. **Powerlevel10k Installation**
    * Switched from AUR/pkg to official `git clone` installation method.
    * Fixed issue where custom `.p10k.zsh` config was not being applied correctly.
    * Ensured ZSH and p10k are configured for both User and Root accounts.

5. **PGP/Signature Errors**
    * Implemented `safe_install()` wrapper function that auto-detects PGP errors.
    * Added `rebuild_keyring()` for nuclear GPG repair.
    * Refactored all deploy modules to use `safe_install()` for resilience.

6. **Power Management**
    * Rewrote `06_power.sh` with proper hardware detection (Laptop vs Desktop vs VM).
    * Added `tlp` configuration for Laptops and `cpupower` (performance) for Desktops/VMs.
    * Integrated `lm_sensors`, `thermald`, and `zram-generator`.
    * Added Power Profile Menu (Super+Shift+P) for Hyprland.

7. **SDDM Theming**
    * Fixed hardcoded "faravena" username in SDDM theme QML files.
    * Implemented dynamic Avatar support via `.face.icon` and AccountsService.
    * Added `set_avatar.sh` utility script for easy user customization.
