#!/bin/bash
# deploy-modules/99_finalization.sh
# Tareas finales y mensajes

banner "FINALIZACIÓN" "Últimos ajustes"

log_info "Instalando gestores de software, recuperación, proyectos y laboratorios..."
install -d -m 700 "$USER_HOME/.local/share/black-ice/system"
install -m 644 "$SCRIPT_DIR/src/system/"*.py "$USER_HOME/.local/share/black-ice/system/"
install -d "$USER_HOME/.local/bin" "$USER_HOME/.local/share/black-ice/software/config" "$USER_HOME/.local/share/applications"
install -m 755 "$SCRIPT_DIR/dotfiles/bin/black-ice-system" "$USER_HOME/.local/bin/black-ice-system"
python3 "$SCRIPT_DIR/scripts/install-security-workspace.py"
install -m 644 "$SCRIPT_DIR/config/apps.json" "$USER_HOME/.local/share/black-ice/software/config/apps.json"
install -Dm644 "$SCRIPT_DIR/config/i18n/en.json" "$USER_HOME/.local/share/black-ice/i18n/en.json"
sudo install -d -m 755 /usr/lib/black-ice /usr/share/black-ice
sudo install -m 755 "$SCRIPT_DIR/scripts/system-transaction.py" /usr/lib/black-ice/system-transaction
sudo install -m 755 "$SCRIPT_DIR/scripts/system-sddm-theme.py" /usr/lib/black-ice/system-sddm-theme
sudo install -m 644 "$SCRIPT_DIR/config/apps.json" /usr/share/black-ice/apps.json
sudo bash "$SCRIPT_DIR/scripts/install-system-tor.sh"
cat > "$USER_HOME/.local/share/applications/black-ice-system.desktop" << EOF
[Desktop Entry]
Type=Application
Name=BLACK-ICE Sistema
Comment=Software, recuperación, proyectos y laboratorios
Exec=$USER_HOME/.local/bin/black-ice-system
Icon=system-software-install
Categories=Settings;System;
Terminal=false
EOF

# --- Crear directorios XDG del usuario ---
log_info "Creando directorios XDG (Desktop, Downloads, etc.)..."
sudo -u "$CURRENT_USER" xdg-user-dirs-update
# Crear directorio Screenshots explícitamente (grim lo necesita)
mkdir -p "$USER_HOME/Pictures/Screenshots"
chown -R "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/Pictures"

# --- Hacer ejecutables los módulos ---
chmod +x "$SCRIPT_DIR/src/deploy/"*.sh

# --- BLACK-ICE FIXES (Udiskie & xdg-open) ---
log_info "Aplicando blindaje para Udiskie y xdg-open..."

# 1. Asegurar que ~/.config/bin existe (puede ser symlink a ~/bin — no usar mkdir -p si es symlink)
if [ ! -e "$USER_HOME/.config/bin" ]; then
    mkdir -p "$USER_HOME/bin"
    ln -sf "$USER_HOME/bin" "$USER_HOME/.config/bin"
fi

# 2. Fix xdg-open para OAuth en CLI tools (gemini-cli, etc.)
# Instala wrapper que garantiza apertura de browser en Wayland
mkdir -p "$USER_HOME/.local/bin"
chown "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.local/bin"
if [ -f "$SCRIPT_DIR/dotfiles/bin/xdg-open-wayland" ]; then
    cp "$SCRIPT_DIR/dotfiles/bin/xdg-open-wayland" "$USER_HOME/.local/bin/xdg-open"
    chmod +x "$USER_HOME/.local/bin/xdg-open"
    chown "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.local/bin/xdg-open"
    log_success "xdg-open → wrapper Wayland instalado en ~/.local/bin/"
fi

# Scripts de gestión BLACK-ICE
for _script in dotfiles-update dotfiles-rollback hyprland-migrate power_profile power_profile_menu.sh waybar_start.sh tpm2-luks-enroll; do
    if [ -f "$SCRIPT_DIR/dotfiles/bin/$_script" ]; then
        cp "$SCRIPT_DIR/dotfiles/bin/$_script" "$USER_HOME/.local/bin/$_script"
        chmod +x "$USER_HOME/.local/bin/$_script"
        chown "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.local/bin/$_script"
        log_success "$_script instalado en ~/.local/bin/"
    fi
done

# Configurar navegador cuando existe uno instalado y no hay una preferencia válida.
_browser=$(xdg-settings get default-web-browser 2>/dev/null || true)
if [[ -z "$_browser" || ! -f "/usr/share/applications/$_browser" && ! -f "$USER_HOME/.local/share/applications/$_browser" ]]; then
    for _desktop in brave-browser.desktop brave.desktop firefox.desktop google-chrome.desktop chromium.desktop; do
        if [[ -f "/usr/share/applications/$_desktop" ]]; then
            xdg-settings set default-web-browser "$_desktop" 2>/dev/null || true
            break
        fi
    done
