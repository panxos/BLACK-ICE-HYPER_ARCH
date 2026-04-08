#!/bin/bash
# deploy-modules/06_sddm_setup.sh
# Instala y configura el tema SDDM CyberSec

banner "MÓDULO 6" "Configuración SDDM CyberSec"
cd "$USER_HOME" || exit 1

log_info "Instalando dependencias de SDDM..."

# Instalar paquetes necesarios usando safe_install
SDDM_DEPS=("sddm" "qt5-quickcontrols" "qt5-quickcontrols2" "qt5-graphicaleffects" "qt5-svg" "qt5-declarative" "qt6-5compat" "qt6-declarative" "qt6-svg" "ttf-jetbrains-mono" "imagemagick")
for dep in "${SDDM_DEPS[@]}"; do
    safe_install "$dep"
done

THEME_NAME="cybersec"
# Assets are two levels up from src/deploy
THEME_SOURCE="$SCRIPT_DIR/assets/sddm/themes/$THEME_NAME"
THEME_DEST="/usr/share/sddm/themes/$THEME_NAME"

log_info "Desplegando tema '$THEME_NAME'..."

if [ -d "$THEME_SOURCE" ]; then
    # Crear directorio destino
    sudo mkdir -p "$THEME_DEST"
    
    # Copiar archivos
    sudo cp -r "$THEME_SOURCE"/* "$THEME_DEST/"
    sudo rm -f "$THEME_DEST/install.sh" "$THEME_DEST/README.md" 2>/dev/null
    
    # Configurar permisos correctos
    sudo chmod 755 "$THEME_DEST"
    sudo find "$THEME_DEST" -type d -exec chmod 755 {} \;
    sudo find "$THEME_DEST" -type f -exec chmod 644 {} \;
    
    log_success "Archivos del tema copiados a $THEME_DEST"
    
    # Verificar que los archivos críticos existen
    if [ ! -f "$THEME_DEST/Main.qml" ]; then
        log_warn "Main.qml no encontrado en el tema — SDDM usará tema por defecto."
        return 0
    fi

    log_success "Tema cybersec verificado correctamente"
else
    log_warn "No se encontró el directorio del tema en: $THEME_SOURCE — SDDM usará tema por defecto."
    return 0
fi

# Configurar SDDM
log_info "Activar tema en sddm.conf..."
SDDM_CONF_DIR="/etc/sddm.conf.d"
sudo mkdir -p "$SDDM_CONF_DIR"

# Clean previous conflicting configs (idempotente: solo mueve si .bak no existe)
if [ -f "/etc/sddm.conf" ] && [ ! -f "/etc/sddm.conf.bak" ]; then
    log_warn "Moviendo /etc/sddm.conf antiguo a .bak para usar configuración modular..."
    sudo mv /etc/sddm.conf /etc/sddm.conf.bak
elif [ -f "/etc/sddm.conf" ]; then
    log_info "/etc/sddm.conf presente pero .bak ya existe — eliminando para usar configuración modular..."
    sudo rm -f /etc/sddm.conf
fi

# Write new config
echo "[Theme]
Current=$THEME_NAME" | sudo tee "$SDDM_CONF_DIR/theme.conf" > /dev/null

# Verificar configuración
if grep -q "Current=$THEME_NAME" "$SDDM_CONF_DIR/theme.conf"; then
    log_success "Tema $THEME_NAME configurado en sddm.conf"
    
    # Fix permissions for the config file
    sudo chmod 644 "$SDDM_CONF_DIR/theme.conf"
else
    log_error "Error al configurar tema en sddm.conf"
    exit 1
fi

# Deshabilitar otros display managers
log_info "Deshabilitando otros display managers..."
sudo systemctl disable gdm lightdm lxdm 2>/dev/null || true

# Habilitar servicio
log_info "Habilitando servicio SDDM..."
sudo systemctl enable sddm --force

log_success "SDDM configurado con tema $THEME_NAME"

# --- Configurar Avatar Default ---
log_info "Configurando soporte de Avatares para SDDM..."

# 1. Habilitar Faces en SDDM via drop-in config
sudo mkdir -p /etc/sddm.conf.d
cat <<EOF | sudo tee /etc/sddm.conf.d/avatar.conf > /dev/null
[Theme]
EnableAvatars=true
FacesDir=/var/lib/AccountsService/icons
CursorTheme=Breeze_Snow
EOF

# 2. Instalar avatar por defecto
# Nota: THEME_SOURCE apunta a assets/sddm/themes/cybersec
# El avatar debería estar en assets/sddm/themes/cybersec/assets/avatar.png o similar
DEFAULT_AVATAR="$THEME_SOURCE/assets/avatar.png"
TARGET_AVATAR="$USER_HOME/.face.icon"

if [ -f "$DEFAULT_AVATAR" ]; then
    log_info "Instalando avatar por defecto en $TARGET_AVATAR..."
    cp "$DEFAULT_AVATAR" "$TARGET_AVATAR"
    chown "$CURRENT_USER:$CURRENT_USER" "$TARGET_AVATAR"
    chmod 644 "$TARGET_AVATAR"
    
    # También copiar a AccountsService para compatibilidad total
    sudo mkdir -p /var/lib/AccountsService/icons
    sudo cp "$DEFAULT_AVATAR" "/var/lib/AccountsService/icons/$CURRENT_USER"
    
    # Crear registro de usuario en AccountsService
    sudo mkdir -p /var/lib/AccountsService/users
    echo -e "[User]\nIcon=/var/lib/AccountsService/icons/$CURRENT_USER\n" | sudo tee "/var/lib/AccountsService/users/$CURRENT_USER" > /dev/null
else
    log_warn "No se encontró avatar.png en $DEFAULT_AVATAR. El usuario tendrá un avatar genérico."
fi

log_info "El tema y configuración se aplicarán después de reiniciar"

success "SDDM Configurado correctamente con soporte de Avatares"
