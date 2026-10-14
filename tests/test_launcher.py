import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "dotfiles/bin"))
import black_ice_launcher as launcher
import black_ice_theme as model


class LauncherTests(unittest.TestCase):
    def test_styles_follow_focused_monitor_and_palette_without_commands(self):
        with patch.object(launcher, "current", return_value="Anubis-Sethek"), patch.object(launcher, "CONFIG", ROOT / "dotfiles"):
            for style, columns in (("cinematic", 2), ("compact", 1), ("tiles", 3)):
                with self.subTest(style=style):
                    text = launcher.theme(style, [{"width": 3840, "height": 2160, "scale": 1},
                                                  {"width": 1280, "height": 720, "scale": 1.5, "focused": True}])
                    self.assertIn(f"columns:{columns};", text)
                    self.assertIn("width:805px;" if style != "compact" else "width:530px;", text)
                    self.assertIn("drun-display-format", text)
                    self.assertNotIn("exec", text)

    def test_selection_persists_and_rejects_invalid_style(self):
        with tempfile.TemporaryDirectory(dir=Path.home() / ".cache/tmp/work") as work, patch.object(launcher, "CONFIG", Path(work)):
            launcher.select("tiles")
            self.assertEqual(launcher.preferences(), {"style": "tiles"})
            with self.assertRaises(ValueError):
                launcher.select("../other")
            self.assertEqual(launcher.preferences()["style"], "tiles")


class PersonalThemeDeletionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(dir=Path.home() / ".cache/tmp/work")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.themes = self.root / "themes"
        self.themes.mkdir()
        self.name = "User-Benjie-aabbccdd"
        folder = self.themes / self.name
        folder.mkdir()
        (folder / "profile.json").write_text('{"name":"Benjie"}')
        (folder / "style.css").write_text("original")
        self.addCleanup(patch.stopall)
        patch.object(model, "ROOT", self.themes).start()
        patch.object(model, "current", return_value="Anubis-Sethek").start()
        patch.dict(os.environ, XDG_DATA_HOME=str(self.root / "data")).start()

    def test_delete_and_restore_preserve_bytes_and_external_wallpaper(self):
        wall = self.root / "wallpaper.png"
        wall.write_bytes(b"wallpaper")
        path = model.trash_theme(self.name)
        self.assertFalse((self.themes / self.name).exists())
        self.assertEqual((path / "style.css").read_text(), "original")
        self.assertEqual(model.restore_theme(path), self.name)
        self.assertTrue(wall.is_file())
        self.assertEqual((self.themes / self.name / "style.css").read_text(), "original")

    def test_original_active_and_symlink_are_protected(self):
        for name in ("Anubis-Sethek", "../User-test"):
            with self.assertRaises(ValueError):
                model.trash_theme(name)
        with patch.object(model, "current", return_value=self.name), self.assertRaises(ValueError):
            model.trash_theme(self.name)
        link = self.themes / "User-Link"
        link.symlink_to(self.themes / self.name, target_is_directory=True)
        with self.assertRaises(ValueError):
            model.trash_theme(link.name)
        self.assertTrue((self.themes / self.name).is_dir())

    def test_restore_never_overwrites_existing_profile(self):
        path = model.trash_theme(self.name)
        (self.themes / self.name).mkdir()
        with self.assertRaises(ValueError):
            model.restore_theme(path)
        self.assertTrue(path.is_dir())
