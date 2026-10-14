#!/usr/bin/env python3
"""Verifica archivos publicables, enlaces locales y correspondencia de la galería."""
from __future__ import annotations

import json
import re
import subprocess
import unicodedata
from pathlib import Path
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    output = subprocess.check_output(["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"], cwd=ROOT)
    names = set(output.decode().strip("\0").split("\0"))
    paths = [ROOT / name for name in sorted(names) if (ROOT / name).is_file()]
    problems = []
    for path in paths:
        name = str(path.relative_to(ROOT))
        if any(ord(c) < 32 for c in name) or unicodedata.normalize("NFC", name) != name:
            problems.append("Nombre inválido: " + name)
        if path.is_symlink() and not path.resolve().is_relative_to(ROOT):
            problems.append("Enlace fuera del proyecto: " + name)
        if path.suffix != ".md":
            continue
        for match in re.finditer(r'!?\[[^\]]*\]\(([^)]+)\)', path.read_text()):
            url = match[1].split(' "')[0].strip("<>")
            if "://" in url or url.startswith(("#", "mailto:")):
                continue
            target = (path.parent / unquote(url.split("#")[0])).resolve()
            if not target.is_relative_to(ROOT) or str(target.relative_to(ROOT)) not in names:
                problems.append(f"Enlace fuera de la distribución: {name} → {url}")
    tracked = subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT)
    ignored = subprocess.run(["git", "check-ignore", "--no-index", "-z", "--stdin"], input=tracked, cwd=ROOT, capture_output=True, check=False)
    if ignored.returncode not in (0, 1):
        raise RuntimeError(ignored.stderr.decode())
    for name in ignored.stdout.decode().strip("\0").split("\0"):
        if name and (ROOT / name).exists():
            problems.append("Archivo seguido por Git pero excluido: " + name)
    catalog = json.loads((ROOT / "dotfiles/waybar/cyber-catalog.json").read_text())
    gallery = {p.stem for p in (ROOT / "docs/images/themes").glob("*.webp")}
    if gallery != set(catalog):
        problems.append("Galería y catálogo no coinciden")
    for problem in problems:
        print(problem)
    print(f"Distribución: {len(paths)} archivos; {len(catalog)} temas; {len(problems)} problemas.")
    return 1 if problems else 0


if __name__ == "__main__":
    raise SystemExit(main())
