#!/usr/bin/env python3
"""Actualiza el catálogo Waybar y conserva reversión de archivos personales."""
from __future__ import annotations

import argparse
import importlib.util
import json
import os
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("visual_installer", ROOT / "scripts/install-visual-refresh.py")
base = importlib.util.module_from_spec(spec)
spec.loader.exec_module(base)


def migrate_motion(content: str, provider: str) -> str:
    if provider == "lua":
        content = re.sub(r'(leaf = "borderangle",\s*enabled = )true(,\s*speed = 8,\s*bezier = "linear",\s*style = "loop",)', r'\1false\2', content)
        return re.sub(r'(leaf = "workspaces",\s*enabled = true,\s*speed = )6(,\s*bezier = "default",)', r'\g<1>2\2', content)
    content = re.sub(r'(?m)^(\s*)animation\s*=\s*borderangle,\s*1,\s*8,\s*linear,\s*loop\s*$', r'\1animation = borderangle, 0', content)
    return re.sub(r'(?m)^(\s*animation\s*=\s*workspaces,\s*1,\s*)6(,\s*default\s*)$', r'\g<1>2\2', content)


def migrate_removable_config(content: str) -> str:
    block = re.search(r"(?m)^notifications:[^\n]*\n(?:[ \t]+[^\n]*\n|\n)*", content + ("\n" if not content.endswith("\n") else ""))
    if block is None:
        return content
    value = block.group()
    old = {"device_mounted": 8000, "device_unmounted": 4000, "device_removed": 4000}
    generated = all(re.search(rf"(?m)^  {key}: {number}\s*$", value) for key, number in old.items())
    if not generated:
        return content
    for key, number in {**old, "job_failed": 0}.items():
        replacement = -1 if key == "job_failed" else number // 1000
        value = re.sub(rf"(?m)^(  {key}: ){number}([ \t]*(?:#[^\n]*)?)$", rf"\g<1>{replacement}\2", value)
    return content[:block.start()] + value.rstrip("\n") + ("\n" if content[block.start():block.end()].endswith("\n") else "") + content[block.end():]


