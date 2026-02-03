#!/bin/bash
# set_wallpaper.sh - Dynamic wallpaper setter with Persistence
CACHE_FILE="$HOME/.cache/current_wallpaper"
WALLPAPER_DIR=""

# Detect Pictures directory
if command -v xdg-user-dir &>/dev/null; then
    PICTURES_DIR=$(xdg-user-dir PICTURES)
    [ -z "$PICTURES_DIR" ] && PICTURES_DIR="$HOME/Pictures"
else
    PICTURES_DIR="$HOME/Pictures"
fi
WALLPAPER_DIR="$PICTURES_DIR/wallpapers"

# 1. Check Persistence Cache
if [ -f "$CACHE_FILE" ]; then
    CACHED_WALL=$(cat "$CACHE_FILE")
    if [ -f "$CACHED_WALL" ]; then
        swww img "$CACHED_WALL" --transition-type none
        exit 0
    fi
fi

# 2. Fallback: HORUS-CYBER default (Si existe explícitamente)
if [ -f "$WALLPAPER_DIR/HORUS-CYBER.jpg" ]; then
    swww img "$WALLPAPER_DIR/HORUS-CYBER.jpg" --transition-type none
    echo "$WALLPAPER_DIR/HORUS-CYBER.jpg" > "$CACHE_FILE"
    exit 0
fi

# 3. Fallback: First image found
WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -name "*.png" -o -name "*.jpg" \) 2>/dev/null | head -n 1)

if [ -f "$WALLPAPER" ]; then
    swww img "$WALLPAPER" --transition-type grow
    echo "$WALLPAPER" > "$CACHE_FILE"
else
    swww img <(convert -size 1920x1080 xc:'#0a0a0a' png:-) 2>/dev/null
fi
