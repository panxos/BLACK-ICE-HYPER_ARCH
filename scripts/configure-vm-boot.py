#!/usr/bin/env python3
"""Conserva parámetros de arranque y retira el splash gráfico en VM."""
import argparse
import re
from pathlib import Path


def without_splash(text):
    line = re.compile(r"^(GRUB_CMDLINE_LINUX_DEFAULT=)([\"'])(.*)\2$", re.MULTILINE)
    match = line.search(text)
    if not match:
        raise ValueError("GRUB_CMDLINE_LINUX_DEFAULT no tiene un formato reconocido")
    value = match.group(3)
    tokens = re.compile(r'''(?:[^\s"'\\]|\\.|"(?:[^"\\]|\\.)*"|'[^']*')+''')
    for token in reversed(list(tokens.finditer(value))):
        if token.group() in {"quiet", "splash"}:
            value = value[:token.start()] + value[token.end():]
    replacement = match.group(1) + match.group(2) + value.strip() + match.group(2)
    return text[:match.start()] + replacement + text[match.end():]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("grub_config", type=Path)
    args = parser.parse_args()
    original = args.grub_config.read_text()
    updated = without_splash(original)
    if updated != original:
        args.grub_config.write_text(updated)
    print("Arranque de VM sin splash gráfico; parámetros restantes conservados.")


if __name__ == "__main__":
    main()
