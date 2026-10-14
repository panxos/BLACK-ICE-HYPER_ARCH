"""Inventario real, dependencias y selección de ventanas sin acciones peligrosas."""
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
import black_ice_shortcuts as shortcuts


class ShortcutTests(unittest.TestCase):
    def test_inventory_uses_bindings_and_does_not_execute_commands(self):
        bindings = [{"key": "F1", "modmask": 0, "dispatcher": "exec", "arg": "cheatsheet"},
                    {"key": "M", "modmask": 64, "dispatcher": "exit", "arg": ""},
                    {"key": "1", "modmask": 64, "dispatcher": "exec", "arg": "black-ice-workspaces focus 1"}]
        with patch.object(shortcuts.shutil, "which", return_value="/usr/bin/available"), patch("subprocess.run") as run:
            entries = shortcuts.inventory(bindings)
        self.assertEqual(len(entries), 3)
        self.assertFalse(run.called)
        self.assertTrue(any(row["action"] == "Ir al escritorio local 1" for row in entries))

    def test_environment_pipelines_and_substitution_dependencies(self):
        command = 'env GDK_BACKEND=wayland ~/.local/bin/cheatsheet'
        self.assertEqual(shortcuts.commands(command), ["~/.local/bin/cheatsheet"])
        command = 'mkdir -p ~/Pictures && grim -g "$(slurp)" ~/Pictures/$(date +%s).png && notify-send "Captura"'
        self.assertEqual(shortcuts.commands(command), ["mkdir", "grim", "notify-send", "slurp", "date"])
        with patch.object(shortcuts.shutil, "which", side_effect=lambda name: None if name == "slurp" else "/usr/bin/" + name):
            self.assertEqual(shortcuts.missing_commands(command), ["slurp"])

    def test_lua_callbacks_are_not_claimed_as_dependency_verified(self):
        rows = shortcuts.inventory([{"key": "F1", "modmask": 0, "dispatcher": "__lua", "arg": "42", "description": "Ver atajos"}])
        self.assertEqual(rows[0]["action"], "Ver atajos")
        self.assertIn("sin inspección", rows[0]["status"])

    def test_release_mouse_and_modifier_labels(self):
        self.assertEqual(shortcuts.shortcut({"key": "SUPER_L", "modmask": 64, "release": True}), "Win · al soltar")
        self.assertEqual(shortcuts.shortcut({"key": "T", "modmask": 72}), "Win + Alt + T")
        self.assertEqual(shortcuts.shortcut({"key": "mouse:272", "modmask": 64}), "Win + Clic izquierdo")

    def test_app_switcher_reads_client_json_and_preserves_pipe_in_title(self):
        with tempfile.TemporaryDirectory(dir=Path.home() / ".cache/tmp/work") as directory:
            home = Path(directory)
            binary = home / "bin"
            binary.mkdir()
            clients = [{"address": "0x123", "workspace": {"id": 7}, "class": "kitty", "title": "Benjie | terminal"}]
            (binary / "hyprctl").write_text("#!/bin/sh\ncat \"$HOME/clients.json\"\n")
            (home / "clients.json").write_text(json.dumps(clients))
            (binary / "wofi").write_text("#!/bin/sh\nhead -n 1\n")
            (binary / "notify-send").write_text("#!/bin/sh\nexit 0\n")
            helper = home / ".local/bin/black-ice-hypr"
            helper.parent.mkdir(parents=True)
            helper.write_text('#!/bin/sh\nprintf "%s\\n" "$@" > "$HOME/focused"\n')
            for path in [*binary.iterdir(), helper]:
                path.chmod(0o755)
            result = subprocess.run(["bash", str(ROOT / "dotfiles/bin/app_switcher")], env={**os.environ, "HOME": str(home), "PATH": str(binary) + ":" + os.environ["PATH"]}, capture_output=True, text=True, timeout=4, check=False)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual((home / "focused").read_text(), "focuswindow\naddress:0x123\n")

    def test_f1_migration_preserves_existing_f1_assignment(self):
        loader = importlib.machinery.SourceFileLoader("shortcut_installer", str(ROOT / "scripts/install-cyber-themes.py"))
        spec = importlib.util.spec_from_loader(loader.name, loader)
        module = importlib.util.module_from_spec(spec)
        loader.exec_module(module)
        with tempfile.TemporaryDirectory(dir=Path.home() / ".cache/tmp/work") as directory:
            home = Path(directory)
            config = home / ".config/hypr/hyprland.conf"
            config.parent.mkdir(parents=True)
            config.write_text("bind = , F1, exec, benjie-help\n")
            operations = module.Installer(home=home).build()
            content = operations[config]["data"].decode()
            self.assertEqual(content.count("F1"), 1)
            self.assertIn("benjie-help", content)
