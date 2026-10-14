"""Perfiles locales de escritorio: validación, composición y persistencia."""
from __future__ import annotations

import configparser
import hashlib
import importlib.machinery
import importlib.util
import json
import math
import os
import re
import shutil
import subprocess
import tempfile
import uuid
from pathlib import Path

from black_ice_layout import configuration

CONFIG = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
ROOT = CONFIG / "waybar/themes"
SDDM_ROOT = Path("/usr/share/sddm/themes")
MODULES = {
    "custom/privacy": "Tor · ONION LINK",
    "custom/launcher": "Aplicaciones", "hyprland/workspaces": "Escritorios",
    "custom/local_ip": "IP local", "custom/public_ip": "IP pública", "custom/vpn": "VPN tun0",
    "custom/settarget": "Objetivo", "custom/docker": "Docker", "custom/kvm": "Máquinas virtuales",
    "custom/updates": "Actualizaciones", "custom/player": "Reproductor", "custom/weather": "Clima",
    "network": "Red", "bluetooth": "Bluetooth", "pulseaudio": "Audio", "battery": "Batería",
    "clock": "Reloj", "custom/control": "Ajustes", "custom/power": "Energía", "tray": "Bandeja",
}
PALETTE = {"bg": "#0c1118", "fg": "#e6edf3", "acc1": "#27c6ed", "acc2": "#ae90e8", "dim": "#a4b5c2"}
LAYOUTS = {"dual-top": "Dos barras · escritorios arriba", "dual-bottom": "Dos barras · escritorios abajo",
           "single-top": "Una barra arriba", "single-bottom": "Una barra abajo"}
SHAPES = {"base": "Estilo original", "angular": "Angular", "slab": "Recto", "capsule": "Redondeado", "bevel": "Relieve"}


def read_json(path: Path) -> dict:
    try:
        value = json.loads(path.read_text())
        return value if isinstance(value, dict) else {}
    except (OSError, ValueError):
        return {}


def atomic(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as handle:
        handle.write(content)
        temporary = Path(handle.name)
    try:
        temporary.chmod(0o600)
        temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)


def angular_svg(colors: dict, opacity: float = .94, bevel: bool = False) -> str:
    fill = colors["bg"]
    details = ""
    if bevel:
        fill = "url(#bevel)"
        details = (f'<defs><linearGradient id="bevel" x2="0" y2="1"><stop stop-color="{colors["dim"]}" stop-opacity=".32"/>'
                   f'<stop offset=".18" stop-color="{colors["bg"]}"/><stop offset="1" stop-color="#050608"/></linearGradient></defs>')
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="64" height="32" viewBox="0 0 64 32">' + details +
            f'<path d="M13 1H63V19L51 31H1V13Z" fill="{fill}" fill-opacity="{opacity}" '
            f'stroke="{colors["acc1"]}" stroke-opacity=".96" stroke-width="1.6"/></svg>\n')


def angular_css(image: str = "assets/angular.svg", colors: dict | None = None, opacity: float = .94, bevel: bool = False) -> str:
    colors = colors or PALETTE
    css = f'''/* Fixed angular caps */
window#waybar {{ background:transparent; background-image:none; border:0; box-shadow:none; }}
.modules-left, .modules-center, .modules-right {{
    background:alpha({colors['bg']},{opacity}); background-image:none; background-clip:padding-box; border-radius:0; box-shadow:none;
    border:2px solid transparent; border-left-width:13px; border-right-width:13px;
    border-image-source:url("{image}"); border-image-slice:2 14 fill;
    border-image-width:2px 13px; border-image-repeat:stretch;
    padding:0 3px; margin:3px 5px;
}}
'''
    if bevel:
        css += f'''.modules-left, .modules-center, .modules-right {{
    background-image:linear-gradient(to bottom, alpha({colors['dim']},.25), alpha({colors['bg']},.96) 22%, #050608);
    background-clip:padding-box; box-shadow:0 2px 3px alpha(#000000,.65);
}}
'''
    return css


