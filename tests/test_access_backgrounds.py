"""Regresiones de fondos de acceso, bloqueo y binario Conky."""
import hashlib
import importlib.machinery
import importlib.util
import json
import os
import runpy
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "dotfiles/bin"))
import black_ice_conky_binary as binary
from black_ice_lock import backgrounds, update


class AccessBackgroundTests(unittest.TestCase):
    def setUp(self):
        parent = Path(os.environ.get("BLACK_ICE_TEST_WORK", Path.home() / ".cache/tmp/work"))
        parent.mkdir(parents=True, exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(dir=parent)
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def test_lock_uses_each_crop_preserves_widgets_and_is_idempotent(self):
        content = (ROOT / "assets/visual/obsidian/hyprlock.conf.in").read_text()
        wall = self.root / "original.png"
        outputs = []
        for name in ("DP-3", "DP-5", "eDP-1"):
            path = self.root / (name + ".png")
            path.touch()
            outputs.append({"output": name, "rendered": str(path)})
        state = {"wallpaper": str(wall), "outputs": outputs}
        rendered = backgrounds(content, state, wall)
        self.assertEqual(rendered.count("background {"), 4)
        for item in outputs:
            self.assertIn("monitor = " + item["output"], rendered)
            self.assertIn("path = " + item["rendered"], rendered)
        self.assertIn("input-field {", rendered)
        self.assertEqual(backgrounds(rendered, state, wall), rendered)
        state["outputs"] = outputs[-1:]
        reduced = backgrounds(rendered, state, wall)
        self.assertNotIn("monitor = DP-3", reduced)
        self.assertEqual(reduced.count("background {"), 2)

    def test_lock_ignores_stale_missing_and_invalid_outputs_and_personal_config(self):
        wall = self.root / "original.png"
        content = (ROOT / "assets/visual/obsidian/hyprlock.conf.in").read_text()
        state = {"wallpaper": str(wall), "outputs": [{"output": "DP-3", "rendered": str(self.root / "missing.png")}]}
        self.assertEqual(backgrounds(content, state, wall), content)
        state["wallpaper"] = str(self.root / "other.png")
        self.assertEqual(backgrounds(content, state, wall), content)
        personal = self.root / "hyprlock.conf"
        personal.write_text("# Ajustes personales\n")
        with patch("black_ice_lock.backgrounds") as render:
            update(personal, state, wall, lambda *_: None)
            render.assert_not_called()

    def test_lock_executes_even_when_preparation_times_out(self):
        loader = importlib.machinery.SourceFileLoader("lock_launcher", str(ROOT / "dotfiles/bin/black-ice-lock"))
        spec = importlib.util.spec_from_loader(loader.name, loader)
        launcher = importlib.util.module_from_spec(spec)
        loader.exec_module(launcher)
        with patch.object(launcher.subprocess, "run", side_effect=[subprocess.CompletedProcess([], 1), subprocess.TimeoutExpired([], 7)]), patch.object(launcher.os, "execlp") as execute:
            launcher.main()
            execute.assert_called_once_with("hyprlock", "hyprlock")

    def test_verified_conky_is_selected_only_for_matching_broken_package(self):
        executable = self.root / "bin/conky"
        executable.parent.mkdir()
        executable.write_text("#!/bin/sh\nexit 0\n")
        executable.chmod(0o755)
        record = {"version": "1.25.3", "package": "conky 1.25.2-1",
                  "files": {"bin/conky": hashlib.sha256(executable.read_bytes()).hexdigest()}}
        (self.root / "manifest.json").write_text(json.dumps(record))
        real = subprocess.run

        def run(args, **kwargs):
            return subprocess.CompletedProcess(args, 0, "conky 1.25.2-1\n", "") if args[0] == "pacman" else real(args, **kwargs)

        with patch.object(binary.subprocess, "run", side_effect=run):
            self.assertEqual(binary.selected(self.root), str(executable))
            executable.write_text("corrupto")
            with self.assertRaises(RuntimeError):
                binary.selected(self.root)
        with patch.object(binary.subprocess, "run", return_value=subprocess.CompletedProcess([], 0, "conky 1.25.3-1\n", "")):
            self.assertEqual(binary.selected(self.root), "conky")

    def test_empty_destination_installs_access_helpers_and_default_scene(self):
        home, system = self.root / "home", self.root / "system"
        idle = home / ".config/hypr/hypridle.conf"
        idle.parent.mkdir(parents=True)
        idle.write_bytes((ROOT / "dotfiles/hypr/hypridle.conf").read_bytes())
        visual = runpy.run_path(str(ROOT / "scripts/install-visual-refresh.py"))["Installer"]
        first = visual(source=ROOT, home=home, system=system)
        first.apply(activate=False)
        catalog = runpy.run_path(str(ROOT / "scripts/install-cyber-themes.py"))["Installer"](source=ROOT, home=home)
        catalog.system = system
        catalog.apply(activate=False)
        for name in ("black-ice-lock", "black-ice-appearance", "black-ice-conky", "black-ice-wallpaper"):
            env = {**os.environ, "HOME": str(home), "XDG_CONFIG_HOME": str(home / ".config"), "XDG_DATA_HOME": str(home / ".local/share")}
            env.pop("PYTHONPATH", None)
            if name != "black-ice-lock":
                subprocess.run([str(home / ".local/bin" / name), "--help"], env=env, capture_output=True, timeout=5, check=True)
            self.assertTrue(os.access(home / ".local/bin" / name, os.X_OK))
        theme = system / "usr/share/sddm/themes/black-ice-obsidian"
        self.assertTrue((theme / "components/AdaptiveBackground.qml").is_file())
        self.assertTrue((theme / "components/WallpaperGeometry.js").is_file())
        self.assertIn("backgroundMode = scene", (theme / "theme.conf").read_text())
        self.assertEqual((theme / "assets/wallpaper.png").read_bytes(), (ROOT / "assets/wallpapers/cyber/anubis-sethek.png").read_bytes())
        self.assertIn("~/.local/bin/black-ice-lock", idle.read_text())
        self.assertIn("LimitCORE=0", (home / ".config/systemd/user/black-ice-conky.service").read_text())

    def test_deploy_prepares_only_broken_conky_and_propagates_build_failure(self):
        source = (ROOT / "src/deploy/99_finalization.sh").read_text()
        start = source.index("if pacman -Q conky")
        block = source[start:source.index("# --- Identidad visual coordinada ---", start)]
        shell = '''pacman() { printf '%s\\n' "$QA_PACKAGE"; }
safe_install() { printf 'dependencia:%s\\n' "$1"; }
python3() { printf 'compilar:%s\\n' "$*"; return "$QA_BUILD_RC"; }
SCRIPT_DIR=/repositorio
stage() {
''' + block + "\n}\nstage\n"
        for version, build_rc, expected in (("1.25.2-1", 0, 0), ("1.25.2-2", 1, 1), ("1.25.3-1", 0, 0)):
            env = {**os.environ, "QA_PACKAGE": "conky " + version, "QA_BUILD_RC": str(build_rc)}
            result = subprocess.run(["bash", "-c", "log_info() { :; };\n" + shell], env=env, capture_output=True, text=True, timeout=5, check=False)
            self.assertEqual(result.returncode, expected, result.stderr)
            if version.startswith("1.25.2-"):
                self.assertIn("dependencia:gperf", result.stdout)
                self.assertIn("scripts/build-conky-wayland.py --apply", result.stdout)
            else:
                self.assertNotIn("compilar:", result.stdout)

    @unittest.skipUnless(shutil.which("node"), "Requiere Node para ejecutar la geometría JavaScript")
    def test_sddm_geometry_for_rows_scene_scale_and_reconnection(self):
        source = (ROOT / "assets/sddm/themes/black-ice-obsidian/components/WallpaperGeometry.js").read_text().replace(".pragma library", "")
        outputs = [{"name": "DP-3", "virtualX": -1920, "virtualY": 0, "width": 1920, "height": 1080},
                   {"name": "DP-5", "virtualX": 0, "virtualY": 0, "width": 1920, "height": 1080},
                   {"name": "eDP-1", "virtualX": 596, "virtualY": 1080, "width": 1366, "height": 768}]
        cases = [(outputs, "DP-5", "auto", True), (outputs, "eDP-1", "auto", True),
                 (outputs, "eDP-1", "scene", True), (outputs, "DP-5", "mirror", True),
                 (outputs, "DP-5", "auto", False), (outputs[1:2], "DP-5", "scene", True)]
        code = source + "\nconsole.log(JSON.stringify(" + json.dumps(cases) + ".map(x => region(...x))));"
        result = json.loads(subprocess.check_output(["node", "-e", code], text=True, timeout=5))
        self.assertEqual((result[0]["x"], result[0]["canvasWidth"], result[0]["panorama"]), (1920, 3840, True))
        self.assertEqual(result[1]["canvasWidth"], 1366)
        self.assertEqual((result[2]["x"], result[2]["y"], result[2]["canvasHeight"]), (2516, 1080, 1848))
        self.assertFalse(result[2]["panorama"])
        self.assertEqual(result[3]["canvasWidth"], 1920)
        self.assertEqual(result[4]["canvasWidth"], 1920)
        self.assertEqual(result[5]["canvasWidth"], 1920)


if __name__ == "__main__":
    unittest.main()
