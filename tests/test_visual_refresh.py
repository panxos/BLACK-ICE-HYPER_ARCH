import importlib.machinery
import importlib.util
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "dotfiles/bin"))


def load(name, path):
    loader = importlib.machinery.SourceFileLoader(name, str(path))
    spec = importlib.util.spec_from_loader(name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


installer_module = load("visual_installer", ROOT / "scripts/install-visual-refresh.py")
appearance = load("visual_appearance", ROOT / "dotfiles/bin/black-ice-appearance")
controls = load("visual_controls", ROOT / "dotfiles/bin/black-ice-control")


class InstallerTests(unittest.TestCase):
    def test_notification_migration_preserves_rules_and_removes_examples(self):
        config = {"scripts": {"demo": {"app-name": "example.app.id"}, "personal": {"app-name": "benjie.lab", "exec": "true"}},
                  "widgets": ["title", "dnd", "notifications"]}
        result = installer_module.notification_config(config)
        self.assertEqual(set(result["scripts"]), {"personal"})
        self.assertIn("buttons-grid", result["widgets"])
        self.assertTrue(result["notification-grouping"])
        self.assertEqual(result, installer_module.notification_config(result))
        self.assertIn("demo", config["scripts"])

    def test_kitty_theme_include_is_last_and_preserves_preferences(self):
        original = 'font_size 13\ninclude obsidian.conf\ninclude themes/mocha.conf\nbackground_opacity 0.85\n'
        result = installer_module.with_kitty_theme(original)
        self.assertEqual(result.count('include obsidian.conf'),1)
        self.assertTrue(result.endswith('include obsidian.conf\n'))
        self.assertIn('font_size 13',result)
        self.assertIn('background_opacity 0.85',result)
        self.assertEqual(result,installer_module.with_kitty_theme(result))

    def test_shortcut_migration_preserves_custom_commands(self):
        original = ('bind = $mainMod ALT, T, exec, ~/.config/bin/theme_visual\n'
                    'bind = SUPER ALT, W, exec, waypaper --folder ~/Pictures/wallpapers --backend awww\n'
                    'bind = SUPER ALT, T, exec, kate\n'
                    'bind = SUPER SHIFT, F9, exec, ~/.local/bin/black-ice-control\n')
        result = installer_module.without_appearance_shortcuts(original)
        self.assertNotIn('theme_visual',result)
        self.assertNotIn('waypaper',result)
        self.assertIn('exec, kate',result)
        self.assertIn('F9',result)
        self.assertEqual(result,installer_module.without_appearance_shortcuts(result))

    def setUp(self):
        base = Path(os.environ.get("BLACK_ICE_TEST_WORK", Path.home() / ".cache/tmp/work"))
        base.mkdir(parents=True, exist_ok=True)
        self.temporary = tempfile.TemporaryDirectory(prefix="visual-test-", dir=base)
        self.root = Path(self.temporary.name)
        self.home = self.root / "home"
        self.system = self.root / "system"
        self.config = self.home / ".config"
        self.installer = installer_module.Installer(ROOT, self.home, self.system)
        self.personal = self.config / "hypr/hyprlock.conf"
        self.personal.parent.mkdir(parents=True)
        self.personal.write_text("# Bloqueo personal\n")
        self.power = self.config / "hypr/hypridle.conf"
        self.power.write_text("# Política de energía personal\n")
        self.pref = self.home / ".local/state/black-ice/conky.json"
        self.pref.parent.mkdir(parents=True)
        self.pref.write_text('{"enabled":false,"variant":"orbit"}\n')
        self.old_link = self.config / "waybar/style.css"
        self.old_link.parent.mkdir(parents=True)
        self.old_link.symlink_to("themes/Emilia-Angular/style.css")
        self.current = self.system / "etc/sddm.conf.d/theme.conf"
        self.current.parent.mkdir(parents=True)
        self.current.write_text("[Theme]\nCurrent=cybersec\nCursorTheme=Personal\n")

    def tearDown(self):
        self.temporary.cleanup()

    def test_apply_rollback_preserves_original_files_links_and_preferences(self):
        before = {p:installer_module.fingerprint(p) for p in (self.personal, self.power, self.pref, self.old_link, self.current)}
        result = self.installer.apply(activate=False)
        self.assertEqual(result["status"], "applied")
        self.assertIn("black-ice-obsidian", self.current.read_text())
        self.assertIn("CursorTheme = Personal", self.current.read_text())
        self.assertEqual(installer_module.fingerprint(self.pref), before[self.pref])
        self.assertEqual(installer_module.fingerprint(self.power), before[self.power])
        self.assertFalse(self.installer.rollback())
        self.assertEqual({p:installer_module.fingerprint(p) for p in before}, before)
        self.assertFalse((self.home / ".local/bin/black-ice-control").exists())

    def test_apply_is_idempotent_and_retains_first_recovery(self):
        first = self.installer.apply(activate=False)
        second = self.installer.apply(activate=False)
        self.assertEqual(first["entries"], second["entries"])
        self.assertEqual((self.config / "kitty/kitty.conf").read_text().count("include obsidian.conf"), 1)
        self.assertEqual((self.config / "hypr/hyprland.conf").read_text().count("source = ~/.config/hypr/obsidian.conf"), 1)
        self.assertFalse(self.installer.rollback())
        self.assertEqual(self.personal.read_text(), "# Bloqueo personal\n")

    def test_partial_failure_restores_files(self):
        write = self.installer.write
        failed = False
        def fail_once(path, operation):
            nonlocal failed
            if path == self.personal and not failed:
                failed = True
                raise OSError("Fallo de escritura simulado")
            return write(path, operation)
        with patch.object(self.installer, "write", fail_once), self.assertRaises(OSError):
            self.installer.apply(activate=False)
        self.assertEqual(self.personal.read_text(), "# Bloqueo personal\n")
        self.assertIn("Current=cybersec", self.current.read_text())

    def test_rollback_preserves_subsequent_personal_edits(self):
        self.installer.apply(activate=False)
        self.personal.write_text("# Ajuste posterior\n")
        conflicts = self.installer.rollback()
        self.assertIn(str(self.personal), conflicts)
        self.assertEqual(self.personal.read_text(), "# Ajuste posterior\n")

    def test_installation_never_writes_authentication_or_boot_files(self):
        paths = self.installer.build()
        self.assertFalse(any("/pam.d/" in str(path) or "/boot/" in str(path) for path in paths))


class ControlsTests(unittest.TestCase):
    def test_invalid_percentages_do_not_execute(self):
        with patch.object(controls, "command") as execute:
            for value in ("-1", "101", "nan", "$(id)"):
                self.assertEqual(controls.action("volume", value)[0], 1)
            execute.assert_not_called()

    def test_brightness_keeps_screen_readable(self):
        with patch.object(controls, "command", return_value=(0, "")) as execute:
            controls.action("brightness", "0")
            execute.assert_called_once_with(
                ["brightnessctl", "-c", "backlight", "set", "5%"], timeout=8
            )

    def test_suspend_requires_current_battery_status(self):
        with patch.object(controls, "command", return_value=(0, "ac")) as execute:
            self.assertEqual(controls.action("suspend")[0], 1)
            self.assertEqual(execute.call_count, 1)

    def test_missing_power_status_cannot_suspend(self):
        with patch.object(controls, "command", return_value=(1, "No disponible")) as execute:
            self.assertEqual(controls.action("suspend")[0], 1)
            self.assertEqual(execute.call_count, 1)

    def test_radio_actions_reject_shell_syntax(self):
        with patch.object(controls, "command") as execute:
            self.assertEqual(controls.action("wifi", "on; reboot")[0], 1)
            execute.assert_not_called()

    def test_unavailable_hardware_has_no_fabricated_values(self):
        with patch.object(controls, "command", return_value=(1, "No disponible")):
            result = controls.state()
        self.assertIsNone(result["brightness"])
        self.assertIsNone(result["volume"])
        self.assertIsNone(result["wifi"])
        self.assertIsNone(result["bluetooth"])
        self.assertEqual(result["power"], "unknown")


class AppearanceTests(unittest.TestCase):
    def test_selecting_a_following_theme_updates_sddm_from_its_profile(self):
        import black_ice_theme
        work = Path.home() / ".cache/tmp/work"
        work.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=work) as temporary, \
                patch.dict(os.environ, {"XDG_CACHE_HOME": temporary}), \
                patch.object(appearance, "themes", return_value=["Mr-Robot"]), \
                patch.object(appearance, "read_json", side_effect=lambda path: {"wallpaper": "wall.png"} if path.name == "theme.json" else {}), \
                patch.object(appearance.subprocess, "run"), patch.object(appearance, "sync"), \
                patch.object(appearance, "set_wallpaper"), \
                patch.object(black_ice_theme, "defaults", return_value={"sddm": {"follow": True}}), \
                patch.object(black_ice_theme, "sddm_preview") as preview, \
                patch.object(black_ice_theme, "install_sddm") as install:
            appearance.apply_theme("Mr-Robot")
        preview.assert_called_once_with({"sddm": {"follow": True}}, Path(temporary) / "black-ice/theme-studio/sddm-apply")
        install.assert_called_once_with(Path(temporary) / "black-ice/theme-studio/sddm-apply")

    def test_all_themes_render_complete_terminal_palettes(self):
        import json
        import re
        palettes = json.loads((ROOT / 'dotfiles/conky/black-ice/palettes.json').read_text())
        with patch.object(appearance,'DATA',ROOT / 'assets/visual/obsidian'):
            for name,colors in palettes.items():
                colors = {**appearance.PALETTE,**colors}
                result = appearance.render('kitty.conf.in',colors,Path('fondo.png'))
                values = dict(line.split(maxsplit=1) for line in result.splitlines() if line.strip())
                self.assertNotIn('@',result,name)
                self.assertTrue(all(re.fullmatch('#[0-9a-f]{6}',values[f'color{i}']) for i in range(16)),name)
                self.assertEqual(values['color0'],colors['bg'],name)
                self.assertEqual(values['color7'],colors['fg'],name)
                self.assertEqual(values['selection_background'],colors['acc1'],name)

    def test_terminal_changes_semantic_and_accent_colors_between_themes(self):
        warm = {**appearance.PALETTE,'bg':'#101114','fg':'#f1f2f4','acc1':'#ed4c5c','acc2':'#cdd2da','dim':'#b6bac2'}
        first,second = appearance.terminal_colors(warm),appearance.terminal_colors(appearance.PALETTE)
        self.assertNotEqual(first['color0'],second['color0'])
        self.assertNotEqual(first['color2'],second['color2'])
        self.assertNotEqual(first['color6'],second['color6'])
        self.assertNotEqual(first['color14'],second['color14'])

    def test_unknown_theme_never_starts_waybar(self):
        with patch.object(appearance, "themes", return_value=["Obsidian-Angular"]), patch.object(appearance.subprocess, "run") as execute:
            with self.assertRaises(ValueError):
                appearance.apply_theme("../../otro")
            execute.assert_not_called()

    def test_render_rejects_control_characters_in_wallpaper_path(self):
        with self.assertRaises(ValueError):
            appearance.render("hyprlock.conf.in", appearance.PALETTE, Path("fondo\nnuevo.png"))


if __name__ == "__main__":
    unittest.main()
