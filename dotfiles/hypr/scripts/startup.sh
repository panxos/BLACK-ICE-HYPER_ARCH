#!/bin/bash
# startup.sh - Orquestador de Inicio BLACK-ICE (P4nx0z Final Fix v4)

# 1. Limpieza Nuclear (Matamos todo lo que maneje notificaciones y bus)
pkill -x waybar
pkill -x awww-daemon
pkill -x swaync
pkill -f xdg-desktop-portal
pkill -f udiskie
pkill -f notification-daemon 2>/dev/null

# 2. Sincronizar el Bus de Datos con Systemd (EL FIX MAESTRO)
dbus-update-activation-environment --systemd --all
systemctl --user import-environment --all

# 3. Lanzar el Panel de Notificaciones PRIMERO y forzar su registro
# Esto asegura que sea el DUEÑO del bus org.freedesktop.Notifications
swaync &
sleep 3 # Damos tiempo real para que el bus se registre

# 4. Lanzar los Portales (GTK -> Hyprland)
"$HOME/.config/hypr/scripts/portal.sh" &
sleep 2

# 5. Lanzar udiskie con el bus ya sincronizado y un delay
export PYTHONUNBUFFERED=1
# Usamos el binario con -n para notificaciones
"$HOME/.config/bin/udiskie-fix" &

# 6. Iniciar el resto del ecosistema
awww-daemon &
"$HOME/.config/hypr/scripts/set_wallpaper.sh" &
waybar &
"$HOME/.config/hypr/scripts/launch_mega.sh" &
"$HOME/.config/bin/battery_notify.sh" &
