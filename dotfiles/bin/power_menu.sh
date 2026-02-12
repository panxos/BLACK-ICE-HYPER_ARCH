#!/bin/bash

# Opciones del menú
OPTIONS="🔒 Lock\n⏾ Sleep\n🔄 Reboot\n⏻ Shutdown\n🚪 Logout"

# Mostrar menú con wofi
CHOICE=$(echo -e "$OPTIONS" | wofi --dmenu --prompt "Power Menu" -i)

case "$CHOICE" in
    "🔒 Lock")
        hyprlock || swaylock
        ;;
    "⏾ Sleep")
        systemctl suspend
        ;;
    "🔄 Reboot")
        systemctl reboot
        ;;
    "⏻ Shutdown")
        systemctl poweroff
        ;;
    "🚪 Logout")
        hyprctl dispatch exit
        ;;
esac
