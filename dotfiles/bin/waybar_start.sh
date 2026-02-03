#!/bin/bash
# Waybar Startup Script with Theme Persistence
# BLACK-ICE ARCH - Francisco Aravena

DEFAULT_THEME_FILE="$HOME/.config/waybar/default_theme"
THEMES_DIR="$HOME/.config/waybar/themes"

# Create default theme file if doesn't exist
if [ ! -f "$DEFAULT_THEME_FILE" ]; then
    echo "Horus-Cyber" > "$DEFAULT_THEME_FILE"
fi

# Read saved theme
THEME=$(cat "$DEFAULT_THEME_FILE" 2>/dev/null || echo "Horus-Cyber")

# Validate theme exists
if [ ! -d "$THEMES_DIR/$THEME" ]; then
    echo "Theme '$THEME' not found, using Horus-Cyber as fallback"
    THEME="Horus-Cyber"
    echo "$THEME" > "$DEFAULT_THEME_FILE"
fi

# Kill existing waybar instances
pkill -9 waybar 2>/dev/null
sleep 0.5

# Start waybar with selected theme
waybar -c "$THEMES_DIR/$THEME/config.jsonc" \
       -s "$THEMES_DIR/$THEME/style.css" &

echo "Waybar started with theme: $THEME"
