#!/bin/bash
# ac_guard.sh — Ejecuta acciones de inactividad solo en batería, nunca en VM
# Uso: ac_guard.sh <dim-down|dim-up|dpms-off|suspend>

# VM: nunca suspender/apagar pantalla (dim-up sí, no es dañino)
if systemd-detect-virt -q 2>/dev/null; then
    [ "$1" = "dim-up" ] && brightnessctl -r 2>/dev/null
    exit 0
fi

# Leer estado AC — admite AC, ADP*, ACAD
AC_ONLINE=$(cat /sys/class/power_supply/AC/online \
                /sys/class/power_supply/ADP*/online \
                /sys/class/power_supply/ACAD/online 2>/dev/null | head -1)

case "$1" in
    dim-down)
        [ "$AC_ONLINE" = "1" ] && exit 0
        brightnessctl -s set 10%
        ;;
    dim-up)
        brightnessctl -r 2>/dev/null
        ;;
    dpms-off)
        [ "$AC_ONLINE" = "1" ] && exit 0
        hyprctl dispatch dpms off
        ;;
    suspend)
        [ "$AC_ONLINE" = "1" ] && exit 0
        systemctl suspend
        ;;
esac
