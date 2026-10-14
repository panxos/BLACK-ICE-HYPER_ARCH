#!/bin/bash
# startup.sh — Orquestador de Inicio BLACK-ICE

# 1. Limpieza
pkill -x waybar 2>/dev/null
pkill -x awww-daemon 2>/dev/null
pkill -x swaync 2>/dev/null
pkill -f xdg-desktop-portal 2>/dev/null
pkill -f notification-daemon 2>/dev/null
rm -f /tmp/hyprlock-locked

# 2. Sincronizar bus con systemd
dbus-update-activation-environment --systemd --all
systemctl --user import-environment --all
hyprctl setcursor Adwaita 24
if command -v xsetroot >/dev/null; then
    xsetroot -cursor_name left_ptr
fi

# 3. Arrancar awww-daemon primero y comprobar el socket, no solo que exista.
# awww puede dejar un socket obsoleto si Hyprland cerró el daemon durante el logout.
for _i in $(seq 1 20); do
    pgrep -x awww-daemon >/dev/null || break
    sleep 0.1
done
if [[ -n "${XDG_RUNTIME_DIR:-}" && "${WAYLAND_DISPLAY:-}" =~ ^wayland-[0-9]+$ ]]; then
    _awww_sock="${XDG_RUNTIME_DIR}/${WAYLAND_DISPLAY}-awww-daemon.sock"
    if [[ -S "$_awww_sock" ]] && ! pgrep -x awww-daemon >/dev/null; then
        rm -f -- "$_awww_sock"
    fi
fi
awww-daemon &

# 4. Lanzar swaync en paralelo
swaync &

# 5. Esperar una conexión real a awww; la existencia del socket no prueba que responda.
_awww_sock="${XDG_RUNTIME_DIR}/${WAYLAND_DISPLAY}-awww-daemon.sock"
for _i in $(seq 1 50); do
    awww query >/dev/null 2>&1 && break
    sleep 0.1
done
if ! awww query >/dev/null 2>&1; then
    logger -t black-ice-hyprland "awww-daemon no respondió; no se pudo cargar el wallpaper inicial"
fi
unset _i _awww_sock
if awww query >/dev/null 2>&1; then
    "$HOME/.config/hypr/scripts/set_wallpaper.sh" &
fi

# 6. Esperar registro swaync en dbus (necesario para waybar)
for _i in $(seq 1 20); do
    dbus-send --session --print-reply --dest=org.freedesktop.DBus \
        /org/freedesktop/DBus org.freedesktop.DBus.ListNames 2>/dev/null \
        | grep -q "org.freedesktop.Notifications" && break
    sleep 0.1
done
unset _i
"$HOME/.local/bin/waybar_start.sh"
"$HOME/.local/bin/black-ice-appearance" sync
systemctl --user start hyprland-session.target

# 7. Portapapeles — matar versiones previas y relanzar limpio
pkill -x wl-clip-persist 2>/dev/null
pkill -f "wl-paste.*cliphist" 2>/dev/null
sleep 0.3
wl-clip-persist --clipboard both &
wl-paste --type text --watch cliphist store &
wl-paste --type image --watch cliphist store &

# 8. Portales y resto en background
"$HOME/.config/hypr/scripts/portal.sh" &
export PYTHONUNBUFFERED=1
if systemctl --user cat black-ice-removable.service >/dev/null 2>&1; then
    systemctl --user start black-ice-removable.service
elif ! pgrep -u "$(id -u)" -f '^/usr/bin/python.*udiskie|^/usr/bin/udiskie' >/dev/null; then
    "$HOME/.config/bin/udiskie-fix" &
fi
"$HOME/.config/bin/battery_notify.sh" &
kbuildsycoca6 &
