import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class DistributionTests(unittest.TestCase):
    def test_installation_copy_keeps_runtime_and_excludes_private_material(self):
        parent = Path.home() / ".cache/tmp/work"
        parent.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=parent) as directory:
            root = Path(directory)
            source = root / "source"
            target = root / "target"
            target.mkdir()
            kept = ("install.sh", "config/apps.json", "config/install.conf.example", "dotfiles/bin/black-ice-control", "docs/THEMES.md", "assets/wallpapers/cyber/sources.json")
            excluded = ("AGENTS.md", ".handoff.md", ".claude/config.json", "openspec/changes/test/tasks.md", "config/install.conf", "install.conf.auto", ".env", "src/__pycache__/module.pyc", "docs/VM_VALIDATION_V4.md", "assets/wallpapers/cyber/prompts.json")
            for name in (*kept, *excluded):
                path = source / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("fixture")
            archive = root / "source.tar"
            subprocess.run(["tar", "-C", str(source), "--exclude-from=" + str(ROOT / "config/distribution-excludes.txt"), "-cf", str(archive), "."], check=True)
            subprocess.run(["tar", "-C", str(target), "-xf", str(archive)], check=True)
            self.assertEqual({str(p.relative_to(target)) for p in target.rglob("*") if p.is_file()}, set(kept))
