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


def image_size(path):
    data = path.read_bytes()
    if data.startswith(b"\x89PNG\r\n\x1a\n") and data[12:16] == b"IHDR":
        return struct.unpack(">II", data[16:24])
    if not data.startswith(b"\xff\xd8"):
        raise ValueError("Formato de imagen no compatible")
    offset = 2
    while offset + 4 <= len(data):
        if data[offset] != 0xFF:
            offset += 1
            continue
        while offset < len(data) and data[offset] == 0xFF:
            offset += 1
        marker = data[offset]
        offset += 1
        if marker in {0xD8, 0xD9, 0x01, *range(0xD0, 0xD8)}:
            continue
        length = int.from_bytes(data[offset:offset + 2], "big")
        if marker in {0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7, 0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF}:
            height = int.from_bytes(data[offset + 3:offset + 5], "big")
            width = int.from_bytes(data[offset + 5:offset + 7], "big")
            return width, height
        offset += length
    raise ValueError("No se pudieron leer las dimensiones de la imagen")


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
        width, height = image_size(background)
        if width < 1 or height < 1:
            raise ValueError("Dimensiones de fondo inválidas")
        target = destination / preset["theme"]
        if target.is_symlink() or any(p.is_symlink() for p in target.rglob("*")):
            raise ValueError("El destino del tema contiene enlaces simbólicos")
        plan.append({"name": name, "theme": preset["theme"], "size": [width, height],
                     "background": "assets/wallpaper" + background.suffix.lower(),
                     "panorama": "assets/panorama" + panorama.suffix.lower() if panorama.is_file() else ""})
    if not apply:
        return plan
    for item in plan:
        preset = presets[item["name"]]
        profile = catalog[item["name"]]
        target = destination / item["theme"]
        shutil.copytree(template, target, dirs_exist_ok=True, ignore=shutil.ignore_patterns("wallpaper.*"))
        background = source / "assets/wallpapers/cyber" / profile["wallpaper"]
        shutil.copyfile(background, target / item["background"])
        panorama = source / "assets/wallpapers/cyber" / profile.get("panorama", "")
        if panorama.is_file():
            shutil.copyfile(panorama, target / item["panorama"])
        font = source / "assets/fonts" / preset["font_file"]
        shutil.copytree(font.parent, target / "assets/fonts" / font.parent.name, dirs_exist_ok=True)
        config = configparser.ConfigParser(interpolation=None)
        config.optionxform = str
        config.read(target / "theme.conf")
        config["General"].update(title=preset["title"], subtitle=preset["subtitle"],
                                 background=item["background"],
                                 backgroundMode=profile.get("wallpaper_mode", "auto"),
                                 backgroundPanorama=item["panorama"],
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
