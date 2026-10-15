#!/usr/bin/env python3
"""Instala los controles de seguridad del candidato sin cambiar temas personales."""
import argparse
import os
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def files(home):
    data = Path(os.environ.get("XDG_DATA_HOME", home / ".local/share")) / "black-ice/system"
    config = Path(os.environ.get("XDG_CONFIG_HOME", home / ".config"))
    result = [(source, data / source.name, 0o644) for source in (ROOT / "src/system").glob("*.py")]
    result.append((ROOT / "config/i18n/en.json", data.parent / "i18n/en.json", 0o644))
    result.append((ROOT / "config/apps.json", data.parent / "software/config/apps.json", 0o644))
    result.append((ROOT / "scripts/select-apps.py", data.parent / "software/scripts/select-apps.py", 0o755))
    for name in ("black-ice-system", "black-ice-privacy", "black-ice-waybar", "black-ice-update", "black_ice_layout.py", "black_ice_theme.py", "waybar_start.sh",
                 "black_ice_i18n.py", "black-ice-language", "black-ice-control", "black-ice-theme-studio", "theme_visual", "conky_visual", "black_ice_launcher.py"):
        result.append((ROOT / "dotfiles/bin" / name, home / ".local/bin" / name, 0o755))
    result.append((ROOT / "dotfiles/waybar/privacy.css", config / "waybar/privacy.css", 0o644))
    result.append((ROOT / "dotfiles/systemd/user/black-ice-privacy.service", config / "systemd/user/black-ice-privacy.service", 0o644))
    return result


def install(targets):
    previous = []
    try:
        for source, destination, mode in targets:
            if destination.is_symlink() or destination.exists() and not destination.is_file():
                raise ValueError("Destino no regular; revisa antes de actualizar: " + str(destination))
            for parent in destination.parents:
                if parent.is_symlink():
                    raise ValueError("Directorio enlazado; conserva tu configuración y revisa el destino: " + str(parent))
            previous.append((destination, destination.read_bytes() if destination.exists() else None,
                             destination.stat().st_mode & 0o777 if destination.exists() else mode))
            destination.parent.mkdir(parents=True, exist_ok=True)
            descriptor, name = tempfile.mkstemp(dir=destination.parent)
            temporary = Path(name)
            try:
                with os.fdopen(descriptor, "wb") as output:
                    output.write(source.read_bytes())
                    output.flush()
                    os.fsync(output.fileno())
                temporary.chmod(mode)
                temporary.replace(destination)
            finally:
                temporary.unlink(missing_ok=True)
    except Exception:
        for destination, content, mode in reversed(previous):
            if content is None:
                destination.unlink(missing_ok=True)
            else:
                destination.write_bytes(content)
                destination.chmod(mode)
        raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    targets = files(Path.home())
    if args.dry_run:
        for _, destination, _ in targets:
            print(destination)
        return 0
    if os.geteuid() == 0:
        parser.error("Ejecuta la instalación como usuario del escritorio, sin sudo")
    install(targets)
    for action in (["daemon-reload"], ["enable", "--now", "black-ice-privacy.service"]):
        result = subprocess.run(["systemctl", "--user", *action], capture_output=True, text=True, check=False, timeout=45)
        if result.returncode:
            print("Archivos instalados; el servicio no quedó activo. Ejecuta systemctl --user daemon-reload y "
                  "systemctl --user enable --now black-ice-privacy.service desde tu sesión.\n" + result.stderr[-1000:], file=sys.stderr)
            return 1
    print("Controles instalados. Reinicia Waybar con ~/.local/bin/waybar_start.sh para mostrar ONION LINK.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, subprocess.TimeoutExpired) as error:
        print(str(error), file=sys.stderr)
        raise SystemExit(1) from None
