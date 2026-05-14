#!/bin/bash
# deploy-modules/99_finalization.sh
# Tareas finales y mensajes

banner "FINALIZACIÓN" "Últimos ajustes"

# --- Crear directorios XDG del usuario ---
log_info "Creando directorios XDG (Desktop, Downloads, etc.)..."
sudo -u $CURRENT_USER xdg-user-dirs-update
# Crear directorio Screenshots explícitamente (grim lo necesita)
mkdir -p "$USER_HOME/Pictures/Screenshots"
chown -R "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/Pictures"
chown -R "$CURRENT_USER:$CURRENT_USER" "$USER_HOME"

# --- Hacer ejecutables los módulos ---
chmod +x "$SCRIPT_DIR/src/deploy/"*.sh

# --- BLACK-ICE  FIXES (Antigravity & Udiskie) ---
log_info "Aplicando blindaje  para Antigravity y Udiskie..."

# 1. Asegurar que ~/.config/bin existe (puede ser symlink a ~/bin — no usar mkdir -p si es symlink)
if [ ! -e "$USER_HOME/.config/bin" ]; then
    mkdir -p "$USER_HOME/bin"
    ln -sf "$USER_HOME/bin" "$USER_HOME/.config/bin"
fi

# 2. Wrapper para Antigravity (Mimetismo GNOME para OAuth)
cat << 'EOF' > "$USER_HOME/.config/bin/antigravity-fix"
#!/bin/bash
# antigravity-fix - P4nx0z Edition
export XDG_CURRENT_DESKTOP=GNOME
export DE=gnome
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export XDG_SESSION_TYPE=wayland
export BROWSER=brave
export GTK_USE_PORTAL=1
/usr/bin/antigravity --password-store=basic --disable-gpu-sandbox "$@"
EOF
chmod +x "$USER_HOME/.config/bin/antigravity-fix"

# 2b. Fix xdg-open para OAuth en CLI tools (gemini-cli, qwen-cli, etc.)
# Instala wrapper que garantiza apertura de browser en Wayland
mkdir -p "$USER_HOME/.local/bin"
chown "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.local/bin"
if [ -f "$SCRIPT_DIR/dotfiles/bin/xdg-open-wayland" ]; then
    cp "$SCRIPT_DIR/dotfiles/bin/xdg-open-wayland" "$USER_HOME/.local/bin/xdg-open"
    chmod +x "$USER_HOME/.local/bin/xdg-open"
    chown "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.local/bin/xdg-open"
    log_success "xdg-open → wrapper Wayland instalado en ~/.local/bin/"
fi

# Configurar browser por defecto
sudo -u "$CURRENT_USER" xdg-settings set default-web-browser brave-browser.desktop 2>/dev/null || \
    sudo -u "$CURRENT_USER" xdg-settings set default-web-browser brave.desktop 2>/dev/null || true

# --- Waypaper config (subfolders habilitados para .webp en subdirectorios) ---
mkdir -p "$USER_HOME/.config/waypaper"
if [ -f "$SCRIPT_DIR/dotfiles/waypaper/config.ini" ]; then
    cp "$SCRIPT_DIR/dotfiles/waypaper/config.ini" "$USER_HOME/.config/waypaper/config.ini"
    chown "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.config/waypaper/config.ini"
    log_success "waypaper config instalada (subfolders=True)"
fi

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

# 4. Blindar el .desktop de Antigravity
mkdir -p "$USER_HOME/.local/share/applications"
cat > "$USER_HOME/.local/share/applications/antigravity.desktop" << EOF
[Desktop Entry]
Name=Antigravity
Comment=Experience liftoff (P4nx0z Fix Edition)
GenericName=Text Editor
Exec=$USER_HOME/.config/bin/antigravity-fix %F
Icon=antigravity
Type=Application
StartupNotify=false
StartupWMClass=Antigravity
Categories=TextEditor;Development;IDE;
MimeType=application/x-antigravity-workspace;
Actions=new-empty-window;
Keywords=vscode;

[Desktop Action new-empty-window]
Name=New Empty Window
Exec=$USER_HOME/.config/bin/antigravity-fix --new-window %F
Icon=antigravity
EOF

# 5. Asegurar que el Keybind en hyprland.conf apunte al wrapper
if [ -f "$USER_HOME/.config/hypr/hyprland.conf" ]; then
    sed -i "s|bind = \$mainMod SHIFT, A, exec, .*|bind = \$mainMod SHIFT, A, exec, bash -l -c \"${USER_HOME}/.config/bin/antigravity-fix\"|g" "$USER_HOME/.config/hypr/hyprland.conf"
fi

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

# sysctl: CPU scheduling, red, memoria
cat > /etc/sysctl.d/99-black-ice-performance.conf << 'EOF'
# BLACK-ICE ARCH - Performance Tuning
vm.swappiness = 5
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
vm.vfs_cache_pressure = 50
# Evita que CPU quede fijo a frecuencia máxima (residuo de auto-cpufreq)
kernel.sched_util_clamp_min = 0
# TCP BBR + fq (mejor throughput en redes modernas)
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.core.netdev_max_backlog = 16384
net.ipv4.tcp_fastopen = 3
net.ipv4.ip_local_port_range = 1024 65535
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
kernel.nmi_watchdog = 0
kernel.unprivileged_userns_clone = 1
kernel.perf_event_paranoid = 1
EOF
sysctl --system &>/dev/null || true
log_success "sysctl aplicado (BBR, sched_util_clamp_min=0)"

# journald: limitar tamaño del log
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/size-limit.conf << 'EOF'
[Journal]
SystemMaxUse=200M
SystemKeepFree=500M
MaxRetentionSec=2week
Compress=yes
EOF
log_success "journald limitado a 200M"

# --- Generar resumen de instalación ---
log_info "Generando resumen..."

echo -e "\n${NEON_PURPLE}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${NEON_PURPLE}║${NC}  ${BOLD}RESUMEN DE INSTALACIÓN${NC}                          ${NEON_PURPLE}║${NC}"
echo -e "${NEON_PURPLE}╚══════════════════════════════════════════════════╝${NC}\n"

echo -e "${CYAN}✓${NC} Repositorios: yay, chaotic-aur, BlackArch"
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
