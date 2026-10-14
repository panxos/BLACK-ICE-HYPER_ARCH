#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
config_dir=${XDG_CONFIG_HOME:-"$HOME/.config"}
for executable in conky python3 hyprctl systemctl; do
    command -v "$executable" >/dev/null || { echo "[ERROR] Falta $executable. Instala conky y python con pacman." >&2; exit 1; }
done
[[ -n ${WAYLAND_DISPLAY:-} && -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] || {
    echo '[ERROR] Ejecuta el instalador dentro de tu sesión Hyprland.' >&2; exit 1;
}
python3 -c 'import gi; gi.require_version("Gtk", "3.0"); from gi.repository import Gtk' || {
    echo '[ERROR] Falta GTK3/PyGObject. Instala python-gobject y gtk3 con pacman.' >&2; exit 1;
}
install -Dm755 "$repo_dir/dotfiles/bin/black-ice-conky" "$HOME/.local/bin/black-ice-conky"
install -Dm755 "$repo_dir/dotfiles/bin/conky_visual" "$HOME/.local/bin/conky_visual"
install -Dm644 "$repo_dir/dotfiles/bin/black_ice_outputs.py" "$HOME/.local/bin/black_ice_outputs.py"
install -Dm644 "$repo_dir/dotfiles/conky/black-ice/draw.lua" "$config_dir/conky/black-ice/draw.lua"
install -Dm644 "$repo_dir/dotfiles/conky/black-ice/preview.lua" "$config_dir/conky/black-ice/preview.lua"
install -Dm644 "$repo_dir/dotfiles/conky/black-ice/palettes.json" "$config_dir/conky/black-ice/palettes.json"
install -Dm644 "$repo_dir/dotfiles/conky/black-ice/theme-defaults.json" "$config_dir/conky/black-ice/theme-defaults.json"
install -Dm644 "$repo_dir/dotfiles/systemd/user/black-ice-conky.service" "$config_dir/systemd/user/black-ice-conky.service"
install -Dm644 "$repo_dir/dotfiles/hypr/conky.conf" "$config_dir/hypr/conky.conf"
mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/black-ice-conky.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=BLACK-ICE — Monitor del escritorio
Comment=Elegir estilos, colores, transparencia y visibilidad
Exec="$HOME/.local/bin/black-ice-conky" menu
Icon=utilities-system-monitor
Categories=System;Monitor;
Terminal=false
EOF
systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP
systemctl --user daemon-reload
systemctl --user enable black-ice-conky.service
systemctl --user restart black-ice-conky.service
if [[ -f "$config_dir/hypr/hyprland.conf" && ! -f "$config_dir/hypr/hyprland.lua" ]]; then
    source_line="source = $config_dir/hypr/conky.conf"
    if ! grep -Fqx -- "$source_line" "$config_dir/hypr/hyprland.conf"; then
        if hyprctl -j binds | python3 -c 'import json,sys; sys.exit(any(b["key"] == "F8" and b["modmask"] in (64,65) for b in json.load(sys.stdin)))'; then
            printf '\n%s\n' "$source_line" >> "$config_dir/hypr/hyprland.conf"
            hyprctl reload >/dev/null
        else
            echo '[INFO] Super+F8 ya tiene una asignación; usa el selector de aplicaciones.'
        fi
    fi
else
    echo '[INFO] Usa black-ice-conky menu o agrega los atajos a tu configuración Lua.'
fi
echo '[INFO] Monitor instalado. Selector: black-ice-conky menu'
