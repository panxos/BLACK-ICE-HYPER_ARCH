"""Asignaciones activas y dependencias, sin ejecutar acciones."""
from __future__ import annotations

import os
import re
import shlex
import shutil
from pathlib import Path

from black_ice_workspaces import IPC

NATIVE = {"killactive": "Cerrar ventana", "exit": "Cerrar sesión", "togglefloating": "Alternar ventana flotante",
          "fullscreen": "Pantalla completa", "pseudo": "Alternar pseudotiling", "layoutmsg": "Cambiar división",
          "movefocus": "Cambiar foco", "movewindow": "Mover ventana", "resizewindow": "Redimensionar ventana",
          "workspace": "Cambiar escritorio", "movetoworkspace": "Mover ventana a escritorio", "mouse": "Arrastrar ventana"}
APPS = {"kitty": "Terminal Kitty", "dolphin": "Archivos · Dolphin", "kate": "Editor · Kate", "brave": "Navegador · Brave",
        "firefox": "Navegador · Firefox", "obsidian": "Notas · Obsidian", "betterbird": "Correo · Betterbird",
        "keepassxc": "Contraseñas · KeePassXC", "caido": "Proxy · Caido", "nwg-displays": "Configurar pantallas",
        "cheatsheet": "Ver atajos", "app_switcher": "Cambiar aplicación", "terminal_manager": "Gestor de terminales",
        "pass_menu": "Menú de contraseñas", "music_player": "Reproductor de música", "music_widget": "Widget de música",
        "power_profile_menu.sh": "Perfil de energía", "wifi_toggle": "Activar o desactivar Wi-Fi",
        "wofi_style_selector": "Estilo del menú",
        "dev": "Herramientas de desarrollo"}


MEDIA = (("play-pause", "Reproducir / pausa"), ("playerctl stop", "Detener música"), ("playerctl next", "Pista siguiente"),
         ("playerctl previous", "Pista anterior"), ("output-volume raise", "Subir volumen"), ("output-volume lower", "Bajar volumen"),
         ("output-volume mute", "Silenciar sonido"), ("pamixer -t", "Silenciar sonido"), ("@DEFAULT_SOURCE@", "Silenciar micrófono"),
         ("brightness raise", "Más brillo"), ("brightness lower", "Menos brillo"), ("brightnessctl", "Brillo de pantalla"))
PROGRAMS = {"kitty", "dolphin", "kate", "brave", "firefox", "obsidian", "betterbird", "keepassxc", "caido"}


def commands(command: str) -> list[str]:
    try:
        lexer = shlex.shlex(command, posix=True, punctuation_chars="|&;()")
        lexer.whitespace_split = True
        tokens = list(lexer)
    except ValueError:
        return []
    result, start = [], True
    for token in tokens:
        if token in {"|", "||", "&&", ";"}:
            start = True
            continue
        if token in {"(", ")"}:
            continue
        if start:
            if token == "env" or re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*=.*", token):
                continue
            if token not in {"true", "false", "echo", "test", "[", "exec"}:
                result.append(token)
            start = False
    result.extend(re.findall(r"\$\(\s*([A-Za-z0-9_./~-]+)", command))
    return list(dict.fromkeys(result))


def missing_commands(command: str) -> list[str]:
    missing = []
    for name in commands(command):
        expanded = os.path.expandvars(os.path.expanduser(name))
        available = os.access(expanded, os.X_OK) and Path(expanded).is_file() if "/" in expanded else shutil.which(expanded) is not None
        if not available:
            missing.append(name)
    return missing


def describe(dispatcher: str, argument: str) -> tuple[str, str]:
    if dispatcher in NATIVE:
        label = NATIVE[dispatcher]
        if dispatcher == "fullscreen" and argument == "1":
            label = "Maximizar ventana"
        if dispatcher in {"workspace", "movetoworkspace"}:
            return "Escritorios", label + " " + argument
        direction = {"l": "izquierda", "r": "derecha", "u": "arriba", "d": "abajo"}.get(argument)
        return "Ventanas", label + (" · " + direction if direction else "")
    if dispatcher != "exec":
        return "Otros", "Acción Lua sin descripción" if dispatcher == "__lua" else dispatcher + " " + argument
    if "black-ice-workspaces" in argument:
        match = re.search(r"\b(focus|move)\s+([1-5])\b", argument)
        return "Escritorios", (("Ir al escritorio local " if match[1] == "focus" else "Mover al escritorio local ") + match[2]) if match else "Escritorios por monitor"
    for token, label in (("black-ice-control appearance", "Estudio de temas"), ("black-ice-control", "Centro de control"),
                         ("black-ice-conky menu", "Estilos de Conky"), ("black-ice-conky toggle", "Mostrar u ocultar Conky"),
                         ("black-ice-wallpapers", "Cambiar fondo"), ("black-ice-launcher", "Menú de aplicaciones")):
        if token in argument:
            return "Escritorio", label
    if "grim" in argument:
        return "Capturas", "Capturar región" if "slurp" in argument else "Capturar pantalla"
    if "cliphist" in argument:
        return "Escritorio", "Historial del portapapeles"
    if "wofi --show" in argument:
        return "Escritorio", "Menú de aplicaciones"
    if "lock-session" in argument or "hyprlock" in argument:
        return "Sistema", "Bloquear pantalla"
    for token, label in MEDIA:
        if token in argument:
            return "Multimedia", label
    first = commands(argument)
    name = Path(first[0]).name if first else argument
    return ("Programas" if name in PROGRAMS else "Herramientas"), APPS.get(name, name)


