#!/bin/bash
# theme_switcher.sh - Switch between Egyptian God Themes
# Usage: ./theme_switcher.sh [Horus|Ra|Isis|Anubis]

THEME=$1
WAYBAR_CONFIG="$HOME/.config/waybar/config.jsonc"
WAYBAR_STYLE="$HOME/.config/waybar/style.css"
THEMES_DIR="$HOME/.config/waybar/themes"

case $THEME in
    Horus)
        THEME_DIR="Horus-Cyber"
        WALLPAPER="HORUS-CYBER.jpg"
        ;;
    Ra)
        THEME_DIR="Ra-Solar"
        WALLPAPER="RA-SOLAR.jpg"
        ;;
    Isis)
        THEME_DIR="Isis-Magic"
        WALLPAPER="ISIS-MAGIC.jpg"
        ;;
    Anubis)
        THEME_DIR="Anubis-Death"
        WALLPAPER="ANUBIS-DEATH.jpg"
        ;;
    *)
        echo "Usage: $0 [Horus|Ra|Isis|Anubis]"
        exit 1
        ;;
esac

echo "Applying Theme: $THEME ($THEME_DIR)..."

# Link Waybar Configs
ln -sf "$THEMES_DIR/$THEME_DIR/config.jsonc" "$WAYBAR_CONFIG"
ln -sf "$THEMES_DIR/$THEME_DIR/style.css" "$WAYBAR_STYLE"

# Restart Waybar
pkill waybar
waybar -c "$WAYBAR_CONFIG" -s "$WAYBAR_STYLE" &

# Set Wallpaper (if available) - Dynamic Path Detection
PICTURES_DIR=$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")
WALLPAPER_PATH="$PICTURES_DIR/wallpapers/$WALLPAPER"

if [ -f "$WALLPAPER_PATH" ]; then
    swww img "$WALLPAPER_PATH" --transition-type grow
else
    # Fallback to .config if that's where they are
    ALT_PATH="$HOME/.config/wallpapers/$WALLPAPER"
    if [ -f "$ALT_PATH" ]; then
        swww img "$ALT_PATH" --transition-type grow
    fi
fi

notify-send "Theme Changed" "Active: $THEME"