fi

# --- Fix xdg-open para Hyprland ---
# El wrapper ~/.local/bin/xdg-open (instalado arriba desde dotfiles/bin/xdg-open-wayland)
# toma precedencia sobre /usr/bin/xdg-open si ~/.local/bin está primero en PATH.
# No modificamos /usr/bin/xdg-open — se sobreescribe en cada pacman -Syu.
log_info "xdg-open: wrapper Wayland activo en ~/.local/bin/ (no se modifica /usr/bin/xdg-open)"

# --- MEGAsync: autostart + watcher (solo si megasync está instalado) ---
if command -v megasync &>/dev/null; then
    log_info "MEGAsync detectado — instalando autostart y watcher Hyprland..."
    mkdir -p "$USER_HOME/.config/autostart"
    if [ -f "$SCRIPT_DIR/dotfiles/autostart/megasync.desktop" ]; then
        cp "$SCRIPT_DIR/dotfiles/autostart/megasync.desktop" "$USER_HOME/.config/autostart/megasync.desktop"
        chown "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.config/autostart/megasync.desktop"
        log_success "megasync.desktop autostart instalado"
    fi
    if [ -f "$SCRIPT_DIR/dotfiles/bin/megasync-watcher.sh" ]; then
        cp "$SCRIPT_DIR/dotfiles/bin/megasync-watcher.sh" "$USER_HOME/.config/bin/megasync-watcher.sh"
        chmod +x "$USER_HOME/.config/bin/megasync-watcher.sh"
        chown "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.config/bin/megasync-watcher.sh"
        log_success "megasync-watcher.sh instalado en ~/.config/bin/"
    fi
else
    log_info "MEGAsync no instalado — omitiendo autostart y watcher"
fi
if command -v megasync &>/dev/null && [ -f "$SCRIPT_DIR/dotfiles/systemd/user/megasync-watcher.service" ]; then
    mkdir -p "$USER_HOME/.config/systemd/user"
    cp "$SCRIPT_DIR/dotfiles/systemd/user/megasync-watcher.service" \
        "$USER_HOME/.config/systemd/user/megasync-watcher.service"
    chown -R "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.config/systemd/user"
    sudo -u "$CURRENT_USER" systemctl --user daemon-reload 2>/dev/null || true
    sudo -u "$CURRENT_USER" systemctl --user enable megasync-watcher.service 2>/dev/null || true
    log_success "megasync-watcher.service habilitado (systemd --user)"
fi

# --- Waypaper config (subfolders habilitados para .webp en subdirectorios) ---
mkdir -p "$USER_HOME/.config/waypaper"
if [ -f "$SCRIPT_DIR/dotfiles/waypaper/config.ini" ]; then
    cp "$SCRIPT_DIR/dotfiles/waypaper/config.ini" "$USER_HOME/.config/waypaper/config.ini"
    chown "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.config/waypaper/config.ini"
    log_success "waypaper config instalada (subfolders=True)"
fi

# --- MIME associations ---
log_info "Instalando asociaciones de archivos (mimeapps.list)..."
mkdir -p "$USER_HOME/.config"
if [ -f "$SCRIPT_DIR/dotfiles/mimeapps.list" ]; then
    cp "$SCRIPT_DIR/dotfiles/mimeapps.list" "$USER_HOME/.config/mimeapps.list"
    chown "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.config/mimeapps.list"
    log_success "mimeapps.list instalado (video→vlc, imágenes→imv, docs→okular)"
fi

# --- KDE ksycoca fix: applications.menu symlink ---
# kbuildsycoca6 busca /etc/xdg/menus/applications.menu para indexar apps de escritorio.
# plasma-desktop provee plasma-applications.menu pero no el alias applications.menu.
# Sin este symlink, KApplicationTrader retorna vacío → Dolphin muestra "Open With" vacío
# al hacer doble clic en cualquier archivo, ignorando mimeapps.list por completo.
log_info "Aplicando fix KDE ksycoca (applications.menu)..."
if [ ! -e /etc/xdg/menus/applications.menu ]; then
    if [ -f /etc/xdg/menus/plasma-applications.menu ]; then
        sudo ln -sf /etc/xdg/menus/plasma-applications.menu /etc/xdg/menus/applications.menu
        log_success "symlink applications.menu → plasma-applications.menu creado"
    elif [ -f /etc/xdg/menus/arch-applications.menu ]; then
        sudo ln -sf /etc/xdg/menus/arch-applications.menu /etc/xdg/menus/applications.menu
        log_success "symlink applications.menu → arch-applications.menu creado"
    else
        log_error "No hay un menú XDG válido. Instala archlinux-xdg-menu y repite el despliegue."
        return 1
    fi
