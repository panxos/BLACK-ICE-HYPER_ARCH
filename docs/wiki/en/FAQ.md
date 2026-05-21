# ❓ Frequently Asked Questions - BLACK-ICE ARCH

Answers to the most common questions about BLACK-ICE ARCH.

---

## 📦 Installation

### Can I install BLACK-ICE ARCH in a virtual machine?

**Yes**, BLACK-ICE ARCH works perfectly in:

- VMware Workstation/Player
- VirtualBox
- KVM/QEMU
- Hyper-V

The installer auto-detects the VM environment and configures appropriate drivers.

**Recommended configuration**:
- 4 GB RAM minimum (8 GB recommended)
- 2 CPU cores minimum
- 30 GB disk
- Enable 3D acceleration

### Can I dual boot with Windows?

**Yes**, the installer automatically detects Windows and adds it to the GRUB menu.

**Recommendations**:
1. Install Windows first
2. Leave unpartitioned space
3. Install BLACK-ICE ARCH in the free space

### Do I need an Internet connection to install?

**Yes**, Internet is **required** during installation to:
- Download packages
- Update the system
- Install tools

### How long does installation take?

| Phase | Time |
|-------|------|
| Base installation | 15–20 min |
| Hyprland deployment | 15–20 min |
| Security tools | 30–60 min |
| **Total** | ~1–2 hours |

### Will my data be erased?

**Yes**, the installer formats the selected disk. **Back up** your important data before installing.

---

## 🛡️ Security Tools

### How many security tools are included?

**100+ tools** organized in 10 categories:

| Category | Count |
|----------|-------|
| Reconnaissance | 14 |
| Web Hacking | 16 |
| Wireless | 8 |
| Windows/AD | 10 |
| Password Cracking | 10 |
| Exploitation | 6 |
| Sniffing & Spoofing | 9 |
| Reverse Engineering | 9 |
| Digital Forensics | 12 |
| Networking | 10 |

### Can I install only specific tools?

**Yes**, the interactive installer lets you:
- Install by category
- Select individual tools
- Install everything at once

### Do tools update automatically?

**No**, update manually:

```bash
sudo pacman -Syu   # Official repos
paru -Syu          # AUR tools
```

### Can I add more tools later?

**Yes**:
1. Re-run the tool installer: `bash src/deploy/02_security_tools.sh`
2. Install manually: `sudo pacman -S tool-name`
3. From AUR: `paru -S tool-name`

---

## 🎨 Customization

### Can I change the theme?

**Yes**, BLACK-ICE ARCH includes multiple themes:

```bash
~/.config/bin/theme_selector
```

Additional themes from:
- GTK: `~/.themes/`
- Icons: `~/.icons/`
- Kvantum: `~/.config/Kvantum/`

### How do I change the wallpaper?

```bash
# Interactive selector
~/.config/bin/wallpaper_switcher

# Or use shortcut
Super + Alt + W
```

### Can I customize Waybar?

**Yes**, edit:

```bash
~/.config/waybar/config.jsonc   # Configuration
~/.config/waybar/style.css      # Styles
```

Then restart Waybar:

```bash
killall waybar && waybar &
```

### How do I change keyboard shortcuts?

Edit the Hyprland config:

```bash
nano ~/.config/hypr/hyprland.conf
```

Find `bind =` sections and modify as needed. Reload:

```bash
hyprctl reload
```

---

## ⚙️ Configuration

### How do I change keyboard layout?

```bash
# Temporary
setxkbmap us

# Permanent — edit hyprland.conf
nano ~/.config/hypr/hyprland.conf

# Find and modify:
# input {
#     kb_layout = us
# }
```

### How do I set up multiple monitors?

Edit `~/.config/hypr/hyprland.conf`:

```bash
# Example for 2 monitors
monitor=DP-1,1920x1080@60,0x0,1
monitor=HDMI-A-1,1920x1080@60,1920x0,1
```

Reload: `hyprctl reload`

### How do I enable LUKS encryption?

Set in `config/install.conf` before running the installer:

```bash
ENABLE_LUKS=yes
LUKS_PASSWORD=your_strong_passphrase
```

### How do I configure auto WiFi?

```bash
nmcli device wifi connect "YOUR_NETWORK" password "YOUR_PASSWORD"
# Network will auto-connect on future boots
```

---

## 🔧 Troubleshooting

### Waybar doesn't appear on startup

```bash
killall waybar
sleep 1 && waybar &

# Check errors
waybar -l debug
```

### Black screen after install

From TTY (Ctrl+Alt+F2):

```bash
cd BLACK-ICE-HYPER_ARCH
./deploy_hyprland.sh

# Enable SDDM
sudo systemctl enable --now sddm
```

### No audio

```bash
pactl info
systemctl --user restart pipewire pipewire-pulse
pactl set-sink-volume @DEFAULT_SINK@ 50%
```

### KDE apps not using dark theme

```bash
cp dotfiles/qt5ct/qt5ct.conf ~/.config/qt5ct/
cp dotfiles/qt6ct/qt6ct.conf ~/.config/qt6ct/
# Then Super + Shift + R to reload Hyprland
```

---

## 🚀 Performance

### How much RAM does Hyprland use?

| State | RAM Usage |
|-------|-----------|
| Idle | 800 MB – 1.2 GB |
| With apps | 2–4 GB |
| Heavy tools | 4–8 GB |

### Does it work on old hardware?

**Minimum recommended**:
- CPU: Dual Core 64-bit (2010+)
- RAM: 4 GB
- GPU: Intel HD 4000 or equivalent

For older hardware, consider a lighter window manager.

---

<div align="center">

**[🏠 Back to Wiki](Home.md)** | **[🔧 Troubleshooting →](Troubleshooting.md)**

</div>
