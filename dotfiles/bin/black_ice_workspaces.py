"""Workspaces locales estables, compartidos por Hyprland y Waybar."""
from __future__ import annotations

import json
import os
import re
import socket
from pathlib import Path

COUNT = 5
CONFIG = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
STATE = CONFIG / "black-ice/workspaces.json"


def read_state(path: Path = STATE) -> dict:
    try:
        value = json.loads(path.read_text())
        return value if isinstance(value, dict) else {}
    except (OSError, ValueError):
        return {}


def plan(monitors: list[dict], workspaces: list[dict], saved: dict) -> dict:
    groups, used = {}, set()
    previous = saved.get("groups", {})
    if not isinstance(previous, dict):
        previous = {}
    for name, ids in previous.items():
        if not isinstance(name, str) or not re.fullmatch(r"[A-Za-z0-9_.:-]+", name) or not isinstance(ids, list):
            continue
        groups[name] = []
        for number in ids:
            if type(number) is int and 0 < number < 2147483647 and number not in used and len(groups[name]) < COUNT:
                groups[name].append(number)
                used.add(number)
    outputs = sorted((m for m in monitors if not m.get("disabled")), key=lambda m: (m.get("id", 0), m["name"]))
    for monitor in outputs:
        name = monitor["name"]
        if not re.fullmatch(r"[A-Za-z0-9_.:-]+", name):
            raise ValueError("Nombre de salida no válido")
        group = groups.setdefault(name, [])
        existing = sorted(w["id"] for w in workspaces if w.get("monitor") == name and w.get("id", 0) > 0)
        for number in existing:
            if len(group) < COUNT and number not in used:
                group.append(number)
                used.add(number)
    for monitor in outputs:
        group = groups[monitor["name"]]
        number = 1
        while len(group) < COUNT:
            if number not in used and not any(w.get("id") == number for w in workspaces):
                group.append(number)
                used.add(number)
            number += 1
        group.sort()
    return {"schema": 1, "groups": groups}


def atomic_write(path: Path, data: str) -> None:
    if path.is_file() and path.read_text() == data:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(f".{path.name}.{os.getpid()}")
    try:
        temporary.write_text(data)
        temporary.chmod(0o600)
        temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)


class IPC:
    def __init__(self) -> None:
        signature = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "")
        if not signature or "/" in signature:
            raise ValueError("Ejecuta este comando dentro de Hyprland")
        self.root = Path(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")) / "hypr" / signature

    def request(self, command: str) -> str:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
            connection.settimeout(3)
            connection.connect(str(self.root / ".socket.sock"))
            connection.sendall(command.encode())
            chunks, size = [], 0
            while data := connection.recv(65536):
                size += len(data)
                if size > 8 * 1024 * 1024:
                    raise ValueError("Respuesta IPC demasiado grande")
                chunks.append(data)
            return b"".join(chunks).decode()

    def query(self, name: str) -> list[dict]:
        value = json.loads(self.request("j/" + name))
        if not isinstance(value, list):
            raise TypeError("Respuesta IPC no válida")
        return value

    def lua(self) -> bool:
        return bool(re.search(r"configProvider:\s*lua\b", self.request("status")))

    def checked(self, command: str) -> None:
        result = self.request(command).strip()
        if result != "ok":
            raise RuntimeError(result or "Hyprland no confirmó el cambio")


def rules(state: dict, monitors: list[dict]) -> tuple[str, str]:
    conf, lua = ["# BLACK-ICE — generado por black-ice-workspaces"], ["-- BLACK-ICE — generado por black-ice-workspaces"]
    for monitor in monitors:
        name = monitor["name"]
        for number in state["groups"][name]:
            conf.append(f"workspace = {number}, monitor:{name}, persistent:true")
            lua.append(f"hl.workspace_rule({{workspace={json.dumps(str(number))},monitor={json.dumps(name)},persistent=true}})")
    for slot in range(1, COUNT + 1):
        for modifiers, action in (("SUPER", "focus"), ("SUPER ALT", "move")):
            command = f"~/.local/bin/black-ice-workspaces {action} {slot}"
            conf.append(f"unbind = {modifiers}, {slot}")
            conf.append(f"bind = {modifiers}, {slot}, exec, {command}")
            combination = json.dumps(modifiers.replace(' ', ' + ') + ' + ' + str(slot))
            lua.append(f"hl.unbind({combination})")
            label = ("Ir al escritorio local " if action == "focus" else "Mover al escritorio local ") + str(slot)
            lua.append(f"hl.bind({combination},hl.dsp.exec_cmd({json.dumps(command)}),{{description={json.dumps(label)}}})")
    return "\n".join(conf) + "\n", "\n".join(lua) + "\n"


def reconcile(ipc: IPC, path: Path = STATE, config: Path = CONFIG) -> dict:
    monitors = ipc.query("monitors")
    if not monitors:
        return read_state(path)
    state = plan(monitors, ipc.query("workspaces"), read_state(path))
    conf, lua = rules(state, monitors)
    atomic_write(path, json.dumps(state, indent=2) + "\n")
    atomic_write(config / "hypr/black-ice-workspaces.conf", conf)
    atomic_write(config / "hypr/black-ice-workspaces.lua", lua)
    if ipc.lua():
        ipc.checked("eval " + lua)
    else:
        for line in conf.splitlines()[1:]:
            key, value = line.split(" = ", 1)
            ipc.checked("keyword " + key + " " + value)
    return state


def switch(ipc: IPC, action: str, slot: int, path: Path = STATE) -> int:
    if not 1 <= slot <= COUNT:
        raise ValueError("El escritorio local debe estar entre 1 y 5")
    focused = next((m for m in ipc.query("monitors") if m.get("focused")), None)
    if focused is None:
        raise ValueError("No hay una pantalla enfocada")
    state = read_state(path)
    if len(state.get("groups", {}).get(focused["name"], [])) != COUNT:
        state = reconcile(ipc, path, path.parent.parent)
    target = state["groups"][focused["name"]][slot - 1]
    if type(target) is not int or not 0 < target < 2147483647:
        raise ValueError("Identificador de escritorio no válido; ejecuta black-ice-workspaces sync")
    if ipc.lua():
        code = f"hl.dsp.focus({{workspace={target}}})" if action == "focus" else f"hl.dsp.window.move({{workspace={target}}})"
        ipc.checked("eval hl.dispatch(" + code + ")")
    else:
        ipc.checked(f"dispatch {'workspace' if action == 'focus' else 'movetoworkspace'} {target}")
    return target


def configure_bar(module: dict, output: str, state: dict) -> None:
    ids = state.get("groups", {}).get(output, [])
    if len(ids) != COUNT:
        return
    module.update({"all-outputs": False, "sort-by-number": True, "move-to-monitor": False,
                   "persistent-workspaces": {output: ids}})
    icons = module.setdefault("format-icons", {})
    old = dict(icons)
    if "{name}" in module.get("format", "{name}"):
        module["format"] = module.get("format", "{name}").replace("{name}", "{icon}")
        for index, number in enumerate(ids, 1):
            icons[str(number)] = str(index)
    else:
        for index, number in enumerate(ids, 1):
            if str(index) in old:
                icons[str(number)] = old[str(index)]

