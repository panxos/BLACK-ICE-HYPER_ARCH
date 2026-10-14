import hashlib
import importlib.util
import json
import shutil
import struct
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("agency", ROOT / "scripts/install-agency-themes.py")
agency = importlib.util.module_from_spec(spec)
spec.loader.exec_module(agency)


class AgencyThemesTests(unittest.TestCase):
    def setUp(self):
        work = Path.home() / ".cache/tmp/work"
        work.mkdir(parents=True, exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(prefix="agency-", dir=work)
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)

    def test_install_preserves_source_quality_and_never_selects_sddm(self):
        destination = self.directory / "themes"
        original = ROOT / "assets/sddm/themes/black-ice-obsidian/Main.qml"
        before = original.read_bytes()
        plan = agency.install(destination=destination, apply=True)
        self.assertEqual({i["name"] for i in plan}, {"FBI-Fieldwork", "NSA-Intercept", "MI5-Operations"})
        catalog = json.loads((ROOT / "dotfiles/waybar/cyber-catalog.json").read_text())
        presets = json.loads((ROOT / "assets/sddm/agency-presets.json").read_text())
        for item in plan:
            target = destination / item["theme"]
            source = ROOT / "assets/wallpapers/cyber" / catalog[item["name"]]["wallpaper"]
            self.assertEqual(hashlib.sha256((target / "assets/wallpaper.png").read_bytes()).digest(), hashlib.sha256(source.read_bytes()).digest())
            self.assertIn("title=" + item["name"].split("-")[0], (target / "theme.conf").read_text())
            self.assertTrue((target / "assets/fonts" / presets[item["name"]]["font_file"]).is_file())
            self.assertEqual((target / "Main.qml").stat().st_mode & 0o777, 0o644)
        self.assertFalse((self.directory / "etc").exists())
        self.assertEqual(original.read_bytes(), before)

    def test_rejects_destination_symlinks_before_installing_any_theme(self):
        destination = self.directory / "themes"
        destination.mkdir()
        outside = self.directory / "personal"
        outside.mkdir()
        (outside / "Main.qml").write_text("personal")
        (destination / "black-ice-mi5-operations").symlink_to(outside, target_is_directory=True)
        with self.assertRaisesRegex(ValueError, "enlaces simbólicos"):
            agency.install(destination=destination, apply=True)
        self.assertEqual((outside / "Main.qml").read_text(), "personal")
        self.assertFalse((destination / "black-ice-fbi-fieldwork").exists())

    def test_rejects_low_resolution_before_writing(self):
        source = self.directory / "source"
        for path in ("assets/sddm/agency-presets.json", "dotfiles/waybar/cyber-catalog.json"):
            (source / path).parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / path, source / path)
        catalog = json.loads((source / "dotfiles/waybar/cyber-catalog.json").read_text())
        shutil.copytree(ROOT / "assets/fonts/barlowcondensed", source / "assets/fonts/barlowcondensed")
        image = source / "assets/wallpapers/cyber" / catalog["FBI-Fieldwork"]["wallpaper"]
        image.parent.mkdir(parents=True)
        image.write_bytes(b"\x89PNG\r\n\x1a\n" + struct.pack(">I", 13) + b"IHDR" + struct.pack(">II", 1920, 1080))
        destination = self.directory / "themes"
        with self.assertRaisesRegex(ValueError, "3840"):
            agency.install(source, destination, apply=True)
        self.assertFalse(destination.exists())


if __name__ == "__main__":
    unittest.main()
