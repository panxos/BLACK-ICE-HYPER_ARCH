#!/usr/bin/env python3
"""Selección de software opcional; produce planes y nunca instala paquetes."""

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = json.loads((ROOT / "config/apps.json").read_text())
APPS = {item["id"]: item for item in CATALOG["apps"]}
PROFILES = {
    "minimal": [],
    "desktop": ["firefox", "keepassxc", "imv", "mpv", "okular"],
    "pentest": ["firefox", "keepassxc", "nmap", "burpsuite", "ffuf", "sqlmap", "impacket", "netexec", "wireshark-qt", "openbsd-netcat", "proxychains-ng", "seclists"],
    "full": list(APPS),
}


def selection(profile: str, groups: list[str], apps: list[str]) -> list[str]:
    unknown_groups = set(groups) - CATALOG["groups"].keys()
    unknown_apps = set(apps) - APPS.keys()
    if unknown_groups or unknown_apps:
        raise ValueError("Selección desconocida: " + ", ".join(sorted(unknown_groups | unknown_apps)))
    wanted = set(PROFILES[profile]) | set(apps)
    wanted.update(key for key, item in APPS.items() if item["group"] in groups)
    return [key for key in APPS if key in wanted]


def terminal(initial: list[str]) -> list[str]:
    if not shutil.which("whiptail") or not sys.stdin.isatty():
        raise ValueError("Sin interfaz interactiva: indica --profile, --groups o --apps explícitamente.")

    def dialog(options: list[str]) -> str | None:
        with open("/dev/tty", "w") as tty:
            result = subprocess.run(["whiptail", "--title", "BLACK-ICE · Aplicaciones", *options],
                                    stdout=tty, stderr=subprocess.PIPE, text=True, check=False)
        if result.returncode in (1, 255):
            return None
        if result.returncode:
            raise ValueError("No se pudo abrir la selección de aplicaciones.")
        return result.stderr.strip()

    mode = dialog(["--menu", "Elige cómo seleccionar. Cancelar omite el software opcional.", "18", "76", "6",
                   "profiles", "Perfiles: mínimo, escritorio, pentest o completo",
                   "groups", "Seleccionar grupos completos", "apps", "Elegir aplicaciones individuales"])
    if mode is None:
        return []
    if mode == "profiles":
        profile = dialog(["--menu", "Completo incluye compilaciones pesadas y acceso remoto.", "18", "76", "5",
                          "minimal", "Solo escritorio base", "desktop", "Uso diario", "pentest", "Pentest esencial", "full", "Todas las aplicaciones"])
        return selection(profile, [], []) if profile else []
    entries = CATALOG["groups"] if mode == "groups" else {key: item["name"] for key, item in APPS.items()}
    args = ["--separate-output", "--checklist", "ESPACIO: marcar. ENTER: confirmar. ESC: omitir.", "24", "86", "15"]
    for key, name in entries.items():
        args.extend([key, name, "ON" if mode == "apps" and key in initial else "OFF"])
    chosen = dialog(args)
    keys = chosen.splitlines() if chosen else []
    return selection("minimal", keys if mode == "groups" else [], keys if mode == "apps" else [])


