#!/bin/bash
TARGET_FILE="$HOME/.config/bin/target"

IP=$(wofi --dmenu --prompt "Target IP" -i)

if [ -n "$IP" ]; then
    mkdir -p "$HOME/.config/bin"
    echo "$IP" > "$TARGET_FILE"
    notify-send "Target Set" "Target IP updated to $IP"
else
    # Si se cancela, no hacer nada o limpiar si se desea
    # echo "" > "$TARGET_FILE"
    notify-send "Target" "Operation cancelled"
fi
