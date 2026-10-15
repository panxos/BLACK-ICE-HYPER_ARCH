import importlib.machinery
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "dotfiles/bin"))
loader = importlib.machinery.SourceFileLoader("wallpaper", str(ROOT / "dotfiles/bin/black-ice-wallpaper"))
spec = importlib.util.spec_from_loader(loader.name, loader)
wallpaper = importlib.util.module_from_spec(spec)
loader.exec_module(wallpaper)


def monitor(name, width=1920, height=1080, x=0, y=0, scale=1, transform=0):
    return {"name": name, "width": width, "height": height, "x": x, "y": y, "scale": scale, "transform": transform}


class WallpaperTests(unittest.TestCase):
    def test_reviewed_theme_panoramas_exist_and_select_by_screen_count(self):
        catalog = json.loads((ROOT / "dotfiles/waybar/cyber-catalog.json").read_text())
        names = ["Anubis-Sethek", "Kevin-Mitnick-Condor", "Kevin-Mitnick-Condor-Noir", "Mr-Robot", "Mr-Robot-Safehouse", "FBI-Fieldwork", "NSA-Intercept", "MI5-Operations", "H4k3r-HTB", "Obsidian-Cobalt",
                 "Brenda-Everforest", "Daniela-Catppuccin", "Emilia-Angular", "Emilia-TokyoNight", "Isabel-Frappe",
                 "Karla-ZombieNight", "Marisol-Dracula", "Melissa-Nord", "Pamela-Lovelace", "Silvia-Gruvbox",
                 "Varinka-Angular", "Varinka-Mono", "Yael-Angular", "Yael-OxoCarbon"]
        for name in names:
            with self.subTest(theme=name):
                profile = catalog[name]
                single = next((ROOT / folder / profile["wallpaper"] for folder in ("assets/wallpapers/cyber", "dotfiles/wallpapers")
                               if (ROOT / folder / profile["wallpaper"]).is_file()), ROOT / profile["wallpaper"])
                panorama = ROOT / "assets/wallpapers/cyber" / profile["panorama"]
                self.assertTrue(single.is_file())
                self.assertTrue(panorama.is_file())
                self.assertEqual(wallpaper.plan([monitor("one")], single, panorama)[0]["source"], str(single))
                for count in (2, 3):
                    items = wallpaper.plan([monitor(str(i), x=i * 1920) for i in range(count)], single, panorama)
                    self.assertTrue(all(i["source"] == str(panorama) and i["panoramic"] for i in items))
                    self.assertEqual([i["viewport"][0] for i in items], [i * 1920 for i in range(count)])

    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.single = self.root / "single.png"
        self.panorama = self.root / "panorama.png"
        self.single.touch()
        self.panorama.touch()

    def test_single_screen_keeps_canonical_background(self):
        items = wallpaper.plan([monitor("laptop", 1366, 768)], self.single, self.panorama)
        self.assertEqual(items[0]["source"], str(self.single))
        self.assertFalse(items[0]["panoramic"])

    def test_top_anchor_preserves_subject_near_upper_edge(self):
        import gi
        gi.require_version("GdkPixbuf", "2.0")
        from gi.repository import GdkPixbuf
        image = GdkPixbuf.Pixbuf.new(GdkPixbuf.Colorspace.RGB, False, 8, 100, 100)
        image.fill(0x0000ffff)
        image.new_subpixbuf(0, 0, 100, 30).fill(0xff0000ff)
        image.savev(str(self.panorama), "png", [], [])
        outputs = [monitor("left", 100, 50), monitor("right", 100, 50, x=100)]
        for anchor, expected in (("top", bytes([255, 0, 0])), ("center", bytes([0, 0, 255]))):
            item = wallpaper.plan(outputs, self.single, self.panorama, anchor=anchor)[0]
            rendered = self.root / (anchor + ".png")
            wallpaper.render(item, rendered)
            self.assertEqual(GdkPixbuf.Pixbuf.new_from_file(str(rendered)).get_pixels()[:3], expected)

    def test_two_aligned_screens_share_nonoverlapping_panorama(self):
        items = wallpaper.plan([monitor("left"), monitor("right", x=1920)], self.single, self.panorama)
        self.assertEqual([i["viewport"] for i in items], [[0, 0, 1920, 1080], [1920, 0, 1920, 1080]])
        self.assertTrue(all(i["source"] == str(self.panorama) and i["canvas"] == [3840, 1080] for i in items))

    def test_current_three_screen_geometry_keeps_laptop_independent(self):
        outputs = [monitor("eDP-1", 1366, 768, 2636, 1080), monitor("DP-3", x=1366), monitor("DP-5", x=3286)]
        items = {i["output"]: i for i in wallpaper.plan(outputs, self.single, self.panorama)}
        self.assertEqual(items["eDP-1"]["source"], str(self.single))
        self.assertEqual(items["DP-3"]["source"], str(self.panorama))
        self.assertEqual(items["DP-5"]["viewport"][0], 1920)

    def test_unified_scene_preserves_native_three_monitor_composition(self):
        outputs = [monitor("eDP-1", 1366, 768, 2636, 1080), monitor("DP-3", x=1366), monitor("DP-5", x=3286)]
        items = {i["output"]: i for i in wallpaper.plan(outputs, self.single, self.panorama, "scene")}
        self.assertTrue(all(i["canvas"] == [3840, 1848] and i["source"] == str(self.single) for i in items.values()))
        self.assertEqual(items["eDP-1"]["viewport"], [1270, 1080, 1366, 768])
        self.assertEqual(items["DP-3"]["viewport"], [0, 0, 1920, 1080])
        self.assertEqual(items["DP-5"]["viewport"], [1920, 0, 1920, 1080])

    def test_native_scene_render_is_pixel_identical_to_source_crop(self):
        import gi
        gi.require_version("GdkPixbuf", "2.0")
        from gi.repository import GdkPixbuf
        source = GdkPixbuf.Pixbuf.new(GdkPixbuf.Colorspace.RGB, False, 8, 100, 80)
        source.fill(0x07121eff)
        source.new_subpixbuf(0, 0, 50, 50).fill(0xaabbccff)
        source.new_subpixbuf(30, 50, 40, 30).fill(0x1267eaff)
        source.savev(str(self.single), "png", [], [])
        items = wallpaper.plan([monitor("left", 50, 50), monitor("right", 50, 50, x=50), monitor("bottom", 40, 30, x=30, y=50)], self.single, mode="scene")
        def rows(image):
            pixels = image.get_pixels()
            width = image.get_width() * image.get_n_channels()
            return b"".join(pixels[y * image.get_rowstride():y * image.get_rowstride() + width] for y in range(image.get_height()))
        for item in items:
            destination = self.root / (item["output"] + ".png")
            wallpaper.render(item, destination)
            x, y, width, height = map(int, item["viewport"])
            actual = GdkPixbuf.Pixbuf.new_from_file(str(destination))
            self.assertEqual(rows(actual), rows(source.new_subpixbuf(x, y, width, height)))

    def test_three_aligned_screens_and_mirror(self):
        outputs = [monitor(str(i), x=i * 1920) for i in range(3)]
        self.assertTrue(all(i["canvas"] == [5760, 1080] for i in wallpaper.plan(outputs, self.single, self.panorama)))
        items = wallpaper.plan(outputs, self.single, self.panorama, "mirror")
        self.assertTrue(all(i["source"] == str(self.single) and not i["panoramic"] for i in items))

    def test_rotation_hidpi_and_negative_coordinates(self):
        output = monitor("portrait", 3840, 2160, -1080, 0, 2, 1)
        geometry = wallpaper.geometry(output)
        self.assertEqual(geometry["pixels"], [2160, 3840])
        self.assertEqual((geometry["width"], geometry["height"]), (1080, 1920))
        items = wallpaper.plan([output], self.single, self.panorama)
        self.assertEqual(items[0]["viewport"], [0, 0, 1080, 1920])

    def test_cached_render_is_reused_and_manual_wallpaper_disables_theme_panorama(self):
        self.panorama.parent.mkdir(exist_ok=True)
        with patch.object(wallpaper.themes, "current", return_value="Anubis-Sethek"), \
             patch.object(wallpaper.themes, "read_json", side_effect=[{"wallpaper":"single.png", "panorama":"panorama.png"}, {}] * 2), \
             patch.object(wallpaper.themes, "picture_dir", return_value=self.root), \
             patch.object(wallpaper, "CACHE", self.root / "cache"), patch.object(wallpaper, "STATE", self.root / "state.json"), \
             patch.object(wallpaper, "monitors", return_value=[monitor("left"), monitor("right", x=1920)]), \
             patch.object(wallpaper.subprocess, "run") as command, \
             patch.object(wallpaper, "render", side_effect=lambda item, destination: destination.touch()) as render:
            first = wallpaper.apply(self.single)
            wallpaper.apply(self.single)
            self.assertEqual(render.call_count, 2)
            self.assertEqual(command.call_count, 4)
            self.assertTrue(all(i["source"] == str(self.single) and not i["panoramic"] for i in first["outputs"]))
            self.assertEqual(json.loads((self.root / "state.json").read_text())["theme"], "Anubis-Sethek")


