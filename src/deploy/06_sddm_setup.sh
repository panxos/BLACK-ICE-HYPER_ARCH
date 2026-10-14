#!/bin/bash
# deploy-modules/06_sddm_setup.sh
# Instala y configura el tema SDDM Obsidiana

banner "MÓDULO 6" "Configuración SDDM Obsidiana"
cd "$USER_HOME" || exit 1

log_info "Instalando dependencias de SDDM..."

# Detectar qué Qt usa el binario sddm-greeter para instalar las dependencias correctas
# SDDM en Arch 0.21+ puede estar compilado con Qt5 o Qt6
if ldd /usr/bin/sddm-greeter 2>/dev/null | grep -q 'libQt6'; then
    SDDM_QT_VER=6
    log_info "SDDM usa Qt6"
    SDDM_DEPS=("sddm" "qt6-declarative" "qt6-svg" "qt6-5compat" "ttf-jetbrains-mono" "imagemagick")
else
    SDDM_QT_VER=5
    log_info "SDDM usa Qt5"
    SDDM_DEPS=("sddm" "qt5-quickcontrols" "qt5-quickcontrols2" "qt5-graphicaleffects" "qt5-svg" "qt5-declarative" "ttf-jetbrains-mono" "imagemagick")
fi

SDDM_DEPS+=("xorg-setxkbmap")
for dep in "${SDDM_DEPS[@]}"; do
    safe_install "$dep"
done

sudo install -d -m 755 /usr/local/share/fonts/black-ice
sudo cp -r "$SCRIPT_DIR/assets/fonts/." /usr/local/share/fonts/black-ice/
sudo fc-cache -f /usr/local/share/fonts/black-ice

THEME_NAME="black-ice-obsidian"
# Assets are two levels up from src/deploy
THEME_SOURCE="$SCRIPT_DIR/assets/sddm/themes/$THEME_NAME"
THEME_DEST="/usr/share/sddm/themes/$THEME_NAME"

log_info "Desplegando tema '$THEME_NAME'..."

if [ -d "$THEME_SOURCE" ]; then
    # Crear directorio destino
    sudo mkdir -p "$THEME_DEST"
    
    # Copiar archivos
    sudo cp -r "$THEME_SOURCE"/* "$THEME_DEST/"
    sudo python3 - "$SCRIPT_DIR" "$THEME_DEST" <<'PY'
import runpy
import sys
from pathlib import Path

source, destination = map(Path, sys.argv[1:])
resources = runpy.run_path(str(source / 'scripts/install-visual-refresh.py'))['sddm_backgrounds'](source)
for relative, content in resources.items():
    target = destination / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(content)
PY
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

    # Fix QML imports según versión Qt del sddm-greeter
    # Qt5 requiere versiones explícitas: "import QtQuick 2.15"
    # Qt6 acepta sin versión: "import QtQuick"
    if [ "$SDDM_QT_VER" -eq 5 ]; then
        log_info "Aplicando QML imports compatibles con Qt5..."
        for qml_file in "$THEME_DEST"/*.qml "$THEME_DEST"/components/*.qml; do
            [ -f "$qml_file" ] || continue
            sudo sed -i \
                -e 's/^import QtQuick$/import QtQuick 2.15/' \
                -e 's/^import QtQuick\.Layouts$/import QtQuick.Layouts 1.15/' \
                -e 's/^import QtQuick\.Controls$/import QtQuick.Controls 2.15/' \
                "$qml_file"
        done
        log_success "QML imports Qt5 aplicados"
    else
        log_info "Qt6 detectado — QML imports sin versión, OK"
    fi

    log_success "Tema $THEME_NAME verificado correctamente"
else
    log_warn "No se encontró el directorio del tema en: $THEME_SOURCE — SDDM usará tema por defecto."
    return 0
fi

# Configurar SDDM
log_info "Activar tema en sddm.conf..."
SDDM_CONF_DIR="/etc/sddm.conf.d"
sudo mkdir -p "$SDDM_CONF_DIR"

sudo python3 - "$THEME_NAME" <<'PY'
import configparser
import os
import sys
import tempfile
from pathlib import Path

for path in [Path('/etc/sddm.conf.d/theme.conf'), Path('/etc/sddm.conf')]:
    if path.name == 'sddm.conf' and not path.exists():
        continue
    config = configparser.ConfigParser(interpolation=None)
    config.optionxform = str
    config.read(path)
    if not config.has_section('Theme'):
        config.add_section('Theme')
    config.set('Theme', 'Current', sys.argv[1])
    with tempfile.NamedTemporaryFile(mode='w', dir=path.parent, delete=False) as output:
        config.write(output, space_around_delimiters=False)
        temporary = Path(output.name)
    temporary.chmod(path.stat().st_mode & 0o777 if path.exists() else 0o644)
    os.replace(temporary, path)
PY

# Verificar configuración
if grep -q "Current=$THEME_NAME" "$SDDM_CONF_DIR/theme.conf"; then
    log_success "Tema $THEME_NAME configurado en sddm.conf"
    
    # Fix permissions for the config file
    sudo chmod 644 "$SDDM_CONF_DIR/theme.conf"
else
    log_warn "Error al configurar tema en sddm.conf — SDDM arrancará con tema por defecto"
    return 0
fi

# Deshabilitar otros display managers
log_info "Deshabilitando otros display managers..."
sudo systemctl disable gdm lightdm lxdm 2>/dev/null || true

# Habilitar servicio
log_info "Habilitando servicio SDDM..."
sudo systemctl enable sddm --force
log_info "Preparando teclado XKB antes del greeter de SDDM..."
sudo python3 "$SCRIPT_DIR/scripts/configure-sddm-keyboard.py" \
    --layout "$(console_to_xkb_layout "${KEYBOARD_LAYOUT:-us}")" --apply

log_success "SDDM configurado con tema $THEME_NAME"

sudo python3 "$SCRIPT_DIR/scripts/install-agency-themes.py" --apply

# --- Configurar Avatar Default ---
log_info "Configurando soporte de Avatares para SDDM..."

# 1. Habilitar Faces en SDDM via drop-in config
sudo mkdir -p /etc/sddm.conf.d
cat <<EOF | sudo tee /etc/sddm.conf.d/avatar.conf > /dev/null
[Theme]
EnableAvatars=true
FacesDir=/var/lib/AccountsService/icons
CursorTheme=Adwaita
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
