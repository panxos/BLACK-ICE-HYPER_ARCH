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
        "save_theme_wall": "Guardar tema y fondo", "wofi_style_selector": "Estilo del menú",
        "rofi_theme_selector": "Tema de Rofi", "dev": "Herramientas de desarrollo"}


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
    for token, label in (("black-ice-control appearance", "Apariencia"), ("black-ice-control", "Centro de control"),
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
    if any(token in argument for token in ("playerctl", "swayosd-client", "pamixer", "brightnessctl", "wpctl")):
        return "Multimedia", argument.replace("~/.local/bin/", "")
    first = commands(argument)
    name = Path(first[0]).name if first else argument
    return "Aplicaciones", APPS.get(name, name)


def shortcut(binding: dict) -> str:
    mask = binding.get("modmask", 0)
    keys = [name for bit, name in ((64, "Win"), (4, "Ctrl"), (8, "Alt"), (1, "Shift"), (2, "Caps"), (16, "Mod2"), (32, "Mod3"), (128, "Mod5")) if mask & bit]
    key = binding.get("key") or "Código " + str(binding.get("keycode", ""))
    key = {"Return": "Enter", "SUPER_L": "Win", "SUPER_R": "Win", "left": "←", "right": "→", "up": "↑", "down": "↓",
           "mouse:272": "Clic izquierdo", "mouse:273": "Clic derecho", "Space": "Espacio"}.get(key, key)
    if key != "Win" or "Win" not in keys:
        keys.append(key)
    return " + ".join(keys) + (" · al soltar" if binding.get("release") else "")


def inventory(bindings: list[dict] | None = None) -> list[dict]:
    rows = []
    for binding in IPC().query("binds") if bindings is None else bindings:
        dispatcher, argument = binding.get("dispatcher", ""), binding.get("arg", "")
        category, label = describe(dispatcher, argument)
        label = binding.get("description") or label
        missing = missing_commands(argument) if dispatcher == "exec" else []
        status = "Falta: " + ", ".join(missing) if missing else "Asignado" if dispatcher != "exec" else "Disponible"
        if dispatcher == "__lua":
            status = "Acción Lua · sin inspección de dependencias"
        rows.append({"keys": shortcut(binding), "action": label, "category": category, "command": argument,
                     "status": status, "missing": missing, "submap": binding.get("submap", "")})
    return sorted(rows, key=lambda row: (row["category"], row["keys"]))
