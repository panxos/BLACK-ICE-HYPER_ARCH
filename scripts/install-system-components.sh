#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
[[ $EUID -eq 0 ]] || { printf '%s\n' 'Ejecuta este instalador con sudo.' >&2; exit 1; }

install -d -m 755 /usr/lib/black-ice /usr/share/black-ice
install -m 755 "$ROOT/scripts/system-transaction.py" /usr/lib/black-ice/system-transaction
install -m 755 "$ROOT/scripts/system-sddm-theme.py" /usr/lib/black-ice/system-sddm-theme
install -m 644 "$ROOT/config/apps.json" /usr/share/black-ice/apps.json
bash "$ROOT/scripts/install-system-tor.sh"
printf '%s\n' 'Componentes de sistema actualizados. Tor y sus reglas siguen sin activarse.'
