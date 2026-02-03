#!/bin/bash
# ==============================================================================
# DEPLOY HYPRLAND - BLACK-ICE ARCH
# Deployment script for Hyprland with security tools
# ==============================================================================
# Author: Francisco Aravena (P4nx0s)
# GitHub: https://github.com/panxos
# ==============================================================================

# --- Manejo de Interrupciones (SIGINT / Ctrl+C) ---
cleanup() {
    echo -e "\n\n${RED}!!! DESPLIEGUE INTERRUMPIDO (Ctrl+C) !!!${NC}"
    echo -e "${YELLOW}[WARN] El sistema puede haber quedado en un estado parcial.${NC}"
    log_error "Despliegue cancelado por el usuario (SIGINT)."
    exit 130
}

trap cleanup SIGINT

# --- Variables Globales ---
# SOTA: SCRIPT_DIR es la raíz del proyecto
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
DOTFILES_DIR="$SCRIPT_DIR/dotfiles"

# --- Logging Setup (Global Redirection) ---
# Save original stdout/stderr for interactive menus (whiptail/read)
exec 3>&1
exec 4>&2

# Captura TODO (stdout y stderr) en un archivo de log y lo muestra en pantalla
LOG_FILE="$HOME/black_ice_deploy.log"
exec > >(tee -i "$LOG_FILE") 2>&1
echo "--- BLACK-ICE DEPLOYMENT STARTED: $(date) ---"


# --- Importar utilidades y colores SOTA ---
source "$SCRIPT_DIR/src/lib/colors.sh"
source "$SCRIPT_DIR/src/lib/logging.sh"
source "$SCRIPT_DIR/src/lib/utils.sh"

# --- Verificar que NO sea root ---
if [ "$EUID" -eq 0 ]; then
    log_error "Este script NO debe ejecutarse como root."
    log_info "Ejecuta como usuario normal (usará sudo cuando sea necesario)"
    exit 1
fi

# Obtener usuario actual
CURRENT_USER=$(whoami)
USER_HOME="/home/$CURRENT_USER"

# Banner will be shown by the first module (repositories)

log_info "Iniciando despliegue de Hyprland para $CURRENT_USER..."
echo ""

# --- Módulos de instalación ---
log_info "Ejecutando módulos de instalación..."

# 1. Repositorios (yay, chaotic-aur, BlackArch)
source "$SCRIPT_DIR/src/deploy/00_repositories.sh"

# 2. Hyprland y componentes base
source "$SCRIPT_DIR/src/deploy/01_hyprland_base.sh"

# 3. Herramientas de seguridad
source "$SCRIPT_DIR/src/deploy/02_security_tools.sh"

# 4. Configuración de terminal (Zsh)
source "$SCRIPT_DIR/src/deploy/03_terminal_config.sh"

# 5. Tema y personalización
source "$SCRIPT_DIR/src/deploy/04_theme_setup.sh"

# 5. Software Suite Premium (Checklist Interactivo)
source "$SCRIPT_DIR/src/deploy/05_software_suite.sh"

# 6. Configuración SDDM (CyberSec Theme)
source "$SCRIPT_DIR/src/deploy/06_sddm_setup.sh"

# 7. Finalización
source "$SCRIPT_DIR/src/deploy/99_finalization.sh"

echo ""
success "¡Despliegue de Hyprland completado!"
echo ""
echo -e "${NEON_CYAN}Próximos pasos:${NC}"
echo -e "  1. ${YELLOW}Cierra sesión${NC}"
echo -e "  2. En el login manager, selecciona ${GREEN}Hyprland${NC}"
echo -e "  3. Inicia sesión"
echo -e "  4. ${CYAN}Win+Return${NC} abre Kitty"
echo -e "  5. ${CYAN}Win+D${NC} abre launcher (wofi)"
echo -e "  6. ${CYAN}Win+Alt+W${NC} cambia wallpaper"
echo -e "  7. ${CYAN}Win+Alt+T${NC} cambia tema"
echo -e "  8. ${CYAN}Win+L${NC} bloquea sesión (Cyberpunk Lock)"
echo ""

exit 0
