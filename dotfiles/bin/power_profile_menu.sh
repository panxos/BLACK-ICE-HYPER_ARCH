#!/bin/bash
# power_profile_menu.sh - Menú de perfiles de energía para Hyprland
# Author: Francisco Aravena (P4nX0Z)
# Created: 2026-02-11
# Usage: bind = $mainMod SHIFT, P, exec, ~/.config/bin/power_profile_menu.sh
#
# Muestra un menú wofi/rofi con opciones de perfil de energía.
# Usa cpupower o powerprofilesctl según disponibilidad.

set -euo pipefail

# Detectar tipo de menú disponible
if command -v wofi &>/dev/null; then
    MENU_CMD="wofi --dmenu --prompt 'Power Profile' -i"
elif command -v rofi &>/dev/null; then
    MENU_CMD="rofi -dmenu -p 'Power Profile' -i"
else
    notify-send "Power Profile" "No se encontró wofi ni rofi" --urgency=critical
    exit 1
fi

# Opciones del menú
OPTIONS="⚡ Performance\n⚖️ Balanced\n🔋 Power Saver"

# Mostrar menú y capturar elección
CHOICE=$(echo -e "$OPTIONS" | eval "$MENU_CMD" 2>/dev/null) || exit 0

# Aplicar perfil según herramienta disponible
apply_profile() {
    local profile="$1"
    local governor=""
    local label=""

    case "$profile" in
        performance)
            governor="performance"
            label="⚡ Performance"
            ;;
        balanced)
            governor="schedutil"
            label="⚖️ Balanced"
            ;;
        powersave)
            governor="powersave"
            label="🔋 Power Saver"
            ;;
    esac

    # Método 1: power-profiles-daemon (si disponible)
    if command -v powerprofilesctl &>/dev/null; then
        powerprofilesctl set "$profile" 2>/dev/null
        notify-send "Power Profile" "Perfil cambiado a: $label" --icon=battery
        return 0
    fi

    # Método 2: cpupower (siempre disponible en BLACK-ICE)
    if command -v cpupower &>/dev/null; then
        sudo cpupower frequency-set -g "$governor" 2>/dev/null
        notify-send "Power Profile" "Governor: $governor ($label)" --icon=battery
        return 0
    fi

    notify-send "Power Profile" "No se pudo aplicar el perfil" --urgency=critical
    return 1
}

# Procesar elección
case "$CHOICE" in
    *"Performance"*)  apply_profile "performance" ;;
    *"Balanced"*)     apply_profile "balanced" ;;
    *"Power Saver"*)  apply_profile "powersave" ;;
    *)                exit 0 ;;
esac
