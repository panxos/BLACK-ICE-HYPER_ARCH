"""Selecciona la corrección local únicamente para Conky 1.25.2."""
from __future__ import annotations

import hashlib
import json
import os
import subprocess
from pathlib import Path


def selected(root: Path | None = None) -> str:
    root = root or Path.home() / ".local/libexec/black-ice/conky-wayland"
    package = subprocess.run(["pacman", "-Q", "conky"], capture_output=True, text=True, timeout=3, check=False)
    if package.returncode or not package.stdout.startswith("conky 1.25.2-"):
        return "conky"
    binary = root / "bin/conky"
    try:
        record = json.loads((root / "manifest.json").read_text())
        if record["package"] != package.stdout.strip() or record["version"] != "1.25.3":
            raise ValueError("La corrección pertenece a otra versión")
        for relative, expected in record["files"].items():
            path = root / relative
            if not path.resolve().is_relative_to(root.resolve()) or path.is_symlink():
                raise ValueError("Recurso fuera de la corrección local")
            with path.open("rb") as stream:
                if hashlib.file_digest(stream, "sha256").hexdigest() != expected:
                    raise ValueError("La corrección local cambió")
        if "bin/conky" not in record["files"] or not os.access(binary, os.X_OK):
            raise ValueError("Falta el ejecutable verificado")
        subprocess.run([str(binary), "--version"], capture_output=True, timeout=3, check=True)
        return str(binary)
    except (OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError) as error:
        raise RuntimeError("Conky 1.25.2 falla en Wayland. Ejecuta scripts/build-conky-wayland.py --apply o instala una versión corregida.") from error
