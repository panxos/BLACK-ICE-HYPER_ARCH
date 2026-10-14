"""Estilos del lanzador Rofi adaptados al tema y al monitor enfocado."""
from __future__ import annotations

import json
import os
import re
from pathlib import Path

from black_ice_i18n import translate
from black_ice_theme import CONFIG, PALETTE, atomic, current, read_json

STYLES = {"cinematic": "Panorámico · cabecera y columnas", "compact": "Compacto · lista",
          "tiles": "Mosaicos · iconos grandes", "classic": "Clásico · Wofi"}


def preferences() -> dict:
    value = read_json(CONFIG / "black-ice/launcher.json")
    return {"style": value.get("style") if value.get("style") in STYLES else "cinematic"}


def select(style: str) -> None:
    if style not in STYLES:
        raise ValueError("Estilo de menú inválido")
    atomic(CONFIG / "black-ice/launcher.json", json.dumps({"style": style}) + "\n")


def theme(style: str, monitors: list[dict]) -> str:
    if style not in STYLES or style == "classic":
        raise ValueError("Selecciona un estilo Rofi")
    monitor = next((m for m in monitors if m.get("focused")), monitors[0] if monitors else {})
    width = int(monitor.get("width", 1366) / max(.5, monitor.get("scale", 1)))
    height = int(monitor.get("height", 768) / max(.5, monitor.get("scale", 1)))
    narrow = width < 1000
    columns = 1 if style == "compact" else (2 if narrow else 3) if style == "cinematic" else (3 if narrow else 4)
    lines = max(2, min(5 if style != "tiles" else 3, (height - 260) // (50 if style != "tiles" else 105)))
    size = min(width - 48, 530 if style == "compact" else 920)
    name = current()
    metadata = read_json(CONFIG / "waybar/themes" / name / "theme.json")
    colors = {**PALETTE, **read_json(CONFIG / "waybar/themes" / name / "palette.json")}
    colors = {k: v if re.fullmatch(r"#[0-9A-Fa-f]{6}", str(v)) else PALETTE[k] for k, v in colors.items() if k in PALETTE}
    font = metadata.get("font", "Roboto")
    if not isinstance(font, str) or not re.fullmatch(r"[A-Za-z0-9 ._-]{1,80}", font):
        font = "Roboto"
    state = read_json(Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "black-ice/appearance.json")
    wall = state.get("wallpaper", "")
    radius = 3 if metadata.get("shape") == "angular" else 14
    banner = ""
    if style == "cinematic" and isinstance(wall, str) and Path(wall).is_file():
        banner = f'background-image:url({json.dumps(wall)}, width);'
    children = "[textbox-banner, inputbar, listview, message]" if style == "cinematic" and banner else "[inputbar, listview, message]"
    vertical = style == "tiles"
    return f'''configuration {{
    show-icons: true;
    drun-display-format: "{{name}}";
    display-drun: "{translate('Aplicaciones')}";
}}
* {{ font:"{font} 11"; background-color:transparent; text-color:{colors['fg']}; }}
window {{ width:{size}px; location:center; anchor:center; background-color:{colors['bg']}; border:1px; border-color:{colors['acc1']}; border-radius:{radius}px; padding:20px; }}
mainbox {{ children:{children}; spacing:16px; }}
textbox-banner {{
    str: "";
    expand: false;
    padding: {50 if height < 800 else 69}px 0px;
    border-radius: 8px;
    {banner}
}}
inputbar {{ children:[prompt, entry]; spacing:14px; padding:14px; border:1px; border-color:{colors['dim']}; border-radius:8px; }}
prompt {{ text-color:{colors['acc1']}; }}
entry {{ placeholder:"{translate('Buscar aplicaciones…')}"; placeholder-color:{colors['dim']}; cursor:true; }}
listview {{ columns:{columns}; lines:{lines}; fixed-height:true; fixed-columns:true; flow:horizontal; spacing:8px; scrollbar:false; }}
element {{ children:[element-icon, element-text]; orientation:{'vertical' if vertical else 'horizontal'}; spacing:12px; padding:12px; border:1px; border-color:transparent; border-radius:8px; }}
element selected.normal, element selected.active {{ background-color:{colors['acc1']}; text-color:{colors['bg']}; }}
element-icon {{ size:{42 if vertical else 24}px; horizontal-align:{'0.5' if vertical else '0.0'}; }}
element-text {{ vertical-align:0.5; horizontal-align:{'0.5' if vertical else '0.0'}; text-color:inherit; }}
message {{ padding:8px; }}
textbox {{ text-color:{colors['dim']}; }}
'''
