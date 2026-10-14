"""Inicialización XKB previa al greeter sin reemplazar Xsetup personalizado."""
import configparser
import importlib.util
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("sddm_keyboard", ROOT / "scripts/configure-sddm-keyboard.py")
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class SddmKeyboardTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(dir=Path.home() / ".cache/tmp/work")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def test_clean_install_sets_layout_before_greeter(self):
        result = MODULE.configure(self.root, "latam", True)
        self.assertTrue(result["applied"])
        script = self.root / MODULE.WRAPPER.lstrip("/")
        self.assertIn('/usr/share/sddm/scripts/Xsetup "$@"', script.read_text())
        self.assertIn("setxkbmap -layout latam", script.read_text())
        subprocess.run(["sh", "-n", str(script)], check=True)
        self.assertEqual(script.stat().st_mode & 0o777, 0o755)

    def test_custom_display_command_is_preserved(self):
        main = self.root / "etc/sddm.conf"
        main.parent.mkdir()
        original = "[X11]\nDisplayCommand=/usr/local/bin/personal-xsetup\n"
        main.write_text(original)
        self.assertFalse(MODULE.configure(self.root, "latam", True)["applied"])
        self.assertEqual(main.read_text(), original)
        self.assertFalse((self.root / MODULE.WRAPPER.lstrip("/")).exists())

    def test_main_override_retains_theme_and_updates_default(self):
        main = self.root / "etc/sddm.conf"
        main.parent.mkdir()
        main.write_text("[Theme]\nCurrent=anubis\n[X11]\ndisplaycommand=" + MODULE.VENDOR + "\n")
        MODULE.configure(self.root, "latam", True)
        MODULE.configure(self.root, "es", True)
        config = configparser.ConfigParser()
        config.read(main)
        self.assertEqual(config["Theme"]["Current"], "anubis")
        self.assertEqual(config["X11"]["DisplayCommand"], MODULE.WRAPPER)
        self.assertIn("setxkbmap -layout es", (self.root / MODULE.WRAPPER.lstrip("/")).read_text())

    def test_preview_writes_nothing_and_rejects_shell_input(self):
        self.assertFalse(MODULE.configure(self.root, "latam", False)["applied"])
        self.assertEqual(list(self.root.iterdir()), [])
        with self.assertRaises(ValueError):
            MODULE.configure(self.root, "latam;touch nope", True)


if __name__ == "__main__":
    unittest.main()
