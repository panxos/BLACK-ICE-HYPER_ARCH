#!/bin/bash
# random_logo.sh - Black-Ice Arch v1.0

# 1. Detectar Color del Tema
CACHE_THEME="$HOME/.cache/current_theme"
[ -f "$CACHE_THEME" ] && THEME=$(cat "$CACHE_THEME") || THEME="Horus-Cyber"

case "$THEME" in
    "Anubis-Death") COLOR="green" ;;
    "Ra-Solar")     COLOR="yellow" ;;
    "Isis-Magic")   COLOR="magenta" ;;
    "Horus-Cyber")  COLOR="cyan" ;;
    *)              COLOR="white" ;;
esac

# 2. Seleccionar Logo
LOGOS_DIR="$HOME/.config/fastfetch/logos"
IMG=$(find "$LOGOS_DIR" -maxdepth 1 -name "*.png" 2>/dev/null | shuf -n 1)

# 3. Ejecutar
if [ -n "$IMG" ] && [ -z "$SSH_CONNECTION" ] && [[ "$TERM" == *"kitty"* ]]; then
    # Kitty Local: Imagen
    # Usar --logo-width para versiones recientes de fastfetch
    fastfetch --logo "$IMG" --logo-type kitty --logo-width 30 --color-keys "$COLOR" --color-title "$COLOR"
else
    # Fallback SSH/ASCII o si Kitty falla
    fastfetch --color-keys "$COLOR" --color-title "$COLOR"
fi
