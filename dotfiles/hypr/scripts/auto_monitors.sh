#!/bin/bash
# auto_monitors.sh — Detecta monitores y configura monitors.conf
#
# Comportamiento:
#   - Primera vez (sin state file): genera config + abre nwg-displays si hay 2+ monitores
#   - Boots siguientes: aplica monitors.conf existente en silencio, no abre nada
#   - Para reconfigurar manualmente: auto_monitors.sh --force-gui
#
# Uso: auto_monitors.sh [--force-gui]

MONITORS_CONF="$HOME/.config/hypr/monitors.conf"
STATE_FILE="$HOME/.cache/black-ice/monitors_configured"
FORCE_GUI=false

[[ "${1:-}" == "--force-gui" ]] && FORCE_GUI=true

mkdir -p "$HOME/.cache/black-ice"

# Boots normales: si ya fue configurado antes, salir silenciosamente
if [[ -f "$STATE_FILE" && "$FORCE_GUI" == false ]]; then
    exit 0
fi

# Necesita Hyprland corriendo para usar hyprctl
command -v hyprctl &>/dev/null || exit 0

MONITOR_COUNT=$(hyprctl monitors -j 2>/dev/null \
    | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "1")

# Monitor único: config mínima, marcar como configurado
if [[ "$MONITOR_COUNT" -eq 1 ]]; then
    if [[ ! -f "$MONITORS_CONF" ]]; then
        echo "monitor=,preferred,auto,1" > "$MONITORS_CONF"
    fi
    touch "$STATE_FILE"
    exit 0
fi

# Múltiples monitores: primera vez o --force-gui
# Generar config base con todos los monitores en fila
python3 - << 'PYEOF'
import subprocess, json, os

try:
    monitors = json.loads(subprocess.check_output(["hyprctl", "monitors", "-j"]).decode())
except Exception:
    raise SystemExit(0)

lines = ["# monitors.conf — BLACK-ICE ARCH (auto-generado)"]
offset_x = 0
for i, m in enumerate(monitors):
    name = m.get("name", f"monitor{i}")
    w    = m.get("width", 1920)
    h    = m.get("height", 1080)
    hz   = m.get("refreshRate", 60)
    scale = m.get("scale", 1.0)
    lines.append(f"monitor={name},{w}x{h}@{hz:.0f},{offset_x}x0,{scale:.1f}")
    offset_x += w

conf = os.path.expanduser("~/.config/hypr/monitors.conf")
with open(conf, "w") as f:
    f.write("\n".join(lines) + "\n")
PYEOF

touch "$STATE_FILE"

# Abrir nwg-displays para ajuste fino (solo en primera vez / --force-gui)
if command -v nwg-displays &>/dev/null; then
    sleep 2
    notify-send "BLACK-ICE ARCH" \
        "Se detectaron $MONITOR_COUNT monitores. Abre nwg-displays para ajustar disposición." \
        --icon=display 2>/dev/null || true
    nwg-displays &
else
    notify-send "BLACK-ICE ARCH" \
        "$MONITOR_COUNT monitores detectados. Config base generada en monitors.conf" \
        --icon=display 2>/dev/null || true
fi
