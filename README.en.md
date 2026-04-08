<div align="center">

```
██████╗ ██╗      █████╗  ██████╗██╗  ██╗    ██╗ ██████╗███████╗
██╔══██╗██║     ██╔══██╗██╔════╝██║ ██╔╝    ██║██╔════╝██╔════╝
██████╔╝██║     ███████║██║     █████╔╝     ██║██║     █████╗  
██╔══██╗██║     ██╔══██║██║     ██╔═██╗     ██║██║     ██╔══╝  
██████╔╝███████╗██║  ██║╚██████╗██║  ██╗    ██║╚██████╗███████╗
╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝    ╚═╝ ╚═════╝╚══════╝
     █████╗ ██████╗  ██████╗██╗  ██╗
    ██╔══██╗██╔══██╗██╔════╝██║  ██║
    ███████║██████╔╝██║     ███████║
    ██╔══██║██╔══██╗██║     ██╔══██║
    ██║  ██║██║  ██║╚██████╗██║  ██║
    ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝
```

# 🧊 BLACK-ICE ARCH

### Automated Arch Linux Installation with Hyprland & Cybersecurity Tools

[![License: MIT](https://img.shields.io/badge/License-MIT-cyan.svg)](LICENSE)
[![Arch Linux](https://img.shields.io/badge/Arch-Linux-1793D1?logo=arch-linux&logoColor=fff)](https://archlinux.org/)
[![Hyprland](https://img.shields.io/badge/Hyprland-v0.53.3-00FFFF)](https://hyprland.org/)
[![Version](https://img.shields.io/badge/Version-3.2.1-neon.svg)](https://github.com/panxos/BLACK-ICE-ARCH)

**[🇪🇸 Español](README.md) | 🇬🇧 English**

---

### 🚀 One-Command Installation

```bash
curl -L http://is.gd/blackice | bash
```

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Requirements](#-requirements)
- [Quick Install](#-quick-install)
- [Manual Installation](#-manual-installation)
- [Security Tools](#-security-tools)
- [Post-Installation](#-post-installation)
- [Keyboard Shortcuts](#-keyboard-shortcuts)
- [Customization](#-customization)
- [Troubleshooting](#-troubleshooting)
- [Documentation](#-documentation)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🎯 Overview

**BLACK-ICE ARCH** is a State-of-the-Art () automated deployment system for Arch Linux, specifically designed for **Cybersecurity Professionals** and **Penetration Testers**. It transforms a minimal Arch installation into a fully configured, aesthetically stunning, and feature-rich Hyprland environment.

### Why BLACK-ICE ARCH?

- ⚡ **One-command installation** from LiveCD
- 🎨 **Cyberpunk aesthetic** with custom themes
- 🛡️ **104 security tools** organized in 10 categories
- 🔒 **Security-focused** with LUKS encryption support
- 🚀 **Optimized performance** with hardware detection
- 📦 **Fully automated** installation and configuration

---

## ✨ Features

### 🎨 Desktop Environment

- **Hyprland** - Next-generation Wayland compositor
  - Smooth animations and effects
  - Multi-workspace support
  - Optimized for performance
  
- **Waybar** - Customizable status bar
  - Cyberpunk-themed modules
  - Real-time system monitoring
  - Network and VPN status
  
- **SDDM** - Display manager with cybersec theme
  - Custom login screen
  - Secure authentication
  - Visual effects

### 🛡️ Security Arsenal

**104 tools organized in 10 categories:**

| Category | Tools | Description |
|----------|-------|-------------|
| 🔍 **Reconnaissance** | 14 | nmap, masscan, rustscan, recon-ng, amass, sherlock |
| 🌐 **Web Hacking** | 16 | burpsuite, zaproxy, sqlmap, nikto, gobuster, ffuf |
| 📡 **Wireless** | 8 | aircrack-ng, kismet, wifite, reaver, bully |
| 🪟 **Windows/AD** | 10 | impacket, crackmapexec, bloodhound, evil-winrm |
| 🔐 **Cracking** | 10 | john, hashcat, hydra, medusa, rockyou |
| 💥 **Exploitation** | 6 | metasploit, armitage, exploitdb, SET |
| 🕵️ **Sniffing** | 9 | wireshark, tcpdump, ettercap, bettercap |
| 🔧 **Reverse Eng.** | 9 | gdb, radare2, ghidra, jadx, apktool |
| 🔬 **Forensics** | 12 | autopsy, volatility3, binwalk, steghide |
| 🌐 **Networking** | 10 | proxychains, sshuttle, chisel, socat |

**Interactive installer** with:

- Category-based installation
- Individual tool selection
- "Install All" option
- Installation logging

### 🎨 Cyberpunk Theme

- **Sweet-Dark** GTK Theme
- **Candy Icons** Icon Pack
- **Kvantum** Qt Theme Engine
- **JetBrains Mono Nerd Font**
- Cyan/Purple/Purple Glow color scheme
- Smooth animations and fast animated borders

### ⚙️ Optimizations

- ✅ Automatic hardware detection (Intel/AMD)
- ✅ Virtualization support (VMware, KVM, VirtualBox)
- ✅ Spanish keyboard layout
- ✅ Fastfetch with random logos
- ✅ Live Video Wallpapers (.mp4 support with `mpvpaper`)
- ✅ Utility scripts for pentesting

### 🆕 New Features (v3.2.1)

- **paru from chaotic-aur**: Installed from chaotic-aur (compiled against the system's current pacman) — never breaks after libalpm upgrades.
- **ABI-resilient AUR helper**: `safe_install` detects a broken paru and falls back to pacman automatically. No more silent mass-install failures after `pacman -Syu`.
- **Correct keyboard at every stage**: LUKS prompt, GRUB menu, SDDM, and Hyprland all use the layout selected during install.
- **AI Native Integration**: Pre-installed CLIs for **Claude Code**, **Gemini**, and **Qwen**.
- **DedSec GRUB Theme**: Interactive theme selector via whiptail.
- **4 gh0stzk-inspired Waybar themes**: Jan-CyberPunk, Emilia-TokyoNight, Marisol-Dracula, Melissa-Nord.
- **s4vitar-darkness Theme**: Pro dual-bar theme with Pacman icons and ultra-dark aesthetic — tribute to s4vitar's iconic setup.
- **Matrix-Hacker Theme**: Matrix-inspired theme with neon green accents and mono fonts.
- **Hardware Temperature Module**: Built-in CPU/GPU monitoring in all themes.
- **Visual Wallpaper Selector**: `wofi` interactive menu (`Win+Alt+W`).
- **KDE/Qt Pro Integration**: Dolphin and Kate with Kvantum-Sweet and Kitty as default terminal.

---

## 💻 Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **CPU** | Dual Core 64-bit | Quad Core+ |
| **RAM** | 4 GB | 16 GB+ |
| **Storage** | 20 GB SSD | 100 GB NVMe |
| **GPU** | Integrated | Dedicated AMD/NVIDIA |
| **Network** | WiFi/Ethernet | Wired Ethernet |

---

## 🚀 Quick Install

### From Arch Linux LiveCD

**One command - that's it!**

```bash
# Option 1: Short URL (is.gd)
curl -L http://is.gd/blackice | bash

# Option 2: Short URL (cutt.ly)
curl -L https://cutt.ly/blackice | bash

# Option 3: Full URL
curl -L https://raw.githubusercontent.com/panxos/BLACK-ICE-HYPER_ARCH/main/bootstrap.sh | bash
```

The bootstrap script will:

1. ✅ Check internet connection
2. ✅ Install git
3. ✅ Clone repository
4. ✅ Set permissions
5. ✅ Execute installation automatically

---

## 📦 Manual Installation

If you prefer manual control:

### Step 1: Boot Arch Live ISO

Download the official Arch Linux ISO and create a bootable USB.

### Step 2: Connect to Internet

```bash
# For WiFi
iwctl
station wlan0 connect "YOUR_NETWORK"
exit

# For Ethernet
dhcpcd
```

### Step 3: Clone Repository

```bash
pacman -Sy git
git clone https://github.com/panxos/BLACK-ICE_ARCH.git
cd BLACK-ICE_ARCH
```

### Step 4: Run Installer

```bash
chmod +x install.sh
./install.sh
```

### Step 5: Post-Installation

After rebooting into your new system:

```bash
cd BLACK-ICE_ARCH
./deploy_hyprland.sh
```

---

## 🛡️ Security Tools

### Interactive Installer

Run the security tools installer:

```bash
sudo ./src/deploy/02_security_tools.sh
```

### Categories

1. **Reconnaissance & Scanning** (14 tools)
   - Network scanners: nmap, masscan, rustscan
   - OSINT: recon-ng, theharvester, spiderfoot, amass
   - DNS: dnsenum, dnsrecon, fierce

2. **Web Application Hacking** (16 tools)
   - Proxies: burpsuite, zaproxy
   - Scanners: sqlmap, nikto, wpscan
   - Fuzzers: gobuster, ffuf, wfuzz, feroxbuster

3. **Wireless & Bluetooth** (8 tools)
   - WiFi: aircrack-ng, kismet, wifite
   - Attacks: reaver, bully, pixiewps

4. **Windows & Active Directory** (10 tools)
   - Frameworks: impacket, crackmapexec
   - Recon: bloodhound, neo4j, smbmap

5. **Password Cracking** (10 tools)
   - Crackers: john, hashcat, ophcrack
   - Brute force: hydra, medusa
   - Wordlists: seclists, rockyou

6. **Exploitation Frameworks** (6 tools)
   - metasploit, armitage, exploitdb
   - social-engineer-toolkit

7. **Network Sniffing & Spoofing** (9 tools)
   - Sniffers: wireshark, tcpdump
   - MITM: ettercap, bettercap, mitmproxy

8. **Reverse Engineering** (9 tools)
   - Debuggers: gdb, radare2, ghidra
   - Android: apktool, jadx, dex2jar

9. **Digital Forensics** (12 tools)
   - Analysis: autopsy, volatility3
   - Recovery: binwalk, foremost, scalpel
   - Steganography: stegseek, steghide

10. **Network Utilities & Tunneling** (10 tools)
    - Tunneling: proxychains, sshuttle, chisel
    - Utilities: socat, netcat, curl

---

## 🎮 Post-Installation

### First Login

1. Select **Hyprland** session in SDDM
2. Login with your credentials
3. Enjoy your cyberpunk desktop!

### Initial Setup

```bash
# Update system
sudo pacman -Syu

# Install additional tools
sudo ./src/deploy/02_security_tools.sh

# Customize theme
~/.config/bin/theme_selector

# Change wallpaper
~/.config/bin/wallpaper_switcher
```

---

## ⌨️ Keyboard Shortcuts

### Essential

| Shortcut | Action |
|----------|--------|
| `Super + Return` | Open terminal (Kitty) |
| `Super + D` | Application launcher (Wofi) |
| `Super + Q` | Close window |
| `Super + M` | Exit Hyprland |
| `Super + L` | Lock screen |

### Applications

| Shortcut | Action |
|----------|--------|
| `Super + Shift + B` | Brave Browser |
| `Super + Shift + F` | Firefox |
| `Super + Shift + K` | KeePassXC |
| `Super + E` | Kate Editor |
| `Super + Shift + D` | Dolphin File Manager |

### Screenshots

| Shortcut | Action |
|----------|--------|
| `Print` | Screenshot region |
| `Shift + Print` | Screenshot fullscreen |
| `Super + Print` | Screenshot region (save) |
| `Ctrl + Print` | Screenshot fullscreen (save) |

### Workspaces

| Shortcut | Action |
|----------|--------|
| `Super + 1-5` | Switch to workspace 1-5 |
| `Super + Shift + 1-5` | Move window to workspace 1-5 |

### Media

| Shortcut | Action |
|----------|--------|
| `F10` | Play/Pause |
| `F11` | Stop |
| `XF86AudioRaiseVolume` | Volume up |
| `XF86AudioLowerVolume` | Volume down |
| `XF86AudioMute` | Mute audio |

**[📖 Complete Cheat Sheet](docs/wiki/en/Keyboard-Shortcuts.md)**

---

## 🎨 Customization

### Themes

```bash
# Change theme
~/.config/bin/theme_selector

# Available themes:
# - s4vitar-darkness
# - Matrix-Hacker (New)
```

### Wallpapers

```bash
# Change wallpaper
~/.config/bin/wallpaper_switcher

# Or use Super + Alt + W (Direct Visual Selector)
```

### Fastfetch Logos

Custom logos are randomly selected on each terminal launch.

Add your own logos:

```bash
cp your-logo.png ~/.config/fastfetch/logos/
```

---

## 🔧 Troubleshooting

### Installation Issues

**Problem**: No internet connection

```bash
# WiFi
iwctl
station wlan0 connect "YOUR_NETWORK"
exit

# Ethernet
dhcpcd
```

**Problem**: Git not found

```bash
pacman -Sy git
```

### Post-Installation Issues

**Problem**: Waybar not loading

```bash
killall waybar
sleep 1 && waybar &
```

**Problem**: Fastfetch shows ASCII instead of image

```bash
# Verify Kitty terminal
echo $TERM
# Should show: xterm-kitty

# Reinstall fastfetch
sudo pacman -S fastfetch
```

**Problem**: KDE apps not using dark theme

```bash
# Reconfigure Qt themes
cp ~/.config/qt5ct/qt5ct.conf ~/.config/qt5ct/qt5ct.conf.bak
cp dotfiles/qt5ct/qt5ct.conf ~/.config/qt5ct/
cp dotfiles/qt6ct/qt6ct.conf ~/.config/qt6ct/
```

**[📖 Full Troubleshooting Guide](docs/wiki/en/Troubleshooting.md)**

---

## 📚 Documentation

### Wiki

- **[🏠 Home](docs/wiki/en/Home.md)** - Wiki home page
- **[📦 Installation](docs/wiki/en/Installation.md)** - Detailed installation guide
- **[⚙️ Configuration](docs/wiki/en/Configuration.md)** - Advanced configuration
- **[🛡️ Security Tools](docs/wiki/en/Security-Tools.md)** - Complete tool catalog
- **[🎨 Customization](docs/wiki/en/Customization.md)** - Themes and personalization
- **[⌨️ Keyboard Shortcuts](docs/wiki/en/Keyboard-Shortcuts.md)** - Complete cheat sheet
- **[🔧 Troubleshooting](docs/wiki/en/Troubleshooting.md)** - Problem solving
- **[❓ FAQ](docs/wiki/en/FAQ.md)** - Frequently asked questions

### Technical Documentation

- **[🏗️ Architecture](docs/ARCHITECTURE.en.md)** - System architecture
- **[🔒 Security](docs/SECURITY.en.md)** - Security analysis
- **[📦 Modules](docs/MODULES.md)** - Module documentation
- **[🤝 Contributing](docs/CONTRIBUTING.en.md)** - Contribution guide

---

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guide](docs/CONTRIBUTING.en.md) for details on:

- Code of conduct
- Development workflow
- Coding standards
- Pull request process

### Quick Start

```bash
# Fork the repository
git clone https://github.com/YOUR_USERNAME/BLACK-ICE_ARCH.git
cd BLACK-ICE_ARCH

# Create a branch
git checkout -b feature/your-feature

# Make changes and commit
git add .
git commit -m "Add your feature"

# Push and create PR
git push origin feature/your-feature
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **[s4vitar](https://www.youtube.com/@s4vitar)** — Primary inspiration for the workflow philosophy, terminal aesthetics, and professional pentesting setup culture. The `s4vitar-darkness` Waybar theme is a direct tribute to his iconic dual-bar setup.
- **[gh0stzk](https://github.com/gh0stzk/dotfiles)** — Inspiration for Jan-CyberPunk, Emilia-TokyoNight, Marisol-Dracula, and Melissa-Nord Waybar themes.
- **[VandalByte](https://github.com/VandalByte/dedsec-grub2-theme)** — DedSec GRUB2 theme.
- [Hyprland](https://hyprland.org/) — Amazing Wayland compositor.
- [Arch Linux](https://archlinux.org/) — The best Linux distribution.
- [Sweet Theme](https://github.com/EliverLara/Sweet) — Beautiful GTK theme.
- Arch Linux community and r/unixporn.

> Full credits: see [CREDITS.md](CREDITS.md)

---

## 👤 Author

**Francisco Aravena (P4nX0Z)**

- Cybersecurity Analyst
- 15+ years of experience in IT and security
- Web: [soporteinfo.net](https://www.soporteinfo.net)
- LinkedIn: [in/faravena](https://www.linkedin.com/in/faravena/)
- YouTube: [@Soporteinfo](https://www.youtube.com/@Soporteinfo)
- [GitHub](https://github.com/panxos)

---

<div align="center">

**⭐ If you like this project, give it a star on GitHub ⭐**

**[🇪🇸 Leer en Español](README.md)**

Made with ❤️ for the Cybersecurity Community

</div>
