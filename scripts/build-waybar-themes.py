#!/usr/bin/env python3
"""Genera perfiles con funciones comunes y geometría declarada por tema."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "dotfiles/waybar"
sys.path.insert(0, str(ROOT / "dotfiles/bin"))
from black_ice_layout import configuration
from black_ice_theme import (
    angular_css,
    angular_svg,
    popup_css,
    workspace,
    workspace_css,
)


def status_styles() -> str:
    return '''/* Laboratory status */
#custom-vpn { background-image:url("assets/hackthebox-disconnected.svg"); background-size:14px 14px; background-repeat:no-repeat; background-position:6px center; padding:0 8px 0 26px; }
#custom-vpn.connected { color:#9fef00; background-image:url("assets/hackthebox-connected.svg"); }
#custom-vpn.disconnected { color:#ff6b6b; }
#custom-control { font-family:"JetBrainsMono Nerd Font"; font-size:15px; padding:0 8px; }
'''


def typography_styles(profile: dict, symbols: bool = False) -> str:
    body, data = profile["font"], profile["data_font"]
    return f'''/* Theme typography */
* {{ font-family:"{body}", "JetBrainsMono Nerd Font", sans-serif; font-size:{profile['size']}px; font-weight:{profile['weight']}; }}
#workspaces button, #workspaces button label, #clock, #custom-player {{ font-family:"{body}", "JetBrainsMono Nerd Font", sans-serif; }}
#custom-local_ip, #custom-public_ip, #custom-vpn, #custom-settarget {{ font-family:"{data}", "JetBrainsMono Nerd Font", monospace; font-size:11px; font-weight:500; }}
#custom-launcher, #custom-control, #custom-power, #network, #bluetooth {{ font-family:"JetBrainsMono Nerd Font"; }}
''' + (f'#workspaces button label {{ font-family:"JetBrainsMono Nerd Font", "{body}"; }}\n' if symbols else '')


def panel(profile: dict) -> str:
    color, accent = profile["bg"], profile["acc1"]
    paths = {
        "angular":"M11 1H299V17L289 27H1V11Z",
        "steps":"M1 8H9V1H283V5H299V21H291V27H17V23H1Z",
        "slab":"M1 1H299V27H1Z",
        "terminal":"M1 1H299V27H1Z",
        "rail":"M1 2H299V26H1Z",
        "capsule":"M14 1H286A13 13 0 0 1 286 27H14A13 13 0 0 1 14 1Z"
    }
    return '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="28" viewBox="0 0 300 28" preserveAspectRatio="none"><path d="' + paths[profile["shape"]] + f'" fill="{color}" fill-opacity=".94" stroke="{accent}" stroke-opacity=".96" stroke-width="1.6"/></svg>\n'


def stylesheet(p: dict) -> str:
    header = "/* " + " ".join(f"{k}={p[k]}" for k in ("bg","acc1","acc2","fg","dim")) + " */\n"
    extra = ""
    if p["shape"] == "terminal":
        extra = f'#workspaces button.active {{ border-bottom: 2px solid {p["acc1"]}; }}\n'
    if p["shape"] == "rail":
        extra = f'window#waybar {{ background: {p["bg"]}; }}\n.modules-left, .modules-center, .modules-right {{ background-image:none; border:1px solid alpha({p["acc1"]},.95); }}\n'
    if p.get("frame") == "bevel" and p["shape"] != "angular":
        extra += f'''window#waybar {{
    background-image:linear-gradient(to bottom, #292c32, {p['bg']});
    border:0;
    box-shadow:none;
}}
.modules-left, .modules-center, .modules-right {{
    background-image:linear-gradient(to bottom, alpha({p['fg']},.045), alpha({p['bg']},.8));
    border:1px solid alpha({p['acc1']},.95);
    border-radius:4px;
    box-shadow:inset 0 1px 1px alpha({p['fg']},.14), 0 1px 2px alpha(#000000,.7);
}}
#workspaces button.active {{
    color:{p['fg']};
    background-image:linear-gradient(to bottom, alpha({p['acc1']},.36), alpha({p['acc1']},.12));
    box-shadow:inset 0 1px 1px alpha({p['fg']},.12);
}}
'''
    return header + f'''
* {{ border:none; border-radius:0; font-family:"{p['font']}", "JetBrainsMono Nerd Font", sans-serif; font-size:{14 if p['font']=='Rajdhani' else 12}px; min-height:0; }}
window#waybar {{ background:transparent; color:{p['fg']}; border:0; box-shadow:none; }}
.modules-left, .modules-center, .modules-right {{ background-image:url("assets/panel.svg"); background-size:100% 100%; background-repeat:no-repeat; padding:0 11px; margin:4px 6px; }}
#custom-launcher {{ color:{p['acc1']}; padding:0 9px; font-size:17px; }}
#workspaces button {{ color:{p['dim']}; padding:0 8px; background:transparent; }}
#workspaces button.active {{ color:{p['acc1']}; background:alpha({p['acc1']},.14); }}
#workspaces button.urgent {{ color:#ffbd88; }}
#workspaces button:hover, #custom-control:hover, #custom-settarget:hover {{ background:alpha({p['acc1']},.18); }}
#network, #bluetooth, #pulseaudio, #battery, #clock, #tray, #custom-control, #custom-power {{ padding:0 8px; color:{p['dim']}; }}
#clock, #custom-player {{ color:{p['fg']}; }}
#custom-control, #custom-power, #custom-local_ip {{ color:{p['acc1']}; }}
#custom-public_ip, #custom-settarget {{ color:{p['acc2']}; }}
#custom-vpn.connected {{ color:{p['acc1']}; }}
#custom-docker, #custom-kvm, #custom-updates, #custom-local_ip, #custom-public_ip, #custom-vpn, #custom-settarget, #custom-player {{ padding:0 8px; }}
#battery.charging {{ color:#9fd2b0; }}
#battery.warning, #custom-updates.updates {{ color:#e9c585; }}
#battery.critical {{ color:#ef8d9d; }}
#network.disconnected, #bluetooth.disabled, #pulseaudio.muted, #custom-vpn.disconnected, #custom-settarget.inactive, .unavailable {{ color:{p['dim']}; }}
tooltip {{ background:{p['bg']}; color:{p['fg']}; border:1px solid {p['acc1']}; }}
tooltip label {{ color:{p['fg']}; padding:8px; }}
''' + extra + popup_css(p)


def write_json(path: Path, value) -> None:
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(json.dumps(value,ensure_ascii=False,indent=2) + "\n")


def main() -> None:
    profiles = json.loads((BASE / "cyber-catalog.json").read_text())
    aliases = json.loads((BASE / "theme-aliases.json").read_text())
    layouts = json.loads((BASE / "layout-map.json").read_text())
    typography = json.loads((BASE / "typography.json").read_text())
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--theme", action="append", choices=list(profiles), help="Regenerar solo este diseño; se puede repetir")
    selected = set(parser.parse_args().theme or layouts)
    for path in (BASE / "themes").glob("*/config.jsonc"):
        if path.parent.name not in aliases and path.parent.name in selected:
            write_json(path,configuration(layouts[path.parent.name]))
    palettes_path = ROOT / "dotfiles/conky/black-ice/palettes.json"
    defaults_path = ROOT / "dotfiles/conky/black-ice/theme-defaults.json"
    walls_path = ROOT / "assets/visual/obsidian/theme-wallpapers.json"
    palettes, defaults, walls = [json.loads(p.read_text()) for p in (palettes_path,defaults_path,walls_path)]
    for name in aliases:
        palettes.pop(name,None)
        defaults.pop(name,None)
        walls.pop(name,None)
    for name, profile in profiles.items():
        if name not in selected:
            continue
        for image in (profile["wallpaper"], profile.get("panorama", "")):
            if not image:
                continue
            candidates = [ROOT / "assets/wallpapers/cyber" / image, ROOT / "dotfiles/wallpapers" / image]
            if image == "black-ice-obsidian.png":
                candidates.append(ROOT / "assets/sddm/themes/black-ice-obsidian/assets/wallpaper.png")
            if not any(p.is_file() for p in candidates):
                raise ValueError(f"Fondo ausente para {name}: {image}")
        folder = BASE / "themes" / name
        (folder / "assets").mkdir(parents=True,exist_ok=True)
        write_json(folder / "config.jsonc",configuration(layouts[name]))
        if name == "Horus-Skyline":
            bars = configuration("single-top")
            bars[0]["modules-left"].remove("group/lab")
            bars[0]["modules-right"].insert(0, "group/lab")
            bars[0]["lab-side"] = "right"
            write_json(folder / "config.jsonc", bars)
        bars = json.loads((folder / "config.jsonc").read_text())
        if name == "s4vitar-darkness":
            bars[0]["workspace-side"] = "center"
        for bar in bars:
            workspace(bar["hyprland/workspaces"], profile.get("workspace", "numbers"))
            if name in {"Mr-Robot", "Mr-Robot-Safehouse", "Fsociety"}:
                bar["custom/launcher"]["format"] = "\u200b"
                bar["custom/launcher"]["tooltip-format"] = "Fsociety · aplicaciones"
            if profile.get("launcher"):
                bar["custom/launcher"]["format"] = "\u200b"
                bar["custom/launcher"]["tooltip-format"] = profile.get("launcher_label", name) + " · aplicaciones"
        write_json(folder / "config.jsonc", bars)
        (folder / "style.css").write_text(stylesheet(profile))
        (folder / "assets/panel.svg").write_text(panel(profile))
        colors = {k:profile[k] for k in ("bg","acc1","acc2","fg","dim")}
        write_json(folder / "palette.json",colors)
        write_json(folder / "theme.json",{"wallpaper":profile["wallpaper"],"shape":profile["shape"],"font":typography[name]["font"],"layout":layouts[name], "workspace":profile.get("workspace", "numbers"), "panorama":profile.get("panorama", ""), **({"panorama_anchor":profile["panorama_anchor"]} if profile.get("panorama_anchor") else {}), **({"wallpaper_mode":profile["wallpaper_mode"]} if profile.get("wallpaper_mode") else {}), **({"sddm":profile["sddm"]} if profile.get("sddm") else {}), **({"launcher":profile["launcher"]} if profile.get("launcher") else {})})
        palettes[name] = colors
        defaults[name] = {"variant":profile["conky"],"opacity":profile["opacity"],"zoom":profile["zoom"],
                          "position":profile.get("position", "bottom_left" if name in {"Seth-Tempest","Ra-Eclipse","Isis-Lunar","Nephthys-Veil","Sekhmet-Redline"} else "bottom_middle")}
        walls[name] = profile["wallpaper"]
    for path, data in [(palettes_path,palettes),(defaults_path,defaults),(walls_path,walls)]:
        write_json(path,data)
    logo = (ROOT / "assets/icons/hackthebox.svg").read_text()
    for folder in (BASE / "themes").iterdir():
        if folder.name not in layouts or folder.name not in selected:
            continue
        css = folder / "style.css"
        content = css.read_text().split("/* Laboratory status */")[0].split("/* Fixed angular caps */")[0].rstrip()+"\n"
        if "Angular" in folder.name or profiles.get(folder.name, {}).get("shape") == "angular":
            colors = palettes[folder.name]
            (folder / "assets").mkdir(exist_ok=True)
            bevel = profiles.get(folder.name, {}).get("frame") == "bevel"
            (folder / "assets/angular.svg").write_text(angular_svg(colors, bevel=bevel))
            content += angular_css(colors=colors, bevel=bevel)
        symbol_font = profiles.get(folder.name, {}).get("workspace") in {"code", "shields"}
        japanese_font = '#workspaces button label { font-family:"Noto Sans JP", "JetBrainsMono Nerd Font"; }\n' if profiles.get(folder.name, {}).get("workspace") == "japanese" else ''
        if folder.name == "s4vitar-darkness":
            content += '''/* Rounded upper workstation bar */
window#waybar { background:transparent; border:0; border-radius:12px; }
'''
            content += f'''.modules-left, .modules-center, .modules-right {{ background:alpha({profiles[folder.name]['bg']},.94); background-image:none; border:1px solid alpha({profiles[folder.name]['acc1']},.96); border-radius:10px; padding:0 5px; margin:3px 4px; }}
'''
            content += '''
#workspaces button { border-radius:7px; }
'''
        if folder.name in {"Mr-Robot", "Mr-Robot-Safehouse", "Fsociety"}:
            content += '''#custom-launcher { background-image:url("assets/fsociety.svg"); background-size:23px 23px; background-repeat:no-repeat; background-position:center; min-width:27px; min-height:24px; padding:0 6px; }
'''
            (folder / "assets/fsociety.svg").write_text('''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><path fill="#edf4f8" d="M10 8Q32 0 54 8L57 29Q56 50 32 62Q8 50 7 29Z"/><path fill="#0b111a" d="M12 20L28 24L25 29L12 26ZM52 20L36 24L39 29L52 26ZM29 30L35 30L38 40L26 40ZM15 42Q24 38 32 45Q40 38 49 42L44 48Q37 48 32 46Q27 48 20 48ZM27 51L37 51L32 59Z"/><path stroke="#0b111a" stroke-width="3" fill="none" d="M13 15Q21 10 28 16M36 16Q43 10 51 15M17 34Q18 38 23 39M47 34Q46 38 41 39"/></svg>\n''')
        profile = profiles.get(folder.name, {})
        if profile.get("launcher"):
            icon = profile["launcher"]
            if icon not in {"mortal-kombat", "toyota", "honda", "nissan", "matrix-code", "condor", "hack4u"}:
                raise ValueError(f"Emblema desconocido: {icon}")
            if icon == "hack4u":
                (folder / "assets/launcher.png").write_bytes((ROOT / "assets/icons/hack4u.png").read_bytes())
                content += '#custom-launcher { background-image:url("assets/launcher.png"); background-size:29px 29px; background-repeat:no-repeat; background-position:center; min-width:33px; min-height:30px; padding:0 7px; }\n'
            else:
                source = (ROOT / "assets/icons" / f"{icon}.svg").read_text()
                source = source.replace("#ffffff", profile["acc1"])
                if icon in {"toyota", "honda", "nissan"}:
                    source = source.replace("<path ", f'<path fill="{profile["acc1"]}" ')
                (folder / "assets/launcher.svg").write_text(source)
                content += '#custom-launcher { background-image:url("assets/launcher.svg"); background-size:25px 25px; background-repeat:no-repeat; background-position:center; min-width:29px; min-height:26px; padding:0 7px; }\n'
        if folder.name == "Kevin-Mitnick-Condor":
            content += '''/* Condor · metal oscuro y líneas de telefonía */
.modules-left, .modules-center, .modules-right { margin:4px 7px; }
#workspaces button { min-width:24px; margin:2px 1px; border-radius:3px; }
#clock { font-weight:700; }
#custom-launcher { background-size:32px 25px; min-width:36px; }
'''
        css.write_text(content + status_styles()+typography_styles(typography[folder.name], symbol_font) + japanese_font + workspace_css(palettes[folder.name]))
        (folder / "assets").mkdir(exist_ok=True)
        for state,color in [("connected","#9fef00"),("disconnected","#ff6b6b")]:
            (folder / "assets" / f"hackthebox-{state}.svg").write_text(logo.replace('<path ',f'<path fill="{color}" '))
    print(f"{len(profiles)} diseños declarados; módulos comunes generados")


if __name__ == "__main__":
    main()
