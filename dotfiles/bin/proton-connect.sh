#!/bin/bash
#=============================================================================
# ProtonVPN Connect Script
# Author: P4NX0S
#=============================================================================

set -euo pipefail

# Configuracion
VPN_NAME="PROTON"
VPN_CONFIG="${VPN_CONFIG_DIR}/proton/PROTON.ovpn"
AUTH_FILE="${VPN_CONFIG_DIR}/proton/auth.txt"
CONFIG_IDENTIFIER="PROTON.ovpn"
LOG_FILE="/tmp/openvpn-proton.log"
WAIT_TIME=10

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Funcion para notificaciones
notify() {
    local msg="$1"
    local icon="${2:-network-vpn}"
    DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus" \
        notify-send "VPN $VPN_NAME" "$msg" --icon="$icon" 2>/dev/null || true
}

# Verificar si ya hay una VPN activa
if pgrep -x openvpn > /dev/null; then
    echo -e "${YELLOW}[!] Ya existe una conexion OpenVPN activa${NC}"
    echo -e "${CYAN}    PID: $(pgrep -x openvpn)${NC}"
    notify "Ya existe una VPN activa. Desconectala primero." "dialog-warning"
    exit 1
fi

# Verificar que el archivo de configuracion existe
if [[ ! -f "$VPN_CONFIG" ]]; then
    echo -e "${RED}[X] Archivo de configuracion no encontrado: $VPN_CONFIG${NC}"
    notify "Archivo de configuracion no encontrado" "dialog-error"
    exit 1
fi

# Verificar archivo de autenticacion
if [[ ! -f "$AUTH_FILE" ]]; then
    echo -e "${RED}[X] Archivo de autenticacion no encontrado: $AUTH_FILE${NC}"
    notify "Archivo de autenticacion no encontrado" "dialog-error"
    exit 1
fi

echo -e "${CYAN}[*] Conectando a $VPN_NAME...${NC}"

# Iniciar OpenVPN
sudo openvpn --config "$VPN_CONFIG" --auth-user-pass "$AUTH_FILE" --daemon --log "$LOG_FILE"

if [[ $? -ne 0 ]]; then
    echo -e "${RED}[X] Error al iniciar OpenVPN${NC}"
    notify "Error al iniciar la conexion" "dialog-error"
    exit 1
fi

# Esperar a que se establezca la conexion
echo -e "${CYAN}[*] Esperando conexion...${NC}"
for i in $(seq 1 $WAIT_TIME); do
    sleep 1
    if ip link show tun0 &>/dev/null; then
        break
    fi
    printf "."
done
echo ""

# Verificar conexion exitosa
if ip link show tun0 &>/dev/null; then
    VPN_IP=$(ip -4 addr show tun0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || echo "N/A")
    echo -e "${GREEN}[OK] Conectado a $VPN_NAME${NC}"
    echo -e "${GREEN}[OK] IP VPN: $VPN_IP${NC}"
    notify "Conectado - IP: $VPN_IP" "network-vpn"
else
    echo -e "${RED}[X] No se pudo establecer la conexion${NC}"
    echo -e "${YELLOW}[!] Revisa el log: $LOG_FILE${NC}"
    notify "Error al establecer conexion" "dialog-error"
    exit 1
fi
