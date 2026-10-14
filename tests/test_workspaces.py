"""Navegación por monitor sin reasignar las ventanas de la sesión."""
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import Mock

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "dotfiles/bin"))
import black_ice_workspaces as workspaces


class WorkspaceTests(unittest.TestCase):
    def setUp(self):
        self.monitors = [{"name": "eDP-1", "id": 0}, {"name": "DP-3", "id": 1}, {"name": "DP-5", "id": 2}]
        self.existing = [{"id": 1, "monitor": "eDP-1"}, {"id": 5, "monitor": "DP-5"},
                         {"id": 7, "monitor": "DP-3"}, {"id": 10, "monitor": "DP-3"}]

    def test_existing_workspaces_are_adopted_and_ids_unique(self):
        state = workspaces.plan(self.monitors, self.existing, {})
        for item in self.existing:
            self.assertIn(item["id"], state["groups"][item["monitor"]])
        ids = [number for group in state["groups"].values() for number in group]
        self.assertEqual(len(ids), 15)
        self.assertEqual(len(set(ids)), 15)
        self.assertTrue(all(group == sorted(group) for group in state["groups"].values()))

    def test_reorder_disconnect_and_reconnect_preserve_mapping(self):
        state = workspaces.plan(self.monitors, self.existing, {})
        swapped = [{"name": m["name"], "id": 2 - m["id"]} for m in self.monitors]
        self.assertEqual(workspaces.plan(swapped, self.existing, state), state)
        disconnected = workspaces.plan(self.monitors[:1], self.existing, state)
        self.assertEqual(disconnected, state)
        self.assertEqual(workspaces.plan(self.monitors, self.existing, disconnected), state)

    def test_corrupt_groups_do_not_duplicate_or_accept_commands(self):
        saved = {"groups": {"eDP-1": [1, 1, True, "2", -3], "DP-3": [1, 7], "DP-5;exec": [9]}}
        state = workspaces.plan(self.monitors, self.existing, saved)
        self.assertEqual(len({i for group in state["groups"].values() for i in group}), 15)
        self.assertNotIn("DP-5;exec", state["groups"])

    def test_numeric_and_japanese_labels_are_local(self):
        state = {"groups": {"DP-3": [6, 7, 8, 9, 10]}}
        numeric = {"format": "{name}"}
        workspaces.configure_bar(numeric, "DP-3", state)
        self.assertEqual([numeric["format-icons"][str(i)] for i in range(6, 11)], list("12345"))
        japanese = {"format": "{icon}", "format-icons": dict(zip(map(str, range(1, 6)), "一二三四五"))}
        workspaces.configure_bar(japanese, "DP-3", state)
        self.assertEqual([japanese["format-icons"][str(i)] for i in range(6, 11)], list("一二三四五"))
        self.assertFalse(japanese["all-outputs"])
        self.assertFalse(japanese["move-to-monitor"])
        self.assertEqual(japanese["persistent-workspaces"], {"DP-3": [6, 7, 8, 9, 10]})

    def test_symbolic_theme_keeps_its_active_icon(self):
        module = {"format": "{icon}", "format-icons": {"default": "○", "active": "●"}}
        workspaces.configure_bar(module, "DP-3", {"groups": {"DP-3": [6, 7, 8, 9, 10]}})
        self.assertEqual(module["format-icons"], {"default": "○", "active": "●"})

    def test_focus_and_move_use_focused_monitor(self):
        with tempfile.TemporaryDirectory(dir=Path.home() / ".cache/tmp/work") as directory:
            path = Path(directory) / "workspaces.json"
            path.write_text(json.dumps({"groups": {"DP-5": [11, 12, 13, 14, 15]}}))
            ipc = Mock()
            ipc.query.return_value = [{"name": "eDP-1"}, {"name": "DP-5", "focused": True}]
            ipc.lua.return_value = False
            self.assertEqual(workspaces.switch(ipc, "focus", 3, path), 13)
            ipc.checked.assert_called_with("dispatch workspace 13")
            ipc.lua.return_value = True
            self.assertEqual(workspaces.switch(ipc, "move", 4, path), 14)
            ipc.checked.assert_called_with("eval hl.dispatch(hl.dsp.window.move({workspace=14}))")
            with self.assertRaises(ValueError):
                workspaces.switch(ipc, "focus", 6, path)

    def test_reconciliation_prewarm_has_no_focus_or_window_moves(self):
        with tempfile.TemporaryDirectory(dir=Path.home() / ".cache/tmp/work") as directory:
            config = Path(directory)
            ipc = Mock()
            ipc.query.side_effect = lambda name: self.monitors if name == "monitors" else self.existing
            ipc.lua.return_value = False
            state = workspaces.reconcile(ipc, config / "black-ice/workspaces.json", config)
            self.assertEqual(len(state["groups"]), 3)
            commands = [call.args[0] for call in ipc.checked.call_args_list]
            self.assertEqual(sum(command.startswith("keyword workspace ") for command in commands), 15)
            self.assertFalse(any(command.startswith("dispatch ") for command in commands))
            self.assertIn("persistent:true", (config / "hypr/black-ice-workspaces.conf").read_text())
            self.assertIn("hl.unbind", (config / "hypr/black-ice-workspaces.lua").read_text())
