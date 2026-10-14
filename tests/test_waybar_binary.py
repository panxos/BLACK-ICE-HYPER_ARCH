import hashlib
import importlib.machinery
import importlib.util
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
loader = importlib.machinery.SourceFileLoader("waybar_binary", str(ROOT / "dotfiles/bin/black-ice-waybar-binary"))
spec = importlib.util.spec_from_loader(loader.name, loader)
model = importlib.util.module_from_spec(spec)
loader.exec_module(model)


class WaybarBinaryTests(unittest.TestCase):
    def test_verified_backport_is_used_and_package_changes_or_corruption_fall_back(self):
        parent = Path.home() / ".cache/tmp/work"
        parent.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=parent) as directory:
            root = Path(directory)
            binary = root / "waybar"
            binary.write_text("#!/bin/sh\nexit 0\n")
            binary.chmod(0o755)
            record = {"package": "waybar-git old-1", "binary_sha256": hashlib.sha256(binary.read_bytes()).hexdigest()}
            (root / "manifest.json").write_text(json.dumps(record))
            actual = subprocess.run

            def command(args, **kwargs):
                if args[0] == "pacman":
                    return subprocess.CompletedProcess(args, 0, record["package"] + "\n", "")
                return actual(args, **kwargs)

            with patch.object(model.subprocess, "run", side_effect=command):
                self.assertEqual(model.selected(root), str(binary))
                record["package"] = "waybar-git new-1"
                self.assertEqual(model.selected(root), "waybar")
                record["package"] = "waybar-git old-1"
                binary.write_text("#!/bin/sh\nexit 1\n")
                self.assertEqual(model.selected(root), "waybar")
                record["binary_sha256"] = hashlib.sha256(binary.read_bytes()).hexdigest()
                (root / "manifest.json").write_text(json.dumps(record))
                self.assertEqual(model.selected(root), "waybar")