class WallpaperStartupTests(unittest.TestCase):
    def test_startup_uses_packaged_default_instead_of_legacy_horus_wallpaper(self):
        parent = Path.home() / ".cache/tmp/work"
        parent.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=parent) as directory:
            home = Path(directory)
            walls = home / "Pictures/wallpapers"
            walls.mkdir(parents=True)
            (walls / "HORUS-CYBER.jpg").write_bytes(b"legacy wallpaper")
            default = walls / "black-ice-obsidian.png"
            default.write_bytes(b"current wallpaper")
            (home / ".cache").mkdir()
            bin_dir = home / "bin"
            bin_dir.mkdir()
            log = home / "awww.log"
            (bin_dir / "xdg-user-dir").write_text("#!/bin/sh\nprintf '%s/Pictures\\n' \"$HOME\"\n")
            (bin_dir / "awww").write_text("#!/bin/sh\nprintf '%s\\n' \"$*\" >> \"$AW_LOG\"\n")
            for tool in (bin_dir / "xdg-user-dir", bin_dir / "awww"):
                tool.chmod(0o755)

            result = subprocess.run(
                ["bash", str(ROOT / "dotfiles/hypr/scripts/set_wallpaper.sh")],
                capture_output=True,
                text=True,
                check=False,
                env={**os.environ, "HOME": str(home), "PATH": f"{bin_dir}:{os.environ['PATH']}", "AW_LOG": str(log)},
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn(f"img {default} --transition-type none", log.read_text())
            self.assertEqual((home / ".cache/current_wallpaper").read_text().strip(), str(default))


if __name__ == "__main__":
    unittest.main()