def workspace_css(colors: dict) -> str:
    return f'''/* Accessible workspace states */
#workspaces button {{ color:{colors['dim']}; min-width:18px; padding:0 7px; border:1px solid transparent; }}
#workspaces button.active {{ color:{colors['fg']}; background:mix({colors['bg']},{colors['acc1']},.30); border:1px solid {colors['acc1']}; box-shadow:inset 0 1px alpha({colors['fg']},.18); }}
#workspaces button.active label {{ color:{colors['fg']}; font-weight:700; }}
#workspaces button:hover {{ color:{colors['fg']}; background:mix({colors['bg']},{colors['acc1']},.18); }}
#workspaces button.urgent {{ color:#ffffff; background:#9b303b; border-color:#ff8c97; }}
'''


def popup_css(colors: dict) -> str:
    return f'''menu, .menu, .context-menu, popover.background {{ background:{colors['bg']}; background-image:none; color:{colors['fg']}; border:1px solid alpha({colors['acc1']},.45); }}
menuitem {{ background:transparent; color:{colors['fg']}; padding:7px 12px; }}
menuitem label, menu label, popover label {{ color:{colors['fg']}; }}
menuitem:hover, menuitem:selected {{ background:mix({colors['bg']},{colors['acc1']},.2); color:{colors['fg']}; }}
menuitem:disabled, menuitem:disabled label {{ color:{colors['dim']}; }}
'''


def themes() -> list[str]:
    return sorted(p.name for p in ROOT.iterdir() if (p / "style.css").is_file() and (p / "config.jsonc").is_file()) if ROOT.is_dir() else []


def current() -> str:
    return (CONFIG / "waybar/style.css").resolve().parent.name


def picture_dir() -> Path:
    config = (CONFIG / "user-dirs.dirs")
    try:
        match = re.search(r'^XDG_PICTURES_DIR="([^"]+)"', config.read_text(), re.MULTILINE)
        if match:
            return Path(match[1].replace("$HOME", str(Path.home())))
    except OSError:
        pass
    return Path.home() / "Pictures"


def defaults(name: str) -> dict:
    if name not in themes():
        raise ValueError("El tema base no está instalado")
    folder = ROOT / name
    saved = read_json(folder / "profile.json")
    if saved:
        return validate(saved)
    metadata = read_json(folder / "theme.json")
    registry = read_json(CONFIG / "conky/black-ice/palettes.json").get(name, {})
    header = dict(re.findall(r"\b(bg|fg|acc1|acc2|dim)=(#[0-9a-fA-F]{6})\b", (folder / "style.css").read_text()[:600]))
    typography = read_json(CONFIG / "waybar/typography.json").get(name, {})
    conky = {"variant": "signal", "opacity": .65, "zoom": .8, "color": "theme", "position": "bottom_middle", "offset_x": 0, "offset_y": 0,
             **read_json(CONFIG / "conky/black-ice/theme-defaults.json").get(name, {})}
    preferences = read_json(Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "black-ice/conky.json")
    conky.update(preferences.get("themes", {}).get(name, {}))
    conky.update(enabled=preferences.get("enabled", True), output=preferences.get("output", "auto"), outputs=preferences.get("outputs", []))
    wall = metadata.get("wallpaper", "")
    return {"version": 1, "name": name + " personal", "base": name, "workspace_style": "base", "wallpaper_mode": metadata.get("wallpaper_mode", "auto"),
            "palette": {**PALETTE, **registry, **header, **read_json(folder / "palette.json")},
            "font": typography.get("font", "Roboto"), "data_font": typography.get("data_font", "RobotoMono Nerd Font"),
            "font_size": typography.get("size", 12), "weight": typography.get("weight", 500),
            "layout": metadata.get("layout", read_json(CONFIG / "waybar/layout-map.json").get(name, "dual-top")),
            "shape": "angular" if metadata.get("shape") == "angular" or "Angular" in name else "base",
            "opacity": .9, "height": 36, "spacing": 0, "lab_side": "right" if name == "Horus-Skyline" else "left",
            "output": "all", "modules": {}, "module_order": [], "module_bars": {}, "wallpaper": str(picture_dir() / "wallpapers" / wall) if wall else "",
            "conky": conky, "sddm": {"theme": metadata.get("sddm", "black-ice-obsidian"), "follow": True}}


def number(value: object, low: float, high: float, label: str) -> float:
    if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value) or not low <= value <= high:
        raise ValueError(f"{label}: elige un valor entre {low} y {high}")
    return value


