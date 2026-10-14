#!/usr/bin/env bash
set -euo pipefail
case ${1:-} in
    Horus) theme=Horus-Nightwatch ;;
    Ra) theme=Ra-Eclipse ;;
    Isis) theme=Isis-Lunar ;;
    Anubis) theme=Anubis-Sethek ;;
    Seth) theme=Seth-Tempest ;;
    Sekhmet) theme=Sekhmet-Redline ;;
    Nephthys) theme=Nephthys-Veil ;;
    *) theme=${1:-Anubis-Sethek} ;;
esac
exec "$HOME/.local/bin/black-ice-appearance" apply "$theme"
