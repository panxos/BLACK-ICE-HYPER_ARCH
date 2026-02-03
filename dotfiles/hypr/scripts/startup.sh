#!/bin/bash
# startup.sh - Orquestador de Inicio BLACK-ICE v1.0
# Colores en Hexadecimal para máxima compatibilidad con Hyprland.

# 1. Limpieza y Portales
pkill waybar
pkill swww-daemon
~/.config/hypr/scripts/portal.sh &
sleep 1

# 2. Iniciar Daemons
swww-daemon &
sleep 0.2

# 3. Restaurar Wallpaper
$HOME/.config/hypr/scripts/set_wallpaper.sh &

# 4. RESTAURAR IDENTIDAD
CACHE_THEME="$HOME/.cache/current_theme"
W_DIR="$HOME/.config/waybar"
THEMES_DIR="$W_DIR/themes"
FF_DIR="$HOME/.config/fastfetch"
DEFAULT_THEME="Horus-Cyber"

[ -f "$CACHE_THEME" ] && THEME=$(cat "$CACHE_THEME") || THEME="$DEFAULT_THEME"
[ ! -d "$THEMES_DIR/$THEME" ] && THEME="$DEFAULT_THEME"

# A. Symlinks de Waybar
rm -f "$W_DIR/config" "$W_DIR/config.jsonc" "$W_DIR/style.css"
ln -sf "$THEMES_DIR/$THEME/config.jsonc" "$W_DIR/config.jsonc"
ln -sf "$THEMES_DIR/$THEME/style.css" "$W_DIR/style.css"

# Wallpaper Rotation (Random on Startup)
RANDOM_WALLPAPER=$(find "$HOME/.config/wallpapers" -type f \( -name "*.jpg" -o -name "*.png" \) 2>/dev/null | shuf -n 1)
[ -f "$RANDOM_WALLPAPER" ] && swww img "$RANDOM_WALLPAPER" --transition-type wipe --transition-fps 60

# Fastfetch Logo Rotation (Random on Startup)
RANDOM_LOGO=$(find "$HOME/.config/fastfetch/logos" -name "*.png" | shuf -n 1)
[ -f "$RANDOM_LOGO" ] && cp "$RANDOM_LOGO" "$HOME/.config/fastfetch/current_logo.png"

# C. Bordes de Hyprland (Formato HEX 0xAARRGGBB)
case "$THEME" in
    "Horus-Cyber")  C="0xee00ffff 0xee003333" ;; # Cyan
    "Ra-Solar")     echo "Ra Solar" && C="0xeeffaa00 0xee552200" ;; # Oro
    "Isis-Magic")   C="0xeeff00ff 0xee330033" ;; # Magenta
    "Anubis-Death") C="0xee44ff00 0xee002200" ;; # VERDE TOXICO
esac
hyprctl keyword general:col.active_border "$C 45deg" 2>/dev/null

# 5. Iniciar Waybar
waybar &