def validate(value: dict) -> dict:
    if not isinstance(value, dict):
        raise ValueError("Perfil inválido")  # noqa: TRY004
    value = json.loads(json.dumps(value))
    value.setdefault("workspace_style", "base")
    value.setdefault("wallpaper_mode", "auto")
    value.setdefault("module_order", [])
    value.setdefault("module_bars", {})
    order, locations = value["module_order"], value["module_bars"]
    if not isinstance(order, list) or any(not isinstance(k, str) or k not in MODULES for k in order) or len(set(order)) != len(order):
        raise ValueError("Orden de módulos inválido")
    if not isinstance(locations, dict) or any(k not in MODULES or v not in {"top", "bottom"} for k, v in locations.items()):
        raise ValueError("Barra de módulo inválida")
    if value["workspace_style"] not in {"base", "numbers", "dots", "diamonds", "code", "ankh", "shields", "japanese"} or value["wallpaper_mode"] not in {"auto", "mirror", "panorama", "scene"}:
        raise ValueError("Símbolos o modo de fondo inválidos")
    if value.get("base") not in themes() or str(value["base"]).startswith("User-"):
        raise ValueError("Selecciona un tema original como base")
    if not isinstance(value.get("name"), str) or not 1 <= len(value["name"].strip()) <= 60 or re.search(r"[\x00-\x1f\x7f]", value["name"]):
        raise ValueError("Escribe un nombre de 1 a 60 caracteres")
    for key in ("font", "data_font"):
        if not isinstance(value.get(key), str) or not re.fullmatch(r"[A-Za-z0-9 ._-]{1,80}", value[key]):
            raise ValueError("Nombre de fuente inválido")
    colors = value.get("palette", {})
    if not isinstance(colors, dict) or set(colors) != set(PALETTE) or any(not re.fullmatch(r"#[0-9a-fA-F]{6}", str(c)) for c in colors.values()):
        raise ValueError("La paleta requiere cinco colores hexadecimales")
    for key, low, high in [("font_size", 10, 18), ("weight", 300, 800), ("height", 28, 60), ("spacing", 0, 12), ("opacity", .3, 1)]:
        number(value.get(key), low, high, key)
    if value.get("layout") not in LAYOUTS or value.get("shape") not in SHAPES or value.get("lab_side") not in {"left", "right"}:
        raise ValueError("Composición de barras inválida")
    if not isinstance(value.get("modules"), dict):
        raise ValueError("Selección de módulos inválida")  # noqa: TRY004
    for key, zone in value["modules"].items():
        if key not in MODULES or zone not in {"default", "left", "center", "right", "hidden"}:
            raise ValueError("Posición de módulo inválida")
        if key == "hyprland/workspaces" and zone not in {"default", "center", "hidden"} or key == "tray" and zone not in {"default", "right", "hidden"}:
            raise ValueError("Escritorios al centro; bandeja a la derecha")
    for key in ("output", "wallpaper"):
        if not isinstance(value.get(key), str) or re.search(r"[\x00-\x1f\x7f]", value[key]):
            raise ValueError("Pantalla o ruta inválida")
    wall = value["wallpaper"]
    if wall and (not Path(wall).is_file() or Path(wall).suffix.lower() not in {".png", ".jpg", ".jpeg", ".webp", ".avif"}):
        raise ValueError("El fondo debe ser una imagen existente")
    conky = value.get("conky", {})
    if not isinstance(conky, dict):
        raise ValueError("Preferencias de Conky inválidas")  # noqa: TRY004
    styles = {"fsociety", "obsidian", "fracture", "signal", "orbit", "ribbon", "terminal", "pulse", "atlas", "horizon", "observatory", "polar", "chronos", "nexus", "gotham", "prism", "circuit", "scope", "stack", "focus"}
    if conky.get("variant") not in styles or conky.get("color") not in {"theme", "swap", "ice", "acid", "ember", "orchid", "mono"}:
        raise ValueError("Estilo o color de Conky inválido")
    if conky.get("position") not in {v + "_" + h for v in ("top", "middle", "bottom") for h in ("left", "middle", "right")}:
        raise ValueError("Posición de Conky inválida")
    for key, low, high in [("opacity", .55, .95), ("zoom", .5, 1.5), ("offset_x", -4000, 4000), ("offset_y", -4000, 4000)]:
        number(conky.get(key), low, high, "Conky " + key)
    if not isinstance(conky.get("enabled"), bool) or not isinstance(conky.get("output"), str) or re.search(r"[\x00-\x1f\x7f]", conky["output"]):
        raise ValueError("Pantalla o visibilidad de Conky inválida")
    outputs = conky.setdefault("outputs", [])
    if not isinstance(outputs, list) or len(outputs) > 32 or any(not isinstance(n, str) or not re.fullmatch(r"[A-Za-z0-9_.:-]{1,128}", n) for n in outputs):
        raise ValueError("Lista de pantallas de Conky inválida")
    sddm = value.get("sddm", {})
    if not isinstance(sddm, dict) or not re.fullmatch(r"[A-Za-z0-9_.-]+", str(sddm.get("theme", ""))) or not isinstance(sddm.get("follow"), bool):
        raise ValueError("Selección de SDDM inválida")
    return value


