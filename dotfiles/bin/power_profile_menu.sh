#!/usr/bin/env bash
set -euo pipefail

if command -v wofi >/dev/null; then
    menu=(wofi --dmenu --prompt 'Energía' -i)
elif command -v rofi >/dev/null; then
    menu=(rofi -dmenu -p 'Energía' -i)
else
    notify-send 'Energía' 'No se encontró Wofi ni Rofi.' --urgency=critical
    exit 1
fi

choice=$(printf '%s\n' '↻ Automático' '⚡ Rendimiento' '⚖ Equilibrado' '🔋 Ahorro' | "${menu[@]}") || exit 0
case "$choice" in
    *Automático*) profile=auto ;;
    *Rendimiento*) profile=performance ;;
    *Equilibrado*) profile=balanced ;;
    *Ahorro*) profile=power-saver ;;
    *) exit 0 ;;
esac

controller="$(dirname "${BASH_SOURCE[0]}")/power_profile"
if [[ ! -x "$controller" ]]; then
    controller=$(command -v power_profile || true)
fi
if [[ -z "$controller" || ! -x "$controller" ]]; then
    notify-send 'Energía' 'Falta power_profile; actualiza los scripts de BLACK-ICE.' --urgency=critical
    exit 1
fi

if output=$("$controller" "$profile" 2>&1); then
    notify-send 'Energía' "$choice: $output" --icon=battery
else
    notify-send 'Energía' "No se aplicó el perfil: ${output:0:600}" --urgency=critical
    exit 1
fi
