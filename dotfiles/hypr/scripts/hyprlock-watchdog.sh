#!/bin/bash
# Watchdog hyprlock — reinicia si muere mientras la sesión está bloqueada
# FIX: corre hyprlock sincrónico; si sale con código 0 (auth OK) borra el lockfile.
#      Si crashea (non-zero), el lockfile persiste y el loop lo reinicia.
LOCKFILE="/tmp/hyprlock-locked"

while true; do
    if [ -f "$LOCKFILE" ] && ! pgrep -x hyprlock > /dev/null; then
        /usr/bin/hyprlock
        if [ $? -eq 0 ]; then
            # Autenticación exitosa — borrar lockfile para no relanzar
            rm -f "$LOCKFILE"
        fi
        # Si salió non-zero (crash/kill), el lockfile queda y el loop reinicia hyprlock
    fi
    sleep 2
done
