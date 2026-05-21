# 🧊 BLACK-ICE ARCH Wiki

Welcome to the official wiki for **BLACK-ICE ARCH** — the automated Arch Linux deployment system for cybersecurity professionals.

---

## 📚 Wiki Contents

### 🚀 Getting Started

- **[📦 Installation](Installation.md)** - Complete step-by-step installation guide
  - System requirements
  - Bootable USB preparation
  - One-command bootstrap install
  - Manual installation
  - Post-install verification

- **[⚙️ Configuration](Configuration.md)** - Advanced system configuration
  - Network configuration
  - Hyprland customization
  - Waybar configuration
  - Performance tuning
  - Environment variables

### 🛡️ Tools & Security

- **[🛡️ Security Tools](Security-Tools.md)** - Catalog of 100+ pre-installed tools
  - Reconnaissance & Scanning (14 tools)
  - Web Hacking (16 tools)
  - Wireless & Bluetooth (8 tools)
  - Windows & Active Directory (10 tools)
  - Password Cracking (10 tools)
  - Exploitation Frameworks (6 tools)
  - Sniffing & Spoofing (9 tools)
  - Reverse Engineering (9 tools)
  - Digital Forensics (12 tools)
  - Network Utilities (10 tools)

### 🎨 Customization

- **[🎨 Customization](Customization.md)** - Themes, wallpapers and personalization
  - GTK/Qt theme switching
  - Wallpaper management
  - Waybar customization
  - Fastfetch config
  - Creating custom themes

- **[⌨️ Keyboard Shortcuts](Keyboard-Shortcuts.md)** - Complete cheat sheet
  - Essential shortcuts
  - Window management
  - Workspaces
  - Applications
  - Multimedia
  - Screenshots

### 🔧 Support

- **[🔧 Troubleshooting](Troubleshooting.md)** - Common issues and solutions
  - Installation problems
  - Network issues
  - Display problems
  - Audio issues
  - Theme problems
  - Performance problems

- **[❓ FAQ](FAQ.md)** - Frequently asked questions
  - General questions
  - Installation
  - Configuration
  - Security tools
  - Performance

### 🤝 Community

- **[🤝 Contributing](Contributing.md)** - How to contribute to the project
  - Code of conduct
  - Bug reporting
  - Feature requests
  - Pull request process
  - Code standards

---

## 🎯 Quick Start

### One-Command Install

```bash
curl -L http://is.gd/blackice | bash
```

### First Steps After Install

1. **Update the system**

   ```bash
   sudo pacman -Syu
   ```

2. **Deploy security tools**

   ```bash
   bash deploy_hyprland.sh
   ```

3. **Customize your environment**

   ```bash
   ~/.config/bin/theme_selector
   ~/.config/bin/wallpaper_switcher
   ```

---

## 📖 Additional Documentation

### Technical Documentation

- [🏗️ System Architecture](../../ARCHITECTURE.md)
- [🔒 Security Analysis](../../SECURITY.md)
- [📦 Module Reference](../../MODULES.md)
- [📝 Changelog](../../CHANGELOG.md)

### External Links

- [Hyprland Documentation](https://wiki.hyprland.org/)
- [Arch Linux Wiki](https://wiki.archlinux.org/)
- [Waybar Wiki](https://github.com/Alexays/Waybar/wiki)

---

## 🆘 Need Help?

- **GitHub Issues**: [Report a problem](https://github.com/panxos/BLACK-ICE-HYPER_ARCH/issues)
- **Discussions**: [Community forum](https://github.com/panxos/BLACK-ICE-HYPER_ARCH/discussions)

---

<div align="center">

**[🏠 Back to README](../../../README.en.md)** | **[🇪🇸 Wiki en Español](../es/Home.md)**

Made with ❤️ for the Cybersecurity Community

</div>
