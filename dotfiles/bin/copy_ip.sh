#!/bin/bash
# copy_ip.sh — Copia al portapapeles el valor IP de un módulo Waybar
# Uso: copy_ip.sh <script_path>
# Ejemplo: copy_ip.sh ~/.config/bin/local_ip
# P4nx0z Edition — BLACK-ICE ARCH

SCRIPT="$1"
[ -z "$SCRIPT" ] && exit 1
[ ! -x "$SCRIPT" ] && SCRIPT="$(command -v "$SCRIPT" 2>/dev/null || printf '%s' "$SCRIPT")"

# Ejecutar el script, parsear el campo "text", extraer solo la IP/valor
RAW=$("$SCRIPT" 2>/dev/null)
if command -v python3 &>/dev/null; then
    VALUE=$(python3 -c "
import json, sys, re
try:
    d = json.loads(sys.stdin.read())
    t = d.get('text','').strip()
    # Remove leading/trailing icon chars (non-ASCII and spaces)
    t = re.sub(r'^[^\w]+', '', t).strip()
    print(t)
except Exception:
    pass
" <<< "$RAW")
else
    # Fallback: strip non-ASCII prefix with tr
    VALUE=$(echo "$RAW" | grep -oP '"text":\s*"\K[^"]+' | sed 's/^[^0-9a-zA-Z]*//' | tr -d '\\')
fi

[ -z "$VALUE" ] && exit 0

echo -n "$VALUE" | wl-copy
notify-send "󰆧 Copiado" "$VALUE" --urgency=low --expire-time=2000
