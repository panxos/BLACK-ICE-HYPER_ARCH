#!/bin/bash
# capslock_status.sh - Caps Lock indicator for hyprlock

if [[ $(hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .capslock') == "true" ]]; then
    echo "⚠ CAPS LOCK ENABLED"
else
    echo ""
fi
