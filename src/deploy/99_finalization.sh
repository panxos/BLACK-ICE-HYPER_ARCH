#!/bin/bash
# deploy-modules/99_finalization.sh
# Tareas finales y mensajes

banner "FINALIZACIÓN" "Últimos ajustes"

# --- Crear directorios XDG del usuario ---
log_info "Creando directorios XDG (Desktop, Downloads, etc.)..."
sudo -u $CURRENT_USER xdg-user-dirs-update
chown -R "$CURRENT_USER:$CURRENT_USER" "$USER_HOME"

# --- Hacer ejecutables los módulos ---
chmod +x "$SCRIPT_DIR/src/deploy/"*.sh

# --- BLACK-ICE  FIXES (Antigravity & Udiskie) ---
log_info "Aplicando blindaje  para Antigravity y Udiskie..."

# 1. Crear directorio de binarios de usuario si no existe
mkdir -p "$USER_HOME/.config/bin"

# 2. Wrapper para Antigravity (Mimetismo GNOME para OAuth)
cat << 'EOF' > "$USER_HOME/.config/bin/antigravity-fix"
#!/bin/bash
# antigravity-fix - P4nx0z Edition
export XDG_CURRENT_DESKTOP=GNOME
export DE=gnome
export WAYLAND_DISPLAY=wayland-1
export XDG_SESSION_TYPE=wayland
export BROWSER=brave
export GTK_USE_PORTAL=1
/usr/bin/antigravity --password-store=basic --disable-gpu-sandbox "$@"
EOF
chmod +x "$USER_HOME/.config/bin/antigravity-fix"

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
echo -e "  ${GREEN}Win+Alt+W${NC}      → Cambiar wallpaper"
echo -e "  ${GREEN}Win+Alt+T${NC}      → Cambiar tema"
echo -e "  ${GREEN}Win+Q${NC}          → Cerrar ventana"

success "Finalización completada"
