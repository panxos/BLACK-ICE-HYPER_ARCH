#!/bin/bash
# deploy-modules/99_finalization.sh
# Tareas finales y mensajes

banner "FINALIZACIÓN" "Últimos ajustes"

# --- Crear directorios XDG del usuario ---
log_info "Creando directorios XDG (Desktop, Downloads, etc.)..."
sudo -u "$CURRENT_USER" xdg-user-dirs-update
# Crear directorio Screenshots explícitamente (grim lo necesita)
mkdir -p "$USER_HOME/Pictures/Screenshots"
chown -R "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/Pictures"
chown -R "$CURRENT_USER:$CURRENT_USER" "$USER_HOME"

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
for _script in dotfiles-update dotfiles-rollback tpm2-luks-enroll; do
    if [ -f "$SCRIPT_DIR/dotfiles/bin/$_script" ]; then
        cp "$SCRIPT_DIR/dotfiles/bin/$_script" "$USER_HOME/.local/bin/$_script"
        chmod +x "$USER_HOME/.local/bin/$_script"
        chown "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.local/bin/$_script"
        log_success "$_script instalado en ~/.local/bin/"
    fi
done

# Configurar browser por defecto
sudo -u "$CURRENT_USER" xdg-settings set default-web-browser brave-browser.desktop 2>/dev/null || \
    sudo -u "$CURRENT_USER" xdg-settings set default-web-browser brave.desktop 2>/dev/null || true

# --- Fix xdg-open para Hyprland (DE desconocido cae en exit_failure) ---
# xdg-utils 1.2+ detecta DE=Hyprland pero no tiene handler → falla silencioso
# Parche: cambiar *) exit_failure → *) open_generic en el switch DE
if [ -f /usr/bin/xdg-open ]; then
    python3 -c "
import sys
with open('/usr/bin/xdg-open', 'r') as f:
    content = f.read()
old = '''    *)
    exit_failure_operation_impossible \"no method available for opening '\$url'\"
    ;;
esac'''
new = '''    *)
    open_generic \"\$url\"
    ;;
esac'''
if old in content:
    content = content.replace(old, new, 1)
    with open('/usr/bin/xdg-open', 'w') as f:
        f.write(content)
    sys.exit(0)
sys.exit(1)
" && log_success "xdg-open parcheado: Hyprland ahora usa open_generic como fallback" \
  || log_info "xdg-open: parche no aplicado (ya aplicado o versión diferente)"
fi

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
        ln -sf /etc/xdg/menus/plasma-applications.menu /etc/xdg/menus/applications.menu
        log_success "symlink applications.menu → plasma-applications.menu creado"
    else
        log_warn "plasma-applications.menu no encontrado — Dolphin puede tener file associations rotas"
    fi
else
    log_info "applications.menu ya existe — skip"
fi
sudo -u "$CURRENT_USER" kbuildsycoca6 2>/dev/null || true
log_success "ksycoca6 regenerado — Dolphin abre archivos por tipo correctamente"

# --- gen_theme_previews — hacer ejecutable ---
if [ -f "$USER_HOME/.config/bin/gen_theme_previews" ]; then
    chmod +x "$USER_HOME/.config/bin/gen_theme_previews"
    log_success "gen_theme_previews listo (se ejecuta en primer boot de Hyprland)"
fi

# --- Kitty color themes — instalar los 21 esquemas de color ---
log_info "Instalando esquemas de color Kitty para los 21 temas Waybar..."
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
    log_success "Kitty themes instalados ($(ls "$KITTY_THEMES_DST"/*.conf 2>/dev/null | wc -l) archivos)"
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

# 3. Wrapper para Udiskie (XWayland para icono en la tray)
cat << 'EOF' > "$USER_HOME/.config/bin/udiskie-fix"
#!/bin/bash
# udiskie-fix - P4nx0z Edition
export XDG_CURRENT_DESKTOP=Unity
export GDK_BACKEND=x11
/usr/bin/udiskie --tray --notify --automount "$@"
EOF
chmod +x "$USER_HOME/.config/bin/udiskie-fix"

# --- Propagar distribución de teclado a Hyprland ---
HYPR_CONF="$USER_HOME/.config/hypr/hyprland.conf"
if [ -f "$HYPR_CONF" ] && [ -n "${KEYBOARD_LAYOUT:-}" ]; then
    ESCAPED_LAYOUT=$(printf '%s\n' "${KEYBOARD_LAYOUT}" | sed 's/[\/&]/\\&/g')
    sed -i "s/^\(\s*kb_layout\s*=\s*\).*/\1${ESCAPED_LAYOUT}/" "$HYPR_CONF"
    log_success "Teclado '${KEYBOARD_LAYOUT}' aplicado en Hyprland (kb_layout)."
fi

