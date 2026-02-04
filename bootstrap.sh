#!/bin/bash
#
# BLACK-ICE ARCH - Bootstrap Installer
# One-command installation from Arch Linux LiveCD
# 
# Usage: curl -L http://is.gd/blackice | bash
#        curl -L https://cutt.ly/blackice | bash
#
# Author: Francisco Aravena (P4nX0Z)
# Repository: https://github.com/panxos/BLACK-ICE-HYPER_ARCH.git
# Version: 1.0
#

set -e

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly NC='\033[0m'

# Configuration
readonly REPO_URL="https://github.com/panxos/BLACK-ICE-HYPER_ARCH.git"
readonly INSTALL_DIR="/tmp/black-ice-arch"
readonly LOG_DIR="$INSTALL_DIR/logs"
readonly LOG_FILE="$LOG_DIR/bootstrap.log"
readonly BRANCH="main"

# Pre-initialize log dir
mkdir -p "$LOG_DIR"
exec > >(tee -i "$LOG_FILE") 2>&1

# Banner
show_banner() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║     ██████╗ ██╗      █████╗  ██████╗██╗  ██╗                  ║
║     ██╔══██╗██║     ██╔══██╗██╔════╝██║ ██╔╝                  ║
║     ██████╔╝██║     ███████║██║     █████╔╝                   ║
║     ██╔══██╗██║     ██╔══██║██║     ██╔═██╗                   ║
║     ██████╔╝███████╗██║  ██║╚██████╗██║  ██╗                  ║
║     ╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝                  ║
║                                                                ║
║              ICE ARCH - Automated Installer                    ║
║          Hyprland + Security Tools + Cyberpunk Theme           ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${MAGENTA}Author:${NC} Francisco Aravena (P4nX0Z)"
    echo -e "${MAGENTA}Repository:${NC} ${REPO_URL}"
    echo ""
}

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $*"
}

log_error() {
    echo -e "${RED}[✗]${NC} $*"
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Este script debe ejecutarse como root (especialmente en la ISO de Arch)"
        log_info "Usa: sudo bash o ejecuta como usuario root"
        exit 1
    fi
}

# Check internet connection
check_internet() {
    log_info "Verificando conexión a Internet..."
    if ping -c 1 8.8.8.8 &> /dev/null || ping -c 1 1.1.1.1 &> /dev/null; then
        log_success "Conexión a Internet OK"
        return 0
    else
        log_error "No hay conexión a Internet"
        log_warn "Verifica tu conexión de red y vuelve a intentar"
        exit 1
    fi
}

# Check if running on Arch Linux LiveCD
check_arch_livecd() {
    log_info "Verificando entorno Arch Linux..."
    
    if [ ! -f /etc/arch-release ]; then
        log_error "Este script debe ejecutarse en Arch Linux"
        exit 1
    fi
    
    log_success "Arch Linux detectado"
}

# --- Resilience: Retry Logic ---
retry_command() {
    local n=1
    local max=3
    local delay=5
    while true; do
        if "$@"; then
            return 0
        else
            if [[ $n -lt $max ]]; then
                ((n++))
                log_warn "Fallo en comando: $*. Reintentando ($n/$max) en ${delay}s..."
                sleep $delay
            else
                log_error "Comando falló tras $max intentos: $*"
                return 1
            fi
        fi
    done
}

# Install required dependencies for bootstrap
install_dependencies() {
    log_info "Instalando dependencias necesarias..."
    
    # Update package database
    retry_command pacman -Sy --noconfirm || {
        log_error "Error crítico: No se pudo actualizar la base de datos de paquetes."
        exit 1
    }
    
    # Install git if not present
    if ! command -v git &> /dev/null; then
        log_info "Instalando git..."
        retry_command pacman -S --needed --noconfirm git || {
            log_error "Error crítico: No se pudo instalar git."
            exit 1
        }
        log_success "Git instalado"
    else
        log_success "Git ya está instalado"
    fi
}

# Clone repository
clone_repository() {
    log_info "Clonando repositorio BLACK-ICE ARCH..."
    
    # Remove existing directory if present
    if [ -d "$INSTALL_DIR" ]; then
        log_warn "Directorio existente encontrado, eliminando..."
        rm -rf "$INSTALL_DIR"
    fi
    
    # Clone repository
    if retry_command git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$INSTALL_DIR"; then
        log_success "Repositorio clonado exitosamente"
    else
        log_error "Error crítico: No se pudo clonar el repositorio."
        log_info "Verifica que la URL sea correcta o tu conexión: $REPO_URL"
        exit 1
    fi
}

# Set permissions
set_permissions() {
    log_info "Configurando permisos de ejecución..."
    
    cd "$INSTALL_DIR" || exit 1
    
    # Make install.sh executable
    if [ -f "install.sh" ]; then
        chmod +x install.sh
        log_success "Permisos configurados para install.sh"
    else
        log_error "No se encontró install.sh en el repositorio"
        exit 1
    fi
    
    # Make all scripts in src/ executable
    if [ -d "src" ]; then
        find src -type f -name "*.sh" -exec chmod +x {} \;
        log_success "Permisos configurados para scripts en src/"
    fi
}

# Show pre-installation information
show_info() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                  ${YELLOW}INFORMACIÓN IMPORTANTE${NC}                      ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Este instalador realizará:${NC}"
    echo ""
    echo -e "  ${GREEN}1.${NC} Particionado y formateo del disco (${RED}DESTRUCTIVO${NC})"
    echo -e "  ${GREEN}2.${NC} Instalación de Arch Linux base"
    echo -e "  ${GREEN}3.${NC} Configuración de Hyprland + Waybar"
    echo -e "  ${GREEN}4.${NC} Instalación de herramientas de seguridad"
    echo -e "  ${GREEN}5.${NC} Aplicación de tema cyberpunk"
    echo -e "  ${GREEN}6.${NC} Configuración de SDDM"
    echo ""
    echo -e "${RED}⚠️  ADVERTENCIA:${NC}"
    echo -e "  - Se ${RED}BORRARÁN TODOS LOS DATOS${NC} del disco seleccionado"
    echo -e "  - Asegúrate de tener ${YELLOW}backups${NC} de información importante"
    echo -e "  - Verifica que estás en el ${YELLOW}disco correcto${NC}"
    echo ""
    echo -e "${CYAN}Ubicación del instalador:${NC} $INSTALL_DIR"
    echo ""
}

# Execute installer
execute_installer() {
    log_info "Iniciando instalador BLACK-ICE ARCH..."
    echo ""
    
    cd "$INSTALL_DIR" || exit 1
    
    # Execute install.sh
    if [ -f "install.sh" ]; then
        exec ./install.sh
    else
        log_error "No se encontró install.sh"
        exit 1
    fi
}

# Main execution
main() {
    show_banner
    
    # Pre-flight checks
    check_root
    check_arch_livecd
    check_internet
    
    # Bootstrap process
    install_dependencies
    clone_repository
    set_permissions
    
    # Show information
    show_info
    
    # Confirmation prompt
    echo -e "${YELLOW}¿Deseas continuar con la instalación?${NC}"
    echo -e "${CYAN}Presiona Enter para continuar o Ctrl+C para cancelar...${NC}"
    read -r < /dev/tty
    
    # Execute installer
    execute_installer
}

# Trap errors
trap 'log_error "Error en línea $LINENO. Abortando."; exit 1' ERR

# Run main
main "$@"
