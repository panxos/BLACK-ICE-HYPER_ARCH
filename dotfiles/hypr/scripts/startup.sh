#!/bin/bash
# startup.sh — Orquestador de Inicio BLACK-ICE

# 1. Limpieza
pkill -x waybar 2>/dev/null
pkill -x awww-daemon 2>/dev/null
pkill -x swaync 2>/dev/null
pkill -f xdg-desktop-portal 2>/dev/null
pkill -f udiskie 2>/dev/null
pkill -f notification-daemon 2>/dev/null

# 2. Sincronizar bus con systemd
dbus-update-activation-environment --systemd --all
systemctl --user import-environment --all

# 3. Arrancar awww-daemon primero (minimiza pantalla gris de Hyprland)
awww-daemon &

# 4. Lanzar swaync en paralelo
swaync &

# 5. Esperar socket awww-daemon (max ~1s, típico <200ms) — luego wallpaper inmediato
_awww_sock="${XDG_RUNTIME_DIR}/${WAYLAND_DISPLAY}-awww-daemon.sock"
for _i in $(seq 1 10); do
    [ -S "$_awww_sock" ] && break
    sleep 0.1
done
unset _i _awww_sock
"$HOME/.config/hypr/scripts/set_wallpaper.sh" &

# 6. Esperar registro swaync en dbus (necesario para waybar)
for _i in $(seq 1 20); do
    dbus-send --session --print-reply --dest=org.freedesktop.DBus \
        /org/freedesktop/DBus org.freedesktop.DBus.ListNames 2>/dev/null \
        | grep -q "org.freedesktop.Notifications" && break
    sleep 0.1
done
unset _i
waybar &

# 7. Portales y resto en background
"$HOME/.config/hypr/scripts/portal.sh" &
export PYTHONUNBUFFERED=1
"$HOME/.config/bin/udiskie-fix" &
"$HOME/.config/hypr/scripts/launch_mega.sh" &
"$HOME/.config/bin/battery_notify.sh" &
