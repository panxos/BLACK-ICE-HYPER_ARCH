# CHANGELOG - BLACK-ICE ARCH

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
- **`theme_selector` refactorizado**: eliminado `/home/faravena` hardcodeado → `$HOME`. Lista de temas ahora auto-detectada dinámicamente desde el directorio. Agrega fallback de wallpaper en 3 niveles (específico → gh0stzk-walls → aleatorio). Borde Hyprland actualizado para los 4 temas nuevos.
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
- **`dotfiles/hypr/hyprland.conf`**: Añadido `exec-once = hypridle`. Corregido keybind `togglesplit` → `layoutmsg, togglesplit` (Hyprland 0.53+ breaking change). Corregida ruta hardcodeada `/home/faravena/` → `$HOME`.
- **`dotfiles/hypr/hypridle.conf`**: Creado archivo faltante. El paquete se instalaba pero el daemon no tenía config y fallaba silenciosamente.
- **`src/deploy/99_finalization.sh`**: Rutas hardcodeadas `/home/faravena/` en `.desktop` y keybind sed → `$USER_HOME`. Añadida propagación de `kb_layout` a `hyprland.conf`.
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
- **Limpieza de Archivos Obsoletos:** Se eliminaron scripts legacy y residuales (`fix_grub_kbd.sh`, `remote_path.txt`, `restore_env.sh`, `sync_to_s3th.sh`) para asegurar un estado de repositorio limpio.
- **Compatibilidad Dinámica Multi-Kernel:** Resuelto un bug crítico que impedía instalar núcleos alternativos (`linux-zen`, `linux-hardened`). La verificación de los presets de `mkinitcpio`, el protocolo de auto-reparación y la auditoría final `99_final.sh` ahora resuelven variables dinámicamente sin fallos fatales.
- **Modo de Espejo Mundial (Worldwide):** Integrada la nueva bandera de alcance "Worldwide" en el menú de países interactivos (tanto en TUI como en Whiptail) forzando al reflector a escanear todo el mundo (`reflector` sin ataduras de país).

## [3.1.0] - 2026-03-26 (P4nx0z "Final Fix" Edition)

### 🛠️ Fixes Maestros y Estándares
- **Migración de Wallpaper Engine**: Se migró de `swww` a `awww` debido al cambio de estándar en los repos oficiales de Arch Linux (`extra/awww`).
- **Refactorización Global de Scripts**: Se actualizaron todos los scripts maestros (`startup.sh`, `set_wallpaper.sh`, `wallpaper_visual`, `theme_selector`) para asegurar compatibilidad nativa con `awww-daemon`.
- **Hyprland Hardening (Misc Fix)**: Se añadió la sección `misc` en `hyprland.conf` para forzar la desactivación del fondo y el logo por defecto (`disable_hyprland_logo = true`). Esto garantiza un inicio limpio y profesional ("Black-Ice Mode").
- **Automatización de Despliegue**: El instalador base ahora instala `awww` de forma automática, asegurando que el entorno sea funcional desde el primer arranque (Out of the Box).

## [3.0.0] - 2026-03-18 (P4nx0z "s3th" Edition)

### 🚀 Novedades y Características
- **Sincronización de Ecosistema s3th**: Importación completa de configuraciones de producción desde el host principal de P4nx0z.
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
- **Agnosticismo de Usuario**: Eliminación de rutas absolutas `/home/faravena/` en favor de variables dinámicas `$HOME` para despliegues universales.
- **VPN Ready**: Instalación por defecto de `openvpn` para túneles de auditoría.

---
