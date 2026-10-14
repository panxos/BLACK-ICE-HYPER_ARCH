#!/usr/bin/env python3
"""Compila un backport local para el primer clic de Waybar 4e207a0."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import subprocess
import tarfile
import tempfile
import urllib.request
from pathlib import Path

COMMIT = "4e207a0cb51a9eb89b4245d90245721f5e39bf06"
SOURCE_HASH = "893c885a6005498e05e92c989579b3e6d83243261f8f34007131c3b8d6b22de4"
DESTINATION = Path.home() / ".local/libexec/black-ice/waybar-fast-ipc"
OLD = 'luaProto = isLuaConfigProvider(getSocket1Reply("systeminfo"));'
NEW = '''auto providerInfo = getSocket1Reply("status");
    if (providerInfo.find("configProvider:") == std::string::npos) {
      providerInfo = getSocket1Reply("systeminfo");
    }
    luaProto = isLuaConfigProvider(providerInfo);'''


def digest(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def publish(binary: Path, package: str) -> None:
    subprocess.run([str(binary), "--version"], check=True, timeout=5)
    record = {"package": package, "commit": COMMIT, "source_sha256": SOURCE_HASH,
              "patch_sha256": hashlib.sha256(NEW.encode()).hexdigest(), "binary_sha256": digest(binary)}
    DESTINATION.mkdir(parents=True, exist_ok=True)
    staged = DESTINATION / ".waybar-new"
    shutil.copyfile(binary, staged)
    staged.chmod(0o755)
    staged.replace(DESTINATION / "waybar")
    manifest = DESTINATION / ".manifest-new.json"
    manifest.write_text(json.dumps(record, indent=2) + "\n")
    manifest.replace(DESTINATION / "manifest.json")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="Compilar e instalar sin root; no reinicia la barra")
    args = parser.parse_args()
    package = subprocess.run(["pacman", "-Q", "waybar-git"], capture_output=True, text=True, check=False)
    if package.returncode or "g4e207a0-" not in package.stdout:
        parser.error("Backport limitado a waybar-git 4e207a0; utiliza el paquete del sistema")
    if not args.apply:
        print("Se compilaría la revisión " + COMMIT + " con consulta status y fallback antiguo.")
        print("Destino: " + str(DESTINATION) + "; sin reemplazar paquetes ni reiniciar Waybar.")
        return 0
    for name in ("meson", "ninja", "g++", "gdbus-codegen", "pkg-config"):
        if not shutil.which(name):
            parser.error("Falta dependencia de compilación: " + name)
    cache = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "tmp/work"
    cache.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="waybar-fast-ipc-", dir=cache) as temporary:
        work = Path(temporary)
        archive = work / "source.tar.gz"
        with urllib.request.urlopen("https://codeload.github.com/Alexays/Waybar/tar.gz/" + COMMIT, timeout=30) as response:
            body = response.read(2 * 1024 * 1024 + 1)
        if hashlib.sha256(body).hexdigest() != SOURCE_HASH:
            raise ValueError("Fuente no coincide con el SHA-256 fijado")
        archive.write_bytes(body)
        with tarfile.open(archive) as bundle:
            bundle.extractall(work, filter="data")
        source = work / ("Waybar-" + COMMIT)
        backend = source / "src/modules/hyprland/backend.cpp"
        content = backend.read_text()
        if content.count(OLD) != 1:
            raise ValueError("La fuente no contiene el bloque esperado; no se aplica el backport")
        backend.write_text(content.replace(OLD, NEW))
        build = work / "build"
        subprocess.run(["meson", "setup", str(build), str(source), "--wrap-mode=nofallback",
                        "-Dexperimental=true", "-Dtests=disabled", "-Dman-pages=disabled", "-Dsystemd=disabled", "-Dniri=false", "-Dmango=false"], check=True)
        subprocess.run(["nice", "-n", "10", "ninja", "-C", str(build), "-j", "2"], check=True)
        publish(build / "waybar", package.stdout.strip())
    print("Backport instalado. La barra actual no se reinició.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
