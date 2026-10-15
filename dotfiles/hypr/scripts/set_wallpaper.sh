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

# 1. waypaper/config.ini — fuente de verdad (se actualiza al seleccionar con waypaper o theme_selector)
_WP_CONFIG="$HOME/.config/waypaper/config.ini"
if [[ -f "$_WP_CONFIG" ]]; then
    _WP_WALL=$(grep "^wallpaper " "$_WP_CONFIG" | head -1 | cut -d= -f2 | tr -d ' ' | sed "s|^~|$HOME|")
    if [[ -f "$_WP_WALL" ]]; then
        echo "$_WP_WALL" > "$CACHE_FILE"
        awww img "$_WP_WALL" --transition-type none
        exit 0
    fi
fi

# 2. Check Persistence Cache (fallback si waypaper/config.ini no tiene path válido)
if [[ -f "$CACHE_FILE" ]]; then
    CACHED_WALL=$(cat "$CACHE_FILE")
    if [[ -f "$CACHED_WALL" ]]; then
        awww img "$CACHED_WALL" --transition-type none
        exit 0
    fi
fi

# 3. Fallback estable: imagen base incluida por el instalador.
DEFAULT_WALLPAPER="$WALLPAPER_DIR/black-ice-obsidian.png"
if [[ -f "$DEFAULT_WALLPAPER" ]]; then
    echo "$DEFAULT_WALLPAPER" > "$CACHE_FILE"
    awww img "$DEFAULT_WALLPAPER" --transition-type none
    exit 0
fi

_tmp=$(mktemp --suffix=.png)
convert -size 1920x1080 xc:'#0a0a0a' "$_tmp" 2>/dev/null && awww img "$_tmp" 2>/dev/null
rm -f "$_tmp"
