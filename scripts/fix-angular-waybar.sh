#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
config_dir=${XDG_CONFIG_HOME:-"$HOME/.config"}
install -Dm755 "$repo_dir/dotfiles/bin/waybar_start.sh" "$HOME/.local/bin/waybar_start.sh"
install -Dm755 "$repo_dir/dotfiles/bin/waybar_start.sh" "$config_dir/bin/waybar_start.sh"
python3 - "$config_dir" <<'PY'
import os
from pathlib import Path
import re
import sys

config = Path(sys.argv[1])
state = Path(os.environ.get('XDG_STATE_HOME', Path.home() / '.local/state'))
backup = state / 'black-ice/waybar-changes/angular-assets'
targets = [(config / 'hypr/scripts/startup.sh', 'startup.sh'),
           (config / 'bin/theme_selector', 'selector-config'),
           (Path.home() / '.local/bin/theme_selector', 'selector-local')]
seen = set()
for path, name in targets:
    if not path.is_file() or path.resolve() in seen:
        continue
    seen.add(path.resolve())
    original = path.read_text()
    updated = original.replace('\nwaybar &\n', '\n"$HOME/.local/bin/waybar_start.sh"\n')
    updated = updated.replace('\nwaybar &>/dev/null &\n', '\n"$HOME/.local/bin/waybar_start.sh" >/dev/null\n')
    if updated != original:
        updated = re.sub(r'^_waybar_pid=\$!\n.*?^unset _waybar_pid\n', '', updated,
                         count=1, flags=re.MULTILINE | re.DOTALL)
        backup.mkdir(parents=True, exist_ok=True, mode=0o700)
        saved = backup / name
        if not saved.exists():
            with saved.open('x') as handle:
                handle.write(original)
            saved.chmod(0o600)
        path.write_text(updated)
        print(f'[INFO] Ruta Waybar corregida: {path}')
PY
"$HOME/.local/bin/waybar_start.sh"
