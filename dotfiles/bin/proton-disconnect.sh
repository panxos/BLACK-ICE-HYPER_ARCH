#!/bin/bash
#=============================================================================
# ProtonVPN Disconnect Script
# Author: P4NX0S
#=============================================================================

# Configuracion
VPN_NAME="PROTON"
CONFIG_IDENTIFIER="PROTON.ovpn"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Funcion para notificaciones
notify() {
    local msg="$1"
    local icon="${2:-network-vpn-disconnected}"
    DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus" \
        notify-send "VPN $VPN_NAME" "$msg" --icon="$icon" 2>/dev/null || true
}

# Buscar proceso de OpenVPN con esta configuracion
PID=$(pgrep -f "$CONFIG_IDENTIFIER" 2>/dev/null)

if [[ -z "$PID" ]]; then
    echo -e "${YELLOW}[!] No hay conexion $VPN_NAME activa${NC}"
    notify "No hay conexion activa" "dialog-warning"
    exit 0
fi

echo -e "${CYAN}[*] Desconectando $VPN_NAME (PID: $PID)...${NC}"

# Matar el proceso
sudo kill "$PID" 2>/dev/null

# Esperar a que termine
sleep 2

# Verificar que se cerro
if pgrep -f "$CONFIG_IDENTIFIER" > /dev/null; then
    echo -e "${YELLOW}[!] Forzando cierre...${NC}"
    sudo kill -9 "$PID" 2>/dev/null
    sleep 1
fi

# Confirmar desconexion
if ! pgrep -f "$CONFIG_IDENTIFIER" > /dev/null; then
    echo -e "${GREEN}[OK] $VPN_NAME desconectado${NC}"
    notify "Desconectado correctamente"
else
    echo -e "${RED}[X] Error al desconectar${NC}"
    notify "Error al desconectar" "dialog-error"
    exit 1
fi
