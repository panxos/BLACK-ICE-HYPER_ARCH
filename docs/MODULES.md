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
| `00_repositories.sh` | Installs Yay, Chaotic-AUR, BlackArch. | `pacman`, `git` |
| `01_hyprland_base.sh` | Installs Hyprland, Waybar, Wofi, Kitty. | `hyprland`, `xdg-desktop-portal` |
| `02_security_tools.sh` | Installs standard Pentesting suite (Burp, Nmap). | `BlackArch` repos |
| `03_terminal_config.sh` | Sets up Zsh, Oh-My-Zsh, P10k, Fastfetch. | `zsh`, `curl` |
| `04_theme_setup.sh` | Configures GTK themes, Fonts, Icons, Wallpapers. | `nwg-look`, `swww` |
| `05_software_suite.sh` | Interactive checklist for extra apps (Browsers, Obsidian). | `yay` |
| `06_sddm_setup.sh` | Installs and themes SDDM (Login Manager). | `sddm`, `qt5` |

## Libraries (`src/lib/`)

- **logging.sh**: Provides `log_info`, `log_error`, `log_warn`, `check_root`, `banner`.
- **utils.sh**: Common utilities (`ask_option`, `retry_command`, `read_password`).
- **colors.sh**: ANSI color codes definition.
