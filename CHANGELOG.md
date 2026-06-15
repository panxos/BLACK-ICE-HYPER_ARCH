# CHANGELOG - BLACK-ICE ARCH

## [3.11.1] - 2026-06-15

### 🛠️ Fixes

- **Dolphin file associations rotas en Hyprland** (`99_finalization.sh`, `startup.sh`): `kbuildsycoca6` busca `/etc/xdg/menus/applications.menu` para indexar apps. `plasma-desktop` provee `plasma-applications.menu` pero no el alias. Sin el symlink, `KApplicationTrader` retorna vacío → doble clic en cualquier archivo muestra dialog "Open With" vacío, ignorando `mimeapps.list`. Fix: symlink `applications.menu → plasma-applications.menu` en `/etc/xdg/menus/` durante la instalación + `kbuildsycoca6 &` en `startup.sh` para mantener el cache actualizado en cada sesión.

---

## [3.11.0] - 2026-06-03 (P4nx0z "Themes" Edition)

### 🎨 Waybar — Port Completo desde gh0stzk/BSPWM a Hyprland

- **6 arquetipos visuales genuinamente distintos** portados desde las rices BSPWM de gh0stzk:
  - **Solid Full** (H4k3r-HTB, Matrix-Hacker, Anubis-Death, Marisol-Dracula): barra sólida extremo a extremo, 26-28px, accent line en borde superior/inferior
  - **Solid Tall** (Daniela-Catppuccin, Silvia-Gruvbox, Isabel-Frappe, Isis-Magic): gradient top→bottom, 34-36px — visualmente más alta
  - **Floating Pill** (Emilia-TokyoNight 90%, Melissa-Nord 92%, Jan-CyberPunk 88%): barra centrada que NO toca los bordes, `border-radius` en `window#waybar`, box-shadow
  - **Framed** (Janis-CyberMagenta 95%, s4vitar-darkness 82%, Brenda-Everforest 97%): borde sólido alrededor del bar, s4vitar la más estrecha (82% = 1120px centrados)
  - **Module Pills** (Pamela-Lovelace, Karla-ZombieNight, Zombie-Decay, Varinka-Mono): fondo transparente, cada módulo con su propio background redondeado
  - **Grouped Sections** (Ra-Solar, Yael-OxoCarbon): left/center/right agrupados en contenedores propios con border-radius

- **config.jsonc diferenciado por tema**: `width`, `height`, `margin-left`, `margin-right` varían por tema. Ya no todos comparten height=22. Rango: 24-36px. Barras flotantes con margin calculado de `(1366 - width_px) / 2`.

- **CSS sin colores hex de 8 dígitos** (`#rrggbbaa`): todos los alpha channels usan `rgba(r,g,b,a)` — compatible GTK3.

- **21 previews 800×450 regenerados**: composite crop que amplifica las barras (40px crop → 60px rendered) para que sean visibles en el selector.

- **Módulos idénticos a Horus-Cyber** en todos los temas: `hardware_temp`, `cpu`, `memory`, `disk`, `vpn`, `workspaces`, `settarget`, `pulseaudio`, `power`, `docker`, `kvm`, `updates`, `local_ip`, `public_ip`, `player`, `battery`, `clock`, `tray`.

- **Horus-Cyber no modificado** (tema activo, intocable).

### 📁 Archivos Modificados

- `dotfiles/waybar/themes/*/config.jsonc` — todos excepto Horus-Cyber
- `dotfiles/waybar/themes/*/style.css` — todos excepto Horus-Cyber
- `dotfiles/waybar/themes/*/preview.png` — regenerados para todos
- `dotfiles/waybar/themes/Horus-Cyber/config.jsonc` — height 22→24, remove network, wofi GTK_THEME
- `src/lib/logging.sh` — versión → 3.11.0

## [3.10.0] - 2026-06-03 (P4nx0z "Spectre" Edition)

### 🚀 Novedades

- **Workspaces estilo Pacman en Emilia-TokyoNight**: Íconos cambiados a `ᗧ` (activo, amarillo) / `·` (inactivo) / `ᗣ` (urgente, cyan). Elimina los Nerd Font icons `󰊯`/`󰾭` que renderizaban como manchas naranjas en fonts sin parche completo.
- **VLC soporte completo de codecs**: Se agregan `vlc-plugin-ffmpeg` (H264/H265/MPEG4 via libavcodec), `vlc-plugin-ass` (subtítulos) y `vlc-plugin-dvd` al módulo Multimedia. Sin esto VLC reportaba "codec no soportado" para la mayoría de archivos de video comunes.
- **`imv` como visor de imágenes predeterminado**: Reemplaza `nomacs` (no empaquetado en repos Arch estándar). Visor nativo Wayland, liviano y soporte completo de formatos (jpeg, png, gif, webp, avif, heic).
- **`mimeapps.list` completo incluido**: Archivo de asociaciones de archivos instalado por `99_finalization.sh`. Cubre video, audio, imágenes, documentos office, archivos comprimidos, código fuente, PDF, email, directorios y esquemas URL. Elimina el problema de "abrir con" sin app por defecto.
- **`waypaper` con `subfolders=True`**: Todos los wallpapers en subdirectorios (ej. `~/Pictures/wallpapers/gh0stzk/`) son visibles y seleccionables.

### 🛠️ Fixes

- **Waybar workspace icons renderizaban mal**: Los íconos Nerd Font de 4 bytes (`U+F0000+`) fallan en fonts sin parche completo. Solución: caracteres Unicode estándar para Pacman style.
- **VLC "codec no soportado"**: VLC 3.0+ está modularizado en Arch — `vlc` base no incluye el plugin ffmpeg. Se debe instalar `vlc-plugin-ffmpeg` explícitamente.
- **mimeapps.list referenciaba `org.nomacs.ImageLounge.desktop`** (no instalado): causaba "no hay app para abrir este archivo" en imágenes.

### 📁 Archivos Modificados

