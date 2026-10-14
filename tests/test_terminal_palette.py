import os
import re
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class TerminalPaletteTests(unittest.TestCase):
    @unittest.skipUnless(shutil.which("zsh") and shutil.which("lsd"), "Requiere zsh y lsd")
    def test_file_listing_uses_terminal_palette_with_and_without_powerlevel(self):
        work = Path.home() / ".cache/tmp/work"
        work.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix="terminal-palette-", dir=work) as directory:
            root = Path(directory)
            (root / "Benjie").mkdir()
            (root / "Apolo.txt").write_text("prueba\n")
            (root / "Almendra.sh").write_text("#!/bin/sh\n")
            (root / "Almendra.sh").chmod(0o755)
            script = 'source "$1"; lsd --ignore-config --color always --icon never --hyperlink never "$2"'
            environment = {key:value for key,value in os.environ.items() if key != "NO_COLOR"}
            for powerlevel in (False, True):
                with self.subTest(powerlevel=powerlevel):
                    prefix = 'p10k() { :; }; ' if powerlevel else ''
                    result = subprocess.run(["zsh", "-dfi", "-c", prefix + script, "review",
                                             str(ROOT / "dotfiles/zsh/black-ice-prompt.zsh"), str(root)],
                                            env=environment, capture_output=True, text=True, check=True, timeout=5)
                    self.assertIn("Benjie", result.stdout)
                    colors = [int(v) for v in re.findall(r"38;5;(\d+)", result.stdout)]
                    self.assertTrue(all(value < 16 for value in colors), colors)
                    self.assertNotIn("38;2;", result.stdout)
                    self.assertRegex(result.stdout, r"\x1b\[(?:0;)?(?:34|38;5;4)m")
