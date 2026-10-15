#!/usr/bin/env bash
set -euo pipefail

waybar_dir=${XDG_CONFIG_HOME:-"$HOME/.config"}/waybar
runtime_dir=${XDG_RUNTIME_DIR:-"$HOME/.cache"}
mkdir -p "$waybar_dir" "$runtime_dir"
exec 9>"$runtime_dir/black-ice-waybar.lock"
flock -w 5 9 || { echo '[ERROR] Otro inicio de Waybar está en curso.' >&2; exit 1; }

valid_theme() {
    [[ $1 =~ ^[[:alnum:]_.-]+$ && -f "$waybar_dir/themes/$1/config.jsonc" && -f "$waybar_dir/themes/$1/style.css" ]]
}

theme=${1:-}
resolve_theme() {
    case "$1" in
        Anubis-Death) printf '%s\n' Anubis-Sethek ;;
        Horus-Cyber) printf '%s\n' Horus-Nightwatch ;;
        Isis-Magic) printf '%s\n' Isis-Lunar ;;
        Nephthys-Pill) printf '%s\n' Nephthys-Veil ;;
        Ra-Solar) printf '%s\n' Ra-Eclipse ;;
        Sekhmet-Angular) printf '%s\n' Sekhmet-Redline ;;
        *) printf '%s\n' "$1" ;;
    esac
}
if [[ -n $theme ]] && ! valid_theme "$theme"; then theme=$(resolve_theme "$theme"); fi
if [[ -n $theme ]] && ! valid_theme "$theme"; then
    echo "[ERROR] Tema no disponible: $theme" >&2
    exit 1
fi
for saved in "$waybar_dir/default_theme" "$HOME/.cache/current_theme"; do
    [[ -n $theme ]] && break
    if [[ -r $saved ]]; then
        IFS= read -r candidate < "$saved" || true
        if ! valid_theme "$candidate"; then candidate=$(resolve_theme "$candidate"); fi
        if valid_theme "$candidate"; then theme=$candidate; fi
    fi
done
if [[ -z $theme ]]; then
    style=$(readlink -f -- "$waybar_dir/style.css" || true)
    candidate=$(basename -- "$(dirname -- "$style")")
    if valid_theme "$candidate"; then theme=$candidate; fi
fi
theme=${theme:-Anubis-Sethek}
valid_theme "$theme" || { echo '[ERROR] No hay un tema Waybar válido.' >&2; exit 1; }
theme_dir=$(realpath -- "$waybar_dir/themes/$theme")
config_file="$theme_dir/config.jsonc"
style_file="$theme_dir/style.css"
if [[ -f "$waybar_dir/privacy.css" && -x "$HOME/.local/bin/black-ice-waybar" ]]; then
    style_file="$runtime_dir/black-ice-waybar.css"
    "$HOME/.local/bin/black-ice-waybar" privacy-style "$theme_dir/style.css" > "$style_file"
fi
if [[ -x "$HOME/.local/bin/black-ice-waybar" ]]; then
    "$HOME/.local/bin/black-ice-waybar" check-style "$style_file" || exit 1
    candidate_config=$(mktemp "$runtime_dir/black-ice-waybar.XXXXXX")
    if ! "$HOME/.local/bin/black-ice-waybar" config "$config_file" >"$candidate_config"; then
        rm -f -- "$candidate_config"
        exit 1
    fi
    mv -- "$candidate_config" "$runtime_dir/black-ice-waybar.json"
    config_file="$runtime_dir/black-ice-waybar.json"
fi
printf '%s\n' "$theme" > "$waybar_dir/default_theme"
mkdir -p "$HOME/.cache"
printf '%s\n' "$theme" > "$HOME/.cache/current_theme"
for file in config config.jsonc; do ln -sfn -- "$theme_dir/config.jsonc" "$waybar_dir/$file"; done
ln -sfn -- "$theme_dir/style.css" "$waybar_dir/style.css"
if [[ -d "$theme_dir/assets" && ( ! -e "$waybar_dir/assets" || -L "$waybar_dir/assets" ) ]]; then
    ln -sfn -- "$theme_dir/assets" "$waybar_dir/assets"
fi

waybar_binary=waybar
if [[ -x "$HOME/.local/bin/black-ice-waybar-binary" ]]; then
    waybar_binary=$("$HOME/.local/bin/black-ice-waybar-binary")
fi

pkill -u "$(id -u)" -x waybar 2>/dev/null || true
for ((attempt=0; attempt<25; attempt++)); do
    pgrep -u "$(id -u)" -x waybar >/dev/null || break
    sleep 0.1
done
if pgrep -u "$(id -u)" -x waybar >/dev/null; then
    echo '[ERROR] Waybar no terminó; no se creará otra instancia.' >&2
    exit 1
fi
if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] && command -v hyprctl >/dev/null; then
    printf -v launch 'exec %q -c %q -s %q > %q 2>&1' \
        "$waybar_binary" "$config_file" "$style_file" "$runtime_dir/black-ice-waybar.log"
    if [[ -x "$HOME/.local/bin/black-ice-hypr" ]]; then
        "$HOME/.local/bin/black-ice-hypr" exec "$launch" >/dev/null 9>&-
    else
        hyprctl dispatch exec "$launch" >/dev/null 9>&-
    fi
else
    nohup "$waybar_binary" -c "$config_file" -s "$style_file" \
        >"$runtime_dir/black-ice-waybar.log" 2>&1 < /dev/null 9>&- &
fi
echo "[INFO] Waybar: $theme"