def order_modules(bar: dict, order: list) -> None:
    if not order:
        return
    ranks = {name: i for i, name in enumerate(order)}
    def rank(name: str) -> int:
        if name.startswith("group/"):
            return min((rank(k) for k in bar.get(name, {}).get("modules", [])), default=len(ranks))
        return ranks.get(name, len(ranks))
    for name, value in bar.items():
        if name.startswith("group/"):
            value["modules"].sort(key=rank)
    for zone in ("modules-left", "modules-center", "modules-right"):
        bar[zone].sort(key=rank)


def move_module(profile: dict, key: str, zone: str, position: str, before: str | None = None) -> None:
    if key not in MODULES or zone not in {"left", "center", "right", "hidden"} or position not in {"top", "bottom"}:
        raise ValueError("Destino de módulo inválido")
    if key == "hyprland/workspaces" and zone != "hidden":
        zone = "center"
        if profile["layout"].startswith("dual"):
            profile["layout"] = "dual-" + position
    elif key == "tray" and zone != "hidden":
        zone = "right"
    profile["modules"][key] = zone
    profile.setdefault("module_bars", {})[key] = position
    order = profile.setdefault("module_order", [])
    order[:] = [m for m in order if m != key]
    for name in MODULES:
        if name not in order and name != key:
            order.append(name)
    order.insert(order.index(before) if before in order else len(order), key)


_monitor_backend = None


def conky_rectangle(profile: dict, monitor: dict) -> dict:
    global _monitor_backend
    if _monitor_backend is None:
        loader = importlib.machinery.SourceFileLoader("black_ice_conky_layout", str(Path(__file__).with_name("black-ice-conky")))
        spec = importlib.util.spec_from_loader(loader.name, loader)
        _monitor_backend = importlib.util.module_from_spec(spec)
        loader.exec_module(_monitor_backend)
    screen = {**monitor, "reserved": [0, 0, 0, 0]}
    for bar in bars(profile):
        screen["reserved"][1 if bar["position"] == "top" else 3] = int(profile["height"])
    geometry = _monitor_backend.layout(screen, profile["conky"]["variant"], profile["conky"])
    return {"x": geometry["gap_x"], "y": geometry["gap_y"] + screen["reserved"][1],
            "width": geometry["surface_width"], "height": geometry["surface_height"]}


def move_conky(profile: dict, monitor: dict, x: float, y: float) -> None:
    settings = profile["conky"]
    candidates = []
    for vertical in ("top", "middle", "bottom"):
        for horizontal in ("left", "middle", "right"):
            candidate = json.loads(json.dumps(profile))
            candidate["conky"].update(position=vertical + "_" + horizontal, offset_x=0, offset_y=0)
            rect = conky_rectangle(candidate, monitor)
            candidates.append((abs(x - rect["x"]) + abs(y - rect["y"]), candidate["conky"]["position"], rect))
    _, position, base = min(candidates, key=lambda c: c[0])
    settings.update(position=position, offset_x=max(-4000, min(4000, round(x - base["x"]))),
                    offset_y=max(-4000, min(4000, round(y - base["y"]))))


