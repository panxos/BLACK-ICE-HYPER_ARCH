#!/bin/bash
# deploy-modules/00_repositories.sh
# Configura yay, chaotic-aur, y BlackArch

banner "MÓDULO 1" "BLACK-ICE Repositorios"

# --- Optimización Geográfica (Mirrors) ---
# Intentar cargar configuración del instalador
# Buscamos en el directorio del script o en /root como respaldo
if [ -f "$SCRIPT_DIR/install.conf.auto" ]; then
    CONF_FILE="$SCRIPT_DIR/install.conf.auto"
elif [ -f "/root/BLACK-ICE_ARCH/install.conf.auto" ]; then
    CONF_FILE="/root/BLACK-ICE_ARCH/install.conf.auto"
fi

if [ -n "$CONF_FILE" ]; then
    source "$CONF_FILE"
    log_info "Pre-detección de país: $SELECTED_COUNTRY (vía $(basename "$CONF_FILE"))"
else
    SELECTED_COUNTRY="Chile" # Default safe
fi

log_info "Optimizando mirrors para $SELECTED_COUNTRY..."
REFLECTOR_COUNTRIES=""
case "$SELECTED_COUNTRY" in
    "Chile")   REFLECTOR_COUNTRIES="Chile,Brazil,United States" ;;
    "Brazil")  REFLECTOR_COUNTRIES="Brazil,Chile,United States" ;;
    "Spain")   REFLECTOR_COUNTRIES="Spain,France,Germany" ;;
    "Germany") REFLECTOR_COUNTRIES="Germany,France,Netherlands" ;;
    *)         REFLECTOR_COUNTRIES="$SELECTED_COUNTRY" ;;
esac

# Ejecutar reflector de forma condicional
if command -v reflector &>/dev/null; then
    echo -e "${YELLOW}>> ¿Optimizar mirrors con reflector?"
    echo -e "   Esto puede tardar unos minutos pero mejora la velocidad de descarga.${NC}"
    echo -n "   [y/N]: "
    read -r -t 10 OPT_MIRRORS || OPT_MIRRORS="n"
    echo ""
    
    if [[ "$OPT_MIRRORS" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}>> OPTIMIZANDO MIRRORS... (NO CANCELE EL PROCESO)${NC}"
        sudo -n reflector --country "$REFLECTOR_COUNTRIES" --protocol https --latest 100 --number 10 --sort rate --connection-timeout 5 --download-timeout 5 --verbose --save /etc/pacman.d/mirrorlist || true
        success "Nodos de descarga optimizados (Georeferencia: $SELECTED_COUNTRY)"
    else
        log_info "Saltando optimización de mirrors (opción del usuario)."
    fi
fi

# --- Instalar yay (AUR Helper) ---
if ! command -v yay &> /dev/null; then
    log_info "Instalando yay (AUR Helper)..."
    
    # Dependencias para compilar
    retry_command sudo -n pacman -S --needed --noconfirm base-devel git
    
    # Clonar y compilar yay
    cd /tmp
    rm -rf yay
    retry_command git clone https://aur.archlinux.org/yay.git || { log_error "No se pudo clonar yay"; exit 1; }
    cd yay
    
    # makepkg no puede ejecutarse como root, pero necesita dependencias
    # makepkg -s instalará las dependencias usando sudo -n automáticamente
    makepkg -si --noconfirm --needed || {
        log_warn "makepkg estándar falló. Intentando instalación forzada de dependencias..."
        sudo -n pacman -S --needed --noconfirm go
        makepkg -si --noconfirm --needed
    }
    
    log_info "Retornando al directorio principal: $SCRIPT_DIR"
    cd "$SCRIPT_DIR"
    
    success "yay instalado correctamente"
else
    log_info "yay ya está instalado"
fi

log_info "Verificando siguiente fase: chaotic-aur"

# --- Añadir chaotic-aur ---
if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
    log_info "Añadiendo repositorio chaotic-aur..."
    
    # Importar claves
    retry_command sudo -n pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    retry_command sudo -n pacman-key --lsign-key 3056513887B78AEB
    
    # Instalar keyring y mirrorlist
    retry_command sudo -n pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
    
    # Añadir al pacman.conf
    echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | sudo -n tee -a /etc/pacman.conf
    
    # Actualizar bases de datos
    retry_command sudo -n pacman -Sy
    
    success "chaotic-aur añadido correctamente"
else
    log_info "chaotic-aur ya está configurado"
fi

# --- Añadir BlackArch (Método Tradicional) ---
if ! grep -q "\[blackarch\]" /etc/pacman.conf; then
    log_info "Añadiendo repositorio BlackArch mediante strap.sh..."
    
    # Descargar el script oficial
    cd /tmp
    retry_command curl -O https://blackarch.org/strap.sh
    
    # Convertir en ejecutable
    chmod +x strap.sh
    
    # Ejecutar con privilegios elevados (formato tradicional)
    retry_command sudo -n ./strap.sh
    
    # Optimizar mirrors (Halifax suele fallar)
    log_info "Optimizando lista de mirrors de BlackArch..."
    sudo -n sed -i 's/^Server = .*halifax.rwth-aachen.de/#&/' /etc/pacman.d/blackarch-mirrorlist
    sudo -n sed -i '/mirror.cedia.org.ec/s/^#//' /etc/pacman.d/blackarch-mirrorlist
    sudo -n sed -i '/mirrors.ocf.berkeley.edu/s/^#//' /etc/pacman.d/blackarch-mirrorlist
    sudo -n sed -i '/ftp2.osuosl.org/s/^#//' /etc/pacman.d/blackarch-mirrorlist
    
    # Limpieza
    rm strap.sh
    
    # Actualizar bases de datos sincronizando doble
    retry_command sudo -n pacman -Syy
    
    success "Repositorio BlackArch configurado y mirrors optimizados"
else
    log_info "El repositorio BlackArch ya se encuentra en /etc/pacman.conf"
fi

# --- Actualizar sistema ---
log_info "Actualizando sistema completo..."
retry_command sudo -n pacman -Syu --noconfirm

success "Repositorios configurados y sistema actualizado"
