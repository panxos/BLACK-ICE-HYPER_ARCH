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

# 3. Lanzar swaync — esperar registro en dbus (max ~2s, típico <400ms)
swaync &
for _i in $(seq 1 20); do
    dbus-send --session --print-reply --dest=org.freedesktop.DBus \
        /org/freedesktop/DBus org.freedesktop.DBus.ListNames 2>/dev/null \
        | grep -q "org.freedesktop.Notifications" && break
    sleep 0.1
done

# 4. Portales en background — no bloqueamos el resto del startup
"$HOME/.config/hypr/scripts/portal.sh" &

# 5. udiskie
export PYTHONUNBUFFERED=1
"$HOME/.config/bin/udiskie-fix" &

# 6. Resto del ecosistema
awww-daemon &
"$HOME/.config/hypr/scripts/set_wallpaper.sh" &
waybar &
"$HOME/.config/hypr/scripts/launch_mega.sh" &
"$HOME/.config/bin/battery_notify.sh" &
