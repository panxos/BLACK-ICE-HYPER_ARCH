#!/usr/bin/env python3
"""Captura temas en una instancia Hyprland headless, con datos de demostración."""
from __future__ import annotations

import argparse
import importlib.machinery
import importlib.util
import json
import os
import shlex
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEMO = {
    "custom/local_ip": "󰩟 192.0.2.10", "custom/public_ip": " 198.51.100.20",
    "custom/vpn": "10.10.14.2", "custom/settarget": "󰓾 192.0.2.42 benjie.lab",
    "custom/docker": " 2", "custom/kvm": "󰢹 1", "custom/updates": "󰏖 4",
    "custom/player": "󰎆", "custom/weather": "󰖙 21°",
    "network": "󰤨", "bluetooth": "󰂯", "pulseaudio": "󰕾 35%", "battery": "󰂄 94%",
}


def run(*args: str, env: dict, **kwargs):
    return subprocess.run(args, env=env, check=True, timeout=15, **kwargs)


def sample_config(bars: list) -> tuple[list, dict]:
    replacements = {key: "custom/demo-" + key for key in DEMO if not key.startswith("custom/")}
    for bar in bars:
        bar["output"] = "HEADLESS-1"
        for key, value in list(bar.items()):
            if isinstance(value, dict):
                for option in list(value):
                    if option.startswith("on-"):
                        del value[option]
                if "modules" in value:
                    value["modules"] = [replacements.get(m, m) for m in value["modules"]]
            elif key.startswith("modules-"):
                bar[key] = [replacements.get(m, m) for m in value]
        for key, label in DEMO.items():
            output = replacements.get(key, key)
            state = "active" if key == "custom/settarget" else "connected"
            payload = json.dumps({"text": label, "class": state}, ensure_ascii=False)
            bar.pop(key, None)
            bar[output] = {"exec": "printf '%s\\n' " + shlex.quote(payload),
                           "return-type": "json", "format": "{}", "tooltip": False}
        if "clock" in bar:
            bar["clock"] = {"format": "21:42", "tooltip": False}
        for key in list(bar):
            if key.startswith("custom/") and key not in DEMO and key not in replacements.values():
                bar[key].pop("exec", None)
                bar[key].pop("exec-if", None)
        bar["hyprland/workspaces"].pop("on-click", None)
        bar["hyprland/workspaces"]["persistent-workspaces"] = {"HEADLESS-1": [1, 2, 3, 4, 5]}
    return bars, replacements


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--instance", required=True, help="Firma de una instancia headless vacía")
    parser.add_argument("--output", type=Path, default=ROOT / "docs/images/themes")
    parser.add_argument("--theme", action="append")
    args = parser.parse_args()
    env = dict(os.environ, HYPRLAND_INSTANCE_SIGNATURE=args.instance)
    instances = json.loads(run("hyprctl", "instances", "-j", env=env, capture_output=True, text=True).stdout)
    instance = next((i for i in instances if i["instance"] == args.instance), None)
    if instance is None:
        parser.error("La instancia solicitada no existe")
    env["WAYLAND_DISPLAY"] = instance["wl_socket"]
    monitors = json.loads(run("hyprctl", "-j", "monitors", env=env, capture_output=True, text=True).stdout)
    clients = json.loads(run("hyprctl", "-j", "clients", env=env, capture_output=True, text=True).stdout)
    if clients or len(monitors) != 1 or monitors[0]["name"] != "HEADLESS-1":
        parser.error("Se requiere una instancia vacía con una única salida HEADLESS-1; no se modifica el escritorio real")
    workspaces = json.loads(run("hyprctl", "-j", "workspaces", env=env, capture_output=True, text=True).stdout)
    if any(w["id"] not in range(1, 6) for w in workspaces):
        parser.error("La instancia contiene otros escritorios; utiliza una instancia headless nueva")
    for index in range(1, 6):
        run("hyprctl", "keyword", "workspace", f"{index},monitor:HEADLESS-1,persistent:true", env=env, capture_output=True)
    catalog = json.loads((ROOT / "dotfiles/waybar/cyber-catalog.json").read_text())
    selected = args.theme or sorted(catalog)
    if set(selected) - catalog.keys():
        parser.error("Tema desconocido")
    args.output.mkdir(parents=True, exist_ok=True)
    cache = Path.home() / ".cache/tmp"
    cache.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="black-ice-gallery-", dir=cache) as temporary:
        work = Path(temporary)
        env["XDG_CONFIG_HOME"] = str(work / "config")
        os.environ["XDG_CONFIG_HOME"] = env["XDG_CONFIG_HOME"]
        sys.path.insert(0, str(ROOT / "dotfiles/bin"))
        loader = importlib.machinery.SourceFileLoader("gallery_waybar", str(ROOT / "dotfiles/bin/black-ice-waybar"))
        spec = importlib.util.spec_from_loader(loader.name, loader)
        backend = importlib.util.module_from_spec(spec)
        loader.exec_module(backend)
        namespace = "gallery-" + str(os.getpid())
        with (work / "render.log").open("w") as log:
            daemon = subprocess.Popen(["awww-daemon", "--no-cache", "--namespace", namespace], env=env, stdout=log, stderr=log)
            bar = None
            try:
                time.sleep(.4)
                for name in selected:
                    folder = ROOT / "dotfiles/waybar/themes" / name
                    wallpaper = next(p for p in (ROOT / "assets/wallpapers/cyber" / catalog[name]["wallpaper"], ROOT / "dotfiles/wallpapers" / catalog[name]["wallpaper"]) if p.is_file())
                    run("awww", "img", "--namespace", namespace, "--outputs", "HEADLESS-1", "--transition-type", "none", str(wallpaper), env=env, stdout=log, stderr=log)
                    bars, replacements = sample_config(backend.config(folder / "config.jsonc", monitors))
                    config = work / "config.json"
                    config.write_text(json.dumps(bars, ensure_ascii=False))
                    css = (folder / "style.css").read_text()
                    for key, value in replacements.items():
                        css = css.replace("#" + key, "#" + value.replace("/", "-"))
                    css = css.replace('url("assets/', 'url("' + str(folder / "assets") + '/')
                    style = work / "style.css"
                    style.write_text(css)
                    bar = subprocess.Popen(["waybar", "-c", str(config), "-s", str(style)], env=env, stdout=log, stderr=log)
                    time.sleep(.65)
                    if bar.poll() is not None:
                        raise RuntimeError("Waybar no abrió: " + log.name)
                    raw = work / "desktop.png"
                    run("grim", "-o", "HEADLESS-1", str(raw), env=env)
                    run("magick", str(raw), "-resize", "1280x720", "-quality", "85", str(args.output / (name + ".webp")), env=env)
                    bar.terminate()
                    bar.wait(timeout=5)
                    bar = None
                    print(name, flush=True)
                log.flush()
                issues = [s for s in (work / "render.log").read_text().splitlines() if "[error]" in s.lower()]
                if issues:
                    raise RuntimeError("Errores durante la galería: " + "\n".join(issues[:8]))
            finally:
                if bar is not None:
                    bar.terminate()
                    bar.wait(timeout=5)
                daemon.terminate()
                daemon.wait(timeout=5)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
