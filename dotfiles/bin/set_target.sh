#!/bin/bash
TARGET_FILE="$HOME/.config/bin/target"

IP=$(wofi --dmenu --prompt "Target IP" -i)

if [ -z "$IP" ]; then
    notify-send "Target" "Operation cancelled"
    exit 0
fi

# Validar formato: solo IPs y hostnames válidos (sin caracteres de shell)
if [[ ! "$IP" =~ ^[a-zA-Z0-9._/-]+$ ]]; then
    notify-send "Target" "Formato inválido: solo IPs y hostnames"
    exit 1
fi

mkdir -p "$HOME/.config/bin"
printf '%s\n' "$IP" > "$TARGET_FILE"
notify-send "Target Set" "Target updated to $IP"