def shortcut(binding: dict) -> str:
    mask = binding.get("modmask", 0)
    keys = [name for bit, name in ((64, "Win"), (4, "Ctrl"), (8, "Alt"), (1, "Shift"), (2, "Caps"), (16, "Mod2"), (32, "Mod3"), (128, "Mod5")) if mask & bit]
    key = binding.get("key") or "Código " + str(binding.get("keycode", ""))
    key = {"Return": "Enter", "SUPER_L": "Win", "SUPER_R": "Win", "left": "←", "right": "→", "up": "↑", "down": "↓",
           "mouse:272": "Clic izquierdo", "mouse:273": "Clic derecho", "Space": "Espacio"}.get(key, key)
    if key != "Win" or "Win" not in keys:
        keys.append(key)
    return " + ".join(keys) + (" · al soltar" if binding.get("release") else "")


MODIFIERS = {"SUPER": 64, "MOD4": 64, "WIN": 64, "CTRL": 4, "CONTROL": 4, "ALT": 8, "MOD1": 8, "SHIFT": 1}


def conf_binds(path: Path | None = None) -> dict[tuple[int, str], tuple[str, str]]:
    """Lee hyprland.conf para recuperar la acción de los atajos que Hyprland publica como callbacks Lua."""
    path = path or Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "hypr/hyprland.conf"
    try:
        lines = path.read_text().splitlines()
    except OSError:
        return {}
    variables = {m[1]: m[2].strip() for line in lines if (m := re.match(r"\s*(\$\w+)\s*=\s*(.*)", line))}
    found: dict[tuple[int, str], tuple[str, str]] = {}
    for line in lines:
        match = re.match(r"\s*bind[a-z]*\s*=\s*(.*)", line)
        if not match:
            continue
        body = match[1]
        for name in sorted(variables, key=len, reverse=True):
            body = body.replace(name, variables[name])
        parts = [part.strip() for part in body.split(",", 3)]
        if len(parts) < 3:
            continue
        mask = sum(MODIFIERS.get(word.upper(), 0) for word in re.split(r"[\s+_]+", parts[0]) if word)
        found[(mask, parts[1].casefold())] = (parts[2], parts[3] if len(parts) > 3 else "")
    try:
        lua = path.with_suffix(".lua").read_text()
    except OSError:
        return found
    for spec, command in re.findall(r'hl\.bind\((?:mainMod\s*\.\.\s*)?"([^"]+)"\s*,\s*hl\.dsp\.exec_cmd\("((?:[^"\\]|\\.)*)"\)', lua):
        words = [word.strip() for word in ("SUPER" + spec if spec.lstrip().startswith("+") else spec).split("+")]
        mask = sum(MODIFIERS.get(word.upper(), 0) for word in words[:-1])
        if words[-1].upper() in {"SUPER_L", "SUPER_R"}:
            mask |= 64
        found.setdefault((mask, words[-1].casefold()), ("exec", command.replace('\\"', '"')))
    return found


def inventory(bindings: list[dict] | None = None) -> list[dict]:
    rows = []
    known = None
    for binding in IPC().query("binds") if bindings is None else bindings:
        dispatcher, argument = binding.get("dispatcher", ""), binding.get("arg", "")
        if dispatcher == "__lua" and not binding.get("description"):
            known = conf_binds() if known is None else known
            dispatcher, argument = known.get((binding.get("modmask", 0), str(binding.get("key", "")).casefold()), (dispatcher, argument))
        category, label = describe(dispatcher, argument)
        label = binding.get("description") or label
        missing = missing_commands(argument) if dispatcher == "exec" else []
        status = "Falta: " + ", ".join(missing) if missing else "Asignado" if dispatcher != "exec" else "Disponible"
        if dispatcher == "__lua":
            status = "Acción Lua · sin inspección de dependencias"
        rows.append({"keys": shortcut(binding), "action": label, "category": category, "command": argument,
                     "status": status, "missing": missing, "submap": binding.get("submap", "")})
    return sorted(rows, key=lambda row: (row["category"], row["keys"]))