- `dotfiles/waybar/themes/Emilia-TokyoNight/config.jsonc` — íconos workspace Pacman
- `dotfiles/waybar/themes/Emilia-TokyoNight/style.css` — CSS Pacman (color amarillo activo, cyan urgente)
- `dotfiles/mimeapps.list` — nuevo archivo, asociaciones completas
- `src/deploy/05_software_suite.sh` — agrega `vlc-plugin-ffmpeg`, `vlc-plugin-ass`, `vlc-plugin-dvd`, `imv`
- `src/deploy/99_finalization.sh` — instala `mimeapps.list` en `~/.config/`

## [3.9.0] - 2026-05-28 (P4nx0z "Obsidian" Edition)

### 🚀 Novedades

- **MEGAsync Hyprland fix**: `megasync-watcher.sh` + `megasync-watcher.service` — convierte ventanas `POPUP_MENU`/`DIALOG` XWayland a tipo `NORMAL` al vuelo. Resuelve login inaccessible (ventana 1×1 hidden), auto-cierre, y sub-secciones (Backup, Add Sync) no navegables.
- **`xdg-open` parcheado para Hyprland**: `xdg-utils` 1.2+ falla con `DE=Hyprland` (exit_failure en switch). El instalador ahora parchea `/usr/bin/xdg-open` para usar `open_generic` como fallback — links desde apps (Telegram, VSCode, terminal) abren el browser correctamente.
- **Wofi reemplaza Rofi**: `$menu` cambiado a `env GTK_THEME=Adwaita:dark wofi --show drun`. Rofi no es nativo Wayland; wofi es el launcher correcto. Incluye override GTK para evitar accent colors del tema Sweet-Dark.
- **Waybar 21 temas actualizados**: iconos de workspace creativos por tema (☥, ❀, ◉, ☠, ▲, ❄, etc.), occupied state via `"default"` key (corrige bug waybar v0.15.0 donde `"occupied"` no es válido), módulo `network` eliminado (redundante con systray nm-applet), launcher usa wofi.
- **Kitty URL handling**: `open_url_with xdg-open` + `detect_urls yes` explícitos — Ctrl+click en URLs abre el browser correctamente.
- **Hyprlock lockfile fix**: `rm -f /tmp/hyprlock-locked` en `startup.sh` — evita que el watchdog relance hyprlock inmediatamente tras un crash de sesión, bloqueando el login.
- **Notificaciones swaync redimensionadas**: tamaños duplicados (`sz-title: 18px`, `sz-body: 16px`, width: 400px) para mejor legibilidad.

### 🛠️ Fixes