class Installer(base.Installer):
    def __init__(self, source: Path = ROOT, home: Path | None = None):
        super().__init__(source=source, home=home)
        self.state = self.home / ".local/state/black-ice/theme-catalog"
        self.manifest = self.state / "restore.json"

    def aliases(self) -> dict:
        return json.loads((self.source / "dotfiles/waybar/theme-aliases.json").read_text())

    def selected(self) -> str:
        name = self.text(self.config / "waybar/default_theme").strip()
        name = self.aliases().get(name, name)
        personal = self.config / "waybar/themes" / name
        if re.fullmatch(r"User-[A-Za-z0-9_.-]+", name) and all((personal / file).is_file() for file in ("profile.json", "config.jsonc", "style.css")):
            return name
        return name if re.fullmatch(r"[A-Za-z0-9_.-]+",name) and (self.source / "dotfiles/waybar/themes" / name / "config.jsonc").is_file() else "Anubis-Sethek"

    def preserve(self, path: Path) -> None:
        if path.is_symlink():
            self.link(path, Path(os.readlink(path)))
        elif path.is_file():
            self.put(path, path.read_bytes(), path.stat().st_mode & 0o777)
        else:
            self.operations[path] = {"remove":True}

    def build(self) -> dict:
        self.operations = {}
        fonts = self.source / "assets/fonts"
        for path in fonts.rglob("*"):
            if path.is_file():
                self.put(self.home / ".local/share/fonts/black-ice" / path.relative_to(fonts), path.read_bytes())
        theme_root = self.source / "dotfiles/waybar/themes"
        aliases = self.aliases()
        for folder in theme_root.iterdir():
            if folder.name in aliases or not folder.is_dir():
                continue
            for path in folder.rglob("*"):
                if path.is_file():
                    self.put(self.config / "waybar/themes" / path.relative_to(theme_root),path.read_bytes())
        retired = set(json.loads((self.source / "dotfiles/waybar/retired-files.json").read_text()))
        linked = set()
        for name in aliases:
            folder = self.config / "waybar/themes" / name
            if folder.is_symlink():
                self.operations[folder] = {"remove":True}
                linked.add(name)
                continue
            retired.update(str(p.relative_to(self.config / "waybar/themes")) for p in folder.rglob("*") if p.is_file() or p.is_symlink())
        if self.manifest.exists():
            for key in json.loads(self.manifest.read_text())["entries"]:
                path = Path(key)
                if path.is_relative_to(self.config / "waybar/themes"):
                    relative = path.relative_to(self.config / "waybar/themes")
                    if relative.parts and relative.parts[0] in aliases:
                        retired.add(str(relative))
        for relative in retired:
            path = Path(relative)
            if path.is_absolute() or ".." in path.parts or path.parts[0] not in aliases:
                raise ValueError("Ruta retirada inválida")
            if path.parts[0] in linked:
                continue
            self.operations[self.config / "waybar/themes" / path] = {"remove":True}
        self.put(self.config / "waybar/theme-aliases.json",json.dumps(aliases,indent=2)+"\n")
        self.put(self.config / "waybar/layout-map.json",(self.source / "dotfiles/waybar/layout-map.json").read_bytes())
        software = self.home / ".local/share/black-ice/software"
        for relative in ("scripts/select-apps.py", "config/apps.json", "VERSION"):
            self.put(software / relative, (self.source / relative).read_bytes())
        self.put(self.home / ".local/bin/black-ice-apps", (self.source / "dotfiles/bin/black-ice-apps").read_bytes(), 0o755)
        self.put(self.home / ".local/bin/black_ice_i18n.py", (self.source / "dotfiles/bin/black_ice_i18n.py").read_bytes(), 0o755)
        self.put(self.home / ".local/bin/black-ice-language", (self.source / "dotfiles/bin/black-ice-language").read_bytes(), 0o755)
        self.put(self.home / ".local/share/black-ice/i18n/en.json", (self.source / "config/i18n/en.json").read_bytes())
        self.put(self.home / ".local/bin/black-ice-doctor", (self.source / "dotfiles/bin/black-ice-doctor").read_bytes(), 0o755)
        self.put(self.home / ".local/bin/black-ice-system", (self.source / "dotfiles/bin/black-ice-system").read_bytes(), 0o755)
        self.put(self.home / ".local/share/black-ice/system/manager.py", (self.source / "src/system/manager.py").read_bytes())
        self.put(self.home / ".local/share/applications/black-ice-apps.desktop", "[Desktop Entry]\nType=Application\nName=BLACK-ICE Aplicaciones\nComment=Instalar, consultar y reintentar aplicaciones\nExec=" + str(self.home / ".local/bin/black-ice-apps") + "\nIcon=system-software-install\nCategories=Settings;System;\nTerminal=false\n")
        for name in ["black-ice-waybar","black-ice-waybar-binary","black-ice-appearance","black-ice-control","black-ice-conky","black_ice_conky_binary.py","black-ice-lock","black_ice_lock.py","conky_visual","cheatsheet","waybar_start.sh", "black-ice-theme-studio", "black-ice-wallpaper", "black_ice_theme.py", "black_ice_layout.py", "black_ice_outputs.py", "black-ice-launcher", "black-ice-wallpapers", "black-ice-hypr", "black-ice-workspaces", "black_ice_workspaces.py", "black_ice_shortcuts.py", "app_switcher", "wifi_toggle", "terminal_manager", "music_player", "music_widget", "pass_menu", "wofi_style_selector"]:
            self.put(self.home / ".local/bin" / name,(self.source / "dotfiles/bin" / name).read_bytes(),0o755)
        for name in ("cheatsheet", "app_switcher", "wifi_toggle", "terminal_manager", "music_player", "music_widget", "pass_menu", "wofi_style_selector"):
            path = self.config / "bin" / name
            if not path.exists() or (path.is_symlink() and path.resolve() == self.home / ".local/bin" / name):
                self.link(path, self.home / ".local/bin" / name)
            else:
                self.preserve(path)
        for name in ("black-ice-conky.service", "black-ice-removable.service", "black-ice-workspaces.service", "hyprland-session.target"):
            self.put(self.config / "systemd/user" / name, (self.source / "dotfiles/systemd/user" / name).read_bytes())
        self.link(self.config / "systemd/user/hyprland-session.target.wants/black-ice-conky.service", Path("../black-ice-conky.service"))
        self.link(self.config / "systemd/user/hyprland-session.target.wants/black-ice-removable.service", Path("../black-ice-removable.service"))
        self.link(self.config / "systemd/user/hyprland-session.target.wants/black-ice-workspaces.service", Path("../black-ice-workspaces.service"))
        for provider in ("conf", "lua"):
            generated = self.config / f"hypr/black-ice-workspaces.{provider}"
            if not generated.exists():
                self.put(generated, ("--" if provider == "lua" else "#") + " BLACK-ICE — generado al iniciar la sesión\n")
            else:
                self.preserve(generated)
        self.put(self.config / "bin/udiskie-fix", (self.source / "dotfiles/bin/udiskie-fix").read_bytes(), 0o755)
        startup = self.config / "hypr/scripts/startup.sh"
        if startup.is_file():
            content = self.text(startup)
            content = content.replace('pkill -f udiskie 2>/dev/null\n', '')
            content = content.replace('"$HOME/.config/bin/udiskie-fix" &', 'systemctl --user start black-ice-removable.service')
            self.put(startup, content, startup.stat().st_mode & 0o777)
        udiskie = self.config / "udiskie/config.yml"
        if not udiskie.exists():
            self.put(udiskie, (self.source / "dotfiles/udiskie/config.yml").read_bytes())
        elif udiskie.is_symlink():
            self.preserve(udiskie)
        else:
            self.put(udiskie, migrate_removable_config(self.text(udiskie)), udiskie.stat().st_mode & 0o777)
        notifications = self.config / "swaync/config.json"
        config = json.loads(self.text(notifications) or "{}")
        self.put(notifications, json.dumps(base.notification_config(config), ensure_ascii=False, indent=2) + "\n")
        self.put(self.home / ".local/share/applications/black-ice-theme-studio.desktop", "[Desktop Entry]\nType=Application\nName=BLACK-ICE Estudio de temas\nComment=Fuentes, barras, módulos, fondos, Conky y SDDM\nExec=" + str(self.home / ".local/bin/black-ice-theme-studio") + "\nIcon=preferences-desktop-theme\nCategories=Settings;DesktopSettings;\nTerminal=false\n")
        self.put(self.config / "bin/theme_switcher.sh",(self.source / "dotfiles/bin/theme_switcher.sh").read_bytes(),0o755)
        self.put(self.config / "black-ice/prompt.zsh", (self.source / "dotfiles/zsh/black-ice-prompt.zsh").read_bytes())
        shell = self.home / ".zshrc"
        hook = '[[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/black-ice/prompt.zsh" ]] && source "${XDG_CONFIG_HOME:-$HOME/.config}/black-ice/prompt.zsh"'
        content = self.text(shell)
        if hook not in content:
            content = content.rstrip() + "\n\n" + hook + "\n"
        self.put(shell, content)
        self.put(self.config / "bin/theme_visual",(self.source / "dotfiles/bin/theme_visual").read_bytes(),0o755)
        self.put(self.home / ".local/bin/theme_visual", (self.source / "dotfiles/bin/theme_visual").read_bytes(), 0o755)
        self.put(self.data / "kitty.conf.in",(self.source / "assets/visual/obsidian/kitty.conf.in").read_bytes())
        for template in ("gtk.css.in", "wofi.css.in", "swaync.css.in"):
            self.put(self.data / template, (self.source / "assets/visual/obsidian" / template).read_bytes())
        for version in ("gtk-3.0", "gtk-4.0"):
            gtk = self.config / version / "gtk.css"
            content = self.text(gtk)
            content = re.sub(r'/\* USER OVERRIDE[^*]*\*/\s*flowbox flowboxchild:selected,\s*flowboxchild:selected,\s*row:selected\s*\{\s*background-color:\s*rgba\(130,\s*0,\s*220,\s*0\.8\);\s*outline-color:\s*transparent;\s*\}', '', content)
            import_line = '@import url("../black-ice/palette.css");'
            if import_line not in content:
                content = import_line + "\n" + content
            self.put(gtk, content.rstrip() + "\n")
        kitty = self.config / "kitty/kitty.conf"
        self.put(kitty,base.with_kitty_theme(self.text(kitty)))
        self.put(self.config / "hypr/obsidian.conf",(self.source / "dotfiles/hypr/obsidian.conf").read_bytes())
        hypr = self.config / "hypr/hyprland.conf"
        content = self.text(hypr)
        migrated = base.without_appearance_shortcuts(content)
        migrated = re.sub(r'(?m)^\$menu\s*=\s*env GTK_THEME=Adwaita:dark wofi --show drun --allow-images\s*$', '$menu = ~/.local/bin/black-ice-launcher', migrated)
        agent = "/usr/lib/polkit-kde-authentication-agent-1"
        safe_agent = "env QT_STYLE_OVERRIDE=Fusion QT_QUICK_CONTROLS_STYLE=Fusion " + agent
        preview = 'bash -c \'sleep 8 && [ ! -f ~/.config/waybar/themes/Horus-Cyber/preview.png ] && ~/.config/bin/gen_theme_previews\''
        migrated = "\n".join(line for line in migrated.split("\n") if line.strip() != "exec-once = " + preview)
        migrated = re.sub(r"(?m)^(\s*exec-once\s*=\s*)" + re.escape(agent) + r"(\s*(?:#.*)?)$", lambda match: match[1] + safe_agent + match[2], migrated)
        if migrated != content:
            self.put(hypr,migrate_motion(migrated, "hyprlang"),hypr.stat().st_mode & 0o777)
        elif hypr.is_file():
            self.put(hypr,migrate_motion(self.text(hypr), "hyprlang"),hypr.stat().st_mode & 0o777)
        idle = self.config / "hypr/hypridle.conf"
        if idle.is_file():
            original_idle = self.text(idle)
            migrated_idle = original_idle.replace("hyprctl dispatch dpms on", "~/.local/bin/black-ice-hypr dpms on")
            migrated_idle = migrated_idle.replace("pidof hyprlock || hyprlock", "pidof hyprlock || ~/.local/bin/black-ice-lock")
            self.put(idle, migrated_idle, idle.stat().st_mode & 0o777)
        lua = self.config / "hypr/hyprland.lua"
        if lua.is_file():
            original = self.text(lua)
            migrated_lua = original.replace('hl.exec_cmd("' + agent + '")', 'hl.exec_cmd("' + safe_agent + '")')
            migrated_lua = migrated_lua.replace('local menu = "env GTK_THEME=Adwaita:dark wofi --show drun --allow-images"', 'local menu = "~/.local/bin/black-ice-launcher"')
            migrated_lua = "\n".join(line for line in migrated_lua.split("\n") if line.strip() != 'hl.exec_cmd("' + preview + '")')
            migrated_lua = migrate_motion(migrated_lua, "lua")
            if migrated_lua != original:
                self.put(lua,migrated_lua,lua.stat().st_mode & 0o777)
            else:
                self.preserve(lua)
        for provider in ("conf", "lua"):
            main = self.config / f"hypr/hyprland.{provider}"
            if main.is_file():
                content = (migrate_motion(migrated, "hyprlang") if provider == "conf" else migrated_lua)
                if "black-ice-workspaces." not in content:
                    generated = self.config / f"hypr/black-ice-workspaces.{provider}"
                    line = (f'dofile("{generated}")' if provider == "lua" else f"source = {generated}")
                    content = content.rstrip() + "\n\n" + line + "\n"
                shortcut = 'env GDK_BACKEND=wayland ~/.local/bin/cheatsheet'
                has_f1 = bool(re.search(r'(?m)^\s*bind\w*\s*=\s*,\s*F1\s*,', content)) if provider == "conf" else bool(re.search(r'hl\.bind\([\"\x27]F1[\"\x27]', content))
                if not has_f1:
                    content += (f'hl.bind("F1", hl.dsp.exec_cmd("{shortcut}"), {{description="Ver atajos de teclado"}})\n' if provider == "lua" else f"bind = , F1, exec, {shortcut}\n")
                self.put(main, content, main.stat().st_mode & 0o777)
        self.put(self.home / ".local/bin/black_ice_launcher.py", (self.source / "dotfiles/bin/black_ice_launcher.py").read_bytes(), 0o755)
        self.put(self.home / ".local/bin/theme_visual", (self.source / "dotfiles/bin/theme_visual").read_bytes(), 0o755)
        self.link(self.config / "bin/theme_visual", self.home / ".local/bin/theme_visual")
        for name in ["palettes.json","theme-defaults.json"]:
            self.put(self.config / "conky/black-ice" / name,(self.source / "dotfiles/conky/black-ice" / name).read_bytes())
        self.put(self.config / "conky/black-ice/draw.lua",(self.source / "dotfiles/conky/black-ice/draw.lua").read_bytes())
        for folder in [self.config / "conky/black-ice",self.config / "waybar"]:
            self.put(folder / "typography.json",(self.source / "dotfiles/waybar/typography.json").read_bytes())
        self.put(self.data / "theme-wallpapers.json",(self.source / "assets/visual/obsidian/theme-wallpapers.json").read_bytes())
        pictures = self.home / "Pictures"
        match = re.search(r'^XDG_PICTURES_DIR="([^"]+)"',self.text(self.config / "user-dirs.dirs"),re.MULTILINE)
        if match:
            candidate = Path(match.group(1).replace("$HOME",str(self.home)))
            if candidate.is_absolute() and candidate.is_relative_to(self.home):
                pictures = candidate
        for pattern in ("*.png", "*.jpg", "*.jpeg", "*.webp"):
            for path in (self.source / "assets/wallpapers/cyber").glob(pattern):
                self.put(pictures / "wallpapers" / path.name,path.read_bytes())
        wallpapers = json.loads((self.source / "assets/visual/obsidian/theme-wallpapers.json").read_text())
        for name in set(wallpapers.values()):
            path = self.source / "dotfiles/wallpapers" / name
            if path.is_file():
                self.put(pictures / "wallpapers" / path.name, path.read_bytes())
        self.put(pictures / "wallpapers/black-ice-obsidian.png",(self.source / "assets/sddm/themes/black-ice-obsidian/assets/wallpaper.png").read_bytes())
        prefs = self.home / ".local/state/black-ice/conky.json"
        try:
            value = json.loads(self.text(prefs))
        except ValueError:
            value = None
        if isinstance(value,dict) and isinstance(value.get("themes"),dict):
            for old,new in aliases.items():
                if old in value["themes"] and new not in value["themes"]:
                    value["themes"][new] = value["themes"][old]
            self.put(prefs,json.dumps(value,ensure_ascii=False,indent=2)+"\n")
        name = self.selected()
        self.put(self.config / "waybar/default_theme",name+"\n")
        self.put(self.home / ".cache/current_theme",name+"\n")
        folder = self.config / "waybar/themes" / name
        self.link(self.config / "waybar/config",folder / "config.jsonc")
        self.link(self.config / "waybar/config.jsonc",folder / "config.jsonc")
        self.link(self.config / "waybar/style.css",folder / "style.css")
        assets = self.config / "waybar/assets"
        if not assets.exists() or assets.is_symlink():
            self.link(assets,folder / "assets")
        for relative in ["hypr/hyprlock.conf","hypr/obsidian-colors.conf","wofi/style.css","swaync/style.css",
                         "kitty/obsidian.conf","black-ice/palette.css","black-ice/lock-frame.svg","black-ice/lock-frame.png",
                         "qt5ct/colors/Black-Ice.conf","qt6ct/colors/Black-Ice.conf","waypaper/config.ini"]:
            self.preserve(self.config / relative)
        self.preserve(self.home / ".cache/current_wallpaper")
        self.preserve(self.home / ".local/state/black-ice/appearance.json")
        return self.operations

    def activate(self) -> None:
        subprocess.run(["systemctl", "--user", "daemon-reload"],check=True,timeout=10)
        subprocess.run([str(self.home / ".local/bin/black-ice-workspaces"), "sync"],check=True,timeout=15)
        subprocess.run(["systemctl", "--user", "start", "black-ice-workspaces.service"],check=True,timeout=10)
        subprocess.run(["fc-cache", "-f", str(self.home / ".local/share/fonts/black-ice")],check=True,timeout=20)
        subprocess.run([str(self.home / ".local/bin/black-ice-appearance"),"apply",self.selected()],check=True,timeout=30)
        active = subprocess.run(["systemctl","--user","is-active","--quiet","black-ice-conky.service"],check=False)
        if active.returncode == 0:
            subprocess.run(["systemctl","--user","restart","black-ice-conky.service"],check=True,timeout=15)
        subprocess.run(["hyprctl","reload"],check=True,timeout=10,stdout=subprocess.DEVNULL)
        manifest = json.loads(self.manifest.read_text())
        for path,entry in manifest["entries"].items():
            entry["after"] = base.fingerprint(Path(path))
        self.save(manifest)


    def prune_retired(self) -> None:
        for name in self.aliases():
            folder = self.config / "waybar/themes" / name
            directories = [p for p in folder.rglob("*") if p.is_dir() and not p.is_symlink()]
            directories.sort(key=lambda p:len(p.parts),reverse=True)
            for path in [*directories,folder]:
                try:
                    path.rmdir()
                except OSError:
                    pass


