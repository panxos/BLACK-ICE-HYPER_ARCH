# ⌨️ Keyboard Shortcuts - BLACK-ICE ARCH

Complete cheat sheet for all Hyprland keyboard shortcuts.

---

## 🎯 Essential Shortcuts

| Shortcut | Action | Description |
|----------|--------|-------------|
| `Super + Enter` | Open Terminal | Opens Kitty terminal |
| `Super + D` | Launcher | Opens Wofi (app launcher) |
| `Super + Q` | Close Window | Closes active window |
| `Super + L` | Lock Screen | Locks the session |
| `Super + V` | Floating | Toggle floating window |
| `Super + F` | Fullscreen | Toggle fullscreen |
| `Super + P` | Pseudo | Pseudo-tiling mode |
| `Super + X` | Power Menu | Opens wlogout |

---

## 🖥️ Terminal Manager — Multi-Tab Sessions

Open with `Super + Ctrl + Enter`:

| Session | Tabs | Use Case |
|---------|------|----------|
| **Pentesting** | Shell, Recon, Exploit, Monitor, Notes | HTB / CTF |
| **Dev** | nvim Editor, Shell, Git, Docker | Development |
| **SOC** | Logs, Network, Processes, Forensics, Shell | Analysis |
| Quick Terminal | 1 tab | Fast shell |
| Monitor | 1 tab | htop |
| Network | 1 tab | `ip a / ss / tcpdump` |
| Logs | 1 tab | `journalctl -f` |

---

## 🪟 Window Management

### Focus Movement

| Shortcut | Action |
|----------|--------|
| `Super + ←` | Focus left |
| `Super + →` | Focus right |
| `Super + ↑` | Focus up |
| `Super + ↓` | Focus down |
| `Super + H` | Focus left (vim) |
| `Super + L` | Focus right (vim) |
| `Super + K` | Focus up (vim) |
| `Super + J` | Focus down (vim) |

### Move Windows

| Shortcut | Action |
|----------|--------|
| `Super + Shift + ←` | Move window left |
| `Super + Shift + →` | Move window right |
| `Super + Shift + ↑` | Move window up |
| `Super + Shift + ↓` | Move window down |

### Resize Windows

| Shortcut | Action |
|----------|--------|
| `Super + Ctrl + ←` | Decrease width |
| `Super + Ctrl + →` | Increase width |
| `Super + Ctrl + ↑` | Decrease height |
| `Super + Ctrl + ↓` | Increase height |
| `Super + R` | Resize mode (use arrows) |

### Layouts

| Shortcut | Action |
|----------|--------|
| `Super + V` | Floating mode |
| `Super + F` | Fullscreen |
| `Super + P` | Pseudo-tiling |
| `Super + S` | Split toggle |

---

## 🗂️ Workspaces

### Switch Workspace

| Shortcut | Action |
|----------|--------|
| `Super + 1–9` | Go to workspace N |
| `Super + Tab` | Next workspace |
| `Super + Shift + Tab` | Previous workspace |

### Move Windows to Workspace

| Shortcut | Action |
|----------|--------|
| `Super + Shift + 1–9` | Move to workspace N |
| `Super + Grave` | Special workspace (scratchpad) |
| `Super + Shift + Grave` | Move to special workspace |

---

## 🚀 Applications

### Main Applications

| Shortcut | Application |
|----------|-------------|
| `Super + Enter` | Kitty Terminal |
| `Super + Ctrl + Enter` | Terminal Manager (multi-tab) |
| `Super + E` | Kate Editor |
| `Super + Shift + B` | Brave Browser |
| `Super + Shift + F` | Firefox |
| `Super + Shift + K` | KeePassXC |
| `Super + Shift + D` | Dolphin File Manager |
| `Super + Shift + C` | VS Code |

### System Tools

| Shortcut | Application |
|----------|-------------|
| `Super + D` | Wofi Launcher |
| `Super + X` | wlogout (Power menu) |
| `Super + Shift + R` | Reload Hyprland config |

### Pentesting Shortcuts

| Shortcut | Tool |
|----------|------|
| `Super + Ctrl + N` | nmap (terminal) |
| `Super + Ctrl + B` | Burp Suite |
| `Super + Ctrl + W` | Wireshark |
| `Super + Ctrl + M` | Metasploit (terminal) |

> **Note**: These shortcuts can be customized in `~/.config/hypr/hyprland.conf`

---

## 📸 Screenshots

| Shortcut | Action |
|----------|--------|
| `Print` | Region screenshot (clipboard) |
| `Shift + Print` | Full screen screenshot (clipboard) |
| `Super + Print` | Region screenshot (save file) |
| `Ctrl + Print` | Full screen screenshot (save file) |
| `Alt + Print` | Active window screenshot |

**Screenshot location**: `~/Pictures/Screenshots/`

---

## 🎵 Multimedia

### Playback Control

| Shortcut | Action |
|----------|--------|
| `F10` | Play/Pause |
| `F11` | Stop |
| `F9` | Previous track |
| `F12` | Next track |

### Volume Control

| Shortcut | Action |
|----------|--------|
| `XF86AudioRaiseVolume` | Volume up |
| `XF86AudioLowerVolume` | Volume down |
| `XF86AudioMute` | Mute/Unmute |
| `Shift + XF86AudioRaiseVolume` | Volume +10% |
| `Shift + XF86AudioLowerVolume` | Volume -10% |

### Screen Brightness

| Shortcut | Action |
|----------|--------|
| `XF86MonBrightnessUp` | Increase brightness |
| `XF86MonBrightnessDown` | Decrease brightness |

---

## 🎨 Customization

### Themes & Wallpapers

| Shortcut | Action |
|----------|--------|
| `Super + Alt + W` | Change wallpaper |
| `Super + Alt + T` | Change theme |
| `Super + Alt + R` | Random wallpaper |

### Waybar

| Shortcut | Action |
|----------|--------|
| `Super + B` | Toggle Waybar |
| `Super + Shift + B` | Reload Waybar |

---

## 🖱️ Mouse

| Action | Result |
|--------|--------|
| `Super + Left Click` | Move window |
| `Super + Right Click` | Resize window |
| `Super + Scroll` | Change workspace |

### Touchpad Gestures

| Gesture | Action |
|---------|--------|
| `3 fingers up` | Previous workspace |
| `3 fingers down` | Next workspace |

---

## 📝 Terminal (Kitty) Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl + Shift + C` | Copy |
| `Ctrl + Shift + V` | Paste |
| `Ctrl + Shift + T` | New tab |
| `Ctrl + Shift + W` | Close tab |
| `Ctrl + Shift + →` | Next tab |
| `Ctrl + Shift + ←` | Previous tab |
| `Ctrl + Shift + F` | Search |

---

## 🔄 Customizing Shortcuts

Edit `~/.config/hypr/hyprland.conf`:

```bash
# General format
bind = MODIFIERS, KEY, ACTION, PARAMS

# Examples
bind = SUPER, Return, exec, kitty
bind = SUPER SHIFT, Q, killactive
bind = SUPER, 1, workspace, 1
bind = SUPER CTRL, T, exec, thunar
```

Reload after changes:
```bash
hyprctl reload
```

---

## 💡 Tips

1. **Print this cheat sheet** — keep it handy while learning
2. **Start with essential shortcuts** before memorizing the advanced ones
3. **Run `hyprctl binds`** to see all active shortcuts at any time
4. **Use `Super + D`** (Wofi) if you forget a shortcut

---

<div align="center">

**[🏠 Back to Wiki](Home.md)** | **[🎨 Customization →](Customization.md)**

</div>
