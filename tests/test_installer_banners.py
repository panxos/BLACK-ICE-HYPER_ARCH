"""Cabeceras seguras en TTY, redirección y bootstrap autónomo."""
import errno
import os
import pty
import re
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ANSI = re.compile(r"\x1b\[[0-9;]*m")


class BannerTests(unittest.TestCase):
    def setUp(self):
        parent = Path.home() / ".cache/tmp/work"
        parent.mkdir(parents=True, exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(dir=parent)
        self.addCleanup(self.temp.cleanup)
        self.work = Path(self.temp.name)

    def render(self, columns=80, tty=False, **settings):
        env = {**os.environ, "COLUMNS": str(columns), "LANG": "C.UTF-8", "LC_ALL": "C.UTF-8", "TERM": "xterm-256color"}
        env.pop("NO_COLOR", None)
        env.update(settings)
        command = ["bash", "-c", 'set -euo pipefail; source "$1"; black_ice_banner "$2" "$3" "$4"', "banner",
                   str(ROOT / "src/lib/banner.sh"), "INSTALACIÓN BASE", "Discos / cifrado / " + "texto " * 20, "4.0.0-dev.2"]
        if not tty:
            return subprocess.check_output(command, env=env, text=True, timeout=5)
        return self.terminal(command, env)

    def terminal(self, command, env):
        master, slave = pty.openpty()
        try:
            result = subprocess.run(command, env=env, stdout=slave, stderr=slave, check=False, timeout=5)
            os.close(slave)
            slave = None
            data = b""
            while True:
                try:
                    block = os.read(master, 8192)
                except OSError as error:
                    if error.errno == errno.EIO:
                        break
                    raise
                if not block:
                    break
                data += block
            self.assertEqual(result.returncode, 0, data.decode())
            return data.decode().replace("\r\n", "\n")
        finally:
            os.close(master)
            if slave is not None:
                os.close(slave)

    def test_width_long_text_and_no_terminal_clear(self):
        for columns in (1, 12, 20, 40, 80, 120):
            with self.subTest(columns=columns):
                value = self.render(columns)
                self.assertNotIn("\x1b", value)
                self.assertTrue(all(len(line) <= columns for line in value.splitlines()), value)
                if columns >= 20:
                    self.assertEqual(len({len(line) for line in value.splitlines() if line}), 1)

    def test_tty_color_no_color_and_dumb_terminal(self):
        colored = self.render(40, tty=True)
        self.assertIn("\x1b[36m", colored)
        self.assertNotIn("\x1b[2J", colored)
        self.assertTrue(all(len(ANSI.sub("", line)) <= 40 for line in colored.splitlines()))
        self.assertNotIn("\x1b", self.render(40, tty=True, NO_COLOR=""))
        self.assertNotIn("\x1b", self.render(40, tty=True, TERM="dumb"))

    def test_ascii_borders_and_invalid_width(self):
        value = self.render(40, LC_ALL="C", LANG="C")
        self.assertIn("+", value)
        self.assertNotIn("┌", value)
        self.assertIn("BLACK-ICE / ARCH", self.render("invalid"))

    def test_preview_of_all_entrypoints_has_no_installer_side_effects(self):
        env = {**os.environ, "HOME": str(self.work / "home"), "XDG_STATE_HOME": str(self.work / "state"),
               "XDG_CACHE_HOME": str(self.work / "cache"), "COLUMNS": "40", "TERM": "dumb"}
        for name in ("bootstrap.sh", "install.sh", "deploy_hyprland.sh"):
            result = subprocess.run(["bash", str(ROOT / name), "--banner"], env=env, capture_output=True, text=True, check=True, timeout=5)
            self.assertIn("BLACK-ICE / ARCH", result.stdout)
            self.assertNotIn("\x1b", result.stdout)
        self.assertFalse((self.work / "state").exists())
        self.assertFalse((self.work / "cache").exists())

    def test_downloaded_bootstrap_works_without_repository_or_term(self):
        standalone = self.work / "bootstrap.sh"
        shutil.copyfile(ROOT / "bootstrap.sh", standalone)
        env = {**os.environ, "COLUMNS": "20", "XDG_CACHE_HOME": str(self.work / "cache")}
        env.pop("TERM", None)
        value = subprocess.check_output(["bash", str(standalone), "--banner"], env=env, text=True, timeout=5)
        self.assertIn("BLACK-ICE / ARCH", value)
        self.assertTrue(all(len(line) <= 20 for line in value.splitlines()))
        self.assertFalse((self.work / "cache").exists())

    def test_input_control_characters_are_not_executed(self):
        env = {**os.environ, "COLUMNS": "80", "TERM": "dumb"}
        value = subprocess.check_output(["bash", "-c", 'source "$1"; black_ice_banner "$2" "$3" 4.0', "banner",
                                         str(ROOT / "src/lib/banner.sh"), "\x1b[2Jtitle\rnext", "%s\\n"], env=env, text=True, timeout=5)
        self.assertNotIn("\x1b", value)
        self.assertIn("%s\\n", value)

    def test_tee_preserves_header_once_in_terminal_and_plain_log(self):
        env = {**os.environ, "COLUMNS": "80", "TERM": "xterm-256color", "LC_ALL": "C.UTF-8",
               "XDG_STATE_HOME": str(self.work / "state")}
        env.pop("NO_COLOR", None)
        code = '''set -euo pipefail
source "$1"
exec 3>&1
exec > >(tee -a "$LOG_FILE")
printf 'ANTES\\n'
banner 'INSTALACIÓN BASE' 'Discos y arranque'
printf 'DESPUÉS\\n'
exec 1>&3
wait
'''
        value = self.terminal(["bash", "-c", code, "banner", str(ROOT / "src/lib/logging.sh")], env)
        self.assertEqual(value.count("BLACK-ICE / ARCH"), 1)
        log = next((self.work / "state/black-ice/logs").glob("*.log")).read_text()
        self.assertEqual(log.count("BLACK-ICE / ARCH"), 1)
        self.assertNotIn("\x1b", log)
        self.assertIn("ANTES", log)
        self.assertIn("DESPUÉS", log)


if __name__ == "__main__":
    unittest.main()