def bars(profile: dict) -> list:
    result = configuration(profile["layout"])
    desktop = result[0] if len(result) == 1 or profile["layout"] == "dual-top" else result[1]
    if profile["lab_side"] == "right":
        for bar in result:
            for zone in ("modules-left", "modules-center", "modules-right"):
                bar[zone] = [m for m in bar[zone] if m not in {"custom/docker", "custom/kvm", "custom/updates", "group/lab"}]
        desktop["modules-right"].insert(0, "group/lab")
        desktop["lab-side"] = "right"
    def remove(bar: dict, key: str) -> None:
        for zone in ("modules-left", "modules-center", "modules-right"):
            bar[zone] = [m for m in bar[zone] if m != key]
        for name, definition in bar.items():
            if name.startswith("group/"):
                definition["modules"] = [m for m in definition["modules"] if m != key]
    for key, zone in profile["modules"].items():
        if zone == "default":
            continue
        for bar in result:
            remove(bar, key)
        if zone != "hidden":
            target = next((b for b in result if b["position"] == profile.get("module_bars", {}).get(key)), desktop)
            target["modules-" + zone].append(key)
    for bar in result:
        bar["profile-desktop"] = bar is desktop
        bar["profile-bars"] = profile.get("module_bars", {})
        bar["profile-order"] = profile.get("module_order", [])
        order_modules(bar, profile.get("module_order", []))
        bar["height"] = int(profile["height"])
        bar["spacing"] = int(profile["spacing"])
        style = profile.get("workspace_style", "base")
        if style == "base":
            style = read_json(ROOT / profile["base"] / "theme.json").get("workspace", "numbers")
        workspace(bar["hyprland/workspaces"], style)
        bar["profile-modules"] = profile["modules"]
        if profile["output"] != "all":
            bar["output"] = profile["output"]
    return result


def workspace(config: dict, style: str) -> None:
    symbols = {"dots": ("○", "●"), "diamonds": ("◇", "◆"), "code": ("\uf120", "\uf121"),
               "ankh": ("☥", "☥"), "shields": ("\uf132", "\uf3ed")}
    if style == "japanese":
        icons = {str(i): "一二三四五六七八九十"[(i - 1) % 10] for i in range(1, 31)}
        config.update({"format": "{icon}", "format-icons": {**icons, "default": "界", "urgent": "危"}, "tooltip": True})
    elif style in symbols:
        idle, active = symbols[style]
        config.update({"format": "{icon}", "format-icons": {"default": idle, "empty": idle, "persistent": idle, "active": active, "urgent": "!"},
                       "tooltip": True, "tooltips": {"default": "Escritorio {name}: {windows}", "empty": "Escritorio {name}"}})
    else:
        config["format"] = "{name}"


def style(profile: dict, base: Path) -> str:
    colors = profile["palette"]
    css = '@import url("' + base.as_uri() + '");\n'
    css += f'''* {{ font-family:"{profile['font']}", "JetBrainsMono Nerd Font"; font-size:{profile['font_size']}px; font-weight:{int(round(profile['weight'] / 100) * 100)}; }}
window#waybar {{ color:{colors['fg']}; }}
#custom-local_ip, #custom-public_ip, #custom-vpn, #custom-settarget {{ font-family:"{profile['data_font']}", "JetBrainsMono Nerd Font"; }}
#workspaces button, #workspaces button label, #clock, #custom-player {{ font-family:"{profile['font']}", "JetBrainsMono Nerd Font"; }}
#workspaces button.active, #custom-launcher, #custom-control, #custom-local_ip {{ color:{colors['acc1']}; }}
#custom-public_ip, #custom-settarget {{ color:{colors['acc2']}; }}
#network, #bluetooth, #pulseaudio, #battery, #clock, #tray, #custom-power, #custom-docker, #custom-kvm {{ color:{colors['fg']}; }}
tooltip {{ background:{colors['bg']}; color:{colors['fg']}; }}
'''
    shape = profile["shape"]
    workspace_style = profile.get("workspace_style", "base")
    if workspace_style == "base":
        workspace_style = read_json(ROOT / profile["base"] / "theme.json").get("workspace", "numbers")
    if workspace_style in {"code", "shields"}:
        css += '#workspaces button label { font-family:"JetBrainsMono Nerd Font"; }\n'
    elif workspace_style == "japanese":
        css += '#workspaces button label { font-family:"Noto Sans JP", "JetBrainsMono Nerd Font"; }\n'
    if shape == "angular":
        css += angular_css(colors=colors, opacity=profile["opacity"])
    elif shape != "base":
        radius = "16px" if shape == "capsule" else "4px" if shape == "bevel" else "0"
        css += f'''.modules-left, .modules-center, .modules-right {{ border-image:none; background-image:none;
background:alpha({colors['bg']},{profile['opacity']}); border:1px solid alpha({colors['acc1']},.95);
border-radius:{radius}; padding:0 10px; margin:3px 5px; box-shadow:none; }}
window#waybar {{ background:transparent; border:none; box-shadow:none; }}
'''
        if shape == "bevel":
            css += f'.modules-left, .modules-center, .modules-right {{ background-image:linear-gradient(to bottom, alpha({colors["fg"]},.14), alpha({colors["bg"]},.9)); box-shadow:inset 0 1px 1px alpha({colors["fg"]},.18), 0 2px 3px alpha(#000000,.5); }}\n'
    css += '#custom-vpn.connected { color:#9fef00; }\n#custom-vpn.disconnected { color:#ff6b6b; }\n'
    return css + popup_css(colors) + workspace_css(colors)


