#!/bin/bash
# theme_visual - Selector visual de temas BLACK-ICE con preview
THEMES_DIR="$HOME/.config/waybar/themes"
W_DIR="$HOME/.config/waybar"
WALL_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")/wallpapers"
CACHE_THEME="$HOME/.cache/current_theme"
FF_DIR="$HOME/.config/fastfetch"

# Devuelve el prefijo de wallpaper asociado al theme
# Rices sin match devuelven cadena vacía → random del pool completo
_wall_prefix() {
    case "$1" in
        Emilia-TokyoNight)   echo "emilia"  ;;
        Jan-CyberPunk)       echo "jan"     ;;
        Marisol-Dracula)     echo "marisol" ;;
        Melissa-Nord)        echo "melissa" ;;
        Brenda-Everforest)   echo "brenda"  ;;
        Daniela-Catppuccin)  echo "daniela" ;;
        Isabel-Frappe)       echo "isabel"  ;;
        Karla-ZombieNight)   echo "karla"   ;;
        Pamela-Lovelace)     echo "pamela"  ;;
        Silvia-Gruvbox)      echo "silvia"  ;;
        Varinka-Mono)        echo "varinka" ;;
        Yael-OxoCarbon)      echo "yael"    ;;
        Zombie-Decay)        echo "z0mbi3"  ;;
        H4k3r-HTB)          echo "h4ck3r"  ;;
        *)                   echo ""        ;;
    esac
}

# Aplica un wallpaper (solo imágenes, no video)
_apply_wall() {
    local wall="$1"
    [[ -z "$wall" || ! -f "$wall" ]] && return
    sed -i "s|^wallpaper = .*|wallpaper = $wall|" "$HOME/.config/waypaper/config.ini" 2>/dev/null
    pkill mpvpaper 2>/dev/null
    awww img "$wall" --transition-type grow --transition-duration 1 2>/dev/null
}

# ── Construir lista rofi con iconos ────────────────────────────────────────────
ROFI_INPUT=""
for theme_dir in "$THEMES_DIR"/*/; do
    theme=$(basename "$theme_dir")
    preview="$theme_dir/preview.png"
    if [[ -f "$preview" ]]; then
        ROFI_INPUT+="$theme\0icon\x1f$preview\n"
    else
        ROFI_INPUT+="$theme\n"
    fi
done

selection=$(printf "%b" "$ROFI_INPUT" | rofi -dmenu \
    -show-icons \
    -icon-size 300 \
    -theme "$HOME/.config/rofi/theme-selector.rasi" \
    -p "󰏘 Theme" \
    -format s)

[[ -z "$selection" ]] && exit 0

THEME_PATH="$THEMES_DIR/$selection"
[[ ! -f "$THEME_PATH/config.jsonc" ]] && notify-send "BLACK-ICE" "Theme inválido: $selection" && exit 1

echo "$selection" > "$CACHE_THEME"

# ── Waybar links ───────────────────────────────────────────────────────────────
rm -f "$W_DIR/config" "$W_DIR/config.jsonc" "$W_DIR/style.css"
ln -sf "$THEME_PATH/config.jsonc" "$W_DIR/config"
ln -sf "$THEME_PATH/config.jsonc" "$W_DIR/config.jsonc"
ln -sf "$THEME_PATH/style.css" "$W_DIR/style.css"

# ── Wallpaper temático ─────────────────────────────────────────────────────────
# Prioridad: 1) wallpaper guardado para este theme  2) random del pool temático  3) random total
THEME_WALL_FILE="$THEME_PATH/wallpaper"
WALL=""

if [[ -f "$THEME_WALL_FILE" ]]; then
    SAVED=$(tr -d '[:space:]' < "$THEME_WALL_FILE")
    [[ -f "$SAVED" ]] && WALL="$SAVED"
fi

if [[ -z "$WALL" ]]; then
    PREFIX=$(_wall_prefix "$selection")
    if [[ -n "$PREFIX" ]]; then
        WALL=$(find "$WALL_DIR" -maxdepth 1 \
            \( -name "${PREFIX}-*.webp" -o -name "${PREFIX}-*.jpg" -o -name "${PREFIX}-*.png" \) \
            2>/dev/null | shuf -n 1)
    fi
fi

if [[ -z "$WALL" ]]; then
    WALL=$(find "$WALL_DIR" -maxdepth 1 \
        \( -name "*.webp" -o -name "*.jpg" -o -name "*.png" \) \
        2>/dev/null | shuf -n 1)
fi

if [[ -n "$WALL" ]]; then
    echo "$WALL" > "$THEME_WALL_FILE"
    _apply_wall "$WALL"
fi

# ── Logo fastfetch aleatorio ───────────────────────────────────────────────────
RANDOM_LOGO=$(find "$FF_DIR/logos" -name "*.png" 2>/dev/null | shuf -n 1)
[[ -f "$RANDOM_LOGO" ]] && cp "$RANDOM_LOGO" "$FF_DIR/current_logo.png"

# ── Restart Waybar ─────────────────────────────────────────────────────────────
pkill -9 waybar 2>/dev/null
sleep 0.3
waybar &>/dev/null &

notify-send "BLACK-ICE" "Theme: $selection" --icon "$THEME_PATH/preview.png" 2>/dev/null
