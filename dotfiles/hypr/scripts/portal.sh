#!/bin/bash
# portal.sh - Orquestador de Portales para BLACK-ICE (Blindado)
# Aseguramos el entorno antes de lanzar los binarios
export XDG_CURRENT_DESKTOP=Hyprland
# Auto-detect the active Wayland socket instead of hardcoding wayland-1
_WAYLAND_SOCK=$(ls /run/user/"$(id -u)"/wayland-* 2>/dev/null | head -1)
export WAYLAND_DISPLAY="${_WAYLAND_SOCK##*/}"
: "${WAYLAND_DISPLAY:=wayland-1}"

sleep 1
killall -e xdg-desktop-portal-hyprland
killall -e xdg-desktop-portal-gtk
killall -e xdg-desktop-portal

sleep 1
# Lanzar el portal de Hyprland con el entorno forzado
/usr/lib/xdg-desktop-portal-hyprland &
sleep 2
# Lanzar el de GTK para manejar los links (OpenURI)
/usr/lib/xdg-desktop-portal-gtk &
sleep 2
# El portal general que los orquesta a todos
/usr/lib/xdg-desktop-portal &
