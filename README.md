<div align="center">

![BLACK-ICE ARCH Banner](docs/images/banner.png)

# 🧊 BLACK-ICE ARCH

### Instalación Automatizada de Arch Linux con Hyprland y Herramientas de Ciberseguridad

[![License: MIT](https://img.shields.io/badge/License-MIT-cyan.svg)](LICENSE)
[![Arch Linux](https://img.shields.io/badge/Arch-Linux-1793D1?logo=arch-linux&logoColor=fff)](https://archlinux.org/)
[![Hyprland](https://img.shields.io/badge/Hyprland-v0.54+-00FFFF)](https://hyprland.org/)
[![Version](https://img.shields.io/badge/Version-3.5.0-neon.svg)](https://github.com/panxos/BLACK-ICE-HYPER_ARCH)

**🇪🇸 Español | [🇬🇧 English](README.en.md)**

---

### 🚀 Instalación en Un Comando

```bash
curl -L http://is.gd/blackice | bash
```

</div>

---

## 📋 Tabla de Contenidos

- [Descripción](#-descripción)
- [Arquitectura de Dos Fases](#-arquitectura-de-dos-fases)
- [Características — Fase 1: Sistema Base](#-características--fase-1-sistema-base)
- [Características — Fase 2: Entorno de Escritorio](#-características--fase-2-entorno-de-escritorio)
- [Herramientas de Seguridad](#-herramientas-de-seguridad)
- [Temas Waybar](#-temas-waybar-21-temas)
- [Galería de Escritorios](#️-galería-de-escritorios)
- [Requisitos del Sistema](#-requisitos-del-sistema)
- [Instalación Rápida](#-instalación-rápida)
- [Instalación Manual](#-instalación-manual)
- [Configuración Desatendida](#-configuración-desatendida)
- [Atajos de Teclado](#️-atajos-de-teclado)
- [Personalización](#-personalización)
- [Solución de Problemas](#-solución-de-problemas)
- [Estructura del Repositorio](#-estructura-del-repositorio)
- [Documentación](#-documentación)
- [Créditos](#-créditos)
- [Licencia](#-licencia)

---

## 🎯 Descripción

**BLACK-ICE ARCH** es un sistema de despliegue automatizado de dos fases para Arch Linux, diseñado específicamente para **profesionales de Ciberseguridad** y **Pentesters**. Transforma una ISO mínima de Arch en una workstation Hyprland completamente configurada, hardened y lista para auditorías de seguridad.

### ¿Por qué BLACK-ICE ARCH?

- ⚡ **Instalación en un comando** desde la LiveCD
- 🎨 **Estética cyberpunk** con 21 temas Waybar intercambiables en vivo
- 🛡️ **+100 herramientas de seguridad** organizadas en 10 categorías
- 🔒 **Cifrado LUKS2** completo soportado desde la instalación base
- 🚀 **Detección automática de hardware** — CPU, GPU, virtualización
- 🤖 **Herramientas IA integradas** — Claude Code, Gemini CLI
- 📦 **Completamente automatizado** con modo desatendido disponible

---

## 🏗️ Arquitectura de Dos Fases

```
ARCH LINUX ISO (LiveCD)
        │
        ▼
┌─────────────────────────────────────────┐
│  FASE 1 — install.sh                    │
│  src/modules/ (00→06, 99)               │
│  Sistema base, disco, cifrado, kernel   │
│  → Primer reboot                        │
└─────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────┐
│  FASE 2 — deploy_hyprland.sh            │
│  src/deploy/ (00→09, 99)                │
│  Entorno de escritorio, herramientas,   │
│  temas, IA, dotfiles                    │
└─────────────────────────────────────────┘
```

---

## ⚙️ Características — Fase 1: Sistema Base

### Detección y Particionado de Disco

- Soporte completo: SATA (`/dev/sdX`), NVMe, VirtIO (KVM), Xen, eMMC
- Particionado automático UEFI/BIOS con detección del modo de arranque
- **LUKS2** cifrado completo de disco con PBKDF2 — contraseña solicitada interactivamente desde `/dev/tty`
- Sistemas de archivos soportados: **btrfs** (con snapshots), **ext4**, **xfs**, **f2fs**

### Kernel y Microcódigo

- Selección interactiva: `linux`, `linux-zen` (gaming/rendimiento), `linux-hardened` (seguridad)
- Auto-detección CPU Intel/AMD → instala `intel-ucode` o `amd-ucode` automáticamente

### Configuración del Sistema

- Locale, timezone, hostname y distribución de teclado configurables
- Creación de usuario con validación de credenciales
- GRUB con soporte LUKS + **tema DedSec** (estilo Watch Dogs)
- Recovery mode automático si se detecta instalación previa de BLACK-ICE

### Gestión de Energía

- Detección automática de entorno: Laptop → TLP + perfiles dinámicos, Desktop/VM → CPUpower rendimiento
- NVMe APST, thermald (Intel físico), lm_sensors, acpid

---

## 🖥️ Características — Fase 2: Entorno de Escritorio

### Compositor y Desktop

- **Hyprland v0.54+** — compositor Wayland con animaciones suaves, soporte multi-monitor y multi-workspace
- **Waybar** — barra de estado completamente customizable con 21 temas cyberpunk
- **SDDM** — gestor de inicio con tema CyberSec personalizado
- **Kitty** — terminal GPU-acelerado con 21 esquemas de color coordinados con los temas Waybar
- **Wofi** — lanzador de aplicaciones Wayland con 4 estilos intercambiables (`Super+Alt+R`)
- **SwayNC** — centro de notificaciones con tema dark
- **wlogout** — menú de cierre de sesión con animaciones fadeIn y hover glow

### Shells y Terminal

- **Zsh** + Oh-My-Zsh + **Powerlevel10k** con segmento SSH personalizado
- **fzf-tab** — completado interactivo con previews (ls, bat, kill)
- Aliases modernos: `lsd` (ls), `bat` (cat), xclip integrado
- `tech_quotes.sh` — citas técnicas aleatorias al abrir terminal

### Editor

- **Neovim** con **NvChad** + LazyVim + LSP configurado
- `git clone --depth=1` para instalación eficiente

### Música

- **MPD** + **ncmpcpp** — reproductor de música local con servicio systemd --user
- **Eww Music Widget** (`Win+Shift+N`) — widget flotante 380×115px top-right con álbum art, barra de progreso interactiva, controles prev/play-pause/next, shuffle y loop
- Alimentado por **playerctl/MPRIS**, CSS cyberpunk completo

### AUR y Repositorios

- **paru** desde chaotic-aur (binario compilado contra el pacman del sistema, nunca se rompe tras `pacman -Syu`)
- Chaotic-AUR habilitado por defecto
- `safe_install` — helper resiliente con detección de ABI mismatch y fallback automático a pacman

### Herramientas BLACK-ICE Integradas

| Script | Atajo | Descripción |
|--------|-------|-------------|
| `cheatsheet` | `Super+I` | Overlay GTK3 fullscreen con todos los atajos, 3 columnas |
| `app_switcher` | `Super+Tab` | Switcher de ventanas via Wofi con íconos Nerd Font |
| `pass_menu` | `Super+Shift+X` | KeePassXC CLI + Wofi — contraseña/usuario/TOTP, auto-limpia en 30s |
| `terminal_manager` | `Super+Ctrl+Enter` | Sesiones Kitty multi-tab (Pentesting/Dev/SOC) |
| `theme_selector` | `Super+Alt+T` | Selector visual de temas Waybar con thumbnails |
| `wallpaper_visual` | `Super+Alt+W` | Selector de wallpapers waypaper GUI |
| `wofi_style_selector` | `Super+Alt+R` | Selector de estilo Wofi (4 estilos) |
| `wifi_toggle` | `Super+Alt+F` | Toggle WiFi nmcli con notificación swaync |
| `power_profile_menu` | `Super+Shift+P` | Menú de perfil de energía |
| `gh0stzk-walls` | CLI | Descarga wallpapers de gh0stzk (`--all`, `--theme`, `--list`) |
| `xdg-open-wayland` | auto | Wrapper xdg-open para OAuth en Wayland (gemini-cli) |
| `docker_menu` / `kvm_menu` | CLI | Menús de gestión Docker y KVM vía Wofi |
| `htb-connect` / `htb-disconnect` | CLI | VPN HackTheBox integrada |

### Herramientas de IA

- **Claude Code CLI** (`@anthropic-ai/claude-code`) — via npm global
- **Gemini CLI** (`@google/gemini-cli`) — via npm global
- Aliases de actualización en Zsh: `claudeupdate`, `geminiupdate`

### Integración Pywal

- `theme_selector` ejecuta `wal -i <wallpaper> -n` al cambiar tema
- Paleta generada del wallpaper activo → aplicada a Kitty via socket (`kitty @ set-colors`) + SIGUSR1
- 21 temas `.conf` manuales por tema Waybar en `dotfiles/kitty/themes/`

---

## 🛡️ Herramientas de Seguridad

**+100 herramientas organizadas en 10 categorías, con instalador whiptail interactivo:**

| Categoría | Herramientas destacadas |
|-----------|------------------------|
| 🔍 **Reconocimiento** | nmap, masscan, rustscan, recon-ng, theHarvester, amass, spiderfoot, sherlock |
| 🌐 **Web Hacking** | burpsuite, zaproxy, sqlmap, nikto, gobuster, ffuf, wfuzz, feroxbuster, wpscan |
| 📡 **Wireless** | aircrack-ng, kismet, wifite, reaver, bully, pixiewps |
| 🪟 **Windows/AD** | impacket, netexec, bloodhound, evil-winrm, certipy, smbmap, neo4j |
| 🔐 **Cracking** | john, hashcat, hydra, medusa, seclists, rockyou |
| 💥 **Explotación** | metasploit, searchsploit, villain, SET, exploitdb |
| 🕵️ **Sniffing/MITM** | wireshark, tcpdump, ettercap, bettercap, mitmproxy |
| 🔧 **Ingeniería Inversa** | gdb, radare2, ghidra, apktool, jadx, dex2jar |
| 🔬 **Forense Digital** | autopsy, volatility3, binwalk, foremost, steghide, stegseek, exiftool |
| 🌐 **Redes/Tunneling** | proxychains, chisel, sshuttle, socat, minicom, snmpcheck |

### Modos del Instalador

- **Suite Estándar** (recomendada) — todo sin paquetes pesados, instalación rápida
- **Selección personalizada** — checklist whiptail, ESPACIO para marcar/desmarcar
- **Suite Completa** — incluye bloodhound (~60min), ghidra (~20min), autopsy (~20min)
- **Modo desatendido** (`AUTO_MODE=true`) — instala Suite Estándar sin preguntas

---

## 🎨 Temas Waybar (21 Temas)

Cambia entre temas en tiempo real con `Super+Alt+T`. El selector actualiza automáticamente Waybar, Hyprland borders, colores de Hyprlock y paleta de Kitty.

| Tema | Estilo |
|------|--------|
| **Horus-Cyber** | Cyberpunk cyan/purple — tema por defecto |
| **H4k3r-HTB** | HackTheBox green, compact pill-right |
| **Matrix-Hacker** | Matrix green rain aesthetic |
| **Jan-CyberPunk** | CyberPunk magenta, floating pills |
| **Janis-CyberMagenta** | Magenta vibrante |
| **s4vitar-darkness** | Doble barra oscura — tributo a s4vitar |
| **Emilia-TokyoNight** | Tokyo Night blue/purple |
| **Marisol-Dracula** | Dracula purple |
| **Isabel-Frappe** | Catppuccin Frappé |
| **Daniela-Catppuccin** | Catppuccin Mocha |
| **Melissa-Nord** | Nord minimalista |
| **Silvia-Gruvbox** | Gruvbox warm |
| **Brenda-Everforest** | Everforest green |
| **Karla-ZombieNight** | ZombieNight dark |
| **Zombie-Decay** | Decay oscuro |
| **Pamela-Lovelace** | Lovelace pastel |
| **Varinka-Mono** | Monochrome, módulos en caja |
| **Yael-OxoCarbon** | OxoCarbon fullwidth slim |
| **Anubis-Death** | Death black/red |
| **Isis-Magic** | Magic purple/gold |
| **Ra-Solar** | Solar orange/gold |

---

## 🖼️ Galería de Escritorios

> Cambia entre temas en tiempo real con `Super+Alt+T` (selector visual con thumbnails)

| | | |
|:---:|:---:|:---:|
| ![Horus-Cyber](dotfiles/waybar/themes/Horus-Cyber/preview.png) | ![H4k3r-HTB](dotfiles/waybar/themes/H4k3r-HTB/preview.png) | ![Matrix-Hacker](dotfiles/waybar/themes/Matrix-Hacker/preview.png) |
| **Horus-Cyber** | **H4k3r-HTB** | **Matrix-Hacker** |
| ![Jan-CyberPunk](dotfiles/waybar/themes/Jan-CyberPunk/preview.png) | ![Janis-CyberMagenta](dotfiles/waybar/themes/Janis-CyberMagenta/preview.png) | ![s4vitar-darkness](dotfiles/waybar/themes/s4vitar-darkness/preview.png) |
| **Jan-CyberPunk** | **Janis-CyberMagenta** | **s4vitar-darkness** |
| ![Emilia-TokyoNight](dotfiles/waybar/themes/Emilia-TokyoNight/preview.png) | ![Marisol-Dracula](dotfiles/waybar/themes/Marisol-Dracula/preview.png) | ![Isabel-Frappe](dotfiles/waybar/themes/Isabel-Frappe/preview.png) |
| **Emilia-TokyoNight** | **Marisol-Dracula** | **Isabel-Frappe** |
| ![Daniela-Catppuccin](dotfiles/waybar/themes/Daniela-Catppuccin/preview.png) | ![Melissa-Nord](dotfiles/waybar/themes/Melissa-Nord/preview.png) | ![Silvia-Gruvbox](dotfiles/waybar/themes/Silvia-Gruvbox/preview.png) |
| **Daniela-Catppuccin** | **Melissa-Nord** | **Silvia-Gruvbox** |
| ![Brenda-Everforest](dotfiles/waybar/themes/Brenda-Everforest/preview.png) | ![Karla-ZombieNight](dotfiles/waybar/themes/Karla-ZombieNight/preview.png) | ![Zombie-Decay](dotfiles/waybar/themes/Zombie-Decay/preview.png) |
| **Brenda-Everforest** | **Karla-ZombieNight** | **Zombie-Decay** |
| ![Pamela-Lovelace](dotfiles/waybar/themes/Pamela-Lovelace/preview.png) | ![Varinka-Mono](dotfiles/waybar/themes/Varinka-Mono/preview.png) | ![Yael-OxoCarbon](dotfiles/waybar/themes/Yael-OxoCarbon/preview.png) |
| **Pamela-Lovelace** | **Varinka-Mono** | **Yael-OxoCarbon** |
| ![Anubis-Death](dotfiles/waybar/themes/Anubis-Death/preview.png) | ![Isis-Magic](dotfiles/waybar/themes/Isis-Magic/preview.png) | ![Ra-Solar](dotfiles/waybar/themes/Ra-Solar/preview.png) |
| **Anubis-Death** | **Isis-Magic** | **Ra-Solar** |

---

## 💻 Requisitos del Sistema

| Componente | Mínimo | Recomendado |
|-----------|--------|-------------|
| **CPU** | Dual Core 64-bit | Quad Core+ |
| **RAM** | 4 GB | 16 GB+ |
| **Almacenamiento** | 20 GB SSD | 100 GB NVMe |
| **GPU** | Integrada | AMD/NVIDIA dedicada |
| **Red** | WiFi/Ethernet | Ethernet cableado |
| **Modo de arranque** | UEFI (recomendado) o BIOS | UEFI |

---

## 🚀 Instalación Rápida

### Desde la LiveCD de Arch Linux

```bash
# Opción 1: URL corta
curl -L http://is.gd/blackice | bash

# Opción 2: URL alternativa
curl -L https://cutt.ly/blackice | bash

# Opción 3: URL completa
curl -L https://raw.githubusercontent.com/panxos/BLACK-ICE-HYPER_ARCH/main/bootstrap.sh | bash
```

El bootstrap hace automáticamente:
1. Verificar conexión a Internet y entorno Arch
2. Instalar git
3. Clonar el repositorio en `/tmp/black-ice-arch`
4. Configurar permisos
5. Lanzar `install.sh` interactivo

---

## 📦 Instalación Manual

### Fase 1 — Desde la LiveCD (como root)

```bash
# Conectar a internet (WiFi)
iwctl
station wlan0 connect "TU_RED"
exit

# Clonar e instalar
pacman -Sy git
git clone https://github.com/panxos/BLACK-ICE-HYPER_ARCH.git
cd BLACK-ICE-HYPER_ARCH
chmod +x install.sh
./install.sh
```

El instalador guía por: disco → cifrado LUKS → filesystem → kernel → locale → usuario → bootloader.

### Fase 2 — Después del primer reboot (como usuario normal)

```bash
cd BLACK-ICE-HYPER_ARCH
./deploy_hyprland.sh
```

El deploy instala: repositorios AUR → Hyprland + desktop → herramientas de seguridad → terminal/shell → temas → software opcional → SDDM → Neovim → IA CLIs → dotfiles.

---

## 🔧 Configuración Desatendida

Copia `config/install.conf.example` a `config/install.conf` y ajusta las variables:

```bash
TARGET_DISK=sda          # Disco destino (sin /dev/)
ENABLE_LUKS=yes          # Cifrado LUKS2
FILESYSTEM=btrfs         # btrfs | ext4 | xfs | f2fs
KERNEL=linux             # linux | linux-zen | linux-hardened
USERNAME=usuario         # Nombre de usuario
TIMEZONE=America/Santiago
AUTO_MODE=true           # Omitir todas las preguntas interactivas
```

**Nunca commitear `install.conf` con contraseñas reales.**

---

## ⌨️ Atajos de Teclado

### Ventanas y Sistema

| Atajo | Acción |
|-------|--------|
| `Super + Enter` | Terminal (Kitty) |
| `Super + D` | Lanzador de apps (Wofi) |
| `Super + Q` | Cerrar ventana |
| `Super + M` | Salir de Hyprland |
| `Super + L` | Bloquear pantalla (Hyprlock) |
| `Super + V` | Toggle flotante |
| `Super + F` | Fullscreen |
| `Super + H` | Portapapeles (cliphist) |

### Aplicaciones

| Atajo | Acción |
|-------|--------|
| `Super + Shift + B` | Brave Browser |
| `Super + Shift + F` | Firefox |
| `Super + E` | Kate Editor |
| `Super + Shift + D` | Dolphin (archivos) |
| `Super + Shift + K` | KeePassXC |
| `Super + Shift + M` | Music Player (ncmpcpp) |
| `Super + Shift + N` | Eww Music Widget toggle |

### Herramientas BLACK-ICE

| Atajo | Acción |
|-------|--------|
| `Super + I` | Cheat Sheet interactivo (overlay) |
| `Super + Tab` | App Switcher (ventanas abiertas) |
| `Super + Shift + X` | Pass Menu (KeePassXC CLI) |
| `Super + Ctrl + Enter` | Terminal Manager (sesiones multi-tab) |
| `Super + Shift + P` | Menú de perfil de energía |

### Personalización

| Atajo | Acción |
|-------|--------|
| `Super + Alt + T` | Selector de tema Waybar (con thumbnails) |
| `Super + Alt + W` | Selector visual de wallpapers |
| `Super + Alt + R` | Selector de estilo Wofi |
| `Super + Alt + F` | Toggle WiFi |

### Capturas de Pantalla

| Atajo | Acción |
|-------|--------|
| `Print` | Región → Swappy (editor) |
| `Shift + Print` | Pantalla completa → portapapeles |
| `Super + Print` | Región → `~/Pictures/Screenshots/` |
| `Ctrl + Print` | Pantalla completa → `~/Pictures/Screenshots/` |

### Multimedia

| Atajo | Acción |
|-------|--------|
| `F10 / XF86AudioPlay` | Play/Pause (playerctl) |
| `F11 / XF86AudioStop` | Stop |
| `F4 / XF86AudioMicMute` | Mute micrófono (wpctl, PipeWire nativo) |
| `XF86AudioRaiseVolume` | Volumen + (SwayOSD) |
| `XF86AudioLowerVolume` | Volumen - (SwayOSD) |
| `XF86MonBrightnessUp/Down` | Brillo ± (SwayOSD) |

**[Cheat Sheet completo](docs/KEYBOARD_SHORTCUTS.md)**

---

## 🎨 Personalización

### Cambiar Tema Waybar

```bash
# Selector visual con thumbnails
Super + Alt + T

# Script directo
~/.local/bin/theme_selector
```

El selector actualiza en tiempo real: Waybar, borde Hyprland, colores Hyprlock y paleta Kitty.

### Cambiar Wallpaper

```bash
# Selector visual waypaper
Super + Alt + W

# Script directo
~/.local/bin/wallpaper_visual

# Descargar wallpapers de gh0stzk
~/.local/bin/gh0stzk-walls --all
~/.local/bin/gh0stzk-walls --theme Horus-Cyber
~/.local/bin/gh0stzk-walls --list
```

### Estilos Wofi

```bash
Super + Alt + R   # Selector entre 4 estilos: default, minimal, fullscreen, grid
```

---

## 🔧 Solución de Problemas

**Waybar no carga o da errores:**
```bash
killall waybar; sleep 1 && waybar &
journalctl --user -u waybar -n 50
```

**paru roto tras actualización del sistema:**
```bash
sudo pacman -Rns paru paru-bin 2>/dev/null
sudo pacman -S paru  # reinstala desde chaotic-aur
```

**SDDM no inicia:**
```bash
sudo systemctl enable --now sddm
```

**Plymouth no activa en el boot:**
```bash
grep "plymouth" /etc/mkinitcpio.conf  # debe aparecer en HOOKS
sudo mkinitcpio -P                     # regenerar initramfs
```

**Teclado incorrecto en prompt LUKS:**
```bash
cat /etc/vconsole.conf  # verifica KEYMAP=<tu_layout>
sudo mkinitcpio -P      # regenerar initramfs con el keymap correcto
```

**Música no reproduce (MPD):**
```bash
systemctl --user status mpd
systemctl --user enable --now mpd
```

---

## 📁 Estructura del Repositorio

```
BLACK-ICE_ARCH/
├── install.sh              # Punto de entrada Fase 1 (LiveCD root)
├── deploy_hyprland.sh      # Punto de entrada Fase 2 (usuario normal)
├── bootstrap.sh            # One-liner curl | bash
├── config/
│   └── install.conf.example
├── src/
│   ├── lib/
│   │   ├── colors.sh       # Variables ANSI de color
│   │   ├── logging.sh      # log_info/warn/error/success, banner
│   │   └── utils.sh        # check_root, retry_command, safe_install
│   ├── modules/            # Fase 1: 00_environment → 99_final
│   └── deploy/             # Fase 2: 00_repositories → 99_finalization
├── dotfiles/
│   ├── hypr/               # hyprland.conf, hyprlock.conf, monitors.conf
│   ├── waybar/             # config.jsonc, style.css, themes/ (21 temas)
│   ├── kitty/              # kitty.conf, themes/ (21 esquemas)
│   ├── wofi/               # config, styles/ (4 estilos)
│   ├── swaync/             # config.json, style.css
│   ├── wlogout/            # layout, style.css
│   └── bin/                # Scripts: theme_selector, wallpaper_visual, etc.
├── tests/
│   ├── pre-install-check.sh
│   └── post-install-validate.sh
└── docs/
    ├── ARCHITECTURE.md
    ├── SECURITY.md
    ├── MODULES.md
    ├── TOOLS_CATALOG.md
    ├── KEYBOARD_SHORTCUTS.md
    └── BLACK-ICE_CheatSheet.md
```

---

## 📚 Documentación

| Documento | Descripción |
|-----------|-------------|
| **[CHANGELOG.md](CHANGELOG.md)** | Historial de versiones |
| **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** | Arquitectura del sistema |
| **[docs/SECURITY.md](docs/SECURITY.md)** | Análisis de seguridad y hardening |
| **[docs/MODULES.md](docs/MODULES.md)** | Documentación de módulos |
| **[docs/TOOLS_CATALOG.md](docs/TOOLS_CATALOG.md)** | Catálogo completo de herramientas |
| **[docs/KEYBOARD_SHORTCUTS.md](docs/KEYBOARD_SHORTCUTS.md)** | Referencia completa de atajos |
| **[docs/BLACK-ICE_CheatSheet.md](docs/BLACK-ICE_CheatSheet.md)** | Cheat Sheet imprimible |
| **[CREDITS.md](CREDITS.md)** | Créditos y agradecimientos |

---

## 🙏 Créditos

- **[s4vitar](https://www.youtube.com/@s4vitar)** — Inspiración principal en workflow, estética de terminal y cultura de pentesting profesional. El tema `s4vitar-darkness` es un tributo directo a su icónico setup de doble barra.
- **[gh0stzk](https://github.com/gh0stzk/dotfiles)** — Inspiración para los temas Jan-CyberPunk, Emilia-TokyoNight, Marisol-Dracula y Melissa-Nord. Script `gh0stzk-walls` integrado con crédito explícito.
- **[VandalByte](https://github.com/VandalByte/dedsec-grub2-theme)** — Tema GRUB2 DedSec (GPL-3.0).
- [Hyprland](https://hyprland.org/) — Compositor Wayland de próxima generación.
- [Arch Linux](https://archlinux.org/) — La distribución Linux de referencia.
- [Sweet Theme](https://github.com/EliverLara/Sweet) — Tema GTK Sweet-Dark.

> Créditos completos: ver [CREDITS.md](CREDITS.md)

---

## 📄 Licencia

MIT License — ver [LICENSE](LICENSE)

---

## 👤 Autor

**Francisco Aravena (P4nX0Z)**

- Analista de Ciberseguridad | 15+ años en TI y seguridad
- 🌐 [soporteinfo.net](https://www.soporteinfo.net)
- 💼 [linkedin.com/in/faravena](https://www.linkedin.com/in/faravena/)
- 📺 [youtube.com/@Soporteinfo](https://www.youtube.com/@Soporteinfo)
- 🐙 [github.com/panxos](https://github.com/panxos)

---

<div align="center">

**⭐ Si te gusta el proyecto, dale una estrella en GitHub ⭐**

**[🇬🇧 Read in English](README.en.md)**

Hecho con ❤️ para la Comunidad de Ciberseguridad

</div>
