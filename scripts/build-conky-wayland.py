#!/usr/bin/env python3
"""Compila Conky 1.25.3 local para evitar el fallo Wayland de 1.25.2."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tarfile
import tempfile
import urllib.request
from pathlib import Path

VERSION = "1.25.3"
SOURCE_HASH = "a374fdf62cb701abda200692a7ac077a8d4a4d252953a1397a989cd626c48d68"
DESTINATION = Path.home() / ".local/libexec/black-ice/conky-wayland"


def manifest(package: str) -> None:
    files = {}
    for path in DESTINATION.rglob("*"):
        if path.is_file() and path.name != "manifest.json":
            with path.open("rb") as stream:
                files[str(path.relative_to(DESTINATION))] = hashlib.file_digest(stream, "sha256").hexdigest()
    temporary = DESTINATION / ".manifest-new"
    temporary.write_text(json.dumps({"package": package, "version": VERSION,
                                    "source_sha256": SOURCE_HASH, "files": files}, indent=2) + "\n")
    temporary.replace(DESTINATION / "manifest.json")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    package = subprocess.run(["pacman", "-Q", "conky"], capture_output=True, text=True, check=True, timeout=5).stdout.strip()
    if not package.startswith("conky 1.25.2-"):
        print("El paquete no corresponde a la regresión 1.25.2; se conserva Conky del sistema.")
        return 0
    if not args.apply:
        print("Compilaría Conky " + VERSION + " en " + str(DESTINATION) + "; paquete original intacto.")
        return 0
    sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "dotfiles/bin"))
    from black_ice_conky_binary import selected
    try:
        if selected(DESTINATION) != "conky":
            print("Conky corregido ya está instalado y sus hashes coinciden.")
            return 0
    except RuntimeError:
        pass
    for name in ("cmake", "ninja", "g++", "pkg-config", "gperf"):
        if not shutil.which(name):
            parser.error("Falta dependencia de compilación: " + name)
    parent = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "tmp/work"
    parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="conky-wayland-", dir=parent) as directory:
        work = Path(directory)
        with urllib.request.urlopen("https://codeload.github.com/brndnmtthws/conky/tar.gz/refs/tags/v" + VERSION, timeout=30) as response:
            body = response.read(8 * 1024 * 1024 + 1)
        if hashlib.sha256(body).hexdigest() != SOURCE_HASH:
            raise ValueError("La fuente no coincide con el SHA-256 fijado")
        archive = work / "source.tar.gz"
        archive.write_bytes(body)
        with tarfile.open(archive) as bundle:
            bundle.extractall(work, filter="data")
        include = subprocess.check_output(["pkg-config", "--variable=includedir", "lua54"], text=True, timeout=5).strip()
        libdir = subprocess.check_output(["pkg-config", "--variable=libdir", "lua54"], text=True, timeout=5).strip()
        build = work / "build"
        subprocess.run(["cmake", "-S", str(work / ("conky-" + VERSION)), "-B", str(build), "-G", "Ninja",
                        "-DCMAKE_BUILD_TYPE=Release", "-DBUILD_TESTING=OFF", "-DBUILD_DOCS=OFF",
                        "-DBUILD_WAYLAND=ON", "-DBUILD_LUA_CAIRO=ON", "-DBUILD_LUA_IMLIB2=ON", "-DBUILD_LUA_RSVG=ON",
                        "-DLUA_INCLUDE_DIR=" + include, "-DLUA_LIBRARY=" + libdir + "/liblua5.4.so",
                        "-DCMAKE_INSTALL_PREFIX=" + str(DESTINATION)], check=True)
        subprocess.run(["nice", "-n", "10", "ninja", "-C", str(build), "-j", "2"], check=True)
        subprocess.run(["cmake", "--install", str(build)], check=True)
        subprocess.run([str(DESTINATION / "bin/conky"), "--version"], check=True, timeout=5)
        manifest(package)
    print("Conky corregido instalado; no se reinició el escritorio.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
