#!/bin/bash
# set_avatar.sh - Selector interactivo de avatar para SDDM y el perfil del usuario
# Author: Francisco Aravena (P4nX0Z)
# Created: 2026-02-11
# Usage: ~/.config/bin/set_avatar.sh
#
# Permite al usuario seleccionar una imagen, la redimensiona y la establece como
# avatar para SDDM (.face.icon) y AccountsService.

set -euo pipefail

AVATAR_SIZE=256
CURRENT_USER=$(whoami)

# Verificar dependencias
for dep in convert zenity; do
    if ! command -v "$dep" &>/dev/null; then
        notify-send "Avatar" "Falta dependencia: $dep" --urgency=critical
        echo "Error: $dep no está instalado"
        exit 1
    fi
done

# Seleccionar imagen con zenity
IMAGE=$(zenity --file-selection \
    --title="BLACK-ICE — Selecciona tu Avatar" \
    --file-filter="Imágenes | *.png *.jpg *.jpeg *.gif *.bmp *.webp" \
    2>/dev/null) || exit 0

# Validar que la imagen existe y es legible
if [[ ! -f "$IMAGE" ]]; then
    notify-send "Avatar" "Archivo no encontrado: $IMAGE" --urgency=critical
    exit 1
fi

# Redimensionar y convertir a PNG
echo "Procesando avatar..."
convert "$IMAGE" \
    -resize "${AVATAR_SIZE}x${AVATAR_SIZE}^" \
    -gravity center \
    -extent "${AVATAR_SIZE}x${AVATAR_SIZE}" \
    "$HOME/.face.icon"

# Copiar a AccountsService (requiere sudo)
sudo cp "$HOME/.face.icon" "/var/lib/AccountsService/icons/$CURRENT_USER" 2>/dev/null || true

# Crear el archivo de configuración de AccountsService
sudo mkdir -p /var/lib/AccountsService/users
if [[ ! -f "/var/lib/AccountsService/users/$CURRENT_USER" ]]; then
    sudo tee "/var/lib/AccountsService/users/$CURRENT_USER" > /dev/null << EOF
[User]
Icon=/var/lib/AccountsService/icons/$CURRENT_USER
EOF
else
    # Actualizar el Icon si ya existe el archivo
    if sudo grep -q "^Icon=" "/var/lib/AccountsService/users/$CURRENT_USER" 2>/dev/null; then
        sudo sed -i "s|^Icon=.*|Icon=/var/lib/AccountsService/icons/$CURRENT_USER|" \
            "/var/lib/AccountsService/users/$CURRENT_USER"
    else
        echo "Icon=/var/lib/AccountsService/icons/$CURRENT_USER" | \
            sudo tee -a "/var/lib/AccountsService/users/$CURRENT_USER" > /dev/null
    fi
fi

notify-send "Avatar Actualizado" "Tu avatar ha sido configurado correctamente.\nSe aplicará en el próximo login de SDDM." --icon="$HOME/.face.icon"
echo "✓ Avatar configurado en ~/.face.icon y AccountsService"