else
    log_info "applications.menu ya existe — skip"
fi
if sudo -u "$CURRENT_USER" kbuildsycoca6; then
    log_success "Índice de aplicaciones KDE regenerado"
else
    log_warn "No se pudo regenerar el índice de aplicaciones KDE"
fi

# --- Kitty color themes — instalar los 21 esquemas de color ---
log_info "Instalando esquemas de color Kitty..."
KITTY_THEMES_SRC="$DOTFILES_DIR/kitty/themes"
KITTY_THEMES_DST="$USER_HOME/.config/kitty/themes"
mkdir -p "$KITTY_THEMES_DST"

if [ -d "$KITTY_THEMES_SRC" ]; then
    cp "$KITTY_THEMES_SRC"/*.conf "$KITTY_THEMES_DST/" 2>/dev/null || true
    chown -R "$CURRENT_USER:$CURRENT_USER" "$KITTY_THEMES_DST"

    # Crear current_theme.conf inicial (default: Horus-Cyber)
    DEFAULT_KITTY="$KITTY_THEMES_DST/current_theme.conf"
    if [ ! -f "$DEFAULT_KITTY" ]; then
        cp "$KITTY_THEMES_SRC/Horus-Cyber.conf" "$DEFAULT_KITTY" 2>/dev/null || true
        chown "$CURRENT_USER:$CURRENT_USER" "$DEFAULT_KITTY"
    fi
    log_success "Kitty themes instalados ($(find "$KITTY_THEMES_DST" -maxdepth 1 -name '*.conf' -printf '.' 2>/dev/null | wc -c) archivos)"
else
    log_warn "No se encontró directorio kitty/themes — saltando"
fi

# --- Copiar previews pre-generadas al directorio de temas Waybar ---
log_info "Instalando previews de temas Waybar..."
for theme_dir in "$DOTFILES_DIR/waybar/themes"/*/; do
    theme=$(basename "$theme_dir")
    dest="$USER_HOME/.config/waybar/themes/$theme"
    mkdir -p "$dest"
    if [ -f "$theme_dir/preview.png" ]; then
        cp "$theme_dir/preview.png" "$dest/preview.png"
        chown "$CURRENT_USER:$CURRENT_USER" "$dest/preview.png"
    fi
done
log_success "Previews de temas instaladas"

install -Dm755 "$SCRIPT_DIR/dotfiles/bin/udiskie-fix" "$USER_HOME/.config/bin/udiskie-fix"
install -Dm644 "$SCRIPT_DIR/dotfiles/systemd/user/black-ice-removable.service" "$USER_HOME/.config/systemd/user/black-ice-removable.service"
install -Dm644 "$SCRIPT_DIR/dotfiles/systemd/user/black-ice-conky.service" "$USER_HOME/.config/systemd/user/black-ice-conky.service"
mkdir -p "$USER_HOME/.config/systemd/user/hyprland-session.target.wants"
ln -sfn ../black-ice-removable.service "$USER_HOME/.config/systemd/user/hyprland-session.target.wants/black-ice-removable.service"
ln -sfn ../black-ice-conky.service "$USER_HOME/.config/systemd/user/hyprland-session.target.wants/black-ice-conky.service"
if [[ ! -e "$USER_HOME/.config/udiskie/config.yml" ]]; then
    install -Dm644 "$SCRIPT_DIR/dotfiles/udiskie/config.yml" "$USER_HOME/.config/udiskie/config.yml"
fi
chown -R "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.config/udiskie" "$USER_HOME/.config/systemd/user"
chown "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.config/bin/udiskie-fix"

# --- Propagar distribución de teclado a Hyprland ---
HYPR_CONF="$USER_HOME/.config/hypr/hyprland.conf"
if [ -f "$HYPR_CONF" ] && [ -n "${KEYBOARD_LAYOUT:-}" ]; then
    XKB_LAYOUT=$(console_to_xkb_layout "$KEYBOARD_LAYOUT")
    ESCAPED_LAYOUT=$(printf '%s\n' "$XKB_LAYOUT" | sed 's/[\/&]/\\&/g')
    sed -i "s/^\(\s*kb_layout\s*=\s*\).*/\1${ESCAPED_LAYOUT}/" "$HYPR_CONF"
    log_success "Teclado '$XKB_LAYOUT' aplicado en Hyprland (kb_layout)."