- **`vpn_status`**: iconos cambiados a BMP range (`U+F023`/`U+F09C` nf-fa-lock/unlock) — los iconos 4-byte `U+F0000+` no renderizan en todas las variantes de Nerd Font.
- **MEGAsync autostart**: `QT_QPA_PLATFORM=xcb` mantenido (MEGA fuerza XCB internamente; usar `wayland` causa crash — issue #710).
- **`megasync.desktop` autostart**: incluido en dotfiles para que systemd-xdg-autostart-generator lo procese correctamente en todos los sistemas.

## [3.8.0] - 2026-05-27 (P4nx0z "Titanium" Edition)

### 🛡️ Seguridad / Resiliencia (CRÍTICO)

- **grub-btrfs integrado**: Snapshots de Snapper ahora aparecen como opción de boot en GRUB (`BLACK-ICE Snapshots`). Si una actualización rompe algo, se bootea el snapshot anterior.
- **`fstrim.timer` habilitado**: TRIM semanal seguro por systemd. Reemplaza el peligroso `discard=async` que corrompió metadata btrfs en NVMe DRAM-less (Kingston NV2).
- **`nodiscard` explícito en fstab**: Defensa en profundidad — nunca se usará `discard=async` aunque alguien lo agregue manualmente.
- **`space_cache=v2` explícito en mount options**: Hardening del free space tree.
- **LUKS `--allow-discards`**: TRIM ahora pasa a través de la capa de cifrado.
- **SMART monitoring (`smartd`)**: Alertas tempranas de degradación de disco.
- **Btrfs scrub mensual**: Timer systemd para detección temprana de corrupción antes de que sea fatal.
- **`nvme.noacpi=1` + `NVME_STABILITY=yes` default**: Estabilidad NVMe para Linux en todos los sistemas.
- **Snapper tuning conservador**: `SPACE_LIMIT` 0.5→0.3, `FREE_LIMIT` 0.2→0.3, `NUMBER_LIMIT` 50→20, `HOUR_LIMIT` 5→4. Reduce churn de CoW.

### 🔧 Fixes

- **`bootstrap.sh`**: URL del repo confirmada como `BLACK-ICE-HYPER_ARCH` (correspondiente al repo real de GitHub).
- **`99_final.sh`**: Nuevo script `/etc/profile.d/blackice-health.sh` con comandos rápidos de salud del sistema (scrub, SMART, snapshots).

### 📝 Documentación

- **`CHANGELOG.md`**: Entrada v3.8.0 con todos los cambios documentados.

## [3.7.1] - 2026-05-21 (P4nx0z "Polish" Edition)

### 🎨 UI / UX

- **Fastfetch**: Colores por módulo (`keyColor`), separador `│`, logo `auto`, padding mejorado.
- **SwayNC**: Config expandida — timestamps relativos, `layer-shell-cover-screen`, atajos de teclado, panel 500px.
- **Wofi grid**: Estilo refinado — bordes más finos, radios menores, mejor contraste.
- **`updates_status`**: Reescrito para usar `paru -Qu` (incluye AUR), excluye `-git`, tooltip con lista de paquetes.
- **Waybar themes**: Intervalo `updates_status` reducido de 3600s → 300s + signal 8 para refresh manual.
- **Fastfetch logos**: Nuevos logos (`mr0b0t`, `skull_matrix`, `tux_hacker`, `vigil4dor`).

### 🛠️ Fixes / Cleanup

- **`startup.sh`**: `pkill` → `pkill -x` (coincidencia exacta, evita matar procesos relacionados).
- **`02_security_tools.sh`**: Entrada duplicada `responder` eliminada.
- **`08_ai_tools.sh`**: Qwen CLI removido (inestable). `claudeupdate` mejorado — ya no hace pipe directo a bash (descarga a tmpfile primero).
- **`05_bootloader.sh`**: `mem_sleep_default=deep` agregado automáticamente en laptops (detecta BAT0/BAT1).
- **GRUB**: Hook pacman para `grub-mkconfig` removido (ya innecesario con kernel hooks de mkinitcpio).
- **Backups**: Eliminados archivos `.bak.emergency` y `.backup.final_rescue` del repo.
- **GTK3**: Nuevo `dotfiles/gtk-3.0/gtk.css` para consistencia visual.
- **SDDM CyberSec**: `Background.qml` y `Login.qml` actualizados.

### 📝 Documentación

- **README.md / README.en.md**: Badge de versión actualizado a `3.7.0`.
- **`docs/MODULES.md`**: Sección `Binaries & Scripts` actualizada con nuevos scripts (`dotfiles-update`, `dotfiles-rollback`, `tpm2-luks-enroll`, `auto_monitors`).

---

## [3.7.0] - 2026-05-21 (P4nx0z "SelfService" Edition)

### 🚀 Novedades

- **`dotfiles-update`**: Nuevo comando — actualiza dotfiles desde el repo sin reinstalar. Auto-snapshot antes de aplicar. Soporte `--dry-run`, `--no-restart`, `--no-backup`.
- **`dotfiles-rollback`**: Nuevo comando — restaura dotfiles desde snapshot local sin internet. Menú interactivo. Retiene últimos 5 backups.
- **`auto_monitors.sh`**: Detección automática de monitores en primer boot. 2+ monitores → genera `monitors.conf` + abre `nwg-displays`. Boots siguientes: salida inmediata (state file). Reconfigurar con `--force-gui`.
- **`tpm2-luks-enroll`**: Script para enrollar TPM2 en LUKS2 — desbloqueo sin contraseña vinculado al hardware (PCR0+7). Auto-detección de dispositivo. `--remove` para revertir.
- **`nwg-displays` + `tpm2-tools`**: Agregados a paquetes de instalación Phase 2.
- **`mpv` + `yt-dlp` + `speedtest-cli`**: Agregados a `05_software_suite.sh` — eran usados por `.zshrc` pero no se instalaban.

### 🛠️ Fixes

- **`.zshrc`**: Eliminado alias `genpass` (apuntaba a script inexistente).

---

## [3.6.4] - 2026-05-21 (P4nx0z "AuditFix" Edition)

### 🛡️ Seguridad

- **`03_config.sh:342`**: `PermitRootLogin yes` → `prohibit-password` en Phase 1. Ya no depende de Phase 2 para cerrar el vector SSH.
- **`bootstrap.sh`**: URL del repo corregida (`BLACK-ICE-HYPER_ARCH` → `BLACK-ICE_ARCH`). El one-liner de instalación estaba roto con 404.

### 🛠️ Fixes

- **`03_config.sh:54`**: Variable de teclado `SYSTEM_KBD` (nunca definida) → `KEYMAP`. El layout del usuario se ignoraba silenciosamente.
- **`03_config.sh:231`**: Validación de initramfs hardcodeada a `linux` → `${SELECTED_KERNEL:-linux}`. Fallaba con kernels zen/hardened.
- **`01_hyprland_base.sh`**: `imagemagick` agregado a `HYPRLAND_PKGS` — aparecía en validación post-install pero nunca se instalaba.
- **`99_finalization.sh`**: `kvm_intel` hardcodeado → detección dinámica Intel/AMD.
- **`nftables.conf`**: Agregada regla ICMPv6 (`ip6 nexthdr icmpv6 accept`).
- **`99_finalization.sh`**: Eliminado "BlackArch" del resumen (no instalado por defecto desde v3.x).

### 📚 Documentación

- **`README.md` + `README.en.md`**: URLs y versión badge corregidos a v3.6.4.
- **`docs/AUDIT_REPORT.md`**: Informe completo de auditoría con hallazgos y fixes.

---

## [3.6.3] - 2026-05-21 (P4nx0z "LockFix" Edition)

### 🛠️ Fixes

- **`hyprlock.conf`: Escape apaga pantalla en lockscreen**: Añadido `bind = ESCAPE, exec, hyprctl dispatch dpms off` — cuando la sesión está bloqueada, Escape apaga el display (DPMS off) sin desbloquear.
- **`hyprland.conf`: `exec-once = hypridle` validado**: Confirmado que hypridle arranca correctamente vía `exec-once`. El keybind `Super+L` (`loginctl lock-session`) depende de hypridle como receptor de la señal de bloqueo.

---

## [3.6.2] - 2026-05-14 (P4nx0z "Cleanup" Edition)

### 🧹 Limpieza

- **Qwen eliminado**: Qwen Code CLI pasó a modelo de pago — eliminado de `08_ai_tools.sh` (instalación + alias `qwenupdate`), `05_software_suite.sh`, READMEs, docs. Desinstalado del sistema (`npm uninstall -g @qwen-code/qwen-code`).
- **Antigravity eliminado**: Ya no es útil — eliminado de `99_finalization.sh` (wrapper antigravity-fix, .desktop, sed keybind), `05_software_suite.sh`, READMEs, `docs/`, keybind de `hyprland.conf` (repo + live). Archivos `~/.config/bin/antigravity-fix` y `~/.config/bin/antigravity/` eliminados del sistema.

---

## [3.6.1] - 2026-05-14 (P4nx0z "Security Audit" Edition)

### 🛡️ Seguridad

- **Eliminados archivos con datos sensibles**: `.claude/settings.local.json` (contenía IP privada + contraseña) removido del disco y añadido a `.gitignore`. Nunca fue commiteado — repo en GitHub estaba limpio.
- **Backups versionados eliminados**: `hyprland.conf.bak.emergency` y `hyprland.conf.backup.final_rescue` removidos del repo vía `git rm`.
- **`set_target.sh`**: Añadida validación de formato antes de escribir al target file — previene escritura de caracteres de shell en `~/.config/bin/target`.
- **`copy_ip.sh` línea 9**: Reemplazado `bash -c "echo $SCRIPT"` (command injection) por `command -v "$SCRIPT"` — elimina vector de inyección con $SCRIPT sin comillas.
- **`08_ai_tools.sh`**: Alias `claudeupdate` — reemplazado `curl | bash` por descarga a tmpfile + ejecución separada — elimina riesgo de ejecución directa de pipe.
- **`bootstrap.sh`**: Guard `[[ "$INSTALL_DIR" == /tmp/black-ice* ]]` antes de `rm -rf` — previene borrado accidental si `INSTALL_DIR` se modifica.

### 🛠️ Fixes

- **`99_finalization.sh` línea 9**: `sudo -u $CURRENT_USER` → `sudo -u "$CURRENT_USER"` (SC2086 — variable sin comillas puede causar split de palabra).
- **`02_security_tools.sh`**: Entrada duplicada `responder` eliminada del array `ALL_TOOLS` — causaba ítem duplicado en menú whiptail.
- **`hardware_temp.sh`**: `printf "%.0f"` ahora solo se ejecuta si `cpu_temp` es numérico — previene error fatal si `sensors` devuelve valor no-numérico.
- **`startup.sh`**: `pkill waybar/awww-daemon/swaync` → `pkill -x` — exact match previene matar procesos con nombre similar.
- **`hyprland.conf`**: Sincronizado con configuración de producción (rofi, Intel GPU env vars, HYPRLAND_INSTANCE_SIGNATURE, touchpad settings, gaps_out=3).

### 🧹 Limpieza

- **Archivos vacíos eliminados**: `dotfiles/hypr/workspaces.conf` (0 bytes) y `tools/_Sidebar.md` (0 bytes).
- **`.gitignore`**: Añadidas entradas `.claude/`, `.cursor/`, `*.bak.*`, `*.backup.*`, `*.emergency`, `*.final_rescue`, `*.rescue`, `*.orig`.

---

## [3.6.0] - 2026-05-14 (P4nx0z "Performance & AUR" Edition)

### 🛠️ Fixes

- **[BUG] `updates_status` JSON inválido**: `tr '\n' '\n'` era un no-op — los nombres de paquetes en el tooltip contenían newlines literales, produciendo JSON inválido. Waybar oculta el módulo cuando recibe JSON inválido. Fix: `tr '\n' ','` para separar paquetes con coma.
- **[BUG] `updates_status` COUNT doble-cero**: `grep -c . || echo 0` — cuando grep no encontraba matches salía con código 1, disparando `|| echo 0`, resultando en `COUNT="0\n0"` y error aritmético `[[ ]]`. Fix: `wc -l` con guard `[[ -n "$UPDATES" ]]`.
- **[BUG] `updates_status` no contaba AUR**: El script usaba `pacman -Qu` (sólo repos oficiales). Paquetes AUR instalados (`amass`, `android-apktool`, etc.) no aparecían como pendientes. Fix: `paru -Qu` como primary con fallback a `pacman -Qu`.
- **[BUG] Grupo A themes no usaban script**: 7 themes (`Anubis-Death`, `Horus-Cyber`, `Isis-Magic`, `Matrix-Hacker`, `Matrix-Hacker/s4vitar-darkness`, `Ra-Solar`, `s4vitar-darkness`) tenían `exec: "pacman -Qu 2>/dev/null | wc -l"` hardcodeado en su config. Salida era número plano sin JSON — sin tooltip, sin color por clase, sin AUR. Migrados a `exec: "~/.config/bin/updates_status"` + `"return-type": "json"`.
- **`updates_status` filtra `-git`**: Los paquetes `-git` siempre aparecen como "actualizables" (tracking HEAD). Filtrados con `grep -v '\-git '` para evitar ruido permanente en el contador.

### 🚀 Novedades

- **Sysctl performance (`99-black-ice-performance.conf`)**: Deploy automático en `99_finalization.sh` de config sysctl que incluye: `kernel.sched_util_clamp_min=0` (corrige CPU atascado en frecuencia máxima post-auto-cpufreq), TCP BBR + fq (mejor throughput), `vm.swappiness=5`, `dirty_ratio=10`, `vfs_cache_pressure=50`, buffers de red a 16MB.
- **journald limits**: Deploy en `99_finalization.sh` de `/etc/systemd/journald.conf.d/size-limit.conf` — limita log del sistema a 200MB, retención 2 semanas.
- **GRUB `mem_sleep_default=deep`**: `05_bootloader.sh` detecta batería (`/sys/class/power_supply/BAT0/1`) y agrega `mem_sleep_default=deep` al cmdline automáticamente — activa suspensión S3 (real suspend) en laptops donde el default de la BIOS es S0 (s2idle).

---

## [3.5.1] - 2026-05-12 (P4nx0z "Compatibility Fix" Edition)

### 🛠️ Fixes

- **Hyprland 0.49+ compat**: Removida opción `pseudotile = yes` del bloque `dwindle` en `hyprland.conf`. La opción fue eliminada en Hyprland v0.49 — causaba error fatal al inicio impidiendo arrancar la sesión. El pseudo-tiling sigue disponible por keybind (`$mod+P`) o via `windowrulev2 = pseudo, class:^(app)$`.
- **Waybar updates module — intervalo**: Reducido `interval` de 3600s (1h) a 300s (5min) en los 22 themes. Con el intervalo anterior el módulo tardaba hasta 1 hora en reflejar que el sistema estaba actualizado.
- **Waybar updates module — señal**: Agregado `"signal": 8` en todos los themes. Permite forzar refresh inmediato post-actualización con `pkill -RTMIN+8 waybar`.
- **Waybar updates script**: Reemplazado `checkupdates` por `pacman -Qu` en `dotfiles/bin/updates_status` y `dotfiles/waybar/scripts/updates_status`. `checkupdates` descargaba la base de datos de pacman en cada ejecución (lento). `pacman -Qu` consulta la BD local — instantáneo.
- **Waybar themes Grupo A**: 7 themes (`Anubis-Death`, `Horus-Cyber`, `Isis-Magic`, `Matrix-Hacker`, `Matrix-Hacker/s4vitar-darkness`, `Ra-Solar`, `s4vitar-darkness`) usaban `exec: "checkupdates | wc -l"` directo en el config. Migrados a `pacman -Qu 2>/dev/null | wc -l`.

---

## [3.5.0] - 2026-04-14 (P4nx0z "Black Ops" Edition)

### 🚀 Novedades

- **Eww Music Widget** (`Win+Shift+N`): Widget flotante 380x115px top-right. Playerctl/MPRIS — álbum art, título, artista, álbum, barra de progreso interactiva, prev/play-pause/next, shuffle, loop. CSS cyberpunk completo. Toggle script con detección de player activo. `eww` añadido al deploy `01_hyprland_base.sh`. Fix: artUrl usa `sed 's|file://||'` (el `#` es token inválido en yuck).
- **Hyprlock per-theme**: `theme_selector` convierte `BORDER_COLORS` (`0xeeRRGGBB`) a `rgba()` y actualiza `outer_color`/`font_color` del input field en `hyprlock.conf` live al cambiar tema.
- **Wlogout animations**: `fadeIn 0.2s` al abrir, hover glow cyan (`box-shadow`), `transform: scale(1.05)` en hover, `scale(0.97)` en active press.
- **Cheat Sheet interactivo** (`Win+I`): Overlay GTK3 fullscreen, 3 columnas, headers con color por categoría. Cierra con Esc/Enter/Q/I/F1. Diseño inspirado en gh0stzk. `GDK_BACKEND=wayland` en exec para compatibilidad Hyprland.
- **App Switcher** (`Win+Tab`): `hyprctl clients -j` → Wofi dmenu con íconos Nerd Font por clase. Foco directo via `hyprctl dispatch focuswindow address:`.
- **Pass Menu** (`Win+Shift+X`): Integración KeePassXC CLI + Wofi. Copia contraseña/usuario/TOTP al portapapeles. Auto-limpia portapapeles en 30s. Lee `$KEEPASS_DB` del entorno o busca en rutas comunes.
- **Terminal Manager** (`Win+Ctrl+Enter`): Sesiones Kitty multi-tab predefinidas. Perfiles: Pentesting (5 tabs), Dev (4 tabs), SOC (5 tabs). Tabs individuales: Shell, Monitor, Redes, Logs.
- **Kitty colores dinámicos via pywal**: `theme_selector` corre `wal -i <wallpaper> -n` al cambiar tema. Paleta generada del wallpaper activo → aplicada a Kitty via socket (`kitty @ set-colors`) + SIGUSR1. Fallback a temas `.conf` manuales si pywal no disponible.
- **21 temas Kitty manuales**: Archivo `.conf` por cada tema Waybar en `dotfiles/kitty/themes/`. Colores coordinados con el esquema del tema.
- **SSH server indicator en p10k**: Segmento custom `ssh_server` — muestra `󰒋 HOSTNAME` con fondo rojo (color 196) solo cuando hay conexión SSH activa. Activado en `POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS`.
- **Mic mute fix con wpctl**: `XF86AudioMicMute` / F4 usa `wpctl set-mute @DEFAULT_SOURCE@ toggle` (PipeWire nativo) en vez de `pamixer`. Soluciona fallo silencioso en sistemas con PipeWire 1.4+.

### 🛠️ Fixes

- **Cheat Sheet CSS**: Eliminado `text-transform: uppercase` (propiedad inválida en GTK3 CSS que impedía lanzar la ventana).
- **Kitty `allow_remote_control`**: Habilitado `allow_remote_control yes` + `listen_on unix:/tmp/kitty-{kitty_pid}`. Necesario para socket-based color updates.
- **Kitty include**: Cambiado `include themes/mocha.conf` → `include themes/current_theme.conf`. Pywal escribe en ese archivo.
- **theme_selector**: Eliminado hardcode `background #1e1e2e`. El fondo ahora viene del tema kitty o pywal.
- **deploy 99_finalization**: Copia `dotfiles/kitty/themes/*.conf` a `~/.config/kitty/themes/` y crea `current_theme.conf` inicial (Horus-Cyber default).

---

## [3.4.0] - 2026-04-13 (P4nx0z "Hyprland Port" Edition)

### 🚀 Novedades

- **Teclas multimedia completas**: swayosd (primario) + pamixer/brightnessctl (fallback). WiFi toggle via nmcli `XF86WLAN`/`XF86RFKill` + fallback `SUPER+ALT+F`. Playerctl para media keys.
- **fzf-tab**: Instalado en deploy + integrado en `.zshrc` con previews ls/bat/kill. Colores BLACK-ICE.
- **Music Player (MPD + ncmpcpp)**: Deploy automático con PipeWire/PulseAudio. Servicio systemd --user. Lanzador `SUPER+SHIFT+M`. Alimenta módulo Waybar via playerctl/mpris.
- **Wofi múltiples estilos**: 4 estilos en `~/.config/wofi/styles/` (default, minimal, fullscreen, grid). Selector en `SUPER+ALT+R`.
- **wifi_toggle**: Script genérico nmcli con notificación swaync.
- **xdg-open-wayland wrapper**: Fix OAuth para gemini-cli, qwen-cli en Wayland — instalado como `~/.local/bin/xdg-open`.

### 🛠️ Fixes

- **wallpaper_visual**: Escaneo recursivo de subdirectorios. Soporte .webp. Indicador ★ del activo.
- **Waybar layouts variety**: Varinka-Mono → módulos individuales en caja. Yael-OxoCarbon → fullwidth slim bar. H4k3r-HTB → compact pill-right con underline tabs.
- **Kitty blur**: `background_opacity 0.92`. Blur reducido (size=4, passes=2). windowrulev2 para opacidad diferenciada. Fondo visible sin blur excesivo.
- **BROWSER env Kitty**: `env BROWSER=xdg-open` en kitty.conf para CLI OAuth.
- **Deploy 01_hyprland_base**: Agrega `swayosd` + `networkmanager` a paquetes base.
- **Deploy 99_finalization**: Instala xdg-open wrapper + xdg-settings browser por defecto.

---

## [3.3.1] - 2026-04-07 (P4nx0z "Hardened Deploy" Edition)

### 🐞 Correcciones Críticas

- **[CRÍTICO] Plymouth mata el deploy completo**: El hook post-install de `pacman -S plymouth` dispara `mkinitcpio -P` automáticamente. Si ese proceso muere (kill inesperado), `safe_install` devuelve 1 y el `mkinitcpio -P` posterior en línea 758 no tenía manejo de error — con `set -uo pipefail` el deploy entero crasheaba aquí, dejando todos los módulos siguientes (03–99) sin ejecutarse.
  - **Fix**: Plymouth se instala con `--noscriptlet` para suprimir el hook automático. La regeneración del initramfs se hace una sola vez al final de la sección, con `|| log_warn` para que un fallo no mate el deploy.
- **[CRÍTICO] Sweet-Dark git clone falla por CWD inválido**: El bloque hacía `cd /usr/share/themes/Sweet-Dark` y luego `sudo rm -rf` ESE mismo directorio. El `git clone` subsiguiente no tenía directorio de trabajo válido y fallaba con "Unable to read current working directory".
  - **Fix**: Se evalúa si `.git` existe sin hacer `cd` primero. Si hay que reclone, se hace `cd /tmp` antes del `rm -rf`. El clone usa `--depth=1 -b Ambar-Blue-Dark` directamente.

---

## [3.3.0] - 2026-04-07 (P4nx0z "Hardened Deploy" Edition)

### 🚀 Novedades

- **`02_security_tools.sh` — UI whiptail checklist completo**: El instalador de herramientas fue completamente rediseñado. Ahora usa `whiptail --checklist` con todos los paquetes en una sola pantalla estilo Debian. ESPACIO para marcar/desmarcar, ENTER para confirmar.
- **Menú principal de 4 opciones**:
  - Suite Estándar (recomendado) — todo sin pesadas
  - Selección personalizada — checklist whiptail
  - Suite Completa — todo incluyendo bloodhound/ghidra/autopsy
  - Saltar instalación
- **Paquetes pesados opcionales y desmarcados por defecto**: `bloodhound` (~60min, neo4j-community), `ghidra` (~20min), `autopsy` (~20min), `sliver` (~15min). Se pueden instalar pero requieren confirmación explícita.
- **Modo desatendido inteligente**: `NON_INTERACTIVE=true` / `AUTO_MODE=true` instala Suite Estándar automáticamente — nunca arranca una compilación de 60 min sin aviso.
- **Aviso visual en compilaciones largas**: Banner amarillo aparece antes de instalar cualquier paquete pesado indicando tiempo estimado.

## [3.2.1] - 2026-04-07 (P4nx0z "Hardened Deploy" Edition)

### 🛠️ Fixes

- **[CRÍTICO] paru ABI mismatch mata todo el deploy**: `pacman -Syu` en módulo 1 puede actualizar `pacman` de 6.x a 7.x cambiando `libalpm.so.15` → `libalpm.so.16`. El binario de `paru` queda roto pero `command -v paru` sigue devolviendo true, haciendo que `safe_install` intente usarlo y falle en 100% de los paquetes sin mensajes útiles.
  - **`00_repositories.sh`**: ahora valida `paru --version` antes de asumir que paru está funcional. Si falla, lo elimina con `pacman -Rns` y reinstala `paru-bin` desde AUR *después* del `pacman -Syu`, garantizando que la ABI esté siempre sincronizada.
  - **`src/lib/utils.sh` → `safe_install`**: agrega `PARU_OK` flag que valida funcionalidad real de paru (no solo existencia del binario). Si paru está roto, hace fallback automático a `pacman` en todos los intentos (1, 2 y 3). El warning es explícito: `libalpm ABI mismatch`.

## [3.2.0] - 2026-04-07 (P4nx0z "Hardened Deploy" Edition)

### 🚀 Nueva Funcionalidad

- **Módulo `09_grub_theme.sh`**: Integración de tema DedSec GRUB2 (GPL-3.0). Auto-detecta variantes disponibles en el repo clonado y ofrece selector `whiptail`. Configura `GRUB_THEME`, `GRUB_GFXMODE=1920x1080,auto` y `GRUB_TERMINAL_OUTPUT=gfxterm` en `/etc/default/grub`, luego regenera `grub.cfg`. Idempotente: reemplaza instalación previa si existe.
- **4 nuevos temas Waybar** inspirados en gh0stzk/dotfiles (créditos en CREDITS.md): `Jan-CyberPunk`, `Emilia-TokyoNight`, `Marisol-Dracula`, `Melissa-Nord`. Cada tema incluye `config.jsonc` (2 barras) + `style.css` completo (~300-400 líneas) con todos los estados definidos y floating pills.
- **`theme_selector` refactorizado**: eliminada ruta de usuario hardcodeada → `$HOME`. Lista de temas ahora auto-detectada dinámicamente desde el directorio. Agrega fallback de wallpaper en 3 niveles (específico → gh0stzk-walls → aleatorio). Borde Hyprland actualizado para los 4 temas nuevos.
- **`gh0stzk-walls`** nuevo script: descarga wallpapers directamente del repo original de gh0stzk con crédito explícito. Soporta `--all`, `--theme NOMBRE`, `--list`.
- **`CREDITS.md`**: nuevo archivo con créditos a gh0stzk, VandalByte (DedSec GRUB), y todos los colorschemes utilizados.
- **`Horus-Cyber/style.css`**: eliminadas 5 reglas CSS duplicadas de `#custom-hardware_temp`.

### 🐞 Correcciones Críticas

- **[CRÍTICO] Teclado nunca aplicado en LUKS/initramfs**: `vconsole.conf` nunca se escribía en `src/modules/03_config.sh` — triple bug: variable inexistente (`SYSTEM_KBD`), heredoc sin cerrar que tragaba código posterior, y falta del redirect `> /etc/vconsole.conf`. Corregido en la raíz.
- **[CRÍTICO] Phase 2 sobreescribía el teclado configurado en Phase 1**: `01_hyprland_base.sh` tenía `KEYMAP=es` hardcoded, deshaciendo la configuración del usuario. Ahora usa `${KEYBOARD_LAYOUT:-es}` desde `install.conf.auto`.
- **[CRÍTICO] GRUB Layout silenciado**: `grub-mklayout` fallaba sin mensaje gracias a `2>/dev/null`. Ahora muestra el error real y limpia el archivo `.gkb` fallido.
- **`install.sh` admitía el bug**: Había un aviso explícito "GRUB usará teclado US". Eliminado y reemplazado por mensaje de éxito real.

### 🔧 Correcciones de Estabilidad

- **`00_repositories.sh`**: Variable `CONF_FILE` no inicializada causaba error fatal con `set -u`. Agregado `CONF_FILE=""`.
- **`01_hyprland_base.sh`**: Paquetes duplicados en `HYPRLAND_PKGS` (`udiskie`, `hyprpaper`, `kvantum-qt5`). Eliminadas las duplicaciones.
- **`04_theme_setup.sh`**: `awww-daemon &` sin guardia — falla fatal si `awww` no está instalado. Envuelto en `if command -v awww`. Añadido fallback de wallpaper si el archivo no existe.
- **`05_software_suite.sh`**: `$NON_INTERACTIVE` sin default causaba error fatal con `set -u`. Cambiado a `${NON_INTERACTIVE:-false}`. También `$LANG` sin default en detección de idioma.
- **`07_neovim_setup.sh`**: `git clone` sin `--depth=1` — descarga innecesaria del historial completo de NvChad.

### 🚀 Mejoras

- **Migración yay → paru-bin**: Reemplazado `yay` por `paru-bin` (binario pre-compilado, sin necesidad de Rust toolchain). Más robusto, mejor resolución de dependencias. Usa `--skipreview` para instalaciones automáticas.
- **Eliminación BlackArch**: Removido el bloque de setup completo (incluyendo `allow-weak-key-signatures` que era un downgrade de seguridad). Todos los tools de seguridad están disponibles en Chaotic-AUR/AUR/repos oficiales.
- **`utils.sh`**: Todos los `yay` → `paru --skipreview`. Eliminada referencia a `blackarch.gpg` en `rebuild_keyring()`.
- **`dotfiles/hypr/hyprland.conf`**: Añadido `exec-once = hypridle`. Corregido keybind `togglesplit` → `layoutmsg, togglesplit` (Hyprland 0.53+ breaking change). Corregida ruta de usuario hardcodeada → `$HOME`.
- **`dotfiles/hypr/hypridle.conf`**: Creado archivo faltante. El paquete se instalaba pero el daemon no tenía config y fallaba silenciosamente.
- **`src/deploy/99_finalization.sh`**: Rutas de usuario hardcodeadas en `.desktop` y keybind sed → `$USER_HOME`. Añadida propagación de `kb_layout` a `hyprland.conf`.
- **`src/deploy/08_ai_tools.sh`**: Nombre de paquete corregido (`@anthropic-ai/claude-cli` → `@anthropic-ai/claude-code`). `nodejs`/`npm` ahora via `safe_install`. Añadida idempotencia a instalación npm y a inyección de aliases.
- **`CLAUDE.md`**: Añadidas secciones de Security Rules, Optimization Rules, Continuous Improvement Protocol y Documentation Mandatory Update Policy.
- **`dotfiles/hypr/hyprlock.conf`**: Corregidos 3 bugs `##color` → `#color` en Pango markup (líneas con tiempo, placeholder y fail_text) — los colores no se renderizaban.
- **`06_sddm_setup.sh`**: `sudo mv /etc/sddm.conf /etc/sddm.conf.bak` fallaba en segunda ejecución (archivo ya no existe). Ahora idempotente con guard `[ ! -f .bak ]`.
- **`07_neovim_setup.sh`**: `rm -rf` + `git clone` sin guard → destruía config existente en cada re-run. Ahora hace `git pull` si ya existe.
- **`03_terminal_config.sh`**: `tee -a /root/.p10k.zsh` duplicaba el bloque ROOT CUSTOMIZATION en cada ejecución. Añadido `grep -q` guard.

### 🛠️ Fixes Adicionales (Audit Round 2)

- **[CRÍTICO] `install.sh`: LUKS_PASSWORD expuesto en disco** — eliminada la línea `printf "LUKS_PASSWORD=%q\n"` que guardaba la contraseña de cifrado en `install.conf.auto`. Agregado `chmod 600` post-escritura.
- **[CRÍTICO] `01_disk.sh`: SATA sin detección de particiones** — la cadena `if/elif` para NVMe/MMC/VirtIO/Xen no tenía rama `else`, dejando `PART_ROOT` sin inicializar en discos SATA `/dev/sdX`. Agregado `else` correctivo.
- **[CRÍTICO] `05_software_suite.sh`: `$USER` vs `$CURRENT_USER` en usermod** — cuando el script corre con sudo, `$USER` = root. Los grupos `libvirt`, `docker`, `wireshark` se añadían al usuario incorrecto. Corregido a `$CURRENT_USER` en las 3 llamadas.
- **`Melissa-Nord/config.jsonc` malformado** — el sed agresivo de la sesión anterior eliminó los bloques `}` de `pulseaudio` y `battery`. Regenerado completamente desde plantilla limpia con `"format": "{id}"` en workspaces (sin íconos, estilo Nord minimalista).
- **`portal.sh`: WAYLAND_DISPLAY hardcodeado a `wayland-1`** — auto-detecta ahora el socket activo desde `/run/user/$(id -u)/wayland-N`, con fallback a `wayland-1`.
- **`startup.sh`: rutas `~/.config/` sin comillas** — expandidas a `"$HOME/.config/..."` para robustez ante espacios en `$HOME`.
- **`battery_status.sh`: `$BATTERY` potencialmente vacío** — reemplazado `ls | grep BAT` por `find` con guard explícito si no hay batería. Rutas entrecomilladas.
- **`wallpaper_visual`: `ls | grep` falla con espacios en nombre** — reemplazado por `find -maxdepth 1 -type f \( -name "*.png" ... \) -printf '%f\n'`.
- **`power_profile_menu.sh`: `eval "$MENU_CMD"`** — sustituido por llamadas directas a `wofi`/`rofi` sin `eval`. Elimina vector de inyección.
- **`theme_selector`: `pkill -9 waybar; sleep 0.4` (race condition)** — reemplazado por `pkill waybar` + loop de espera de hasta 2 segundos con `pgrep -x waybar`.
- **`00_repositories.sh`: `cd /tmp` sin error handling** — `cd /tmp || { log_error ...; return 1; }`.
- **`99_finalization.sh`: `chown` y `sed` con escapes correctos** — `chown -R "$CURRENT_USER:$CURRENT_USER"` y escape de `$KEYBOARD_LAYOUT` antes del `sed -i`.
- **`09_grub_theme.sh`: delimitador `/` en sed con rutas** — cambiado a `|` para evitar conflicto con paths que contienen `/`.

---

## [3.1.1] - 2026-04-06 (P4nx0z Edition)

### 🛠️ Mejoras y Correcciones de Entorno
- **Limpieza de Archivos Obsoletos:** Se eliminaron scripts legacy y residuales (`fix_grub_kbd.sh`, `remote_path.txt`, `restore_env.sh`) para asegurar un estado de repositorio limpio.
- **Compatibilidad Dinámica Multi-Kernel:** Resuelto un bug crítico que impedía instalar núcleos alternativos (`linux-zen`, `linux-hardened`). La verificación de los presets de `mkinitcpio`, el protocolo de auto-reparación y la auditoría final `99_final.sh` ahora resuelven variables dinámicamente sin fallos fatales.
- **Modo de Espejo Mundial (Worldwide):** Integrada la nueva bandera de alcance "Worldwide" en el menú de países interactivos (tanto en TUI como en Whiptail) forzando al reflector a escanear todo el mundo (`reflector` sin ataduras de país).

## [3.1.0] - 2026-03-26 (P4nx0z "Final Fix" Edition)

### 🛠️ Fixes Maestros y Estándares
- **Migración de Wallpaper Engine**: Se migró de `swww` a `awww` debido al cambio de estándar en los repos oficiales de Arch Linux (`extra/awww`).
- **Refactorización Global de Scripts**: Se actualizaron todos los scripts maestros (`startup.sh`, `set_wallpaper.sh`, `wallpaper_visual`, `theme_selector`) para asegurar compatibilidad nativa con `awww-daemon`.
- **Hyprland Hardening (Misc Fix)**: Se añadió la sección `misc` en `hyprland.conf` para forzar la desactivación del fondo y el logo por defecto (`disable_hyprland_logo = true`). Esto garantiza un inicio limpio y profesional ("Black-Ice Mode").
- **Automatización de Despliegue**: El instalador base ahora instala `awww` de forma automática, asegurando que el entorno sea funcional desde el primer arranque (Out of the Box).

## [3.0.0] - 2026-03-18 (P4nx0z Edition)

### 🚀 Novedades y Características
- **Dotfiles de Producción**: Importación completa de configuraciones probadas en producción.
  - **Dotfiles**: Versiones finales de Hyprland, Waybar, Kitty, y SwayNC.
  - **Scripts Tácticos**: Carpeta `~/bin/` integrada con scripts de automatización para HTB, TryHackMe, VPN y gestión de energía.
  - **Quotes Épicos**: Integración de `tech_quotes.sh` en el inicio de ZSH para motivación técnica al abrir la terminal.
- **Integración de IA (SOTA CLIs)**:
  - Instalación automática de `claude-cli`, `gemini-cli` y `qwen-cli`.
  - Inyección de alias de actualización dinámica en ZSH (`claudeupdate`, `geminiupdate`, `qwenupdate`).
- **Ecosistema Hyprland v0.40+ Ready**:
  - Incorporación de `hypridle` y `hyprcursor` para compatibilidad con las últimas versiones del compositor.
  - Soporte para notificaciones dinámicas en el montaje de discos vía `udiskie`.

### 🐞 Corrección de Bugs (Critical Fixes)
- **Error "target not found: virtio-vga-gl"**: Eliminado paquete obsoleto de la lista de instalación base. Los drivers de video ahora se gestionan dinámicamente según el entorno.
- **Fallos de Firma PGP (Keyring)**: Implementado el "Protocolo de Emergencia PGP" que sincroniza NTP y actualiza `archlinux-keyring` antes del proceso de `pacstrap`. Esto soluciona errores de "Invalid Signature" en ISOs antiguas.
- **Syntax Error en Base Module**: Corregido uso ilegal de la palabra clave `local` fuera de funciones en `src/modules/02_base.sh`.
- **Desalineación de Banners UI**: Refactorización de la librería de logging para usar anchos de columna dinámicos y alineación matemática. Los marcos de la interfaz ahora son estables independientemente del largo del texto.

### 🖥️ Multi-Monitor

- **`dotfiles/hypr/monitors.conf`**: Creado con soporte completo multi-monitor. Entradas explícitas para `eDP-1` (laptop), `HDMI-A-1`, `DP-1/2/3`, `USB-C-1`, y fallback universal `monitor=,preferred,auto,1`. Compatibilidad con el esquema de gh0stzk/dotfiles.

### 🛡️ Seguridad y Hardening
- **Logging Centralizado**: Redirección total de salida a `~/black_ice_install.log` para auditoría post-instalación.
- **Agnosticismo de Usuario**: Eliminación de rutas de usuario hardcodeadas en favor de variables dinámicas `$HOME` para despliegues universales.
- **VPN Ready**: Instalación por defecto de `openvpn` para túneles de auditoría.

---
