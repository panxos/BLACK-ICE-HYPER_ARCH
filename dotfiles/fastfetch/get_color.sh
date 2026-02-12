#!/bin/bash
# get_color.sh - Black-Ice Arch v1.0
CACHE_THEME="$HOME/.cache/current_theme"
[ -f "$CACHE_THEME" ] && THEME=$(cat "$CACHE_THEME") || THEME="Horus-Cyber"

case "$THEME" in
    "Anubis-Death") echo "green" ;;
    "Ra-Solar")     echo "yellow" ;;
    "Isis-Magic")   echo "magenta" ;;
    "Horus-Cyber")  echo "cyan" ;;
    *)              echo "white" ;;
esac
