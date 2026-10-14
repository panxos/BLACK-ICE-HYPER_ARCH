#!/usr/bin/env python3
"""Instala pantallas de acceso de agencias sin cambiar la selección de SDDM."""
import argparse
import configparser
import json
import re
import shutil
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def install(source=ROOT, destination=Path("/usr/share/sddm/themes"), apply=False):
    presets = json.loads((source / "assets/sddm/agency-presets.json").read_text())
    catalog = json.loads((source / "dotfiles/waybar/cyber-catalog.json").read_text())
    template = source / "assets/sddm/themes/black-ice-obsidian"
    plan = []
    for name, preset in presets.items():
        if not re.fullmatch(r"black-ice-[a-z0-9-]+", preset["theme"]):
            raise ValueError("Nombre de tema inválido")
        font = (source / "assets/fonts" / preset["font_file"]).resolve(strict=True)
        if not font.is_relative_to((source / "assets/fonts").resolve()):
            raise ValueError("Fuente fuera del catálogo")
        profile = catalog[name]
        background = (source / "assets/wallpapers/cyber" / profile["wallpaper"]).resolve(strict=True)
        if not background.is_relative_to((source / "assets/wallpapers/cyber").resolve()):
            raise ValueError("Fondo fuera del catálogo")
        panorama = (source / "assets/wallpapers/cyber" / profile.get("panorama", "")).resolve()
        if panorama.is_file() and not panorama.is_relative_to((source / "assets/wallpapers/cyber").resolve()):
            raise ValueError("Panorama fuera del catálogo")
        with background.open("rb") as stream:
            header = stream.read(24)
        if header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
            raise ValueError("Se requiere un PNG válido")
        width, height = struct.unpack(">II", header[16:24])
        if width < 3840 or height < 2160:
            raise ValueError("El fondo de acceso debe conservar al menos 3840×2160")
        target = destination / preset["theme"]
        if target.is_symlink() or any(p.is_symlink() for p in target.rglob("*")):
            raise ValueError("El destino del tema contiene enlaces simbólicos")
        plan.append({"name": name, "theme": preset["theme"], "size": [width, height]})
    if not apply:
        return plan
    for item in plan:
        preset = presets[item["name"]]
        profile = catalog[item["name"]]
        target = destination / item["theme"]
        shutil.copytree(template, target, dirs_exist_ok=True, ignore=shutil.ignore_patterns("wallpaper.png"))
        shutil.copyfile(source / "assets/wallpapers/cyber" / profile["wallpaper"], target / "assets/wallpaper.png")
        panorama = source / "assets/wallpapers/cyber" / profile.get("panorama", "")
        if panorama.is_file():
            shutil.copyfile(panorama, target / "assets/panorama.png")
        font = source / "assets/fonts" / preset["font_file"]
        shutil.copytree(font.parent, target / "assets/fonts" / font.parent.name, dirs_exist_ok=True)
        config = configparser.ConfigParser(interpolation=None)
        config.optionxform = str
        config.read(target / "theme.conf")
        config["General"].update(title=preset["title"], subtitle=preset["subtitle"],
                                 backgroundMode=profile.get("wallpaper_mode", "auto"),
                                 backgroundPanorama="assets/panorama.png" if panorama.is_file() else "",
                                 backgroundAnchor=profile.get("panorama_anchor", "center"),
                                 bodyFontFile="assets/fonts/" + preset["font_file"],
                                 font=profile["font"], bodyFont=profile["font"],
                                 accent=profile["acc1"], secondary=profile["acc2"],
                                 foreground=profile["fg"], muted=profile["dim"], surface=profile["bg"])
        with (target / "theme.conf").open("w") as stream:
            config.write(stream, space_around_delimiters=False)
        metadata = configparser.ConfigParser(interpolation=None)
        metadata.optionxform = str
        metadata.read(target / "metadata.desktop")
        metadata["SddmGreeterTheme"]["Name"] = item["name"]
        metadata["SddmGreeterTheme"]["Theme-Id"] = item["theme"]
        metadata["SddmGreeterTheme"]["Version"] = (source / "VERSION").read_text().strip()
        with (target / "metadata.desktop").open("w") as stream:
            metadata.write(stream, space_around_delimiters=False)
        target.chmod(0o755)
        for path in target.rglob("*"):
            path.chmod(0o755 if path.is_dir() else 0o644)
    return plan


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--destination", type=Path, default=Path("/usr/share/sddm/themes"))
    args = parser.parse_args()
    print(json.dumps(install(destination=args.destination, apply=args.apply), ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
