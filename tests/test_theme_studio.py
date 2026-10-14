import importlib.machinery
import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "dotfiles/bin"))
import black_ice_theme as model

loader = importlib.machinery.SourceFileLoader("studio_waybar", str(ROOT / "dotfiles/bin/black-ice-waybar"))
spec = importlib.util.spec_from_loader(loader.name, loader)
backend = importlib.util.module_from_spec(spec)
loader.exec_module(backend)


def flatten(bar, zone):
    values = []
    def visit(name):
        if name.startswith("group/"):
            for child in bar[name]["modules"]:
                visit(child)
        else:
            values.append(name)
    for name in bar[zone]:
        visit(name)
    return values


class StudioTests(unittest.TestCase):
    def test_multiple_conky_outputs_survive_profile_save(self):
        self.profile["conky"].update(output="selected", outputs=["DP-3", "DP-5"])
        saved = model.defaults(model.save(self.profile))
        self.assertEqual(saved["conky"]["outputs"], ["DP-3", "DP-5"])
        self.assertEqual(saved["conky"]["output"], "selected")
        legacy = dict(self.profile["conky"])
        legacy.pop("outputs")
        self.profile["conky"] = legacy
        self.assertEqual(model.validate(self.profile)["conky"]["outputs"], [])

    def test_invalid_conky_outputs_are_rejected(self):
        for value in ("DP-3", ["../bad"], [None], ["DP-3\n"]):
            with self.subTest(value=value), self.assertRaises(ValueError):
                self.profile["conky"]["outputs"] = value
                model.validate(self.profile)

    def setUp(self):
        work = Path.home() / ".cache/tmp/work"
        work.mkdir(parents=True, exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(prefix="theme-studio-", dir=work)
        self.addCleanup(self.temp.cleanup)
        self.config = Path(self.temp.name)
        self.themes = self.config / "waybar/themes"
        self.themes.mkdir(parents=True)
        import shutil
        shutil.copytree(ROOT / "dotfiles/waybar/themes/Horus-Nightwatch", self.themes / "Horus-Nightwatch")
        self.addCleanup(patch.stopall)
        patch.object(model, "ROOT", self.themes).start()
        patch.object(model, "CONFIG", self.config).start()
        self.profile = model.defaults("Horus-Nightwatch")
        self.profile.update(name="Horus Benjie", wallpaper="", layout="single-top", shape="angular", lab_side="right")

    def test_save_reload_and_update_preserve_original(self):
        original = (self.themes / "Horus-Nightwatch/style.css").read_bytes()
        name = model.save(self.profile)
        saved = model.defaults(name)
        self.assertEqual(saved, self.profile)
        self.assertTrue((self.themes / name / "assets/angular.svg").is_file())
        self.assertEqual((self.themes / "Horus-Nightwatch/style.css").read_bytes(), original)
        self.profile["font"] = "Ubuntu Sans"
        self.assertEqual(model.save(self.profile), name)
        self.assertEqual(model.defaults(name)["font"], "Ubuntu Sans")

    def test_invalid_values_never_write_profiles(self):
        for key, bad in [("name", "\nBenjie"), ("base", "../etc"), ("font", 'Roboto"; color:red'),
                         ("opacity", float("nan")), ("height", 1), ("wallpaper", "/no-such-file.png")]:
            with self.subTest(key=key):
                value = {**self.profile, key: bad}
                with self.assertRaises(ValueError):
                    model.save(value)
        self.assertEqual(model.themes(), ["Horus-Nightwatch"])

    def test_japanese_workspace_style_survives_saved_profile(self):
        self.profile["workspace_style"] = "japanese"
        name = model.save(self.profile)
        bars = model.bars(model.defaults(name))
        self.assertEqual(bars[0]["hyprland/workspaces"]["format-icons"]["1"], "一")
        self.assertIn('font-family:"Noto Sans JP"', (self.themes / name / "style.css").read_text())

    def test_workspace_and_tray_constraints(self):
        for key, location in [("tray", "left"), ("hyprland/workspaces", "right")]:
            value = {**self.profile, "modules": {key: location}}
            with self.assertRaises(ValueError):
                model.validate(value)

    def test_hidden_and_moved_modules_survive_compact_adaptation(self):
        self.profile["modules"] = {"battery": "hidden", "clock": "left", "custom/power": "hidden"}
        name = model.save(self.profile)
        for width in (600, 900, 1366, 2560):
            with self.subTest(width=width):
                bars = backend.config(self.themes / name / "config.jsonc", [{"name": "eDP-1", "width": width, "scale": 1}])
                bar = bars[0]
                left, right = flatten(bar, "modules-left"), flatten(bar, "modules-right")
                self.assertIn("custom/docker", right)
                self.assertIn("custom/kvm", right)
                self.assertNotIn("custom/docker", left)
                self.assertIn("clock", left)
                self.assertNotIn("clock", right)
                self.assertNotIn("battery", left + right)
                self.assertNotIn("custom/power", left + right)
                self.assertEqual(bar["modules-center"], ["hyprland/workspaces"])
                self.assertIn("tray", right)

    def test_output_selection_does_not_duplicate_other_screens(self):
        self.profile["output"] = "DP-1"
        name = model.save(self.profile)
        monitors = [{"name": n, "width": 1920, "scale": 1} for n in ("eDP-1", "DP-1")]
        bars = backend.config(self.themes / name / "config.jsonc", monitors)
        self.assertEqual([bar["output"] for bar in bars], ["DP-1"])

    def test_tools_appear_on_next_poll_without_restarting_bar(self):
        for name, binary in [("docker", "docker"), ("kvm", "virsh")]:
            with self.subTest(name=name), patch.object(backend.shutil, "which", return_value=None), patch.object(backend, "command") as run:
                self.assertEqual(backend.service(name)["text"], "")
                run.assert_not_called()
            with patch.object(backend.shutil, "which", return_value="/usr/bin/" + binary), patch.object(backend, "command", return_value=(0, "")):
                self.assertIn("0", backend.service(name)["text"])
            with patch.object(backend.shutil, "which", return_value="/usr/bin/" + binary), patch.object(backend, "command", return_value=(1, "")):
                self.assertEqual(backend.service(name)["class"], "unavailable")

    def test_all_angular_themes_have_fixed_caps(self):
        for folder in (ROOT / "dotfiles/waybar/themes").iterdir():
            metadata = model.read_json(folder / "theme.json")
            if "Angular" in folder.name or metadata.get("shape") == "angular":
                self.assertIn("border-image-slice:2 14 fill", (folder / "style.css").read_text())
                self.assertTrue((folder / "assets/angular.svg").is_file())

    def test_font_from_gtk_spinbutton_produces_valid_native_css(self):
        import gi
        gi.require_version("Gtk", "3.0")
        from gi.repository import Gtk
        self.profile.update(weight=500.0, font_size=12.0)
        name = model.save(self.profile)
        css = (self.themes / name / "style.css").read_text()
        self.assertIn("font-weight:500;", css)
        Gtk.CssProvider().load_from_path(str(self.themes / name / "style.css"))

    def test_dragged_modules_preserve_order_bar_and_hidden_state_when_compact(self):
        self.profile["layout"] = "dual-top"
        model.move_module(self.profile, "clock", "right", "bottom")
        model.move_module(self.profile, "custom/control", "right", "bottom", before="clock")
        model.move_module(self.profile, "battery", "hidden", "top")
        model.move_module(self.profile, "tray", "left", "bottom")
        self.assertEqual(self.profile["modules"]["tray"], "right")
        name = model.save(self.profile)
        for width in (900, 1366):
            bars = backend.config(self.themes / name / "config.jsonc", [{"name":"eDP-1", "width":width, "scale":1}])
            top, bottom = bars
            right = bottom["modules-right"]
            self.assertLess(right.index("custom/control"), right.index("clock"))
            self.assertIn("tray", right)
            self.assertNotIn("clock", top["modules-right"])
            self.assertNotIn("battery", [m for b in bars for z in ("modules-left", "modules-center", "modules-right") for m in flatten(b,z)])

    def test_drag_conky_keeps_native_position_across_save_and_reload(self):
        monitor = {"name":"eDP-1", "width":1366, "height":768, "scale":1}
        model.move_conky(self.profile, monitor, 120, 220)
        rect = model.conky_rectangle(self.profile, monitor)
        self.assertEqual((rect["x"], rect["y"]), (120, 220))
        name = model.save(self.profile)
        saved = model.defaults(name)
        self.assertEqual(model.conky_rectangle(saved, monitor), rect)

    def test_sddm_selection_is_not_changed_by_saving(self):
        with patch.object(model.subprocess, "run") as run:
            name = model.save(self.profile)
        run.assert_not_called()
        self.assertEqual(model.read_json(self.themes / name / "profile.json")["sddm"], self.profile["sddm"])

    def test_install_sddm_uses_the_allowlisted_privileged_operation(self):
        preview = self.config / "sddm-apply"
        preview.mkdir()
        (preview / "Main.qml").write_text("preview")
        with patch.object(model.subprocess, "run") as run:
            model.install_sddm(preview)
        args = run.call_args.args[0]
        self.assertEqual(args[:3], ["pkexec", "/usr/lib/black-ice/system-transaction", "sddm-theme"])
        self.assertEqual(args[3], str(preview))

    def test_sddm_preview_preserves_uhd_background_bytes(self):
        import shutil
        sddm = self.config / "sddm"
        shutil.copytree(ROOT / "assets/sddm/themes/black-ice-obsidian", sddm / "black-ice-obsidian")
        self.profile["wallpaper"] = str(ROOT / "assets/wallpapers/cyber/fbi-fieldwork-uhd.png")
        with patch.object(model, "SDDM_ROOT", sddm), patch.object(model.subprocess, "run") as run:
            preview = model.sddm_preview(self.profile, self.config / "preview")
        run.assert_not_called()
        self.assertEqual((preview / "background.png").read_bytes(), Path(self.profile["wallpaper"]).read_bytes())
        import json
        pictures = self.config / "Pictures"
        walls = pictures / "wallpapers"
        walls.mkdir(parents=True)
        (walls / "base.png").touch()
        (self.config / "private.png").write_text("dato de prueba que no debe publicarse")
        (walls / "escape.png").symlink_to(self.config / "private.png")
        (self.themes / self.profile["base"] / "theme.json").write_text(json.dumps({"wallpaper": "base.png", "panorama": "escape.png"}))
        self.profile["wallpaper"] = str(walls / "base.png")
        with patch.object(model, "SDDM_ROOT", sddm), patch.object(model, "picture_dir", return_value=pictures):
            preview = model.sddm_preview(self.profile, self.config / "safe-preview")
        self.assertFalse((preview / "panorama.png").exists())


if __name__ == "__main__":
    unittest.main()