fi

# --- eww music widget ---
log_info "Instalando eww music widget..."
mkdir -p "$USER_HOME/.config/eww"
ln -sf "$DOTFILES_DIR/eww/eww.yuck" "$USER_HOME/.config/eww/eww.yuck"
ln -sf "$DOTFILES_DIR/eww/eww.scss" "$USER_HOME/.config/eww/eww.scss"
# music_widget toggle script
cp --remove-destination "$DOTFILES_DIR/bin/music_widget" "$USER_HOME/.config/bin/music_widget"
chmod +x "$USER_HOME/.config/bin/music_widget"
chown -h "$CURRENT_USER:$CURRENT_USER" \
    "$USER_HOME/.config/eww/eww.yuck" \
    "$USER_HOME/.config/eww/eww.scss" \
    "$USER_HOME/.config/bin/music_widget"
log_success "eww music widget instalado (Win+Shift+N para toggle)"

# --- Optimizaciones de rendimiento del sistema ---
log_info "Aplicando configuración de rendimiento (sysctl + journald)..."

sudo tee /etc/sysctl.d/99-black-ice-performance.conf > /dev/null << 'EOF'
# BLACK-ICE ARCH — Performance Tuning
# RAM
vm.swappiness = 5
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
vm.dirty_writeback_centisecs = 500
vm.vfs_cache_pressure = 50
vm.overcommit_memory = 1
# CPU scheduling
kernel.sched_util_clamp_min = 0
kernel.sched_autogroup_enabled = 1
# TCP BBR + pentesting
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.core.netdev_max_backlog = 65536
net.ipv4.tcp_fastopen = 3
net.ipv4.ip_local_port_range = 1024 65535
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.rmem_default = 1048576
net.core.wmem_default = 1048576
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
# Docker / KVM
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
# Kernel hardening (compatible con pentesting)
kernel.nmi_watchdog = 0
kernel.unprivileged_userns_clone = 1
kernel.perf_event_paranoid = 1
kernel.kptr_restrict = 1
fs.file-max = 2097152
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512
EOF
sudo sysctl --system &>/dev/null || true
log_success "sysctl aplicado (BBR + optimizaciones Docker/KVM/pentesting)"

# Módulos kernel persistentes para Docker y KVM
_CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}')
_KVM_MODULE="kvm_intel"
[[ "$_CPU_VENDOR" == "AuthenticAMD" ]] && _KVM_MODULE="kvm_amd"

sudo tee /etc/modules-load.d/black-ice.conf > /dev/null << EOF
br_netfilter
${_KVM_MODULE}
EOF
sudo modprobe br_netfilter 2>/dev/null || true
sudo modprobe "${_KVM_MODULE}" 2>/dev/null || true
log_success "Módulos br_netfilter + ${_KVM_MODULE} configurados para boot"

# journald: limitar tamaño del log
sudo mkdir -p /etc/systemd/journald.conf.d
sudo tee /etc/systemd/journald.conf.d/size-limit.conf > /dev/null << 'EOF'
[Journal]
SystemMaxUse=200M
SystemKeepFree=200M
MaxRetentionSec=2week
Compress=yes
RateLimitIntervalSec=30s
RateLimitBurst=10000
EOF
log_success "journald limitado a 200M"

# --- Firewall profesional (nftables) ---
log_info "Configurando firewall nftables (black-ice-filter)..."

if command -v nft &>/dev/null; then
    # Instalar config si existe en dotfiles
    if [[ -f "$DOTFILES_DIR/nftables/nftables.conf" ]]; then
        if sudo nft --check -f "$DOTFILES_DIR/nftables/nftables.conf"; then
            if [[ -s /etc/nftables.conf ]] && ! sudo cmp -s "$DOTFILES_DIR/nftables/nftables.conf" /etc/nftables.conf; then
                log_warn "Se conserva el firewall existente. Revisa las diferencias antes de sustituir /etc/nftables.conf."
            else
                sudo install -m 600 "$DOTFILES_DIR/nftables/nftables.conf" /etc/nftables.conf
                sudo nft -f /etc/nftables.conf
                sudo systemctl enable nftables
                log_success "Reglas nftables aplicadas sin errores."
            fi
        else
            log_error "Las reglas nftables no pasaron la validación; no se aplicaron."
            exit 1
        fi
    fi
else
    log_warn "nftables no instalado — instalar con: pacman -S nftables"
fi

# --- Hardening SSH ---
log_info "Aplicando hardening SSH..."
if grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config 2>/dev/null; then
    sudo sed -i 's/^PermitRootLogin yes/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
    log_success "SSH: PermitRootLogin → prohibit-password"
