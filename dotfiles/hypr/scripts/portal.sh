#!/bin/bash
# portal.sh - Orquestador de Portales para BLACK-ICE (Blindado)
# Aseguramos el entorno antes de lanzar los binarios
export XDG_CURRENT_DESKTOP=Hyprland
# Auto-detect the active Wayland socket instead of hardcoding wayland-1
_WAYLAND_SOCK=$(ls /run/user/"$(id -u)"/wayland-* 2>/dev/null | head -1)
export WAYLAND_DISPLAY="${_WAYLAND_SOCK##*/}"
: "${WAYLAND_DISPLAY:=wayland-1}"

sleep 0.3
killall -e xdg-desktop-portal-hyprland 2>/dev/null
killall -e xdg-desktop-portal-gtk 2>/dev/null
killall -e xdg-desktop-portal 2>/dev/null

sleep 0.3
/usr/lib/xdg-desktop-portal-hyprland &
sleep 0.5
/usr/lib/xdg-desktop-portal-gtk &
sleep 0.3
/usr/lib/xdg-desktop-portal &