def graphical(initial: list[str]) -> list[str]:
    import gi
    gi.require_version("Gtk", "3.0")
    from gi.repository import Gtk

    if not Gtk.init_check()[0]:
        raise ValueError("No hay una sesión gráfica disponible.")
    window = Gtk.Window(title="BLACK-ICE · Selección de aplicaciones")
    window.set_default_size(980, 680)
    window.connect("destroy", Gtk.main_quit)
    outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12, margin=18)
    window.add(outer)
    outer.pack_start(Gtk.Label(label="Selecciona aplicaciones, grupos o un perfil. Nada se instala desde esta pantalla.", xalign=0), False, False, 0)
    toolbar = Gtk.Box(spacing=8)
    outer.pack_start(toolbar, False, False, 0)
    search = Gtk.SearchEntry(placeholder_text="Buscar aplicaciones o grupos…")
    outer.pack_start(search, False, False, 0)
    scroll = Gtk.ScrolledWindow()
    outer.pack_start(scroll, True, True, 0)
    listing = Gtk.ListBox(selection_mode=Gtk.SelectionMode.NONE)
    scroll.add(listing)
    checks = {}
    rows = {}
    count = Gtk.Label(xalign=0)

    def recount(*_args: object) -> None:
        chosen = [key for key, check in checks.items() if check.get_active()]
        heavy = sum(APPS[key]["heavy"] for key in chosen)
        count.set_text(f"{len(chosen)} seleccionadas · {heavy} pesadas · dependencias resueltas por el gestor")

    def choose(keys: list[str]) -> None:
        for key, check in checks.items():
            check.set_active(key in keys)
        recount()

    for profile, title in [("minimal", "Ninguna"), ("desktop", "Escritorio"), ("pentest", "Pentest"), ("full", "Todas")]:
        button = Gtk.Button(label=title)
        button.connect("clicked", lambda _button, p=profile: choose(PROFILES[p]))
        toolbar.pack_start(button, False, False, 0)
    for group, title in CATALOG["groups"].items():
        group_check = Gtk.CheckButton(label=title)
        listing.add(group_check)
        group_check.connect("toggled", lambda check, g=group: [checks[key].set_active(check.get_active()) for key in checks if APPS[key]["group"] == g])
        rows[group] = (group_check, title.casefold())
        for key, item in APPS.items():
            if item["group"] != group:
                continue
            label = item["name"] + (" · compilación/descarga pesada" if item["heavy"] else "")
            check = Gtk.CheckButton(label=label, margin_start=24)
            check.set_tooltip_text(key)
            check.connect("toggled", recount)
            checks[key] = check
            listing.add(check)
            rows[key] = (check, (label + " " + title + " " + key).casefold())
    search.connect("search-changed", lambda entry: [widget.get_parent().set_visible(entry.get_text().casefold() in text) for widget, text in rows.values()])
    outer.pack_start(count, False, False, 0)
    actions = Gtk.ButtonBox(layout_style=Gtk.ButtonBoxStyle.END)
    outer.pack_start(actions, False, False, 0)
    result = []

    def accept(_button: object) -> None:
        result.extend(key for key, check in checks.items() if check.get_active())
        window.destroy()

    cancel = Gtk.Button(label="Omitir software opcional")
    cancel.connect("clicked", lambda _button: window.destroy())
    save = Gtk.Button(label="Usar esta selección")
    save.connect("clicked", accept)
    actions.add(cancel)
    actions.add(save)
    choose(initial)
    window.show_all()
    Gtk.main()
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--profile", choices=list(PROFILES))
    parser.add_argument("--groups", nargs="*", default=[])
    parser.add_argument("--apps", nargs="*", default=[])
    parser.add_argument("--ui", choices=["auto", "gtk", "terminal"])
    parser.add_argument("--output", type=Path)
    parser.add_argument("--load", type=Path)
    parser.add_argument("--packages", action="store_true")
    parser.add_argument("--list", action="store_true")
    args = parser.parse_args()
    try:
        if args.list:
            print(json.dumps(CATALOG, ensure_ascii=False, indent=2))
            return 0
        chosen = selection(args.profile or "minimal", args.groups, args.apps)
        if args.load:
            data = json.loads(args.load.read_text())
            if data.get("schema") != 1 or not isinstance(data.get("apps"), list) or not all(isinstance(key, str) for key in data["apps"]):
                raise ValueError("Plan de aplicaciones inválido.")
            chosen = selection("minimal", [], data["apps"])
        if args.ui:
            use_gtk = args.ui == "gtk" or args.ui == "auto" and bool(os.environ.get("WAYLAND_DISPLAY") or os.environ.get("DISPLAY"))
            if use_gtk:
                try:
                    chosen = graphical(chosen)
                except ImportError:
                    if args.ui == "gtk":
                        raise ValueError("Instala python-gobject y gtk3 para la interfaz gráfica.") from None
                    chosen = terminal(chosen)
            else:
                chosen = terminal(chosen)
        plan = {"schema": 1, "version": (ROOT / "VERSION").read_text().strip(), "apps": chosen,
                "heavy": [key for key in chosen if APPS[key]["heavy"]]}
        if args.output:
            args.output.parent.mkdir(parents=True, exist_ok=True)
            temporary = args.output.with_name(args.output.name + ".new")
            with open(temporary, "w", opener=lambda path, flags: os.open(path, flags, 0o600)) as file:
                file.write(json.dumps(plan, indent=2, ensure_ascii=False) + "\n")
            temporary.replace(args.output)
        print("\n".join(chosen) if args.packages else json.dumps(plan, indent=2, ensure_ascii=False))
        return 0
    except (OSError, ValueError) as exc:
        parser.exit(2, f"Error: {exc}\n")


if __name__ == "__main__":
    sys.exit(main())
