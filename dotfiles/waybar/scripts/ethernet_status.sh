#!/bin/bash
# ~/.config/waybar/scripts/ethernet_status.sh
# Detect interface type and IP

# Find default interface
iface=$(ip route get 1.1.1.1 2>/dev/null | grep -oP '(?<=dev\s)\w+' | head -n 1)

if [ -z "$iface" ]; then
    echo "{\"text\": \"Disconnected\", \"class\": \"disconnected\"}"
    exit 0
fi

ip_addr=$(ip -4 addr show $iface | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

# Detect Type
if [[ "$iface" == wl* ]]; then
    icon="" # Wifi Icon
elif [[ "$iface" == en* || "$iface" == eth* ]]; then
    icon="" # Ethernet Icon (Nerd Font)
else
    icon="🌐"
fi

if [ -n "$ip_addr" ]; then
    echo "{\"text\": \"<span color='#00FFFF'>$icon</span> <span color='#cba6f7'>$ip_addr</span>\", \"tooltip\": \"Interface: $iface\"}"
else
    echo "{\"text\": \"<span color='#f38ba8'>No IP</span>\", \"class\": \"disconnected\"}"
fi
