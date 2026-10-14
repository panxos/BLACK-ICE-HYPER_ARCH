#!/bin/bash
# power_manager.sh - Gestor de Perfiles de Energía para BLACK-ICE ARCH
# Ubicación: ~/.config/hypr/scripts/power_manager.sh

# Colores para notificaciones
NEON_BLUE='\033[38;2;0;255;255m'
NEON_GREEN='\033[38;2;57;255;20m'
NEON_PURPLE='\033[38;2;189;147;249m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Verificar si es laptop
IS_LAPTOP=false
if find /sys/class/power_supply/ -maxdepth 1 -name 'BAT*' -type d 2>/dev/null | grep -q . || \
   [ -d /sys/class/power_supply/battery ]; then
    IS_LAPTOP=true
fi

# Función para notificar
notify() {
    notify-send -u normal -t 3000 "⚡ Power Manager" "$1"
}

# Función para aplicar perfil
apply_profile() {
    local profile="$1"
    
    if [ "$IS_LAPTOP" = true ]; then
        # Laptop: Usar TLP
        case "$profile" in
            performance)
                sudo tlp ac
                notify "🚀 Modo Performance activado\nCPU al máximo rendimiento"
                ;;
            balanced)
                # TLP automático según fuente de energía
                sudo systemctl restart tlp.service
                notify "⚡ Modo Balanceado activado\nAdaptación automática AC/Batería"
                ;;
            powersave)
                sudo tlp bat
                notify "🔋 Modo Ahorro activado\nMáxima duración de batería"
                ;;
        esac
    else
        # Desktop: Usar cpupower
        case "$profile" in
            performance)
                sudo cpupower frequency-set -g performance >/dev/null 2>&1
                notify "🚀 Modo Performance activado\nCPU Governor: Performance"
                ;;
            balanced)
                sudo cpupower frequency-set -g schedutil >/dev/null 2>&1
                notify "⚡ Modo Balanceado activado\nCPU Governor: Schedutil"
                ;;
            powersave)
                sudo cpupower frequency-set -g powersave >/dev/null 2>&1
                notify "🔋 Modo Ahorro activado\nCPU Governor: Powersave"
                ;;
        esac
    fi
}

# Función para mostrar estado actual
show_status() {
    if [ "$IS_LAPTOP" = true ]; then
        local ac_status=$(cat /sys/class/power_supply/AC*/online 2>/dev/null || echo "0")
        local battery=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null || echo "N/A")
        
        if [ "$ac_status" = "1" ]; then
            echo -e "${NEON_GREEN}🔌 AC Conectado${NC} | Batería: ${battery}%"
        else
            echo -e "${YELLOW}🔋 Batería${NC} | Nivel: ${battery}%"
        fi
        
        # Mostrar perfil TLP activo
        if systemctl is-active --quiet tlp.service; then
            echo -e "${NEON_BLUE}TLP:${NC} Activo (Adaptativo)"
        fi
    else
        local governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown")
        echo -e "${NEON_PURPLE}Desktop Mode${NC} | Governor: ${NEON_BLUE}${governor}${NC}"
    fi
}

# Menú interactivo con Rofi
show_menu() {
    local options="🚀 Performance\n⚡ Balanced\n🔋 Power Saver\n📊 Show Status"
    
    local choice=$(echo -e "$options" | rofi -dmenu -i -p "Power Profile" \
        -theme ~/.config/rofi/power.rasi 2>/dev/null || \
        echo -e "$options" | fzf --prompt="Select Power Profile: ")
    
    case "$choice" in
        "🚀 Performance")
            apply_profile "performance"
            ;;
        "⚡ Balanced")
            apply_profile "balanced"
            ;;
        "🔋 Power Saver")
            apply_profile "powersave"
            ;;
        "📊 Show Status")
            show_status | rofi -dmenu -p "Power Status" || show_status
            ;;
    esac
}

# Modo CLI
if [ "$1" = "status" ]; then
    show_status
elif [ "$1" = "performance" ] || [ "$1" = "balanced" ] || [ "$1" = "powersave" ]; then
    apply_profile "$1"
else
    show_menu
fi