def main() -> int:
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--apply",action="store_true")
    group.add_argument("--rollback",action="store_true")
    group.add_argument("--dry-run",action="store_true")
    group.add_argument("--status",action="store_true")
    parser.add_argument("--no-activate",action="store_true")
    args = parser.parse_args()
    installer = Installer()
    try:
        if args.dry_run:
            print(json.dumps({"files":len(installer.build()),"selected":installer.selected(),"retired":installer.aliases(),"system_writes":0},indent=2))
        elif args.status:
            value = json.loads(installer.manifest.read_text()) if installer.manifest.exists() else {}
            print(json.dumps({"status":value.get("status","not-installed"),"files":len(value.get("entries",{})),"restore":str(installer.manifest)}))
        elif args.rollback:
            conflicts = installer.rollback()
            if not conflicts and not args.no_activate:
                installer.reactivate_original()
            print(json.dumps({"conflicts":conflicts,"status":"rollback-conflicts" if conflicts else "rolled-back"}))
            return int(bool(conflicts))
        else:
            installer.apply(activate=False)
            if not args.no_activate:
                try:
                    installer.activate()
                except (OSError,subprocess.SubprocessError):
                    manifest = json.loads(installer.manifest.read_text())
                    for path,entry in manifest["entries"].items():
                        entry["after"] = base.fingerprint(Path(path))
                    installer.save(manifest)
                    if not installer.rollback():
                        installer.reactivate_original()
                    raise
            installer.prune_retired()
            print(json.dumps({"status":"applied","theme":installer.selected(),"restore":str(installer.manifest)}))
    except (OSError,ValueError,subprocess.SubprocessError) as error:
        print("No se completó el catálogo: " + str(error))
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
