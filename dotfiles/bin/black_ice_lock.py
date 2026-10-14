"""Fondos Hyprlock derivados de los recortes del escritorio."""
from __future__ import annotations

import re
from pathlib import Path

START = "# BLACK-ICE OUTPUT BACKGROUNDS BEGIN"
END = "# BLACK-ICE OUTPUT BACKGROUNDS END"


def backgrounds(content: str, state: dict, wallpaper: Path) -> str:
    content = re.sub(r"\n" + re.escape(START) + r".*?" + re.escape(END), "", content, flags=re.DOTALL)
    match = re.search(r"(?m)^background\s*\{[^}]*\}", content)
    if not match or state.get("wallpaper") != str(wallpaper.resolve()):
        return content
    blocks = []
    for item in state.get("outputs", []):
        output, rendered = item.get("output", ""), item.get("rendered", "")
        if not re.fullmatch(r"[A-Za-z0-9_.:-]{1,128}", output) or not rendered or any(c in rendered for c in "\n\r\x00"):
            continue
        path = Path(rendered)
        if not path.is_file():
            continue
        block = re.sub(r"(?m)^\s*monitor\s*=.*$", "    monitor = " + output, match[0])
        block = re.sub(r"(?m)^\s*path\s*=.*$", lambda _, path=path: "    path = " + str(path), block)
        block = re.sub(r"(?m)^\s*zindex\s*=.*$", "", block)
        blocks.append(block[:-1].rstrip() + "\n    zindex = -1\n}")
    if not blocks:
        return content
    fallback = re.sub(r"(?m)^\s*zindex\s*=.*$", "", match[0])
    fallback = fallback[:-1].rstrip() + "\n    zindex = -2\n}"
    extra = "\n" + START + "\n" + "\n\n".join(blocks) + "\n" + END
    return content[:match.start()] + fallback + extra + content[match.end():]


def update(path: Path, state: dict, wallpaper: Path, atomic) -> None:
    if not path.is_file():
        return
    content = path.read_text()
    if not content.startswith("# BLACK-ICE ARCH — bloqueo Obsidiana"):
        return
    atomic(path, backgrounds(content, state, wallpaper))
