"""Pruebas de adaptación y sensores sin modificar la sesión del escritorio."""
import importlib.machinery
import importlib.util
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import Mock, patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "dotfiles/bin"))
TEMP_ROOT = Path(os.environ.get("BLACK_ICE_TEST_TMP", Path.home() / ".cache/tmp"))
TEMP_ROOT.mkdir(parents=True, exist_ok=True)
loader = importlib.machinery.SourceFileLoader("desktop_monitor", str(ROOT / "dotfiles/bin/black-ice-conky"))
spec = importlib.util.spec_from_loader(loader.name, loader)
monitor = importlib.util.module_from_spec(spec)
loader.exec_module(monitor)


class DesktopMonitorTest(unittest.TestCase):
    def test_late_crash_records_error_and_waits_before_retry(self):
        with tempfile.TemporaryDirectory(dir=TEMP_ROOT) as directory, patch.object(monitor, "RUNTIME", Path(directory)):
            plan = {"output": "eDP-1"}
            dead = Mock(pid=100, poll=Mock(return_value=-6))
            children = {"eDP-1": {"plan": plan, "child": dead, "started": 1}}
            retries = {}
            with patch.object(monitor, "launch", return_value=Mock(pid=101, poll=Mock(return_value=None))) as launch:
                error = monitor.reconcile(children, {"eDP-1": plan}, {}, {}, .7, retries, now=10)
                self.assertIn("código -6", error["eDP-1"])
                self.assertFalse(launch.called)
                monitor.reconcile(children, {"eDP-1": plan}, {}, {}, .7, retries, now=14)
                self.assertFalse(launch.called)
                monitor.reconcile(children, {"eDP-1": plan}, {}, {}, .7, retries, now=15)
                self.assertEqual(launch.call_count, 1)
                self.assertEqual(retries["eDP-1"]["count"], 1)
                monitor.reconcile(children, {"eDP-1": plan}, {}, {}, .7, retries, now=46)
                self.assertFalse(retries)

    def test_repeated_start_failures_back_off_and_changed_plan_can_retry(self):
        with tempfile.TemporaryDirectory(dir=TEMP_ROOT) as directory, patch.object(monitor, "RUNTIME", Path(directory)):
            plans = {"eDP-1": {"output": "eDP-1"}}
            retries, children = {}, {}
            with patch.object(monitor, "launch", side_effect=RuntimeError("sin capa")) as launch:
                for now in (0, 1, 5, 6, 15):
                    monitor.reconcile(children, plans, {}, {}, .7, retries, now=now)
                self.assertEqual(launch.call_count, 3)
                self.assertEqual(retries["eDP-1"]["next"], 35)
                plans["eDP-1"] = {"output": "eDP-1", "gap_x": 10}
                monitor.reconcile(children, plans, {}, {}, .7, retries, now=16)
                self.assertEqual(launch.call_count, 4)

    def test_status_requires_live_process_and_matching_layer_and_rejects_zombies(self):
        with tempfile.TemporaryDirectory(dir=TEMP_ROOT) as directory:
            root = Path(directory)
            (root / "100").mkdir()
            (root / "100/comm").write_text("conky\n")
            (root / "100/status").write_text("State:\tS (sleeping)\n")
            status = {"pids": {"eDP-1": 100}, "actual_outputs": ["eDP-1"]}
            self.assertFalse(monitor.live_status(status, {}, root)["running"])
            layers = {"eDP-1": {"levels": {"0": [{"pid": 100}]}}}
            self.assertTrue(monitor.live_status(status, layers, root)["running"])
            (root / "100/status").write_text("State:\tZ (zombie)\n")
            self.assertFalse(monitor.live_status(status, layers, root)["running"])

    def test_multiple_output_modes_and_reconnection(self):
        outputs = [{"name": "eDP-1"}, {"name": "DP-3"}, {"name": "DP-5"}, {"name": "off", "dpmsStatus": False}]
        for mode, chosen, expected in [("auto", [], ["eDP-1"]), ("all", [], ["eDP-1", "DP-3", "DP-5"]),
                                       ("selected", ["DP-3", "DP-5"], ["DP-3", "DP-5"]), ("selected", [], [])]:
            prefs = {**monitor.DEFAULT, "output": mode, "outputs": chosen}
            self.assertEqual([m["name"] for m in monitor.select_monitors(outputs, prefs)], expected)
        prefs = {**monitor.DEFAULT, "output": "selected", "outputs": ["DP-5"]}
        self.assertEqual(monitor.select_monitors(outputs[:2], prefs), [])
        self.assertEqual(monitor.select_monitors(outputs, prefs), [outputs[2]])

    def test_reconciliation_preserves_children_on_color_change_and_detach(self):
        with tempfile.TemporaryDirectory(dir=TEMP_ROOT) as directory, patch.object(monitor, "RUNTIME", Path(directory)):
            children = {}
            plans = {name: monitor.layout({"name": name, "width": 1366, "height": 768}, "fracture") for name in ("eDP-1", "DP-3", "DP-5")}
            processes = [Mock(pid=i + 100, poll=Mock(return_value=None)) for i in range(3)]
            with patch.object(monitor, "launch", side_effect=processes) as launch, patch.object(monitor, "terminate") as terminate:
                self.assertEqual(monitor.reconcile(children, plans, {"acc1": "#111111"}, {}, .7), {})
                self.assertEqual(launch.call_count, 3)
                monitor.reconcile(children, plans, {"acc1": "#abcdef"}, {}, .6)
                self.assertEqual(launch.call_count, 3)
                self.assertFalse(terminate.called)
                for name in plans:
                    self.assertIn('#abcdef', (monitor.instance_dir(name) / "frame.lua").read_text())
                monitor.reconcile(children, {"eDP-1": plans["eDP-1"]}, {}, {}, .7)
                self.assertEqual(list(children), ["eDP-1"])
                self.assertEqual(terminate.call_count, 2)

    def test_failed_output_does_not_stop_other_instances(self):
        with tempfile.TemporaryDirectory(dir=TEMP_ROOT) as directory, patch.object(monitor, "RUNTIME", Path(directory)):
            process = Mock(pid=100, poll=Mock(return_value=None))
            plans = {name: {"output": name} for name in ("eDP-1", "DP-3")}
            with patch.object(monitor, "launch", side_effect=[process, RuntimeError("sin superficie")]):
                children = {}
                errors = monitor.reconcile(children, plans, {}, {}, .7)
            self.assertEqual(list(children), ["eDP-1"])
            self.assertEqual(errors, {"DP-3": "sin superficie"})

    def test_corrupt_output_selection_recovers(self):
        with patch.object(monitor, "load_json", return_value={"outputs": ["DP-3", "DP-3", "../bad", 1]}):
            self.assertEqual(monitor.preferences()["outputs"], ["DP-3"])

    def test_fsociety_stays_low_and_centered_above_bottom_bar(self):
        import json
        setting = {**monitor.DEFAULT, **json.loads((ROOT / "dotfiles/conky/black-ice/theme-defaults.json").read_text())["Fsociety"]}
        for width,height,scale,transform in [(1366,768,1,0),(900,768,1,0),(1920,1080,1.5,0),(1920,1080,1.5,1)]:
            output = {"name":"test","width":width,"height":height,"scale":scale,"transform":transform,"reserved":[0,0,0,36]}
            plan = monitor.layout(output,"fsociety",setting)
            logical_width = round((height if transform else width)/scale)
            self.assertLessEqual(plan["surface_height"],112)
            self.assertLessEqual(abs(plan["gap_x"] + plan["surface_width"]/2 - logical_width/2),1)

    def test_outputs_restore_preference_after_detach(self):
        integrated = {"name": "eDP-1"}
        external = {"name": "DP-1", "focused": True}
        self.assertEqual(monitor.select_monitor([integrated, external], "DP-1"), external)
        self.assertEqual(monitor.select_monitor([integrated], "DP-1"), integrated)
        self.assertEqual(monitor.select_monitor([integrated, external], "DP-1"), external)

    def test_disabled_outputs_do_not_get_widgets(self):
        self.assertEqual(monitor.select_monitor([{"name": "DP-1", "disabled": True}], "DP-1"), {})
        self.assertEqual(monitor.select_monitor([{"name": "eDP-1", "dpmsStatus": False}], "auto"), {})

    def test_layout_preserves_bars_and_reflows(self):
        cases = [(1366, 768, 1, 0), (3440, 1440, 1, 0), (1920, 1080, 1.5, 0), (1920, 1080, 1.5, 1)]
        for width, height, scale, transform in cases:
            for variant in monitor.STYLES:
                with self.subTest(size=(width, height), scale=scale, transform=transform, variant=variant):
                    output = {"name": "DP-1", "width": width, "height": height, "scale": scale,
                              "transform": transform, "reserved": [0, 28, 0, 28]}
                    plan = monitor.layout(output, variant)
                    logical_w = round((height if transform else width) / scale)
                    logical_h = round((width if transform else height) / scale)
                    self.assertLessEqual(plan["width"], 1920 if variant in monitor.FULLSCREEN else 1008)
                    self.assertLessEqual(plan["width"] + plan["margin_x"], logical_w)
                    self.assertLessEqual(plan["height"] + plan["margin_y"] + 28, logical_h)
                    self.assertLessEqual(abs(plan["margin_x"] + plan["width"] / 2 - logical_w / 2), 1)
                    self.assertLess(plan["height"], logical_h - 56)
        portrait = monitor.layout({"name": "DP-1", "width": 1920, "height": 1080, "scale": 1.5, "transform": 1}, "fracture")
        self.assertTrue(portrait["compact"])

    def test_bar_reserves_are_not_added_twice(self):
        output = {"name": "eDP-1", "width": 1366, "height": 768, "reserved": [0, 28, 0, 28]}
        plan = monitor.layout(output, "fracture")
        self.assertEqual(plan["margin_y"], 24)
        self.assertEqual(plan["gap_y"] + plan["surface_height"] + 24, 768 - 56)
        self.assertEqual(plan["gap_x"] + plan["surface_width"] / 2, 1366 / 2)

    def test_position_zoom_and_offsets_fit_available_area(self):
        output = {"name": "eDP-1", "width": 1366, "height": 768, "reserved": [0, 28, 0, 28]}
        for position in monitor.POSITIONS:
            for zoom in (.65, 1.0, 1.35):
                for variant in monitor.STYLES:
                    settings = {**monitor.DEFAULT, "position": position, "zoom": zoom, "offset_x": 4000, "offset_y": -4000}
                    with self.subTest(position=position, zoom=zoom, variant=variant):
                        plan = monitor.layout(output, variant, settings)
                        self.assertGreaterEqual(plan["gap_x"], 0)
                        self.assertGreaterEqual(plan["gap_y"], 0)
                        self.assertLessEqual(plan["surface_width"] + plan["gap_x"], 1366)
                        self.assertLessEqual(plan["surface_height"] + plan["gap_y"], 712)

    def test_position_values_recover_from_invalid_configuration(self):
        value = {"position": "invalid", "zoom": float("nan"), "offset_x": "invalid", "offset_y": 9999}
        monitor.sanitize_position(value)
        self.assertEqual(value, {"position": "bottom_middle", "zoom": 1.0, "offset_x": 0, "offset_y": 4000})

    def test_preferences_upgrade_without_losing_output(self):
        with patch.object(monitor, "load_json", return_value={"variant": "orbit", "output": "DP-2", "enabled": False}):
            prefs = monitor.preferences()
        self.assertEqual(prefs["variant"], "orbit")
        self.assertEqual(prefs["output"], "DP-2")
        self.assertFalse(prefs["enabled"])
        self.assertEqual(prefs["opacity"], .78)

    def test_invalid_opacity_is_bounded_or_restored(self):
        for raw, expected in [(0, .55), (1, .95), ("bad", .78), (float("nan"), .78)]:
            with self.subTest(raw=raw), patch.object(monitor, "load_json", return_value={"opacity": raw}):
                self.assertEqual(monitor.preferences()["opacity"], expected)

    def test_all_themes_have_valid_default_compositions(self):
        import json
        palettes = json.loads((ROOT / "dotfiles/conky/black-ice/palettes.json").read_text())
        defaults = json.loads((ROOT / "dotfiles/conky/black-ice/theme-defaults.json").read_text())
        self.assertEqual(set(palettes), set(defaults))
        for setting in defaults.values():
            self.assertIn(setting["variant"], monitor.STYLES)
            self.assertTrue(.55 <= setting["opacity"] <= .95)

    def test_theme_switch_restores_customization_and_preserves_hidden(self):
        prefs = {**monitor.DEFAULT, "enabled": False, "themes": {"Emilia-Angular": {"variant": "orbit", "color": "acid", "opacity": .6}}}
        with patch.object(monitor, "preferences", return_value=prefs), patch.object(monitor, "theme", return_value={"name": "Emilia-Angular"}):
            result = monitor.resolved_preferences()
        self.assertEqual((result["variant"], result["color"], result["opacity"]), ("orbit", "acid", .6))
        self.assertFalse(result["enabled"])
        prefs = {**monitor.DEFAULT, "enabled": False}
        with patch.object(monitor, "preferences", return_value=prefs), patch.object(monitor, "theme", return_value={"name": "Seth-Tempest"}), patch.object(monitor, "ASSETS", ROOT / "dotfiles/conky/black-ice"):
            result = monitor.resolved_preferences()
        self.assertEqual(result["variant"], "scope")
        self.assertFalse(result["enabled"])

    def test_color_combinations_keep_theme_background_and_original(self):
        palette = {**monitor.FALLBACK, "name": "Emilia-Angular"}
        for scheme in monitor.COLORS:
            changed = monitor.colored(palette, scheme)
            self.assertEqual(changed["bg"], palette["bg"])
        self.assertEqual(monitor.colored(palette, "swap")["acc1"], palette["acc2"])
        self.assertEqual(palette, {**monitor.FALLBACK, "name": "Emilia-Angular"})

    def test_centering_respects_side_reservations(self):
        output = {"name": "DP-1", "width": 1920, "height": 1080, "reserved": [100, 28, 20, 28]}
        plan = monitor.layout(output, "signal")
        self.assertLessEqual(abs(plan["margin_x"] + plan["width"] / 2 - 1000), 1)

    def test_sensor_discovery_uses_device_and_label(self):
        with tempfile.TemporaryDirectory(dir=TEMP_ROOT) as directory:
            base = Path(directory)
            for number, name, label in [(9, "coretemp", "Package id 0"), (2, "nvme", "Composite"), (1, "amdgpu", "edge")]:
                hw = base / f"hwmon{number}"
                hw.mkdir()
                (hw / "name").write_text(name)
                (hw / "temp1_label").write_text(label)
                (hw / "temp1_input").write_text("63000")
            paths = monitor.sensors(base)
            self.assertIn("hwmon9", paths["cpu"])
            self.assertIn("hwmon2", paths["nvme"])
            self.assertNotIn("amdgpu", str(paths))
            self.assertEqual(monitor.sensor_values(paths)["cpu"], 63)
            Path(paths["cpu"]).unlink()
            self.assertIsNone(monitor.sensor_values(paths)["cpu"])

    def test_absent_sensors_do_not_become_zero(self):
        self.assertEqual(monitor.sensor_values({"cpu": "/nonexistent/black-ice-sensor"}), {"cpu": None})

    def test_usb_power_overrides_battery_discharge(self):
        with tempfile.TemporaryDirectory(dir=TEMP_ROOT) as directory:
            base = Path(directory)
            bat, usb = base / "BAT0", base / "USBC"
            bat.mkdir()
            usb.mkdir()
            for path, value in [(bat / "type", "Battery"), (bat / "status", "Discharging"),
                                (bat / "capacity", "42"), (usb / "type", "USB"), (usb / "online", "1")]:
                path.write_text(value)
            self.assertEqual(monitor.power(base)["interval"], 2)
            (usb / "online").write_text("0")
            self.assertEqual(monitor.power(base)["interval"], 5)
            (bat / "status").write_text("Unknown")
            self.assertEqual(monitor.power(base)["interval"], 2)

    def test_lua_serialization_cannot_execute_theme_strings(self):
        result = monitor.lua({'label': '\"]; os.execute("false"); --', 'value': None})
        self.assertIn('\\"', result)
        self.assertIn('["value"]=nil', result)

    def test_native_config_avoids_deprecated_transparency(self):
        plan = monitor.layout({"name": "eDP-1", "width": 1366, "height": 768}, "fracture")
        config = monitor.conky_config(plan)
        self.assertIn('["out_to_wayland"]=true', config)
        self.assertIn('["out_to_x"]=false', config)
        self.assertNotIn("own_window_argb", config)

    def test_theme_follows_symlink_and_explicit_override(self):
        with tempfile.TemporaryDirectory(dir=TEMP_ROOT) as directory:
            config = Path(directory)
            style = config / "waybar/themes/Emilia-Angular/style.css"
            style.parent.mkdir(parents=True)
            style.write_text('/* Palette: acc1=#123456 | fg=#ffffff */')
            (config / "waybar/style.css").symlink_to(style)
            with patch.object(monitor, "CONFIG", config), patch.object(monitor, "ASSETS", config):
                self.assertEqual(monitor.theme()["acc1"], "#123456")
                self.assertEqual(monitor.theme()["name"], "Emilia-Angular")
                (style.parent / "palette.json").write_text('{"acc1":"#abcdef"}')
                self.assertEqual(monitor.theme()["acc1"], "#abcdef")
                (style.parent / "palette.json").write_text('{"acc1":"invalid"}')
                self.assertEqual(monitor.theme()["acc1"], monitor.FALLBACK["acc1"])

    def test_missing_theme_has_readable_fallback(self):
        with tempfile.TemporaryDirectory(dir=TEMP_ROOT) as directory, \
                patch.object(monitor, "CONFIG", Path(directory)), \
                patch.object(monitor, "ASSETS", Path(directory)):
            value = monitor.theme()
            self.assertEqual(value["fg"], monitor.FALLBACK["fg"])
            self.assertEqual(value["acc1"], monitor.FALLBACK["acc1"])


if __name__ == "__main__":
    unittest.main()
