# BLACK-ICE ARCH 🛡️❄️

> **The Advanced CyberSecurity & Pentesting Environment on Arch Linux with Hyprland**

BLACK-ICE ARCH is an automated, modular, and security-hardened deployment platform. It transforms a standard Arch Linux installation into a professional-grade workstation optimized for offensive security, defensive analysis, and high-performance workflow.

## 🚀 Key Features (v3.2.1 - Hardened Deploy Edition)

- **AI Native Integration**: Pre-installed CLIs for **Claude Code**, **Gemini**, and **Qwen** with dynamic update aliases.
- **Tactic Ecosystem**: Full synchronization with high-productivity dotfiles (Hyprland, Waybar, SwayNC).
- **Security Suite**: Integrated tools (Nmap, Caido, Burp, Wireshark) via official repos and Chaotic-AUR.
- **Modular Architecture**: Clean separation between Base System (Installation) and User Environment (Deployment).
- **Aesthetic Excellence**: Dynamic UI banners and high-resolution cyberpunk wallpapers.
- **Resilient Installer**: Automated PGP keyring repair, hardware-adaptive package selection, and auto-recovery from `paru` ABI breaks post-upgrade.
- **paru desde chaotic-aur**: Instalado desde chaotic-aur (compilado contra el pacman del sistema) — nunca rompe por upgrades de libalpm.
- **Correct keyboard at every stage**: LUKS prompt, GRUB menu, SDDM, and Hyprland all use the layout selected during install.

## 🛠️ Installation

### 1. Requirements
- Arch Linux ISO (latest recommended).
- Internet connection.
- UEFI enabled (recommended).

### 2. Execution
Download the repository and run the main installer:

```bash
git clone https://github.com/panxos/BLACK-ICE-ARCH
cd BLACK-ICE-ARCH
./install.sh
```

### 3. Deployment
After rebooting into your new system, run the environment deployment:

```bash
./deploy_hyprland.sh
```

## 🐞 Recent Bug Fixes
- **PGP/Signature Errors**: Solved via automated NTP sync and keyring updates before pacstrap.
- **Package Conflicts**: Removed deprecated `virtio-vga-gl` ensuring smooth VM installations.
- **UI Scaling**: Fixed misaligned borders in CLI banners across different terminal widths.

## 🎨 Waybar Themes

BLACK-ICE ARCH includes **10 Waybar themes** (6 original + 4 inspired by gh0stzk):

| Theme | Style | Source |
|---|---|---|
| Horus-Cyber | Neon cyan/purple | Original BLACK-ICE |
| Ra-Solar | Orange solar | Original BLACK-ICE |
| Isis-Magic | Magenta/dark | Original BLACK-ICE |
| Anubis-Death | Green/dark | Original BLACK-ICE |
| s4vitar-darkness | Purple dark | Original BLACK-ICE |
| Matrix-Hacker | Matrix green | Original BLACK-ICE |
| **Jan-CyberPunk** | **Neon cyan/pink** | **Inspired by [gh0stzk](https://github.com/gh0stzk/dotfiles)** |
| **Emilia-TokyoNight** | **Blue/purple** | **Inspired by [gh0stzk](https://github.com/gh0stzk/dotfiles)** |
| **Marisol-Dracula** | **Dracula purple/pink** | **Inspired by [gh0stzk](https://github.com/gh0stzk/dotfiles)** |
| **Melissa-Nord** | **Cool blue minimal** | **Inspired by [gh0stzk](https://github.com/gh0stzk/dotfiles)** |

Switch themes with `Win+Alt+Y`. Download gh0stzk-inspired wallpapers with `gh0stzk-walls --all`.

> Full credits: see [CREDITS.md](CREDITS.md)

## 👨‍💻 Developer
**Francisco Aravena (P4nx0z)**
- Web: [soporteinfo.net](https://www.soporteinfo.net)
- LinkedIn: [in/faravena](https://www.linkedin.com/in/faravena/)
- YouTube: [@Soporteinfo](https://www.youtube.com/@Soporteinfo)

## 🙏 Agradecimientos

- **[s4vitar](https://www.youtube.com/@s4vitar)** — Inspiración principal del entorno de trabajo, filosofía de terminal y estética de pentesting profesional. El tema `s4vitar-darkness` es un homenaje directo a su setup.
- **[gh0stzk](https://github.com/gh0stzk/dotfiles)** — Inspiración para los temas Waybar Jan-CyberPunk, Emilia-TokyoNight, Marisol-Dracula y Melissa-Nord.
- **[VandalByte](https://github.com/VandalByte/dedsec-grub2-theme)** — Tema GRUB DedSec.
- **Comunidad Arch Linux** — Por mantener el ecosistema de paquetes que hace posible todo esto.

> Full credits: see [CREDITS.md](CREDITS.md)

---
*Developed with focus on Cybersecurity and high-efficiency workflows.*
