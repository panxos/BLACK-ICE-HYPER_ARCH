"""Confirmaciones del plan y duración limitada de autorización sudo."""
import os
import subprocess
import unittest

import test_repository_recovery as recovery_tests

ROOT = recovery_tests.ROOT


class DeploymentConfirmationsTests(unittest.TestCase):
    def setUp(self):
        fixture = recovery_tests.RepositoryRecoveryTests("test_no_working_mirrorlist_stops_installation")
        fixture.setUp()
        self.addCleanup(fixture.doCleanups)
        self.work = fixture.work
        self.env = fixture.env
        self.run_code = fixture.run_code

    def test_session_refreshes_without_reauthentication_and_releases_lock(self):
        if os.geteuid() == 0:
            self.skipTest("Requiere usuario sin privilegios")
        (self.work / "sudo-cache").touch()
        result = self.run_code('''exec 8>"$SUDO_CACHE.lock"
flock -n 8
start_sudo_session 0.05
trap stop_sudo_session EXIT
pid=$SUDO_SESSION_PID
( stop_sudo_session )
exec 8>&-
flock -n "$SUDO_CACHE.lock" true
sleep 0.22
kill -0 "$pid"
stop_sudo_session
if kill -0 "$pid" 2>/dev/null; then exit 9; fi
printf 'SESSION_STOPPED\\n'
''')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("SESSION_STOPPED", result.stdout)
        calls = (self.work / "sudo-calls").read_text().splitlines()
        self.assertGreaterEqual(calls.count("-n -v"), 3)
        self.assertNotIn("-v", calls)

    def test_exit_trap_removes_helper_after_failure(self):
        if os.geteuid() == 0:
            self.skipTest("Requiere usuario sin privilegios")
        (self.work / "sudo-cache").touch()
        result = self.run_code('''start_sudo_session 45
trap stop_sudo_session EXIT
printf '%s' "$SUDO_SESSION_PID" > "$SUDO_CACHE.pid"
exit 19
''')
        self.assertEqual(result.returncode, 19)
        pid = int((self.work / "sudo-cache.pid").read_text())
        with self.assertRaises(ProcessLookupError):
            os.kill(pid, 0)

    def test_session_does_not_busy_loop_with_zero_interval(self):
        result = self.run_code("start_sudo_session 0")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.work / "sudo-calls").exists())

    def test_termination_cleans_session_and_preserves_signal_exit(self):
        if os.geteuid() == 0:
            self.skipTest("Requiere usuario sin privilegios")
        (self.work / "sudo-cache").touch()
        result = self.run_code('''start_sudo_session 45
trap stop_sudo_session EXIT
trap 'exit 143' TERM
printf '%s' "$SUDO_SESSION_PID" > "$SUDO_CACHE.pid"
kill -TERM "$BASHPID"
exit 99
''')
        self.assertEqual(result.returncode, 143)
        pid = int((self.work / "sudo-cache.pid").read_text())
        with self.assertRaises(ProcessLookupError):
            os.kill(pid, 0)

    def package_flags(self, **settings):
        code = '''set -euo pipefail
source "$1/src/lib/utils.sh"
log_info() { :; }; log_success() { :; }; log_warn() { :; }; log_error() { :; }
pacman() { [[ "$1" == -Q && -f "$PACKAGE_MARKER" ]]; }
paru() {
    [[ "$1" != --version ]] || return 0
    printf '%s\\n' "$@" > "$PACKAGE_FLAGS"
    touch "$PACKAGE_MARKER"
}
safe_install benjie-demo-package
'''
        env = {**self.env, "PACKAGE_MARKER": str(self.work / "installed"), "PACKAGE_FLAGS": str(self.work / "flags"), **settings}
        result = subprocess.run(["bash", "-c", code, "test", str(ROOT)], env=env, capture_output=True, text=True, check=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        return (self.work / "flags").read_text().splitlines()

    def test_routine_confirmation_does_not_suppress_aur_review(self):
        flags = self.package_flags(ASSUME_YES="true", ALLOW_UNREVIEWED_AUR="false")
        self.assertNotIn("--noconfirm", flags)
        self.assertIn("--confirm", flags)
        self.assertIn("--review", flags)
        self.assertNotIn("--skipreview", flags)
        self.assertIn("--nouseask", flags)

    def test_explicit_aur_permission_automates_selected_package(self):
        flags = self.package_flags(ASSUME_YES="true", ALLOW_UNREVIEWED_AUR="true")
        self.assertIn("--noconfirm", flags)
        self.assertIn("--skipreview", flags)
        self.assertNotIn("--skippgpcheck", flags)

    def test_interactive_mode_retains_package_prompts(self):
        flags = self.package_flags(ASSUME_YES="false", ALLOW_UNREVIEWED_AUR="false")
        self.assertIn("--confirm", flags)
        self.assertIn("--review", flags)
        self.assertNotIn("--noconfirm", flags)
        self.assertNotIn("--skipreview", flags)

    def test_preview_reports_policy_without_creating_state(self):
        env = {**self.env, "HOME": str(self.work / "home"), "XDG_STATE_HOME": str(self.work / "state")}
        for mode, expected in (([], "true; AUR sin revisión: false"),
                               (["--interactive"], "false; AUR sin revisión: false"),
                               (["--yes", "--allow-unreviewed-aur"], "true; AUR sin revisión: true")):
            result = subprocess.run(["bash", str(ROOT / "deploy_hyprland.sh"), "--dry-run", "--profile", "minimal", *mode],
                                    env=env, capture_output=True, text=True, check=False, timeout=5)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn(expected, result.stdout)
        self.assertFalse((self.work / "state").exists())
        self.assertFalse((self.work / "home").exists())


if __name__ == "__main__":
    unittest.main()
