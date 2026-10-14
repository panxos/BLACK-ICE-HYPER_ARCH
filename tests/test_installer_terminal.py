"""Selección real en PTY y vista previa sin operaciones del instalador."""
import errno
import fcntl
import os
import pty
import re
import select
import struct
import subprocess
import sys
import tempfile
import termios
import time
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ANSI = re.compile(r"\x1b\[[0-9;]*[A-Za-z]")


class InstallerTerminalTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(dir=Path.home() / ".cache/tmp/work")
        self.addCleanup(self.temp.cleanup)
        self.work = Path(self.temp.name)

    def terminal(self, command, answers, columns=80, **settings):
        env = {**os.environ, "HOME": str(self.work / "home"), "XDG_STATE_HOME": str(self.work / "state"),
               "XDG_CACHE_HOME": str(self.work / "cache"), "TERM": "xterm-256color", "COLUMNS": str(columns),
               "LC_ALL": "C.UTF-8", "LANG": "C.UTF-8"}
        env.pop("NO_COLOR", None)
        env.update(settings)
        master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 48, columns, 0, 0))

        launcher = 'import fcntl, os, sys, termios; fcntl.ioctl(0, termios.TIOCSCTTY, 0); os.execvp(sys.argv[1], sys.argv[1:])'
        process = subprocess.Popen([sys.executable, "-c", launcher, *command], stdin=slave, stdout=slave, stderr=slave,
                                   env=env, start_new_session=True)
        os.close(slave)
        data = b""
        sent = 0
        deadline = time.monotonic() + 10
        try:
            while time.monotonic() < deadline:
                if select.select([master], [], [], 0.05)[0]:
                    try:
                        block = os.read(master, 65536)
                    except OSError as error:
                        if error.errno == errno.EIO:
                            break
                        raise
                    if not block:
                        break
                    data += block
                    if data.count(b"Opcion [") + data.count("Opción [".encode()) > sent and sent < len(answers):
                        os.write(master, answers[sent])
                        sent += 1
                elif process.poll() is not None:
                    break
            else:
                self.fail("El terminal no terminó: " + data.decode(errors="replace")[-1000:])
            return process.wait(timeout=2), data.decode().replace("\r\n", "\n")
        finally:
            if process.poll() is None:
                process.kill()
            process.wait()
            os.close(master)

    def selection(self, answers, **settings):
        code = '''set -euo pipefail
source "$1/src/lib/logging.sh"
source "$1/src/lib/utils.sh"
choice=$(ask_option 'Selecciona región' Chile 'United States' Spain)
printf 'RESULT=%s\\n' "$choice"
'''
        return self.terminal(["bash", "-c", code, "test", str(ROOT)], answers, **settings)

    def test_selection_returns_only_exact_value_after_invalid_answers(self):
        status, value = self.selection([b"0\n", b"999999\n", b"text\n", b"02\n"])
        self.assertEqual(status, 0, value)
        self.assertIn("RESULT=United States\n", value)
        self.assertEqual(value.count("Elige un número entre 1 y 3."), 3)
        self.assertNotIn("RESULT=  ", value)

    def test_eof_cancels_without_selecting_first_option(self):
        status, value = self.selection([b"\x04"])
        self.assertNotEqual(status, 0, value)
        self.assertNotIn("RESULT=", value)

    def test_preview_completes_without_state_or_config_writes(self):
        status, value = self.terminal(["bash", str(ROOT / "install.sh"), "--preview"], [b"1\n", b"2\n"])
        self.assertEqual(status, 0, value)
        self.assertIn("VISTA PREVIA", value)
        self.assertIn("Región de demostración: Chile", value)
        self.assertIn("Sistema de archivos de demostración: ext4", value)
        self.assertIn("FIN DE LA VISTA PREVIA", value)
        self.assertIn("\x1b[2J\x1b[H", value)
        self.assertFalse((self.work / "state").exists())
        self.assertFalse((self.work / "home").exists())
        self.assertFalse((self.work / "cache").exists())

    def test_plain_terminal_preview_retains_linear_output(self):
        status, value = self.terminal(["bash", str(ROOT / "install.sh"), "--preview"], [b"1\n", b"1\n"], NO_COLOR="")
        self.assertEqual(status, 0, value)
        self.assertNotIn("\x1b", value)
        self.assertIn("no modifica el sistema", value)

    def test_menu_and_sections_fit_narrow_and_wide_terminals(self):
        code = '''set -euo pipefail
source "$1/src/lib/terminal-ui.sh"
black_ice_stage 7 'Arranque del sistema y configuración de firmware'
black_ice_menu 'Selecciona una opción con descripción larga' 'Opción internacional con letras áéíóú y un texto extenso' 'Alternativa'
black_ice_status ERROR 'Mensaje largo de error para verificar el salto de línea correcto'
black_ice_notice /dev/nvme0n1
'''
        for columns in (1, 12, 20, 40, 80, 120):
            with self.subTest(columns=columns):
                status, value = self.terminal(["bash", "-c", code, "test", str(ROOT)], [], columns=columns)
                self.assertEqual(status, 0, value)
                plain = ANSI.sub("", value)
                self.assertTrue(all(len(line) <= columns for line in plain.splitlines()), plain)

    def test_logs_strip_literal_and_actual_color_codes(self):
        env = {**os.environ, "XDG_STATE_HOME": str(self.work / "state")}
        subprocess.run(["bash", "-c", 'source "$1/src/lib/logging.sh"; log_info "${NEON_BLUE}Mensaje${NC}"; log_success "$2"',
                        "test", str(ROOT), "\x1b[36mListo\x1b[0m"], env=env, capture_output=True, check=True)
        log = next((self.work / "state/black-ice/logs").glob("*.log")).read_text()
        self.assertNotIn("\x1b", log)
        self.assertNotIn("\\033", log)
        self.assertIn("[SUCCESS] Listo", log)


if __name__ == "__main__":
    unittest.main()