fi
sudo systemctl reload sshd 2>/dev/null || true

if pacman -Q conky 2>/dev/null | grep -q '^conky 1\.25\.2-'; then
    log_info "Preparando corrección de Conky 1.25.2 para Wayland..."
    for _conky_dep in base-devel cmake ninja gperf lua54 wayland-protocols; do
        safe_install "$_conky_dep" || return 1
    done
    python3 "$SCRIPT_DIR/scripts/build-conky-wayland.py" --apply || return 1
fi

# --- Identidad visual coordinada ---
if [[ -f "$SCRIPT_DIR/scripts/install-visual-refresh.py" ]]; then
    log_info "Instalando Obsidiana y sus controles visuales..."
    safe_install "gtk3"
    _visual_args=(--apply --no-activate)
    if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] && hyprctl monitors >/dev/null 2>&1; then
        _visual_args=(--apply)
    fi
    if python3 "$SCRIPT_DIR/scripts/install-visual-refresh.py" "${_visual_args[@]}"; then
        log_success "Identidad Obsidiana instalada; SDDM se usará en el próximo inicio"
    else
        log_warn "No se completó Obsidiana; revisa el error y el manifiesto de reversión"
    fi
fi

if [[ -f "$SCRIPT_DIR/scripts/install-cyber-themes.py" ]]; then
    _catalog_args=(--apply --no-activate)
    if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] && hyprctl monitors >/dev/null 2>&1; then
        _catalog_args=(--apply)
    fi
    if python3 "$SCRIPT_DIR/scripts/install-cyber-themes.py" "${_catalog_args[@]}"; then
        log_success "Catálogo de temas y módulos de seguridad instalado"
    else
        log_warn "No se completó el catálogo; revisa el manifiesto de reversión"
    fi
fi

if [[ -f "$USER_HOME/.config/hypr/hyprland.conf" && -x "$USER_HOME/.local/bin/hyprland-migrate" ]]; then
    log_info "Verificando migración compatible con la versión instalada de Hyprland..."
    if ! python3 "$USER_HOME/.local/bin/hyprland-migrate"; then
        log_error "La migración no pasó la validación; se conserva la configuración anterior."
        return 1
    fi
fi

systemctl --user daemon-reload

# --- Generar resumen de instalación ---
log_info "Generando resumen..."

echo -e "\n${NEON_PURPLE}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${NEON_PURPLE}║${NC}  ${BOLD}RESUMEN DE INSTALACIÓN${NC}                          ${NEON_PURPLE}║${NC}"
echo -e "${NEON_PURPLE}╚══════════════════════════════════════════════════╝${NC}\n"

echo -e "${CYAN}✓${NC} Repositorios: Arch, chaotic-aur; helper paru"
echo -e "${CYAN}✓${NC} Desktop: Hyprland + Waybar + Kitty + Dolphin"
echo -e "${CYAN}✓${NC} Wallpapers: $(find "$WALLPAPER_DEST" -mindepth 1 -maxdepth 1 ! -name '.*' -printf '.' 2>/dev/null | wc -c) disponibles"
echo -e "${CYAN}✓${NC} Terminal: Zsh + Powerlevel10k (usuario y root)"
echo -e "${CYAN}•${NC} Paquetes opcionales seleccionados: ${#SELECTED_APPS[@]}; fallos: ${#FAILED_APPS[@]}"

echo -e "\n${YELLOW}Hotkeys útiles:${NC}"
echo -e "  ${GREEN}Win+Return${NC}     → Kitty (terminal)"
echo -e "  ${GREEN}Win+D${NC}          → Wofi (launcher)"
echo -e "  ${GREEN}Win+E${NC}          → Dolphin (file manager)"
echo -e "  ${GREEN}Win+Shift+S${NC}    → Screenshot"
echo -e "  ${GREEN}Win+Alt+W${NC}      → Cambiar wallpaper (selector)"
echo -e "  ${GREEN}Win+Alt+T${NC}      → BLACK-ICE Control · Apariencia"
echo -e "  ${GREEN}Win+Alt+R${NC}      → Cambiar estilo Wofi"
echo -e "  ${GREEN}Win+Alt+F${NC}      → Toggle WiFi"
echo -e "  ${GREEN}Win+Q${NC}          → Cerrar ventana
  ${GREEN}Win+Shift+N${NC}    → Toggle widget de música (eww)"
echo -e "  ${GREEN}XF86Audio*${NC}     → Volumen/Mute/Mic (teclas multimedia)"
echo -e "  ${GREEN}XF86Brightness*${NC}→ Brillo pantalla"

success "Finalización completada"
