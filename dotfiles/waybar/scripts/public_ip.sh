#!/bin/bash
# ~/.config/waybar/scripts/public_ip.sh
# Public IP Fetcher

ip=$(curl -s --max-time 2 ifconfig.me)
if [ -z "$ip" ]; then
    echo "Offline"
else
    echo "$ip"
fi