def save(value: dict) -> str:
    profile = validate(value)
    slug = re.sub(r"[^A-Za-z0-9]+", "-", profile["name"]).strip("-")[:35] or "Theme"
    name = "User-" + slug + "-" + hashlib.sha256(profile["name"].encode()).hexdigest()[:8]
    folder = ROOT / name
    base = ROOT / profile["base"]
    if folder.is_symlink() or (folder.exists() and not (folder / "profile.json").is_file()):
        raise ValueError("La ruta del perfil está ocupada; elige otro nombre")
    folder.mkdir(parents=True, exist_ok=True)
    if (base / "assets").is_dir():
        shutil.copytree(base / "assets", folder / "assets", dirs_exist_ok=True)
    atomic(folder / "assets/angular.svg", angular_svg(profile["palette"], profile["opacity"]))
    base_metadata = read_json(base / "theme.json")
    base_wall = picture_dir() / "wallpapers" / base_metadata.get("wallpaper", "")
    panorama = base_metadata.get("panorama", "") if profile["wallpaper"] and Path(profile["wallpaper"]).resolve() == base_wall.resolve() else ""
    for file, data in [("profile.json", profile), ("palette.json", profile["palette"]), ("config.jsonc", bars(profile)),
                       ("theme.json", {"wallpaper_path": profile["wallpaper"], "shape": profile["shape"], "layout": profile["layout"],
                                       "font": profile["font"], "data_font": profile["data_font"], "conky": profile["conky"], "label": profile["name"],
                                       "panorama": panorama, "panorama_anchor": base_metadata.get("panorama_anchor", "center") if panorama else "center",
                                       "workspace": profile.get("workspace_style", "base")})]:
        atomic(folder / file, json.dumps(data, ensure_ascii=False, indent=2) + "\n")
    atomic(folder / "style.css", style(profile, base / "style.css"))
    return name


def apply(name: str) -> None:
    subprocess.run([str(Path.home() / ".local/bin/black-ice-appearance"), "apply", name], check=True, timeout=30)


def trash_theme(name: str) -> Path:
    if not re.fullmatch(r"User-[A-Za-z0-9_.-]+", name):
        raise ValueError("Solo se pueden eliminar temas personalizados")
    folder = ROOT / name
    if folder.is_symlink() or folder.resolve().parent != ROOT.resolve() or not read_json(folder / "profile.json"):
        raise ValueError("El tema personalizado no es válido")
    if name == current():
        raise ValueError("Aplica otro tema antes de eliminar el que está activo")
    data = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share"))
    destination = data / "black-ice/deleted-themes" / uuid.uuid4().hex / name
    destination.parent.mkdir(parents=True, mode=0o700)
    shutil.move(str(folder), str(destination))
    return destination


def restore_theme(path: Path) -> str:
    data = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share"))
    root = data / "black-ice/deleted-themes"
    if path.is_symlink() or path.resolve().parent.parent != root.resolve() or not re.fullmatch(r"User-[A-Za-z0-9_.-]+", path.name):
        raise ValueError("Ruta de papelera inválida")
    if not read_json(path / "profile.json") or (ROOT / path.name).exists() or (ROOT / path.name).is_symlink():
        raise ValueError("El perfil no es válido o ya existe un tema con ese nombre")
    shutil.move(str(path), str(ROOT / path.name))
    path.parent.rmdir()
    return path.name


