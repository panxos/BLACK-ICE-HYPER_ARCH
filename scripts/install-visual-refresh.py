#!/usr/bin/env python3
"""Instala Obsidiana con preferencias conservadas y reversión comprobable."""
from __future__ import annotations

import argparse
import base64
import configparser
import hashlib
import io
import json
import logging
import os
import re
import stat
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOG = logging.getLogger("visual-refresh")


def notification_config(value: dict) -> dict:
    config = json.loads(json.dumps(value))
    config.update({"text-empty": "No hay notificaciones", "control-center-width": 420,
                   "notification-window-width": 380, "notification-grouping": True,
                   "relative-timestamps": True, "keyboard-shortcuts": True,
                   "timeout": 8, "timeout-low": 3, "timeout-critical": 0})
    widgets = config.setdefault("widgets", ["inhibitors", "title", "dnd", "notifications"])
    if "buttons-grid" not in widgets:
        widgets.insert(widgets.index("notifications") if "notifications" in widgets else len(widgets), "buttons-grid")
    settings = config.setdefault("widget-config", {})
    settings.setdefault("title", {}).update({"text": "Notificaciones", "button-text": "Limpiar"})
    settings.setdefault("dnd", {}).update({"text": "No molestar"})
    settings.setdefault("inhibitors", {}).update({"text": "Aplicaciones en silencio", "button-text": "Restablecer"})
    grid = settings.setdefault("buttons-grid", {})
    grid["buttons-per-row"] = 3
    actions = grid.setdefault("actions", [])
    actions[:] = [a for a in actions if a.get("label") != "\ufaa8"]
    for label, command in [("Apariencia", "~/.local/bin/black-ice-control appearance"),
                           ("Conexiones", "~/.local/bin/black-ice-control network"),
                           ("Software", "~/.local/bin/black-ice-system software")]:
        if not any(a.get("label") == label for a in actions):
            actions.append({"label": label, "type": "normal", "command": command})
        else:
            for action in actions:
                if action.get("label") == label and action.get("type") == "button":
                    action["type"] = "normal"
    for key in ("scripts", "notification-visibility"):
        entries = config.get(key, {})
        for name in list(entries):
            if entries[name].get("app-name") == "example.app.id":
                entries.pop(name)
        if not entries:
            config.pop(key, None)
    return config
SYSTEM_WRITER = """
import os, pathlib, sys, tempfile
p = pathlib.Path(sys.argv[1]); action = sys.argv[2]
if action == 'remove':
    p.unlink(missing_ok=True)
else:
    p.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix='.black-ice-', dir=p.parent)
    try:
        if action == 'link':
            os.close(fd); os.unlink(tmp); os.symlink(sys.argv[3], tmp)
        else:
            with os.fdopen(fd, 'wb') as f:
                f.write(sys.stdin.buffer.read()); os.fchmod(f.fileno(), int(sys.argv[3]))
        os.replace(tmp, p)
    finally:
        if os.path.lexists(tmp): os.unlink(tmp)
"""


def ini_update(text: str, changes: dict) -> str:
    parser = configparser.ConfigParser(interpolation=None, strict=False)
    parser.optionxform = str
    parser.read_string(text)
    for section, options in changes.items():
        if not parser.has_section(section):
            parser.add_section(section)
        for key, value in options.items():
            parser.set(section, key, str(value))
    result = io.StringIO()
    parser.write(result)
    return result.getvalue()


def sddm_backgrounds(source: Path, name: str = "Anubis-Sethek") -> dict[str, bytes]:
    profile = json.loads((source / "dotfiles/waybar/cyber-catalog.json").read_text())[name]
    root = (source / "assets/wallpapers/cyber").resolve()
    wall = (root / profile["wallpaper"]).resolve(strict=True)
    if not wall.is_relative_to(root):
        raise ValueError("Fondo fuera del catálogo")
    files = {"assets/wallpaper.png": wall.read_bytes()}
    options = {"background": "assets/wallpaper.png", "backgroundMode": profile.get("wallpaper_mode", "auto"),
               "backgroundPanorama": "", "backgroundAnchor": profile.get("panorama_anchor", "center")}
    panorama = (root / profile.get("panorama", "")).resolve()
    if panorama.is_file() and panorama.is_relative_to(root):
        files["assets/panorama.png"] = panorama.read_bytes()
        options["backgroundPanorama"] = "assets/panorama.png"
    template = source / "assets/sddm/themes/black-ice-obsidian/theme.conf"
    files["theme.conf"] = ini_update(template.read_text(), {"General": options}).encode()
    return files


