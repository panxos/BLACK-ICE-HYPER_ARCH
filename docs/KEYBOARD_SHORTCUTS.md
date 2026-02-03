![BLACK-ICE ARCH Banner](images/banner.png)

# BLACK-ICE ARCH - Keyboard Shortcuts Cheat Sheet

## 🎯 Essential Shortcuts

### Window Management

| Shortcut | Action |
|----------|--------|
| `Super + Return` | Open Kitty terminal |
| `Super + Q` | Kill active window |
| `Super + M` | Exit Hyprland session |
| `Super + V` | Toggle floating mode |
| `Super + F` | Fullscreen (hides bar) |
| `Super + Space` | Maximize (keeps bar) |
| `Super + P` | Pseudo-tile mode |
| `Super + J` | Toggle split direction |

### Application Launcher

| Shortcut | Action |
|----------|--------|
| `Super + D` | Open Wofi launcher |

### Session Control

| Shortcut | Action |
|----------|--------|
| `Super + L` | Lock screen (Hyprlock) |

---

## 🚀 Application Shortcuts

### Browsers

| Shortcut | Application |
|----------|-------------|
| `Super + Shift + B` | Brave Browser |
| `Super + Shift + F` | Firefox |
| `F12` | Brave Browser (quick launch) |

### Productivity

| Shortcut | Application |
|----------|-------------|
| `Super + E` | Kate (text editor) |
| `Super + Shift + T` | Kate (alternative) |
| `Super + Shift + D` | Dolphin (file manager) |
| `Super + Shift + K` | KeePassXC (password manager) |
| `Super + Shift + O` | Obsidian (notes) |
| `Super + Shift + E` | Betterbird (email) |

### Security Tools

| Shortcut | Application |
|----------|-------------|
| `Super + Shift + A` | Antigravity (AI assistant) |
| `Super + Shift + C` | Caido (web security) |

---

## 🎨 Customization

### Theme & Wallpaper

| Shortcut | Action |
|----------|--------|
| `Super + Alt + W` | Cycle wallpapers |
| `Super + Alt + Y` | Theme selector |

---

## 🖥️ Workspace Navigation

### Switch Workspace

| Shortcut | Workspace |
|----------|-----------|
| `Super + 1` | Workspace 1 |
| `Super + 2` | Workspace 2 |
| `Super + 3` | Workspace 3 |
| `Super + 4` | Workspace 4 |
| `Super + 5` | Workspace 5 |

### Move Window to Workspace

| Shortcut | Action |
|----------|--------|
| `Super + Alt + 1` | Move to workspace 1 |
| `Super + Alt + 2` | Move to workspace 2 |
| `Super + Alt + 3` | Move to workspace 3 |
| `Super + Alt + 4` | Move to workspace 4 |
| `Super + Alt + 5` | Move to workspace 5 |

---

## ⌨️ Focus Navigation

| Shortcut | Action |
|----------|--------|
| `Super + ←` | Focus left |
| `Super + →` | Focus right |
| `Super + ↑` | Focus up |
| `Super + ↓` | Focus down |

---

## 🔊 Media Controls

### Audio

| Shortcut | Action |
|----------|--------|
| `XF86AudioRaiseVolume` | Volume up (+5%) |
| `XF86AudioLowerVolume` | Volume down (-5%) |
| `XF86AudioMute` | Mute/unmute audio |
| `XF86AudioMicMute` | Mute/unmute microphone |

### Playback

| Shortcut | Action |
|----------|--------|
| `F10` | Play/Pause (Teams, Zoom, media) |
| `F11` | Stop playback |

### Brightness

| Shortcut | Action |
|----------|--------|
| `XF86MonBrightnessUp` | Increase brightness (+5%) |
| `XF86MonBrightnessDown` | Decrease brightness (-5%) |

### Network

| Shortcut | Action |
|----------|--------|
| `XF86WLAN` | Toggle WiFi on/off |

---

## 📸 Screenshots

| Shortcut | Action |
|----------|--------|
| `Print` | Screenshot selection → Swappy editor |
| `Shift + Print` | Fullscreen → Clipboard |
| `Super + Print` | Screenshot selection → Save to `~/Pictures/Screenshots/` |
| `Ctrl + Print` | Fullscreen → Save to `~/Pictures/Screenshots/` |

---

## 🖱️ Mouse Bindings

| Shortcut | Action |
|----------|--------|
| `Super + Left Click + Drag` | Move window |
| `Super + Right Click + Drag` | Resize window |

---

## 🎯 ZSH Aliases & Functions

### System Management

```bash
# Update system
update          # Full system update (pacman + AUR)

# Cleanup
cleanup         # Remove orphaned packages and cache

# System info
sysinfo         # Display system information
```

### Pentesting Utilities

```bash
# Set target IP for HTB/CTF
settarget <IP> [machine_name]

# Example:
settarget 10.10.10.123 "HackTheBox-Machine"
```

### Navigation

```bash
# Quick directory jumps
..              # cd ..
...             # cd ../..
....            # cd ../../..

# List files
ll              # ls -lah (detailed list)
la              # ls -A (show hidden)
```

### Network

```bash
# Quick IP check
myip            # Show public IP
localip         # Show local IP

# Port scanning
portscan <IP>   # Quick nmap scan
```

---

## 🔧 Terminal Shortcuts (Kitty)

| Shortcut | Action |
|----------|--------|
| `Ctrl + Shift + C` | Copy |
| `Ctrl + Shift + V` | Paste |
| `Ctrl + Shift + T` | New tab |
| `Ctrl + Shift + W` | Close tab |
| `Ctrl + Shift + →` | Next tab |
| `Ctrl + Shift + ←` | Previous tab |
| `Ctrl + Shift + +` | Increase font size |
| `Ctrl + Shift + -` | Decrease font size |
| `Ctrl + Shift + F11` | Toggle fullscreen |

---

## 💡 Pro Tips

### Hyprland Gestures

- **3-finger swipe horizontal**: Switch workspaces

### Waybar Modules

- **Click VPN module**: Toggle VPN status
- **Click Target module**: Show current target IP
- **Click Updates module**: Launch system update
- **Click Power button**: Open power menu (Lock/Sleep/Reboot/Shutdown/Logout)

### Custom Scripts Location

All custom scripts are located in `~/.config/bin/`:

- `wallpaper_switcher` - Cycle wallpapers
- `theme_selector` - Change Waybar themes
- `check_target_status.sh` - Display target IP
- `check_vpn_status.sh` - Display VPN status
- `power_menu.sh` - Power management menu

---

## 📋 Quick Reference Card

### Most Used (Top 10)

1. `Super + Return` - Terminal
2. `Super + D` - App launcher
3. `Super + Q` - Close window
4. `Super + L` - Lock screen
5. `Super + 1-5` - Switch workspace
6. `Super + Shift + B` - Brave browser
7. `Super + E` - Kate editor
8. `Print` - Screenshot
9. `Super + Alt + W` - Change wallpaper
10. `F12` - Quick browser

---

**Configuration Files**:

- Hyprland: `~/.config/hypr/hyprland.conf`
- Waybar: `~/.config/waybar/config.jsonc`
- ZSH: `~/.zshrc`
- Kitty: `~/.config/kitty/kitty.conf`

**Customize**: Edit `~/.config/hypr/hyprland.conf` to modify keybindings