# --- eww music widget ---
log_info "Instalando eww music widget..."
mkdir -p "$USER_HOME/.config/eww"
ln -sf "$DOTFILES_DIR/eww/eww.yuck" "$USER_HOME/.config/eww/eww.yuck"
ln -sf "$DOTFILES_DIR/eww/eww.scss" "$USER_HOME/.config/eww/eww.scss"
# music_widget toggle script
ln -sf "$DOTFILES_DIR/bin/music_widget" "$USER_HOME/.config/bin/music_widget"
chmod +x "$USER_HOME/.config/bin/music_widget"
chown -h "$CURRENT_USER:$CURRENT_USER" \
    "$USER_HOME/.config/eww/eww.yuck" \
    "$USER_HOME/.config/eww/eww.scss" \
    "$USER_HOME/.config/bin/music_widget"
log_success "eww music widget instalado (Win+Shift+N para toggle)"

# --- Optimizaciones de rendimiento del sistema ---
log_info "Aplicando configuración de rendimiento (sysctl + journald)..."

cat > /etc/sysctl.d/99-black-ice-performance.conf << 'EOF'
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
kernel.sched_migration_cost_ns = 500000
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
sysctl --system &>/dev/null || true
log_success "sysctl aplicado (BBR + optimizaciones Docker/KVM/pentesting)"

# Módulos kernel persistentes para Docker y KVM
_CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}')
_KVM_MODULE="kvm_intel"
[[ "$_CPU_VENDOR" == "AuthenticAMD" ]] && _KVM_MODULE="kvm_amd"

cat > /etc/modules-load.d/black-ice.conf << EOF
br_netfilter
${_KVM_MODULE}
EOF
modprobe br_netfilter 2>/dev/null || true
modprobe "${_KVM_MODULE}" 2>/dev/null || true
log_success "Módulos br_netfilter + ${_KVM_MODULE} configurados para boot"

# journald: limitar tamaño del log
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/size-limit.conf << 'EOF'
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
        cp "$DOTFILES_DIR/nftables/nftables.conf" /etc/nftables.conf
        nft -f /etc/nftables.conf 2>/dev/null || true
        systemctl enable nftables
        log_success "Firewall nftables activado (tabla inet black-ice-filter)"
    fi
else
    log_warn "nftables no instalado — instalar con: pacman -S nftables"
fi

# --- Hardening SSH ---
log_info "Aplicando hardening SSH..."
if grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config 2>/dev/null; then
    sed -i 's/^PermitRootLogin yes/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
    log_success "SSH: PermitRootLogin → prohibit-password"
fi
systemctl reload sshd 2>/dev/null || true

# --- Generar resumen de instalación ---
log_info "Generando resumen..."

echo -e "\n${NEON_PURPLE}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${NEON_PURPLE}║${NC}  ${BOLD}RESUMEN DE INSTALACIÓN${NC}                          ${NEON_PURPLE}║${NC}"
echo -e "${NEON_PURPLE}╚══════════════════════════════════════════════════╝${NC}\n"

echo -e "${CYAN}✓${NC} Repositorios: yay, chaotic-aur"
echo -e "${CYAN}✓${NC} Desktop: Hyprland + Waybar + Kitty + Dolphin"
echo -e "${CYAN}✓${NC} Wallpapers: $(ls -1 "$WALLPAPER_DEST/" 2>/dev/null | wc -l) disponibles"
echo -e "${CYAN}✓${NC} Terminal: Zsh + Powerlevel10k (usuario y root)"
echo -e "${CYAN}✓${NC} Herramientas de seguridad: Instaladas"

echo -e "\n${YELLOW}Hotkeys útiles:${NC}"
echo -e "  ${GREEN}Win+Return${NC}     → Kitty (terminal)"
echo -e "  ${GREEN}Win+D${NC}          → Wofi (launcher)"
echo -e "  ${GREEN}Win+E${NC}          → Dolphin (file manager)"
echo -e "  ${GREEN}Win+Shift+S${NC}    → Screenshot"
echo -e "  ${GREEN}Win+Alt+W${NC}      → Cambiar wallpaper (selector)"
echo -e "  ${GREEN}Win+Alt+T${NC}      → Cambiar tema Waybar"
echo -e "  ${GREEN}Win+Alt+R${NC}      → Cambiar estilo Wofi"
echo -e "  ${GREEN}Win+Alt+F${NC}      → Toggle WiFi"
echo -e "  ${GREEN}Win+Q${NC}          → Cerrar ventana
  ${GREEN}Win+Shift+N${NC}    → Toggle widget de música (eww)"
echo -e "  ${GREEN}XF86Audio*${NC}     → Volumen/Mute/Mic (teclas multimedia)"
echo -e "  ${GREEN}XF86Brightness*${NC}→ Brillo pantalla"

success "Finalización completada"
