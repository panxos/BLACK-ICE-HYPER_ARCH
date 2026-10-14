"""Verifica selección y rutas sin iniciar ni detener procesos del escritorio."""
import os
import subprocess
import tempfile
import time
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TEMP_ROOT = Path(os.environ.get("BLACK_ICE_TEST_TMP", Path.home() / ".cache/tmp"))


class WaybarStartTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(dir=TEMP_ROOT)
        self.addCleanup(self.temporary.cleanup)
        self.home = Path(self.temporary.name)
        self.base = self.home / ".config/waybar"
        self.bin = self.home / "bin"
        self.bin.mkdir()
        for name in ("Emilia-Angular", "Sekhmet-Angular", "Horus-Cyber"):
            directory = self.base / "themes" / name
            (directory / "assets").mkdir(parents=True)
            (directory / "config.jsonc").write_text("{}")
            (directory / "style.css").write_text("/* theme */")
        scripts = {"pkill": "exit 1", "pgrep": "exit 1", "waybar": 'printf "%s\\n" "$@" > "$HOME/arguments"'}
        for name, script in scripts.items():
            path = self.bin / name
            path.write_text("#!/bin/sh\n" + script + "\n")
            path.chmod(0o755)
        self.env = {**os.environ, "HOME": str(self.home), "XDG_CONFIG_HOME": str(self.home / ".config"),
                    "XDG_RUNTIME_DIR": str(self.home), "PATH": str(self.bin) + ":" + os.environ["PATH"]}
        self.env.pop("HYPRLAND_INSTANCE_SIGNATURE", None)

    def run_launcher(self, *args):
        arguments = self.home / "arguments"
        arguments.unlink(missing_ok=True)
        result = subprocess.run(["bash", str(ROOT / "dotfiles/bin/waybar_start.sh"), *args],
                                env=self.env, capture_output=True, text=True, timeout=5, check=False)
        if result.returncode == 0:
            for _ in range(100):
                if arguments.exists() and arguments.read_text().strip():
                    break
                time.sleep(0.01)
            else:
                self.fail("Waybar no recibió los argumentos del lanzador")
        return result

    def test_explicit_theme_uses_real_paths_and_persists(self):
        result = self.run_launcher("Sekhmet-Angular")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.home / "arguments").read_text().splitlines(),
                         ["-c", str(self.base / "themes/Sekhmet-Angular/config.jsonc"),
                          "-s", str(self.base / "themes/Sekhmet-Angular/style.css")])
        self.assertEqual((self.base / "default_theme").read_text().strip(), "Sekhmet-Angular")
        self.assertEqual((self.base / "assets").resolve(), self.base / "themes/Sekhmet-Angular/assets")
        self.assertEqual((self.base / "style.css").resolve(), self.base / "themes/Sekhmet-Angular/style.css")

    def test_saved_theme_survives_new_start(self):
        self.assertEqual(self.run_launcher("Emilia-Angular").returncode, 0)
        self.assertEqual(self.run_launcher().returncode, 0)
        self.assertEqual((self.base / "default_theme").read_text().strip(), "Emilia-Angular")

    def test_hyprland_owns_bar_instead_of_applying_terminal(self):
        helper = self.bin / "hyprctl"
        helper.write_text('#!/bin/sh\n[ "$1" = dispatch ] && [ "$2" = exec ] || exit 2\nprintf "%s" "$3" > "$HOME/dispatch"\nsh -c "$3"\n')
        helper.chmod(0o755)
        self.env["HYPRLAND_INSTANCE_SIGNATURE"] = "review-session"
        result = self.run_launcher("Emilia-Angular")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.home / "dispatch").read_text().startswith("exec waybar -c "))
        self.assertEqual((self.home / "arguments").read_text().splitlines(),
                         ["-c", str(self.base / "themes/Emilia-Angular/config.jsonc"),
                          "-s", str(self.base / "themes/Emilia-Angular/style.css")])

    def test_asset_alias_changes_with_theme(self):
        self.run_launcher("Emilia-Angular")
        self.run_launcher("Sekhmet-Angular")
        self.assertEqual((self.base / "assets").resolve(), self.base / "themes/Sekhmet-Angular/assets")

    def test_personal_asset_directory_is_preserved(self):
        (self.base / "assets").mkdir()
        (self.base / "assets/personal.txt").write_text("original")
        self.run_launcher("Emilia-Angular")
        self.assertEqual((self.base / "assets/personal.txt").read_text(), "original")

    def test_invalid_explicit_theme_does_not_change_selection(self):
        self.run_launcher("Emilia-Angular")
        self.assertNotEqual(self.run_launcher("../outside").returncode, 0)
        self.assertEqual((self.base / "default_theme").read_text().strip(), "Emilia-Angular")

    def test_invalid_css_is_rejected_before_stopping_current_bar(self):
        self.run_launcher("Emilia-Angular")
        helper = self.home / ".local/bin/black-ice-waybar"
        helper.parent.mkdir(parents=True)
        helper.write_text("#!/bin/sh\nexit 1\n")
        helper.chmod(0o755)
        result = self.run_launcher("Sekhmet-Angular")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual((self.base / "default_theme").read_text().strip(), "Emilia-Angular")
        self.assertEqual((self.base / "style.css").resolve(), self.base / "themes/Emilia-Angular/style.css")

    def test_corrupt_saved_name_uses_valid_stylesheet_link(self):
        (self.base / "default_theme").write_text("../outside\n")
        (self.base / "style.css").symlink_to(self.base / "themes/Emilia-Angular/style.css")
        result = self.run_launcher()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.base / "default_theme").read_text().strip(), "Emilia-Angular")


if __name__ == "__main__":
    unittest.main()
