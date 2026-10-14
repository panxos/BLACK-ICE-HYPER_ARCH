"""Fija el mapa XKB antes de iniciar el greeter, conservando Xsetup personalizado."""
import argparse
import configparser
import json
import os
import re
import shlex
from pathlib import Path

WRAPPER = "/usr/local/libexec/black-ice/sddm-xsetup"
VENDOR = "/usr/share/sddm/scripts/Xsetup"


def configure(root: Path, layout: str, apply: bool) -> dict:
    if not re.fullmatch(r"[a-zA-Z0-9_-]+", layout):
        raise ValueError("Distribución XKB inválida")
    folder = root / "etc/sddm.conf.d"
    files = sorted(folder.glob("*.conf"))
    main = root / "etc/sddm.conf"
    if main.exists():
        files.append(main)
    display_command = VENDOR
    target = folder / "90-black-ice-keyboard.conf"
    for path in files:
        config = configparser.ConfigParser(interpolation=None)
        config.read(path)
        if config.has_option("X11", "DisplayCommand"):
            display_command = config.get("X11", "DisplayCommand")
            target = path
    if display_command not in (VENDOR, WRAPPER):
        return {"applied": False, "reason": "DisplayCommand personalizado conservado"}
    if apply:
        if root.resolve() == Path("/") and os.geteuid() != 0:
            raise PermissionError("Se requiere root para configurar SDDM")
        wrapper = root / WRAPPER.lstrip("/")
        wrapper.parent.mkdir(parents=True, exist_ok=True)
        wrapper.write_text("#!/bin/sh\nset -eu\n" + VENDOR + ' "$@"\nexec /usr/bin/setxkbmap -layout ' + shlex.quote(layout) + "\n")
        wrapper.chmod(0o755)
        config = configparser.ConfigParser(interpolation=None)
        config.optionxform = str
        config.read(target)
        if not config.has_section("X11"):
            config.add_section("X11")
        for option in list(config["X11"]):
            if option.lower() == "displaycommand":
                config.remove_option("X11", option)
        config.set("X11", "DisplayCommand", WRAPPER)
        target.parent.mkdir(parents=True, exist_ok=True)
        with target.open("w") as stream:
            config.write(stream)
        target.chmod(0o644)
    return {"applied": apply, "layout": layout, "wrapper": WRAPPER, "config": str(target)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path("/"))
    parser.add_argument("--layout", required=True)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    print(json.dumps(configure(args.root, args.layout, args.apply), ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
