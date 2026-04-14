![BLACK-ICE ARCH Banner](images/banner.png)

# BLACK-ICE ARCH — Keyboard Shortcuts

> Referencia completa de keybinds Hyprland. Presiona **Win+I** para ver el Cheat Sheet interactivo.

---

## 🪟 Ventanas

| Shortcut | Acción |
|----------|--------|
| `Super + Enter` | Abrir terminal Kitty |
| `Super + Q` | Cerrar ventana activa |
| `Super + M` | Salir de Hyprland |
| `Super + V` | Toggle flotante |
| `Super + F` | Fullscreen (oculta barra) |
| `Super + Space` | Maximize (mantiene barra) |
| `Super + P` | Pseudo-tile mode |
| `Super + J` | Toggle dirección split |

---

## 🗂️ Workspaces

| Shortcut | Acción |
|----------|--------|
| `Super + 1…5` | Ir al workspace 1–5 |
| `Super + Alt + 1…5` | Mover ventana al WS 1–5 |
| `Super + ←↑↓→` | Mover foco entre ventanas |
| `Super + Mouse1 drag` | Mover ventana flotante |
| `Super + Mouse2 drag` | Redimensionar ventana |

---

## 🚀 Aplicaciones

| Shortcut | Aplicación |
|----------|-----------|
| `Super + D` | Wofi launcher (apps) |
| `Super + Shift + B` | Brave Browser |
| `Super + Shift + F` | Firefox |
| `Super + E` | Kate (editor) |
| `Super + Shift + T` | Kate (alternativo) |
| `Super + Shift + D` | Dolphin (archivos) |
| `Super + Shift + K` | KeePassXC |
| `Super + Shift + O` | Obsidian |
| `Super + Shift + E` | Betterbird (email) |
| `Super + Shift + M` | Music Player (ncmpcpp) |
| `F12` | Brave Browser (acceso rápido) |

---

## 🔧 Herramientas BLACK-ICE

| Shortcut | Herramienta |
|----------|------------|
| `Super + I` | **Cheat Sheet** (este overlay) |
| `Super + Tab` | **App Switcher** (wofi con ventanas abiertas) |
| `Super + Shift + X` | **Pass Menu** (KeePassXC CLI via wofi) |
| `Super + Ctrl + Enter` | **Terminal Manager** (sesiones Kitty multi-tab) |
| `Super + Shift + A` | Antigravity (editor IA) |
| `Super + Shift + C` | Caido (proxy web) |
| `Super + Shift + P` | Perfil de energía (menu) |
| `Super + H` | Portapapeles (cliphist via wofi) |
| `Super + L` | Bloquear pantalla (Hyprlock) |

---

## 🎨 Personalización

| Shortcut | Acción |
|----------|--------|
| `Super + Alt + T` | Selector de temas Waybar |
| `Super + Alt + R` | Estilo Wofi (4 estilos) |
| `Super + Alt + W` | Selector de wallpaper (waypaper) |
| `Super + Alt + F` | Toggle WiFi (nmcli) |

---

## 📸 Capturas de Pantalla

| Shortcut | Acción |
|----------|--------|
| `Print` | Región → Swappy (editor) |
| `Shift + Print` | Pantalla completa → Portapapeles |
| `Super + Print` | Región → `~/Pictures/Screenshots/` |
| `Ctrl + Print` | Pantalla completa → `~/Pictures/Screenshots/` |

---

## 🔊 Multimedia

| Shortcut | Acción |
|----------|--------|
| `XF86AudioRaiseVolume` | Volumen + (SwayOSD) |
| `XF86AudioLowerVolume` | Volumen - (SwayOSD) |
| `XF86AudioMute` | Mute/unmute salida |
| `F4 / XF86AudioMicMute` | Mute/unmute micrófono (wpctl) |
| `F10 / XF86AudioPlay` | Play/Pause (playerctl) |
| `F11 / XF86AudioStop` | Stop (playerctl) |
| `XF86AudioNext` | Siguiente pista |
| `XF86AudioPrev` | Pista anterior |
| `XF86MonBrightnessUp` | Brillo + (SwayOSD) |
| `XF86MonBrightnessDown` | Brillo - (SwayOSD) |
| `XF86WLAN / XF86RFKill` | Toggle WiFi |
| `XF86Display` | nwg-displays (monitor config) |

---

## 🖥️ Terminal Manager — Sesiones Kitty

Abrir con `Super + Ctrl + Enter`:

| Sesión | Tabs | Uso |
|--------|------|-----|
| **Pentesting** | 5 (Shell, Recon, Exploit, Monitor, Notas) | HTB / CTF |
| **Dev** | 4 (Editor nvim, Shell, Git, Docker) | Desarrollo |
| **SOC** | 5 (Logs, Network, Procesos, Forensics, Shell) | Análisis |
| Tab → Terminal | 1 | Shell rápido |
| Tab → Monitor | 1 | htop |
| Tab → Redes | 1 | `ip a / ss / tcpdump` |
| Tab → Logs | 1 | `journalctl -f` |

---

## 🔑 Pass Menu — KeePassXC CLI

Abrir con `Super + Shift + X`. Requiere `$KEEPASS_DB` en `.zshrc`:

```bash
export KEEPASS_DB="$HOME/Documents/passwords.kdbx"
export KEEPASS_KEY="$HOME/Documents/passwords.keyx"  # opcional
```

Acciones disponibles: copiar contraseña, copiar usuario, copiar TOTP, ver detalles.
El portapapeles se limpia automáticamente en 30 segundos.

---

## 🖱️ Kitty (Terminal)

| Shortcut | Acción |
|----------|--------|
| `Ctrl + Shift + C` | Copiar |
| `Ctrl + Shift + V` | Pegar |
| `Ctrl + Shift + F` | Toggle fullscreen |
| `Ctrl + Shift + U` | Insertar carácter Unicode |

---

## 🎯 ZSH — Aliases útiles

```bash
update          # Actualización completa (pacman + AUR)
cleanup         # Limpiar paquetes huérfanos y cache
sysinfo         # Info del sistema (fastfetch)
settarget <IP>  # Fijar target para HTB/CTF
myip            # IP pública
localip         # IP local
ll              # ls -lah
..  ...  ....   # cd .. / ../.. / ../../..
```

---

## 💡 Tips de Waybar

| Elemento | Acción |
|----------|--------|
| Módulo VPN | Click → toggle VPN |
| Módulo Target | Click → mostrar target IP |
| Módulo Updates | Click → actualizar sistema |
| Botón Power | Menú (Lock/Sleep/Reboot/Shutdown/Logout) |

---

## 📁 Archivos de configuración

| Archivo | Ruta |
|---------|------|
| Hyprland | `~/.config/hypr/hyprland.conf` |
| Waybar | `~/.config/waybar/themes/<Tema>/config.jsonc` |
| Kitty | `~/.config/kitty/kitty.conf` |
| ZSH | `~/.zshrc` |
| p10k | `~/.p10k.zsh` |
| Scripts | `~/.config/bin/` |