def sddm_themes() -> list[str]:
    root = SDDM_ROOT
    return sorted(p.name for p in root.iterdir() if (p / "Main.qml").is_file()) if root.is_dir() else []


def sddm_preview(profile: dict, destination: Path) -> Path:
    profile = validate(profile)
    source = SDDM_ROOT / profile["sddm"]["theme"]
    if source.name not in sddm_themes():
        raise ValueError("El tema de SDDM no está instalado")
    shutil.copytree(source, destination, dirs_exist_ok=True)
    if source.name == "black-ice-obsidian":
        qml = destination / "Main.qml"
        content = qml.read_text().replace('font.family: "Rajdhani"', 'font.family: config.font || "Rajdhani"')
        content = content.replace('font.family: "Noto Sans"', 'font.family: config.bodyFont || "Roboto"')
        qml.write_text(content)
    config = configparser.ConfigParser(interpolation=None)
    config.optionxform = str
    config.read(destination / "theme.conf")
    if not config.has_section("General"):
        config.add_section("General")
    if profile["sddm"]["follow"]:
        mapping = {"accent": "acc1", "secondary": "acc2", "foreground": "fg", "muted": "dim", "surface": "bg"}
        for key, color in mapping.items():
            config["General"][key] = profile["palette"][color]
        config["General"].update(font=profile["font"], bodyFont=profile["font"])
        if profile["wallpaper"]:
            background = "background" + Path(profile["wallpaper"]).suffix.lower()
            shutil.copyfile(profile["wallpaper"], destination / background)
            config["General"]["background"] = background
            metadata = read_json(ROOT / profile["base"] / "theme.json")
            expected = metadata.get("wallpaper_path") or str(picture_dir() / "wallpapers" / metadata.get("wallpaper", ""))
            wallpaper_root = (picture_dir() / "wallpapers").resolve()
            panorama = (wallpaper_root / metadata.get("panorama", "")).resolve()
            follows_base = Path(profile["wallpaper"]).resolve() == Path(expected).expanduser().resolve()
            config["General"].update(backgroundMode=profile.get("wallpaper_mode", "auto"),
                                     backgroundPanorama="", backgroundAnchor=metadata.get("panorama_anchor", "center"))
            if follows_base and panorama.is_file() and panorama.is_relative_to(wallpaper_root) and panorama.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp", ".avif"} and profile.get("wallpaper_mode") != "mirror":
                name = "panorama" + panorama.suffix.lower()
                shutil.copyfile(panorama, destination / name)
                config["General"]["backgroundPanorama"] = name
    with (destination / "theme.conf").open("w") as handle:
        config.write(handle)
    return destination


def install_sddm(preview: Path) -> None:
    if not (preview / "Main.qml").is_file():
        raise ValueError("Genera primero la vista previa de SDDM")
    # SDDM conserva la sesión actual; la selección se usa en el próximo acceso.
    subprocess.run(["pkexec", "/usr/lib/black-ice/system-transaction", "sddm-theme", str(preview)],
                   check=True, capture_output=True, text=True, timeout=60)


def restore_sddm() -> None:
    writer = '''import json,os,tempfile
from pathlib import Path
backup=Path('/var/lib/black-ice/sddm-original.json')
if not backup.exists(): raise SystemExit('No existe una selección anterior guardada')
for name,content in json.loads(backup.read_text()).items():
 path=Path(name)
 if name not in {'/etc/sddm.conf','/etc/sddm.conf.d/theme.conf','/etc/sddm.conf.d/zz-black-ice-personal.conf'}: raise SystemExit('Ruta inválida')
 if content is None: path.unlink(missing_ok=True)
 else:
  with tempfile.NamedTemporaryFile(mode='w',dir=path.parent,delete=False) as f: f.write(content); temporary=f.name
  os.chmod(temporary,0o644);os.replace(temporary,path)
'''
    subprocess.run(["sudo", "-n", "/usr/bin/python3", "-c", writer], check=True, capture_output=True, text=True, timeout=15)
