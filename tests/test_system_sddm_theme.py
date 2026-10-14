"""Validación del helper de instalación de temas SDDM."""
import importlib.util
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("system_sddm_theme", ROOT / "scripts/system-sddm-theme.py")
helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)


class SddmThemeTests(unittest.TestCase):
    def setUp(self):
        parent = Path.home() / ".cache/tmp/work"
        parent.mkdir(parents=True, exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(dir=parent)
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.home = self.base / "home/benjie"
        self.preview = self.home / ".cache/black-ice/theme-studio/sddm-apply"
        self.preview.mkdir(parents=True)
        (self.preview / "Main.qml").write_text("user preview is not installed\n")
        (self.preview / "background.png").write_bytes(b"image fixture")
        (self.preview / "theme.conf").write_text(
            "[General]\nbackground=background.png\nbackgroundMode=auto\nbackgroundAnchor=center\n"
            "accent=#27c6ed\nsecondary=#ae90e8\nforeground=#e6edf3\nmuted=#a4b5c2\n"
            "surface=#0c1118\nfont=Rajdhani\nbodyFont=Roboto\nshowAvatar=true\n"
        )
        self.source = self.base / "system/black-ice-obsidian"
        self.source.mkdir(parents=True)
        (self.source / "Main.qml").write_text("trusted template\n")
        (self.source / "theme.conf").write_text("[General]\nbackground=assets/wallpaper.png\n")
        self.target_root = self.base / "system"
        self.target = self.target_root / "black-ice-personal"
        self.config = self.base / "etc/theme.conf"
        self.config.parent.mkdir(parents=True)
        self.config.write_text("[Theme]\nCurrent=black-ice-obsidian\n")
        self.other_config = self.base / "etc/zz-theme.conf"
        self.backup = self.base / "var/lib/black-ice/sddm-original.json"
        self.patches = [
            patch.object(helper, "ROOT", self.target_root),
            patch.object(helper, "SOURCE", self.source),
            patch.object(helper, "TARGET", self.target),
            patch.object(helper, "CONFIGS", (self.config, self.other_config, self.base / "etc/missing.conf")),
            patch.object(helper, "BACKUP", self.backup),
            patch.object(helper.pwd, "getpwuid", return_value=SimpleNamespace(pw_dir=str(self.home))),
        ]
        for item in self.patches:
            item.start()
            self.addCleanup(item.stop)

    def test_install_uses_root_template_and_applies_selected_colors_and_background(self):
        helper.install(self.preview, 1000)
        self.assertEqual((self.target / "Main.qml").read_text(), "trusted template\n")
        self.assertEqual((self.target / "background.png").read_bytes(), b"image fixture")
        self.assertIn("accent = #27c6ed", (self.target / "theme.conf").read_text())
        self.assertIn("Current=black-ice-personal", self.config.read_text())
        self.assertTrue(self.backup.is_file())

    def test_rejects_unapproved_sddm_options(self):
        (self.preview / "theme.conf").write_text("[General]\nExecStart=/tmp/anything\n")
        with self.assertRaisesRegex(ValueError, "no permitidas"):
            helper.validate_config(self.preview)

    def test_rejects_symlinked_preview(self):
        link = self.home / ".cache/black-ice/theme-studio/sddm-apply-link"
        link.symlink_to(self.preview, target_is_directory=True)
        with self.assertRaisesRegex(ValueError, "vista previa SDDM"):
            helper.preview_for_uid(link, 1000)


if __name__ == "__main__":
    unittest.main()
