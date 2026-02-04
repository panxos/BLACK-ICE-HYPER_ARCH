#!/bin/bash
# ==============================================================================
# BLACK-ICE ARCH - Advanced Pentesting Environment Installer
# ==============================================================================
# Author: Francisco Aravena (Alias P4nx0s)
# GitHub: https://github.com/panxos
# Web:    www.soporteinfo.net
# ========================================================================

# --- Variables Globales ---
INSTALL_DIR=$(dirname "$(readlink -f "$0")")

# --- Importar Librerías SOTA ---
source "$INSTALL_DIR/src/lib/colors.sh"
source "$INSTALL_DIR/src/lib/logging.sh"
source "$INSTALL_DIR/src/lib/utils.sh"

# --- Logging Setup (Global Redirection) ---
exec 3>&1 # Save stdout
exec 4>&2 # Save stderr

# Redirigir stdout/stderr al archivo de log y pantalla
exec > >(tee -i "$LOG_FILE") 2>&1
echo "--- BLACK-ICE INSTALLATION STARTED: $(date) ---"
log_info "Log de sesión: $LOG_FILE"

CONFIG_FILE="$INSTALL_DIR/config/install.conf"

# --- STRICT MODE ---
set -uo pipefail
# Note: We don't use 'set -e' globally yet to handle custom error traps, 
# but individual modules should be strict.

# ... (Error handling and cleanup code remains, updated with log_error)

# --- Detectar Configuración ---
if [ -f "$CONFIG_FILE" ]; then
    log_info "Cargando configuración desde: $CONFIG_FILE"
    source "$CONFIG_FILE"
    AUTO_MODE=true
else
    log_warn "No se encontró configuración. Iniciando modo interactivo."
fi

# ...

# --- MAIN INSTALLATION FLOW ---

banner "SYSTEM INITIALIZATION" "v2.0.0 (SOTA Edition)"

log_info "Inicializando protocolo de instalación BLACK-ICE..."

# 1. Environment Checks & Network
source "$INSTALL_DIR/src/modules/00_environment.sh"

# --- Check for Existing System (Idempotency) ---
if [ -f "/etc/black-ice-release" ] || [ -f "/mnt/etc/black-ice-release" ]; then
    log_warn "Sistema BLACK-ICE detectado."
    read -p "¿Desea reinstalar el sistema base y formatear disco? (y/N) " REINSTALL_CHOICE < /dev/tty
    if [[ ! "$REINSTALL_CHOICE" =~ ^[Yy]$ ]]; then
        log_info "Saltando formateo e instalación base. Pasando a configuración..."
        SKIP_BASE=true
    else
        SKIP_BASE=false
    fi
else
    SKIP_BASE=false
fi

if [ "$SKIP_BASE" = false ]; then
    # 2. Disk Partitioning (Secure Wipe & Encryption)
    source "$INSTALL_DIR/src/modules/01_disk.sh"

    # 3. Base System Install (Kernel Selection Hardened/Zen)
    source "$INSTALL_DIR/src/modules/02_base.sh"
else
    log_info "Modo de recuperación/reconfiguración activo."
    # Ensure /mnt is mounted if checking headers
    # mount_partitions logic would go here if needed for chroot
fi

# 4. System Configuration
source "$INSTALL_DIR/src/modules/03_config.sh"

# 5. User & Root Setup (Wheel/Sudoers)
source "$INSTALL_DIR/src/modules/04_user.sh"

# 6. Bootloader (GRUB Encrypted)
source "$INSTALL_DIR/src/modules/05_bootloader.sh"

# 7. Post-Install Prep (Deployment Scripts)
source "$INSTALL_DIR/src/modules/99_final.sh"


echo
    echo -e "${NEON_GREEN}    ███████╗██╗  ██╗██╗████████╗ ██████╗ ${NC}"
    echo -e "${NEON_GREEN}    ██╔════╝╚██╗██╔╝██║╚══██╔══╝██╔═══██╗${NC}"
    echo -e "${NEON_GREEN}    █████╗   ╚███╔╝ ██║   ██║   ██║   ██║${NC}"
    echo -e "${NEON_GREEN}    ██╔══╝   ██╔██╗ ██║   ██║   ██║   ██║${NC}"
    echo -e "${NEON_GREEN}    ███████╗██╔╝ ██╗██║   ██║   ╚██████╔╝${NC}"
    echo -e "${NEON_GREEN}    ╚══════╝╚═╝  ╚═╝╚═╝   ╚═╝    ╚═════╝ ${NC}"
echo
echo -e "${NEON_BLUE}>> SISTEMA LISTO PARA REINICIO.${NC}"
echo -e "${NEON_BLUE}>> Logueate con tu usuario: ${WHITE}${BOLD}$USER_NAME${NC}${NEON_BLUE} (NO USAR ROOT).${NC}"
echo -e "${NEON_BLUE}>> Ejecuta 'deploy_hyprland.sh' tras entrar a tu sesión.${NC}"
echo -e "\n${YELLOW}${BOLD}[!] IMPORTANTE (GRUB LUKS Prompt):${NC}"
echo -e "${YELLOW}El primer prompt de contraseña (el de pantalla negra de GRUB) utiliza teclado US.${NC}"
echo -e "${YELLOW}Si tu clave tiene '-', usa la tecla a la derecha del '0' en esa pantalla.${NC}"
echo -e "\nEscribe ${BOLD}reboot${NC} para reiniciar."

# --- Guardar configuración para uso futuro con escapado seguro ---
log_info "Respaldando configuración de sesión (install.conf.auto)..."
CONFIG_FILE="$INSTALL_DIR/install.conf.auto"
{
    echo "# BLACK-ICE ARCH - Configuración Auto-Generada"
    printf "KEYBOARD_LAYOUT=%q\n" "${KEYMAP:-us}"
    printf "TARGET_DISK=%q\n" "${DISK#/dev/}"
    printf "ENABLE_LUKS=%q\n" "$( [ "$ENCRYPT" == "true" ] && echo "yes" || echo "no" )"
    printf "LUKS_PASSWORD=%q\n" "$LUKS_PASS"
    printf "FILESYSTEM=%q\n" "${FILESYSTEM:-ext4}"
    printf "KERNEL=%q\n" "${SELECTED_KERNEL:-linux}"
    printf "TIMEZONE=%q\n" "${TIMEZONE:-America/Santiago}"
    printf "SYSTEM_LANG=%q\n" "${SYSTEM_LANG:-es_CL}"
    printf "SYSTEM_LOCALE=%q\n" "${SYSTEM_LOCALE:-es_CL}"
    printf "SELECTED_COUNTRY=%q\n" "${SELECTED_COUNTRY:-Chile}"
    printf "HOSTNAME=%q\n" "${HOSTNAME:-black-ice}"
    printf "NVME_STABILITY=%q\n" "${NVME_STABILITY:-no}"
    printf "USERNAME=%q\n" "${USER_NAME:-admin}"
    echo "#Nota: Las contraseñas de root y usuario no se guardan por seguridad en este archivo auto-generado"
} > "$CONFIG_FILE"

exit 0
