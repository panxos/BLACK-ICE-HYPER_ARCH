#!/bin/bash
# random_logo.sh - Black-Ice Fastfetch v3.1
# Selección aleatoria de logos (PNG con aspect ratio, ASCII con colores de tema)
# NOTA: Todo el config de logo va en config.jsonc, no por CLI

LOGOS_DIR="$HOME/.config/fastfetch/logos"
CACHE_THEME="$HOME/.cache/current_theme"

# 1. Detectar Color del Tema
[ -f "$CACHE_THEME" ] && THEME=$(cat "$CACHE_THEME") || THEME="Horus-Cyber"

case "$THEME" in
    "Anubis-Death") COLOR="green" ;;
    "Ra-Solar")     COLOR="yellow" ;;
    "Isis-Magic")   COLOR="magenta" ;;
    "Horus-Cyber")  COLOR="cyan" ;;
    *)              COLOR="white" ;;
esac

# 2. Verificar si fastfetch tiene soporte de imágenes
HAS_IMAGE_SUPPORT=false
if [ -f /usr/lib/libMagickCore-7.Q16HDRI.so ] || [ -f /usr/lib/libMagickCore-7.Q16.so ]; then
    HAS_IMAGE_SUPPORT=true
fi

# 3. Seleccionar Logo
if [ "$HAS_IMAGE_SUPPORT" = true ]; then
    IMG=$(find "$LOGOS_DIR" -maxdepth 1 -name "*.png" 2>/dev/null | shuf -n 1)
    if [ -n "$IMG" ]; then
        # Solo --kitty, el resto viene del config.jsonc
        fastfetch --kitty "$IMG"
        exit 0
    fi
fi

# 4. Fallback: Usar logo ASCII aleatorio con color del tema
RAW=$(find "$LOGOS_DIR" -maxdepth 1 -name "*.raw" 2>/dev/null | shuf -n 1)
if [ -n "$RAW" ]; then
    fastfetch --raw "$RAW" \
              --logo-color-1 "$COLOR" \
              --logo-color-2 "$COLOR" \
              --bright-color
else
    fastfetch
fi
