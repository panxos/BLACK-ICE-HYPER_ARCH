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
echo -e "  ${GREEN}Win+Q${NC}          → Cerrar ventana"
echo -e "  ${GREEN}XF86Audio*${NC}     → Volumen/Mute/Mic (teclas multimedia)"
echo -e "  ${GREEN}XF86Brightness*${NC}→ Brillo pantalla"

success "Finalización completada"
