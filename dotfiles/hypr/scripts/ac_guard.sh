#!/usr/bin/env bash
set -euo pipefail

POWER_SUPPLY_ROOT="${BLACK_ICE_POWER_SUPPLY_ROOT:-/sys/class/power_supply}"

power_source() {
    local device type online status scope
    local discharging=false uncertain=false external=false
    for device in "$POWER_SUPPLY_ROOT"/*; do
        [[ -d "$device" ]] || continue
        type=$(cat "$device/type" 2>/dev/null || true)
        scope=$(cat "$device/scope" 2>/dev/null || true)
        [[ "$scope" != Device ]] || continue
        if [[ "$type" == Battery ]]; then
            status=$(cat "$device/status" 2>/dev/null || true)
            case "$status" in
                Discharging) discharging=true ;;
                Full|'Not charging') ;;
                *) uncertain=true ;;
            esac
        elif [[ -e "$device/online" ]]; then
            online=$(cat "$device/online" 2>/dev/null || true)
            case "$online" in
                1) external=true ;;
                0) ;;
                *) uncertain=true ;;
            esac
        elif [[ "$type" == Mains || "$type" == USB* ]]; then
            uncertain=true
        fi
    done
    if "$external"; then
        printf 'ac\n'
    elif "$discharging" && ! "$uncertain"; then
        printf 'battery\n'
    else
        printf 'unknown\n'
    fi
}

action="${1:-}"
case "$action" in
    status) power_source; exit 0 ;;
    dim-up) brightnessctl -r 2>/dev/null || true; exit 0 ;;
    dim-down|dpms-off|suspend) ;;
    *) printf 'Uso: ac_guard.sh {status|dim-down|dim-up|dpms-off|suspend}\n' >&2; exit 2 ;;
esac

if systemd-detect-virt -q 2>/dev/null || [[ "$(power_source)" != battery ]]; then
    exit 0
fi
case "$action" in
    dim-down) brightnessctl -s set 10% ;;
    dpms-off)
        if [[ -x "$HOME/.local/bin/black-ice-hypr" ]]; then
            "$HOME/.local/bin/black-ice-hypr" dpms off
        else
            hyprctl dispatch dpms off
        fi ;;
    suspend) systemctl suspend ;;
esac
