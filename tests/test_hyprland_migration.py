"""Pruebas de conservación, validación y recuperación de la migración."""

import errno
import json
import os
import runpy
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

REPO = Path(__file__).resolve().parents[1]
MIGRATOR = REPO / "dotfiles/bin/hyprland-migrate"


class MigrationTests(unittest.TestCase):
    def setUp(self) -> None:
        cache = Path.home() / ".cache/tmp/work"
        cache.mkdir(parents=True, exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(prefix="test-migration-", dir=cache)
        self.work = Path(self.temp.name)
        self.home = self.work / "benjie"
        self.root = self.home / ".config/hypr"
        self.root.mkdir(parents=True)
        self.legacy = self.root / "hyprland.conf"
        self.legacy.write_text("$mainMod = SUPER\ninput { kb_layout = latam }\n")
        self.converter = self.work / "converter"
        self.converter.write_text('''#!/usr/bin/env python3
import sys
text = sys.stdin.read()
if "unsupported" in text:
    print("-- TODO: manual review")
    raise SystemExit(3)
print("\\n".join("-- " + s.lstrip("# ") for s in text.splitlines()))
''')
        self.converter.chmod(0o755)
        self.hyprland = self.work / "Hyprland"
        self.hyprland.write_text('''#!/usr/bin/env python3
import os,sys
if "--version" in sys.argv:
    print("Hyprland " + os.environ.get("TEST_VERSION", "0.56.2"))
else:
    print("invalid config" if os.environ.get("TEST_INVALID") else "config ok")
''')
        self.hyprland.chmod(0o755)
        self.env = dict(os.environ, HOME=str(self.home),
                        XDG_CONFIG_HOME=str(self.home / ".config"),
                        XDG_CACHE_HOME=str(self.home / ".cache"),
                        XDG_STATE_HOME=str(self.home / ".local/state"))
        self.env.pop("HYPRLAND_INSTANCE_SIGNATURE", None)

    def tearDown(self) -> None:
        self.temp.cleanup()

    def invoke(self, *args: str) -> subprocess.CompletedProcess:
        return subprocess.run([sys.executable, str(MIGRATOR), "--converter", str(self.converter),
                               "--hyprland", str(self.hyprland), *args],
                              env=self.env, text=True, capture_output=True, timeout=20, check=False)

    def test_dry_run_preserves_every_config_file(self) -> None:
        original = self.legacy.read_bytes()
        result = self.invoke("--dry-run")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(list(self.root.iterdir()), [self.legacy])
        self.assertEqual(self.legacy.read_bytes(), original)
        self.assertFalse((self.home / ".local").exists())

    def test_success_is_idempotent_and_preserves_legacy(self) -> None:
        original = self.legacy.read_bytes()
        first = self.invoke()
        self.assertEqual(first.returncode, 0, first.stderr)
        lua = self.root / "hyprland.lua"
        contents = lua.read_bytes()
        second = self.invoke()
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertEqual(lua.read_bytes(), contents)
        self.assertEqual(self.legacy.read_bytes(), original)
        self.assertTrue(os.access(self.home / ".local/bin/hyprland-migrate", os.X_OK))
        backups = list((self.home / ".local/state/black-ice/hyprland-migrations").glob("*/manifest.json"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].parent.stat().st_mode & 0o777, 0o700)

    def test_existing_lua_is_never_replaced(self) -> None:
        lua = self.root / "hyprland.lua"
        lua.write_text("-- personal\n")
        self.assertEqual(self.invoke().returncode, 0)
        self.assertEqual(lua.read_text(), "-- personal\n")

    def test_broken_lua_symlink_is_preserved(self) -> None:
        lua = self.root / "hyprland.lua"
        lua.symlink_to("missing.lua")
        self.assertEqual(self.invoke().returncode, 0)
        self.assertEqual(os.readlink(lua), "missing.lua")

    def test_validator_success_code_without_confirmation_is_rejected(self) -> None:
        self.env["TEST_INVALID"] = "1"
        self.assertNotEqual(self.invoke().returncode, 0)
        self.assertFalse((self.root / "hyprland.lua").exists())
        self.assertFalse((self.home / ".local/state").exists())

    def test_incomplete_conversion_is_rejected(self) -> None:
        self.legacy.write_text("unsupported = true\n")
        self.assertNotEqual(self.invoke().returncode, 0)
        self.assertFalse((self.root / "hyprland.lua").exists())

    def test_sources_preserve_shared_variable_order(self) -> None:
        self.legacy.write_text("$mainMod = SUPER\nsource = personal.conf\nbind = $mainMod, Q, exec, $terminal\n")
        (self.root / "personal.conf").write_text("$terminal = kitty\n")
        result = self.invoke()
        self.assertEqual(result.returncode, 0, result.stderr)
        lua = (self.root / "hyprland.lua").read_text()
        self.assertLess(lua.index("$terminal = kitty"), lua.index("exec, $terminal"))
        self.assertNotIn("source =", lua)

    def test_missing_cyclic_and_external_sources_are_rejected(self) -> None:
        outside = self.work / "outside.conf"
        outside.write_text("input { kb_layout = us }\n")
        for target in ("missing.conf", "hyprland.conf", str(outside)):
            with self.subTest(target=target):
                self.legacy.write_text(f"source = {target}\n")
                self.assertNotEqual(self.invoke().returncode, 0)
                self.assertFalse((self.root / "hyprland.lua").exists())

    def test_generated_modules_and_helper_remain_connected(self) -> None:
        self.legacy.write_text("source = monitors.conf\nsource = vm-performance.conf\n")
        (self.root / "monitors.conf").write_text("monitor = ,preferred,auto,1\n")
        (self.root / "vm-performance.conf").write_text("env = LIBVA_DRIVER_NAME,iHD\n")
        helper = self.root / "scripts/auto_monitors.sh"
        helper.parent.mkdir()
        helper.write_text("#!/bin/bash\nexit 0\n")
        helper.chmod(0o755)
        result = self.invoke()
        self.assertEqual(result.returncode, 0, result.stderr)
        text = (self.root / "hyprland.lua").read_text()
        self.assertIn('dofile(', text)
        self.assertIn("monitors.lua", text)
        self.assertIn("--sync-generated", helper.read_text())
        self.assertEqual(subprocess.run(["bash", "-n", str(helper)], check=False).returncode, 0)
        (self.root / "monitors.conf").write_text("monitor = ,preferred,auto,1.5\n")
        result = self.invoke("--sync-generated")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("1.5", (self.root / "monitors.lua").read_text())
        result = self.invoke("--rollback")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(helper.read_text(), "#!/bin/bash\nexit 0\n")
        self.assertFalse((self.root / "monitors.lua").exists())

    def test_custom_module_changes_are_not_overwritten(self) -> None:
        self.legacy.write_text("source = monitors.conf\n")
        (self.root / "monitors.conf").write_text("monitor = ,preferred,auto,1\n")
        self.assertEqual(self.invoke().returncode, 0)
        lua = self.root / "monitors.lua"
        lua.write_text("-- personal layout\n")
        self.assertNotEqual(self.invoke("--sync-generated").returncode, 0)
        self.assertEqual(lua.read_text(), "-- personal layout\n")

    def test_rollback_protects_later_personal_changes(self) -> None:
        self.assertEqual(self.invoke().returncode, 0)
        lua = self.root / "hyprland.lua"
        lua.write_text("-- personal\n")
        self.assertNotEqual(self.invoke("--rollback").returncode, 0)
        self.assertEqual(lua.read_text(), "-- personal\n")

    def test_rollback_restores_previous_configuration(self) -> None:
        original = self.legacy.read_bytes()
        self.assertEqual(self.invoke().returncode, 0)
        result = self.invoke("--rollback")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((self.root / "hyprland.lua").exists())
        self.assertEqual(self.legacy.read_bytes(), original)

    def test_old_hyprland_is_skipped_and_new_version_cannot_rollback(self) -> None:
        self.env["TEST_VERSION"] = "0.54.3"
        self.assertEqual(self.invoke().returncode, 0)
        self.assertFalse((self.root / "hyprland.lua").exists())
        self.env["TEST_VERSION"] = "0.56.2"
        self.assertEqual(self.invoke().returncode, 0)
        self.env["TEST_VERSION"] = "0.57.0"
        self.assertNotEqual(self.invoke("--rollback").returncode, 0)
        self.assertTrue((self.root / "hyprland.lua").exists())

    def test_failed_publication_restores_prior_files(self) -> None:
        module = runpy.run_path(str(MIGRATOR))
        helper = self.root / "helper.sh"
        helper.write_bytes(b"original")
        lua = self.root / "hyprland.lua"
        changes = {helper: b"updated", lua: b"candidate"}
        with patch.dict(os.environ, self.env), patch.object(os, "link", side_effect=OSError(errno.EIO, "simulated")), self.assertRaises(module["MigrationError"]):
            module["commit"](changes, {self.legacy: self.legacy.read_bytes()}, self.work, self.root)
        self.assertEqual(helper.read_bytes(), b"original")
        self.assertFalse(lua.exists())
        manifests = list((self.home / ".local/state/black-ice/hyprland-migrations").glob("*/manifest.json"))
        self.assertEqual(json.loads(manifests[0].read_text())["status"], "reverted")

    def test_updater_preserves_unrelated_configuration(self) -> None:
        tools = self.work / "tools"
        tools.mkdir()
        (tools / "Hyprland").symlink_to(self.hyprland)
        (tools / "hyprlang2lua").symlink_to(self.converter)
        self.env["PATH"] = str(tools) + os.pathsep + os.environ["PATH"]
        personal = self.home / ".config/waybar/style.css"
        personal.parent.mkdir()
        personal.write_text("/* personal */\n")
        result = subprocess.run(["bash", str(REPO / "dotfiles/bin/dotfiles-update"),
                                 "--no-pull", "--repo", str(REPO)],
                                env=self.env, capture_output=True, text=True, timeout=20, check=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(personal.read_text(), "/* personal */\n")
        self.assertFalse(personal.parent.is_symlink())
        self.assertTrue((self.root / "hyprland.lua").is_file())
        for name in ("dotfiles-update", "dotfiles-rollback", "hyprland-migrate"):
            self.assertTrue(os.access(self.home / ".local/bin" / name, os.X_OK))
        result = subprocess.run([str(self.home / ".local/bin/dotfiles-update"), "--no-pull"],
                                cwd=self.work, env=self.env, capture_output=True, text=True, timeout=20, check=False)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_failed_pull_does_not_migrate_or_install_commands(self) -> None:
        tools = self.work / "tools"
        tools.mkdir()
        git = tools / "git"
        git.write_text("#!/bin/sh\nexit 42\n")
        git.chmod(0o755)
        self.env["PATH"] = str(tools) + os.pathsep + os.environ["PATH"]
        result = subprocess.run(["bash", str(REPO / "dotfiles/bin/dotfiles-update"), "--repo", str(REPO)],
                                env=self.env, capture_output=True, text=True, timeout=20, check=False)
        self.assertEqual(result.returncode, 42)
        self.assertFalse((self.root / "hyprland.lua").exists())
        self.assertFalse((self.home / ".local/bin").exists())

    def test_live_theme_border_supports_both_config_managers(self) -> None:
        module = runpy.run_path(str(MIGRATOR))
        calls = []
        def fake_run(command: list[str], **kwargs: object) -> subprocess.CompletedProcess:
            calls.append(command)
            if command[0] == "Hyprland":
                return subprocess.CompletedProcess(command, 0, "Hyprland 0.56.2", "")
            output = "eval is only supported with the lua config manager" if command[1] == "eval" else "ok"
            return subprocess.CompletedProcess(command, 0, output, "")
        with patch.dict(module["set_border"].__globals__, run=fake_run):
            module["set_border"]("0xee7aa2f7 0xee003333 45deg")
        self.assertEqual(calls[1][1], "eval")
        self.assertIn('"rgba(7aa2f7ee)"', calls[1][-1])
        self.assertEqual(calls[2][1], "keyword")
        with self.assertRaises(module["MigrationError"]):
            module["set_border"]('rgba(000000ff)\"); os.execute("touch bad")')

    def test_compact_blocks_are_normalized_without_changing_shell_commands(self) -> None:
        module = runpy.run_path(str(MIGRATOR))
        normalize = module["normalize_sections"]
        self.assertEqual(normalize('decoration { blur { enabled = false } }'),
                         'decoration {\nblur {\nenabled = false\n}\n}\n')
        command = 'exec-once = bash -c \'printf "{}"\''
        self.assertEqual(normalize(command), command + '\n')

    def test_automatic_preview_rotation_is_removed_without_changing_custom_commands(self) -> None:
        module = runpy.run_path(str(MIGRATOR))
        automatic = "exec-once = bash -c 'sleep 8 && [ ! -f ~/.config/waybar/themes/Horus-Cyber/preview.png ] && ~/.config/bin/gen_theme_previews'"
        custom = "exec-once = ~/.config/bin/gen_theme_previews --force"
        self.assertEqual(module["normalize_sections"](automatic + "\n" + custom), custom + "\n")


if __name__ == "__main__":
    unittest.main()
