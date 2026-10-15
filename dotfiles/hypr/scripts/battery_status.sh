#!/bin/bash
# battery_status.sh - Battery status indicator for hyprlock

# Check if battery exists
if [ ! -d "/sys/class/power_supply/BAT0" ] && [ ! -d "/sys/class/power_supply/BAT1" ]; then
    echo ""
    exit 0
fi

# Get battery info
BATTERY=$(find /sys/class/power_supply/ -maxdepth 1 -name 'BAT*' -printf '%f\n' 2>/dev/null | head -1)
if [ -z "$BATTERY" ]; then
    echo ""
    exit 0
fi
CAPACITY=$(cat "/sys/class/power_supply/$BATTERY/capacity" 2>/dev/null || echo "0")
STATUS=$(cat "/sys/class/power_supply/$BATTERY/status" 2>/dev/null || echo "Unknown")

# Battery icon based on level
if [ $CAPACITY -ge 80 ]; then
    ICON="󰁹"
elif [ $CAPACITY -ge 60 ]; then
    ICON="󰂀"
elif [ $CAPACITY -ge 40 ]; then
    ICON="󰁾"
elif [ $CAPACITY -ge 20 ]; then
    ICON="󰁼"
else
    ICON="󰁺"
fi

# Charging indicator
if [ "$STATUS" = "Charging" ]; then
    echo "$ICON $CAPACITY% (CHARGING)"
else
    echo "$ICON $CAPACITY%"
fi