def fingerprint(path: Path) -> str:
    if path.is_symlink():
        return "link:" + os.readlink(path)
    if path.is_file():
        return "sha256:" + hashlib.sha256(path.read_bytes()).hexdigest()
    return "absent"


def without_appearance_shortcuts(content: str) -> str:
    pattern = r'^\s*bind\s*=\s*(?:\$mainMod|SUPER)\s+ALT\s*,\s*(?:T\s*,\s*exec\s*,\s*~/.config/bin/theme_visual|W\s*,\s*exec\s*,\s*waypaper --folder ~/Pictures/wallpapers --backend awww)[ \t]*\n'
    return re.sub(pattern, '', content, flags=re.MULTILINE)


def with_kitty_theme(content: str) -> str:
    content = re.sub(r'^[ \t]*include[ \t]+obsidian\.conf[ \t]*(?:#.*)?$', '', content, flags=re.MULTILINE)
    return content.rstrip() + "\n\ninclude obsidian.conf\n"


class Installer:
    def __init__(self, source: Path = ROOT, home: Path | None = None, system: Path = Path("/")) -> None:
        self.source = source
        self.home = home or Path.home()
        self.config = self.home / ".config"
        self.data = self.home / ".local/share/black-ice/obsidian"
        self.state = self.home / ".local/state/black-ice/visual-refresh"
        self.system = system
        self.manifest = self.state / "restore.json"
        self.operations = {}

    def text(self, path: Path) -> str:
        try:
            return path.read_text()
        except FileNotFoundError:
            return ""

    def put(self, path: Path, data: bytes | str, mode: int = 0o644) -> None:
        self.operations[path] = {"data": data.encode() if isinstance(data, str) else data, "mode": mode}

    def link(self, path: Path, target: Path) -> None:
        self.operations[path] = {"link": str(target)}

    def build(self) -> dict:
        self.operations = {}
        source = self.source
        resources = source / "assets/visual/obsidian"
        fonts = source / "assets/fonts"
        for path in fonts.rglob("*"):
            if path.is_file():
                self.put(self.home / ".local/share/fonts/black-ice" / path.relative_to(fonts), path.read_bytes())
        for path in resources.iterdir():
            if path.is_file():
                self.put(self.data / path.name, path.read_bytes())
        theme = source / "assets/sddm/themes/black-ice-obsidian"
        for path in theme.rglob("*"):
            if path.is_file():
                self.put(self.system / "usr/share/sddm/themes/black-ice-obsidian" / path.relative_to(theme), path.read_bytes())
        for relative, content in sddm_backgrounds(source).items():
            self.put(self.system / "usr/share/sddm/themes/black-ice-obsidian" / relative, content)
        wallpaper = theme / "assets/wallpaper.png"
        self.put(self.data / "wallpaper.png", wallpaper.read_bytes())
        pictures = self.home / "Pictures"
        dirs = self.text(self.config / "user-dirs.dirs")
        import re
        match = re.search(r'^XDG_PICTURES_DIR="([^"]+)"', dirs, re.MULTILINE)
        if match:
            candidate = Path(match.group(1).replace("$HOME", str(self.home)))
            if candidate.is_absolute() and candidate.is_relative_to(self.home):
                pictures = candidate
        catalog = json.loads((source / "dotfiles/waybar/cyber-catalog.json").read_text())
        wall_name = catalog["Anubis-Sethek"]["wallpaper"]
        wall = pictures / "wallpapers" / wall_name
        self.put(wall, (source / "assets/wallpapers/cyber" / wall_name).read_bytes())
        self.put(pictures / "wallpapers/black-ice-obsidian.png", wallpaper.read_bytes())
        for font in (theme / "assets").glob("*.ttf"):
            self.put(self.home / ".local/share/fonts/black-ice" / font.name, font.read_bytes())
        self.put(self.home / ".local/share/fonts/black-ice/OFL.txt", (theme / "assets/OFL-Rajdhani.txt").read_bytes())
        self.put(self.home / ".local/bin/black_ice_i18n.py", (source / "dotfiles/bin/black_ice_i18n.py").read_bytes(), 0o755)
        self.put(self.home / ".local/bin/black-ice-language", (source / "dotfiles/bin/black-ice-language").read_bytes(), 0o755)
        self.put(self.home / ".local/share/black-ice/i18n/en.json", (source / "config/i18n/en.json").read_bytes())
        for name in ["black-ice-appearance", "black-ice-control", "black-ice-lock-status", "black-ice-conky", "black_ice_conky_binary.py", "black-ice-lock", "black_ice_lock.py", "conky_visual", "waybar_start.sh"]:
            self.put(self.home / ".local/bin" / name, (source / "dotfiles/bin" / name).read_bytes(), 0o755)
        for name in ["theme_selector", "power_menu.sh", "settings_menu"]:
            self.put(self.config / "bin" / name, (source / "dotfiles/bin" / name).read_bytes(), 0o755)
        for path in (source / "dotfiles/conky/black-ice").glob("*"):
            if path.is_file():
                self.put(self.config / "conky/black-ice" / path.name, path.read_bytes())
        for name in ("Obsidian-Angular", "Anubis-Sethek"):
            folder = source / "dotfiles/waybar/themes" / name
            for path in folder.rglob("*"):
                if path.is_file():
                    self.put(self.config / "waybar/themes" / name / path.relative_to(folder), path.read_bytes())
        colors = json.loads((source / "dotfiles/waybar/themes/Anubis-Sethek/palette.json").read_text())
        for template, dest in [("hyprlock.conf.in", "hypr/hyprlock.conf"), ("wofi.css.in", "wofi/style.css"),
                               ("swaync.css.in", "swaync/style.css"), ("kitty.conf.in", "kitty/obsidian.conf"),
                               ("gtk.css.in", "black-ice/palette.css"), ("qt-colors.conf.in", "qt5ct/colors/Black-Ice.conf"),
                               ("qt-colors.conf.in", "qt6ct/colors/Black-Ice.conf"),
                               ("lock-frame.svg.in", "black-ice/lock-frame.svg")]:
            content = (resources / template).read_text().replace("@WALLPAPER@", str(wall)).replace("@LOCK_FRAME@", str(self.config / "black-ice/lock-frame.png"))
            for key, value in colors.items():
                content = content.replace("@" + key.upper() + "@", value[1:] if template == "hyprlock.conf.in" else value)
            self.put(self.config / dest, content)
        self.put(self.config / "black-ice/lock-frame.png", (resources / "lock-frame.png").read_bytes())
        kitty = self.config / "kitty/kitty.conf"
        content = with_kitty_theme(self.text(kitty))
        self.put(kitty, content)
        self.put(self.config / "hypr/obsidian.conf", (source / "dotfiles/hypr/obsidian.conf").read_bytes())
        self.put(self.config / "hypr/obsidian-colors.conf", "general {\n    col.active_border = rgba(27c6edee) rgba(ae90e8ee) 45deg\n}\n")
        hypr = self.config / "hypr/hyprland.conf"
        content = without_appearance_shortcuts(self.text(hypr))
        include = "source = ~/.config/hypr/obsidian.conf"
        if include not in content:
            content += "\n" + include + "\n"
        self.put(hypr, content)
        for version in ("3.0", "4.0"):
            gtk = self.config / ("gtk-" + version)
            content = self.text(gtk / "gtk.css")
            imported = '@import url("../black-ice/palette.css");'
            if imported not in content:
                content = imported + "\n" + content
            self.put(gtk / "gtk.css", content)
            self.put(gtk / "settings.ini", ini_update(self.text(gtk / "settings.ini"), {"Settings":{
                "gtk-font-name":"Noto Sans 10", "gtk-application-prefer-dark-theme":"1"}}))
        for version in ("5", "6"):
            qt = self.config / ("qt" + version + "ct")
            self.put(qt / ("qt" + version + "ct.conf"), ini_update(self.text(qt / ("qt" + version + "ct.conf")), {"Appearance":{
                "color_scheme_path":str(qt / "colors/Black-Ice.conf"), "custom_palette":"true", "style":"Fusion"},
                "Fonts":{"general":"\"Noto Sans,10,-1,5,50,0,0,0,0,0,Regular\""}}))
        waypaper = self.config / "waypaper/config.ini"
        content = self.text(waypaper)
        parser = configparser.ConfigParser(interpolation=None)
        parser.read_string(content or "[Settings]\n")
        old_post = parser.get("Settings", "post_command", fallback="").strip()
        hook = str(self.home / ".local/bin/black-ice-appearance") + " sync"
        post = old_post if hook in old_post else (old_post + "; " + hook if old_post else hook)
        self.put(waypaper, ini_update(content, {"Settings":{"wallpaper": str(wall), "post_command": post}}))
        self.put(self.home / ".cache/current_wallpaper", str(wall) + "\n")
        for path in [self.home / ".cache/current_theme", self.config / "waybar/default_theme"]:
            self.put(path, "Anubis-Sethek\n")
        for path in ["config", "config.jsonc", "style.css"]:
            self.link(self.config / "waybar" / path, self.config / "waybar/themes/Anubis-Sethek" / ("style.css" if path == "style.css" else "config.jsonc"))
        assets = self.config / "waybar/assets"
        if not assets.exists() or assets.is_symlink():
            self.link(assets, self.config / "waybar/themes/Anubis-Sethek/assets")
        sway = self.config / "swaync/config.json"
        config = json.loads(self.text(sway) or "{}")
        config = notification_config(config)
        self.put(sway, json.dumps(config, indent=2) + "\n")
        current = self.system / "etc/sddm.conf.d/theme.conf"
        self.put(current, ini_update(self.text(current), {"Theme":{"Current":"black-ice-obsidian"}}))
        main = self.system / "etc/sddm.conf"
        if main.exists():
            self.put(main, ini_update(self.text(main), {"Theme":{"Current":"black-ice-obsidian"}}))
        self.put(self.home / ".local/share/applications/black-ice-control.desktop", "[Desktop Entry]\nType=Application\nName=BLACK-ICE Control\nComment=Sistema y apariencia\nExec=" + str(self.home / ".local/bin/black-ice-control") + "\nIcon=preferences-system\nCategories=Settings;System;\nTerminal=false\n")
        self.put(self.home / ".local/state/black-ice/appearance.json", json.dumps({"theme":"Anubis-Sethek", "wallpaper":str(wall), "palette":colors}, indent=2) + "\n")
        return self.operations

    def privileged(self, path: Path) -> bool:
        return self.system == Path("/") and not path.is_relative_to(self.home)

    def write(self, path: Path, operation: dict) -> None:
        if self.privileged(path):
            action = "link" if "link" in operation else "remove" if operation.get("remove") else "file"
            value = operation.get("link", str(operation.get("mode", 0o644)))
            subprocess.run(["sudo", "-n", "python", "-c", SYSTEM_WRITER, str(path), action, value],
                           input=operation.get("data", b""), check=True, timeout=20)
            return
        if operation.get("remove"):
            path.unlink(missing_ok=True)
            return
        path.parent.mkdir(parents=True, exist_ok=True)
        fd, temporary = tempfile.mkstemp(prefix=".black-ice-", dir=path.parent)
        try:
            if "link" in operation:
                os.close(fd)
                os.unlink(temporary)
                os.symlink(operation["link"], temporary)
            else:
                with os.fdopen(fd, "wb") as handle:
                    handle.write(operation["data"])
                    os.fchmod(handle.fileno(), operation["mode"])
            os.replace(temporary, path)
        finally:
            if os.path.lexists(temporary):
                os.unlink(temporary)

    def save(self, value: dict) -> None:
        self.state.mkdir(parents=True, exist_ok=True, mode=0o700)
        self.write(self.manifest, {"data":(json.dumps(value, indent=2) + "\n").encode(), "mode":0o600})

    def apply(self, activate: bool = True) -> dict:
        operations = self.build()
        manifest = json.loads(self.manifest.read_text()) if self.manifest.exists() else {"entries":{}, "status":"new"}
        if manifest.get("status") == "rolled-back":
            manifest = {"entries":{}, "status":"new"}
        for path in operations:
            key = str(path)
            if key not in manifest["entries"]:
                before = {"kind":"absent"}
                if path.is_symlink():
                    before = {"kind":"link", "target":os.readlink(path)}
                elif path.is_file():
                    before = {"kind":"file", "data":base64.b64encode(path.read_bytes()).decode(), "mode":stat.S_IMODE(path.stat().st_mode)}
                manifest["entries"][key] = {"before":before}
        manifest["status"] = "applying"
        self.save(manifest)
        try:
            for path, operation in operations.items():
                self.write(path, operation)
                manifest["entries"][str(path)]["after"] = fingerprint(path)
            self.save(manifest)
            if activate:
                subprocess.run(["fc-cache", "-f", str(self.home / ".local/share/fonts/black-ice")], check=True, timeout=20)
                subprocess.run([str(self.home / ".local/bin/black-ice-appearance"), "apply", "Anubis-Sethek"], check=True, timeout=25)
                monitor_active = subprocess.run(["systemctl", "--user", "is-active", "--quiet", "black-ice-conky.service"], check=False)
                if monitor_active.returncode == 0:
                    subprocess.run(["systemctl", "--user", "restart", "black-ice-conky.service"], check=True, timeout=15)
                subprocess.run(["hyprctl", "reload"], check=True, timeout=10, stdout=subprocess.DEVNULL)
                subprocess.run(["swaync-client", "-R"], timeout=10, stdout=subprocess.DEVNULL, check=False)
            for key in manifest["entries"]:
                manifest["entries"][key]["after"] = fingerprint(Path(key))
            manifest["status"] = "applied"
            self.save(manifest)
        except (OSError, subprocess.SubprocessError):
            for key, entry in manifest["entries"].items():
                if "after" not in entry:
                    entry["after"] = fingerprint(Path(key))
            self.save(manifest)
            conflicts = self.rollback()
            if activate and not conflicts:
                self.reactivate_original()
            raise
        return manifest

    def rollback(self) -> list[str]:
        if not self.manifest.exists():
            raise ValueError("No existe un manifiesto de reversión")
        manifest = json.loads(self.manifest.read_text())
        allowed = set(self.build())
        conflicts = []
        for key, entry in reversed(list(manifest["entries"].items())):
            path = Path(key)
            if path not in allowed or fingerprint(path) != entry.get("after"):
                conflicts.append(key)
                continue
            before = entry["before"]
            if before["kind"] == "link":
                operation = {"link":before["target"]}
            elif before["kind"] == "file":
                operation = {"data":base64.b64decode(before["data"]), "mode":before["mode"]}
            else:
                operation = {"remove":True}
            self.write(path, operation)
        manifest["status"] = "rollback-conflicts" if conflicts else "rolled-back"
        self.save(manifest)
        return conflicts

    def reactivate_original(self) -> None:
        if self.home != Path.home() or self.system != Path("/"):
            return
        helper = self.home / ".local/bin/waybar_start.sh"
        if helper.exists():
            subprocess.run([str(helper)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=15, check=False)
        wall = self.text(self.home / ".cache/current_wallpaper").strip()
        if wall and Path(wall).is_file():
            subprocess.run(["awww", "img", wall, "--transition-type", "none"], timeout=15, check=False)
        subprocess.run(["hyprctl", "reload"], timeout=10, check=False, stdout=subprocess.DEVNULL)
        subprocess.run(["swaync-client", "-R"], timeout=10, check=False, stdout=subprocess.DEVNULL)
        subprocess.run(["swaync-client", "-rs"], timeout=10, check=False, stdout=subprocess.DEVNULL)


def main() -> int:
    parser = argparse.ArgumentParser(description="Despliega Obsidiana sin reiniciar SDDM")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--apply", action="store_true")
    group.add_argument("--rollback", action="store_true")
    group.add_argument("--dry-run", action="store_true")
    group.add_argument("--status", action="store_true")
    parser.add_argument("--no-activate", action="store_true", help="Instala archivos sin activar el escritorio")
    args = parser.parse_args()
    installer = Installer()
    try:
        if args.dry_run:
            paths = installer.build()
            print(json.dumps({"files":len(paths), "system_files":sum(installer.privileged(p) for p in paths),
                              "theme":"Anubis-Sethek", "restarts_display_manager":False}, indent=2))
        elif args.status:
            manifest = json.loads(installer.manifest.read_text()) if installer.manifest.exists() else {}
            print(json.dumps({"status":manifest.get("status", "not-installed"), "files":len(manifest.get("entries", {})), "restore":str(installer.manifest)}))
        elif args.apply:
            result = installer.apply(activate=not args.no_activate)
            print(json.dumps({"status":result["status"], "files":len(result["entries"]), "restore":str(installer.manifest)}))
        else:
            conflicts = installer.rollback()
            if not conflicts:
                installer.reactivate_original()
            print(json.dumps({"conflicts":conflicts, "status":"rollback-conflicts" if conflicts else "rolled-back"}))
            if conflicts:
                return 1
    except (OSError, ValueError, configparser.Error, subprocess.SubprocessError) as error:
        LOG.error("No se aplicó la renovación visual: %s", error)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
