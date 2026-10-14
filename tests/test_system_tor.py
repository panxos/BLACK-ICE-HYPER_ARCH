"""Errores de verificación y fronteras del helper de Tor transparente."""
import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import Mock, patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "dotfiles/bin"))
sys.path.insert(0, str(ROOT / "src/system"))
from manager import Manager
from system_privacy import SystemPrivacy

spec = importlib.util.spec_from_file_location("system_tor_helper", ROOT / "scripts/system-tor.py")
helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)


class SystemTorTests(unittest.TestCase):
    def setUp(self):
        base = Path.home() / ".cache/tmp/work"
        base.mkdir(parents=True, exist_ok=True)
        temporary = tempfile.TemporaryDirectory(dir=base)
        self.addCleanup(temporary.cleanup)
        self.work = Path(temporary.name)

    def test_toggle_uses_system_helper_without_opening_a_terminal(self):
        privacy = SystemPrivacy(Manager(self.work))
        with patch.object(privacy, "state", return_value={"enabled": False}), \
                patch.object(privacy, "enable", return_value={"enabled": True}) as enable:
            self.assertTrue(privacy.toggle()["enabled"])
        enable.assert_called_once()
        with self.assertRaisesRegex(ValueError, "cualquier terminal"):
            privacy.terminal()
        with patch.object(privacy, "state", return_value={"enabled": True}), \
                patch.object(privacy, "disable", return_value={"enabled": False}) as disable:
            self.assertFalse(privacy.toggle()["enabled"])
        disable.assert_called_once()

    def test_toggle_recovers_enabled_but_unverified_tor_instead_of_disabling_it(self):
        privacy = SystemPrivacy(Manager(self.work))
        with patch.object(privacy, "state", return_value={"enabled": True, "phase": "blocked"}), \
                patch.object(privacy, "enable", return_value={"enabled": True, "phase": "protected"}) as enable, \
                patch.object(privacy, "disable") as disable:
            self.assertEqual(privacy.toggle()["phase"], "protected")
        enable.assert_called_once()
        disable.assert_not_called()

    def test_missing_requirement_install_is_limited_to_tor_and_nftables(self):
        privacy = SystemPrivacy(Manager(self.work))
        with patch("system_privacy.shutil.which", return_value=None), patch("system_privacy.command") as command, \
                patch.object(privacy, "action", return_value={"enabled": True}):
            privacy.enable()
        self.assertEqual(command.call_args.args[0][-3:], ["install", "tor", "nftables"])

    def test_stale_global_verification_is_blocked(self):
        state = self.work / "status.json"
        state.write_text(json.dumps({"enabled": True, "phase": "protected", "checked": 0}))
        with patch("system_privacy.STATE", state):
            self.assertEqual(SystemPrivacy(Manager(self.work)).state()["phase"], "blocked")

    def test_indicator_visibility_is_saved_without_changing_tor_state(self):
        manager = Manager(self.work, config=self.work / "config")
        privacy = SystemPrivacy(manager)
        state = self.work / "tor-state.json"
        state.write_text('{"enabled":true,"phase":"protected"}')
        before = state.read_bytes()
        with patch("system_privacy.STATE", state):
            self.assertTrue(privacy.visible())
            self.assertEqual(privacy.set_visible(False), {"visible": False, "enabled": True})
            self.assertFalse(privacy.visible())
        self.assertEqual(state.read_bytes(), before)

    def test_removed_or_changed_table_is_restored_before_reporting_blocked(self):
        flag = self.work / "enabled"
        flag.touch()
        (self.work / "rules.sha256").write_text("expected")
        for value in (RuntimeError("table absent"), "changed"):
            with self.subTest(value=str(value)), patch.object(helper, "FLAG", flag), patch.object(helper, "ROOT", self.work), \
                    patch.object(helper, "effective_hash", side_effect=[value] if isinstance(value, Exception) else None,
                                 return_value=value if isinstance(value, str) else ""), \
                    patch.object(helper, "apply_filter") as restore, patch.object(helper, "publish", side_effect=lambda phase, *args, **kwargs: {"phase": phase}), \
                    patch.object(helper, "run") as run:
                self.assertEqual(helper.verify()["phase"], "blocked")
                restore.assert_called_once()
                run.assert_not_called()

    def test_negative_exit_verification_never_reports_protection(self):
        flag = self.work / "enabled"
        flag.touch()
        (self.work / "rules.sha256").write_text("expected")
        run = Mock(side_effect=["active", json.dumps({"IsTor": False, "IP": "1.1.1.1"}),
                                json.dumps({"IsTor": False, "IP": "1.1.1.1"})])
        with patch.object(helper, "FLAG", flag), patch.object(helper, "ROOT", self.work), \
                patch.object(helper, "effective_hash", return_value="expected"), patch.object(helper, "run", run), \
                patch.object(helper, "publish", side_effect=lambda phase, *args, **kwargs: {"phase": phase}), \
                patch.object(helper.time, "sleep"):
            self.assertEqual(helper.verify()["phase"], "blocked")

    def test_transient_exit_check_error_is_retried_before_reporting_blocked(self):
        flag = self.work / "enabled"
        flag.touch()
        (self.work / "rules.sha256").write_text("expected")
        run = Mock(side_effect=["active", RuntimeError("TLS unexpected EOF"),
                                json.dumps({"IsTor": True, "IP": "8.8.8.8"})])
        with patch.object(helper, "FLAG", flag), patch.object(helper, "ROOT", self.work), \
                patch.object(helper, "effective_hash", return_value="expected"), patch.object(helper, "run", run), \
                patch.object(helper, "publish", side_effect=lambda phase, *args, **kwargs: {"phase": phase}), \
                patch.object(helper.time, "sleep") as sleep:
            self.assertEqual(helper.verify()["phase"], "protected")
        sleep.assert_called_once_with(1)

    def test_privileged_uid_is_rejected(self):
        for uid in (0, -1, "957"):
            with self.subTest(uid=uid), self.assertRaises(ValueError):
                helper.rules(uid)
