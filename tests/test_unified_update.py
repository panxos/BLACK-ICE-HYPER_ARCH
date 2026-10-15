"""Pruebas del alcance y las barreras del actualizador unificado."""
import importlib.util
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("black_ice_update", ROOT / "scripts/black-ice-update.py")
update = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(update)


class UnifiedUpdateTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.repo = Path(self.temp.name)
        (self.repo / ".git").mkdir()
        (self.repo / "scripts").mkdir()
        (self.repo / "scripts/black-ice-update.py").touch()

    def test_repository_must_be_a_black_ice_checkout(self):
        self.assertEqual(update.find_repository(str(self.repo)), self.repo.resolve())
        with self.assertRaisesRegex(ValueError, "checkout Git válido"):
            update.find_repository(str(self.repo.parent))

    def test_detects_linked_hyprland_configuration(self):
        config = self.repo / "config"
        config.mkdir()
        target = self.repo / "hypr-source"
        target.mkdir()
        (config / "hypr").symlink_to(target, target_is_directory=True)
        with patch.dict(update.os.environ, {"XDG_CONFIG_HOME": str(config)}):
            self.assertTrue(update.hyprland_config_is_linked())

    @patch.object(update.os, "geteuid", return_value=0)
    @patch.object(update, "run")
    def test_refuses_root_before_running_any_update_step(self, run, _geteuid):
        with self.assertRaises(SystemExit):
            update.main(["--repo", str(self.repo), "--no-pull"])
        run.assert_not_called()

    @patch.object(update, "hyprland_config_is_linked", return_value=False)
    @patch.object(update, "run")
    def test_dry_run_lists_user_and_privileged_steps_without_running_them(self, run, _linked):
        run.return_value = 0
        with patch("builtins.print") as output:
            self.assertEqual(update.main(["--repo", str(self.repo), "--dry-run", "--no-pull"]), 0)
        commands = [call.args[0] for call in run.call_args_list]
        self.assertEqual(len(commands), 2)
        self.assertTrue(all(command[-1] == "--dry-run" for command in commands))
        self.assertTrue(any("sudo bash scripts/install-system-components.sh" in call.args[0]
                            for call in output.call_args_list))

    @patch.object(update, "hyprland_config_is_linked", return_value=True)
    @patch.object(update, "run", return_value=0)
    def test_linked_hyprland_skips_only_visual_migration(self, run, _linked):
        with patch("builtins.print"):
            self.assertEqual(update.main(["--repo", str(self.repo), "--dry-run", "--no-pull"]), 0)
        self.assertIn("--skip-migration", run.call_args_list[0].args[0])

    @patch.object(update, "run")
    @patch.object(update, "dirty_checkout", return_value=True)
    def test_dirty_checkout_stops_before_pull_or_install(self, dirty, run):
        self.assertEqual(update.main(["--repo", str(self.repo)]), 1)
        dirty.assert_called_once_with(self.repo)
        run.assert_not_called()

    @patch.object(update, "run", return_value=19)
    def test_failed_step_stops_before_later_components(self, run):
        self.assertEqual(update.main(["--repo", str(self.repo), "--no-pull"]), 19)
        run.assert_called_once()


if __name__ == "__main__":
    unittest.main()
