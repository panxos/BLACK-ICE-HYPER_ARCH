# 📦 Modules Reference

## Installation Modules (`src/modules/`)

| Module | Description | Key Functions |
|--------|-------------|---------------|
| `00_environment.sh` | Checks connectivity, time, and optimizing mirrors (Reflector). | `check_root`, `check_boot_mode` |
| `01_disk.sh` | Partitions disk, sets up LUKS encryption, LVM/Btrfs. | `sgdisk`, `cryptsetup`, `mkfs` |
| `02_base.sh` | Installs base packages (Kernel, Firmware, Editors). | `pacstrap`, `genfstab` |
| `03_config.sh` | Configures Hostname, Locale, Timezone, Hosts file. | `arch-chroot`, `ln -sf` |
| `04_user.sh` | Creates user, sets passwords, adds to wheel group. | `useradd`, `passwd`, `visudo` |
| `05_bootloader.sh` | Installs GRUB, configures EFI/BIOS boot, LUKS kernel params. | `grub-install`, `grub-mkconfig` |
| `99_final.sh` | Quality of life fixes, cleans cache, prepares reboot. | `systemctl enable` |

## Deployment Modules (`src/deploy/`)

| Module | Description | Dependencies |
|--------|-------------|--------------|
| `00_repositories.sh` | Installs paru-bin, Chaotic-AUR. BlackArch removed (SHA1/GPG issues, tools available via AUR/Chaotic). | `pacman`, `git` |
| `01_hyprland_base.sh` | Installs Hyprland, Waybar, Wofi, Kitty. | `hyprland`, `xdg-desktop-portal` |
| `02_security_tools.sh` | Installs standard Pentesting suite (Burp, Nmap, Caido). | `Chaotic-AUR`, `AUR` |
| `03_terminal_config.sh` | Sets up Zsh, Oh-My-Zsh, P10k, Fastfetch. | `zsh`, `curl` |
| `04_theme_setup.sh` | Configures GTK themes, Fonts, Icons, Wallpapers. | `nwg-look`, `awww` |
| `05_software_suite.sh` | Interactive checklist for extra apps (Browsers, Obsidian). | `paru` |
| `06_sddm_setup.sh` | Installs and themes SDDM (Login Manager). | `sddm`, `qt5` |
| `07_neovim_setup.sh` | Neovim + NvChad v2.5 + Mason LSPs. | `neovim`, `git` |
| `08_ai_tools.sh` | Claude Code CLI, Gemini CLI via npm. | `nodejs`, `npm` |
| `09_grub_theme.sh` | Tema DedSec para GRUB2. Selector de variante via whiptail. Clona repo, copia tema, configura `GRUB_THEME` y regenera `grub.cfg`. | `git`, `grub` |
| `99_finalization.sh` | XDG dirs, keyboard propagation to Hyprland, xdg-open Wayland wrapper. | `xdg-user-dirs` |

## Libraries (`src/lib/`)

- **logging.sh**: Provides `log_info`, `log_error`, `log_warn`, `check_root`, `banner`.
- **utils.sh**: Common utilities (`ask_option`, `retry_command`, `read_password`).
- **colors.sh**: ANSI color codes definition.

## Binaries & Scripts (`dotfiles/bin/`)

| Script | Description |
|--------|-------------|
| `theme_selector` | Interactive theme picker for Waybar and Hyprland. |
| `hardware_temp.sh` | Monitors CPU/GPU temperatures and returns JSON for Waybar. |
| `wallpaper_visual` | Visual wallpaper selector using Wofi. |
| `power_menu.sh` | Rofi-based system power management. |
| `dotfiles-update` | Updates dotfiles from repo without reinstalling. Auto-snapshot, `--dry-run` support. |
| `dotfiles-rollback` | Restores dotfiles from local snapshot. Interactive menu, no internet required. |
| `tpm2-luks-enroll` | Enrolls TPM2 chip for passwordless LUKS2 unlock (PCR0+7). Auto-detects device. |
| `auto_monitors.sh` | One-time monitor auto-detection on first Hyprland boot. Opens `nwg-displays` if 2+ monitors. |
