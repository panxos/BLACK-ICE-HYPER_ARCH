#!/bin/bash
# deploy-modules/99_finalization.sh
# Tareas finales y mensajes

banner "FINALIZACIÓN" "Últimos ajustes"

# --- Crear directorios XDG del usuario ---
log_info "Creando directorios XDG (Desktop, Downloads, etc.)..."
sudo -u $CURRENT_USER xdg-user-dirs-update
chown -R $CURRENT_USER:$CURRENT_USER "$USER_HOME"

# --- Hacer ejecutables los módulos ---
chmod +x "$SCRIPT_DIR/src/deploy/"*.sh

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
