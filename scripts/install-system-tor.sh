#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
[[ $EUID -eq 0 ]] || { echo 'Run this installer with sudo.' >&2; exit 1; }
install -d -m 755 /usr/lib/black-ice /etc/black-ice
install -m 755 "$root/scripts/system-tor.py" /usr/lib/black-ice/system-tor
install -m 755 "$root/scripts/system-transaction.py" /usr/lib/black-ice/system-transaction
install -m 644 "$root/config/tor/torrc" /etc/black-ice/torrc
install -m 644 "$root/config/tor/"*.service /etc/systemd/system/
printf 'u black-ice-tor - "BLACK-ICE Tor client" /var/lib/black-ice-tor\n' | systemd-sysusers -
install -d -m 700 -o black-ice-tor -g black-ice-tor /var/lib/black-ice-tor
systemctl daemon-reload
if command -v tor >/dev/null; then
    runuser -u black-ice-tor -- tor --verify-config -f /etc/black-ice/torrc
fi
echo 'System Tor controls installed. Traffic rules have not been activated.'
