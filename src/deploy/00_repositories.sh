#!/bin/bash
# deploy-modules/00_repositories.sh
# Configura chaotic-aur primero, luego paru desde chaotic-aur (ABI siempre correcta)

banner "MÓDULO 1" "BLACK-ICE Repositorios"
cd "$USER_HOME" || exit 1

# --- Optimización Geográfica (Mirrors) ---
CONF_FILE=""
if [ -f "$SCRIPT_DIR/install.conf.auto" ]; then
    CONF_FILE="$SCRIPT_DIR/install.conf.auto"
elif [ -f "/root/BLACK-ICE_ARCH/install.conf.auto" ]; then
    CONF_FILE="/root/BLACK-ICE_ARCH/install.conf.auto"
fi

if [ -n "$CONF_FILE" ]; then
    source "$CONF_FILE"
    log_info "Pre-detección de país: $SELECTED_COUNTRY (vía $(basename "$CONF_FILE"))"
else
    SELECTED_COUNTRY="Chile"
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

if ! command -v reflector &>/dev/null; then
    log_info "Instalando reflector..."
    sudo pacman -S --noconfirm reflector
fi

if command -v reflector &>/dev/null; then
    echo -e "${YELLOW}>> ¿Optimizar mirrors con reflector?"
    echo -e "   Esto puede tardar unos minutos pero mejora la velocidad de descarga.${NC}"
    echo -n "   [y/N]: "
    read -r -t 10 OPT_MIRRORS < /dev/tty || OPT_MIRRORS="n"
    echo ""

    if [[ "$OPT_MIRRORS" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}>> OPTIMIZANDO MIRRORS... (NO CANCELE EL PROCESO)${NC}"
        sudo -n reflector --country "$REFLECTOR_COUNTRIES" --protocol https --latest 100 --number 10 --sort rate --connection-timeout 5 --download-timeout 5 --verbose --save /etc/pacman.d/mirrorlist || true
        success "Nodos de descarga optimizados (Georeferencia: $SELECTED_COUNTRY)"
    else
        log_info "Saltando optimización de mirrors (opción del usuario)."
    fi
fi

# --- Chaotic-AUR PRIMERO (paru vive aquí, compilado contra pacman actual) ---
log_info "Verificando siguiente fase: chaotic-aur"
if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
    log_info "Añadiendo repositorio chaotic-aur..."

    retry_command sudo -n pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com || \
    retry_command sudo -n pacman-key --recv-key 3056513887B78AEB --keyserver hkps://keys.gnupg.net

    retry_command sudo -n pacman-key --lsign-key 3056513887B78AEB

    retry_command sudo -n pacman -U --noconfirm \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

    sudo -n pacman-key --populate archlinux chaotic

    echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | sudo -n tee -a /etc/pacman.conf

    retry_command sudo -n pacman -Sy

    success "chaotic-aur añadido correctamente"
else
    log_info "chaotic-aur ya está configurado"
    sudo -n pacman-key --populate archlinux chaotic >/dev/null 2>&1 || true
    sudo -n pacman -Sy --noconfirm >/dev/null 2>&1 || true
fi

# --- Actualizar sistema ANTES de instalar paru (ABI correcta garantizada) ---
log_info "Actualizando sistema completo..."
retry_command sudo -n pacman -Syu --noconfirm

# --- Instalar paru desde chaotic-aur (compilado contra el pacman actual del sistema) ---
# paru-bin de AUR es un binario pre-compilado: queda roto si pacman sube de versión mayor.
# chaotic-aur provee 'paru' compilado fresh contra la libalpm del sistema — siempre compatible.
_PARU_OK=false
if command -v paru &>/dev/null && paru --version &>/dev/null 2>&1; then
    _PARU_OK=true
fi

if [ "$_PARU_OK" = false ]; then
    log_info "Instalando paru desde chaotic-aur..."
    # Eliminar CUALQUIER versión previa (paru-bin conflicta con paru de chaotic-aur)
    sudo -n pacman -Rns --noconfirm paru-bin 2>/dev/null || true
    sudo -n pacman -Rns --noconfirm paru 2>/dev/null || true

    # Instalar desde chaotic-aur (compilado contra libalpm del sistema)
    if sudo -n pacman -S --noconfirm --needed paru; then
        log_success "paru instalado desde chaotic-aur ($(paru --version | head -1))"
    else
        # Fallback: compilar desde AUR (requiere Rust, más lento pero siempre funciona)
        log_warn "paru no disponible en chaotic-aur. Compilando desde AUR (puede tardar)..."
        retry_command sudo -n pacman -S --needed --noconfirm base-devel git rust
        cd /tmp || { log_error "No se pudo acceder a /tmp"; return 1; }
        rm -rf paru
        retry_command git clone https://aur.archlinux.org/paru.git || { log_error "No se pudo clonar paru"; exit 1; }
        cd paru || { log_error "No se pudo entrar al directorio paru"; exit 1; }
        makepkg -si --noconfirm --needed || { log_error "makepkg falló para paru"; exit 1; }
        cd "$SCRIPT_DIR" || { log_error "No se pudo volver a SCRIPT_DIR"; exit 1; }
        log_success "paru compilado e instalado ($(paru --version | head -1))"
    fi
else
    log_info "paru operativo ($(paru --version | head -1))"
fi

# BlackArch eliminado (v3.2+): Issues GPG/SHA1 persistentes. Tools vía AUR + Chaotic-AUR.
success "Repositorios configurados y sistema actualizado"
