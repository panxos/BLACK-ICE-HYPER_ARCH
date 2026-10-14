"""Autenticación caducada y fallos de mirrors sin modificar el sistema real."""
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

import test_installer_terminal as terminal_tests

ROOT = Path(__file__).resolve().parents[1]


class RepositoryRecoveryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(dir=Path.home() / ".cache/tmp/work")
        self.addCleanup(self.temp.cleanup)
        self.work = Path(self.temp.name)
        self.bin = self.work / "bin"
        self.bin.mkdir()
        self.env = {**os.environ, "PATH": str(self.bin) + ":" + os.environ["PATH"], "XDG_CACHE_HOME": str(self.work / "cache"),
                    "SUDO_CALLS": str(self.work / "sudo-calls"), "SUDO_CACHE": str(self.work / "sudo-cache")}
        self.script("sudo", '''printf '%s\\n' "$*" >> "$SUDO_CALLS"
case "$*" in
    '-n -v') test -f "$SUDO_CACHE"; exit $? ;;
    '-v') test "${DENY_AUTH:-false}" != true || exit 1; touch "$SUDO_CACHE"; exit 0 ;;
esac
[[ ${1:-} != -n ]] || shift
[[ ${1:-} != -- ]] || shift
exec "$@"
''')

    def script(self, name, content):
        path = self.bin / name
        path.write_text("#!/usr/bin/env bash\n" + content)
        path.chmod(0o755)

    def run_code(self, body, **settings):
        prefix = '''set -euo pipefail
log_info() { printf 'INFO %s\\n' "$*"; }
log_warn() { printf 'WARN %s\\n' "$*" >&2; }
log_error() { printf 'ERROR %s\\n' "$*" >&2; }
log_success() { printf 'OK %s\\n' "$*"; }
source "$1/src/lib/privileges.sh"
source "$1/src/lib/repositories.sh"
'''
        return subprocess.run(["bash", "-c", prefix + body, "test", str(ROOT)], env={**self.env, **settings},
                              text=True, capture_output=True, check=False, timeout=10)

    def tty_auth(self, **settings):
        console = terminal_tests.InstallerTerminalTests("test_eof_cancels_without_selecting_first_option")
        console.setUp()
        self.addCleanup(console.doCleanups)
        code = '''set -euo pipefail
log_warn() { printf 'WARN %s\\n' "$*" >&2; }
log_error() { printf 'ERROR %s\\n' "$*" >&2; }
source "$1/src/lib/privileges.sh"
run_as_root touch "$2"
'''
        return console.terminal(["bash", "-c", code, "test", str(ROOT), str(self.work / "operation")], [],
                                **{**self.env, **settings})

    @unittest.skipIf(os.geteuid() == 0, "Requiere usuario sin privilegios")
    def test_expired_sudo_requests_auth_then_runs_operation(self):
        status, value = self.tty_auth()
        self.assertEqual(status, 0, value)
        self.assertIn("sudo necesita autenticación", value)
        self.assertTrue((self.work / "operation").exists())
        self.assertEqual((self.work / "sudo-calls").read_text().splitlines()[:2], ["-n -v", "-v"])

    @unittest.skipIf(os.geteuid() == 0, "Requiere usuario sin privilegios")
    def test_denied_auth_does_not_run_operation(self):
        status, value = self.tty_auth(DENY_AUTH="true")
        self.assertEqual(status, 77, value)
        self.assertFalse((self.work / "operation").exists())

    @unittest.skipIf(os.geteuid() == 0, "Requiere usuario sin privilegios")
    def test_noninteractive_expiry_fails_without_password_prompt(self):
        result = self.run_code('run_as_root touch "$SUDO_CACHE.operation"', NON_INTERACTIVE="true")
        self.assertEqual(result.returncode, 77)
        self.assertIn("sudo -v", result.stderr)
        self.assertNotIn("\n-v\n", "\n" + (self.work / "sudo-calls").read_text())
        self.assertFalse((self.work / "sudo-cache.operation").exists())

    def test_auth_failure_is_not_retried_as_network_failure(self):
        result = self.run_code('''run_as_root() { printf 'ATTEMPT\\n'; return 77; }
retry_repository_command pacman -Syu
''')
        self.assertEqual(result.returncode, 77)
        self.assertEqual(result.stdout.count("ATTEMPT"), 1)

    def test_operation_failure_is_bounded_and_cannot_be_skipped(self):
        result = self.run_code('''run_as_root() { printf 'ATTEMPT\\n'; return 1; }
sleep() { :; }
retry_repository_command pacman -Syu
''')
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout.count("ATTEMPT"), 3)

    def mirror(self, mode, existing=True):
        destination = self.work / "mirrorlist"
        old = 'Server = https://existing.example/$repo/os/$arch\n'
        if existing:
            destination.write_text(old)
        self.script("reflector", '''target=${!#}
case "$REFLECTOR_MODE" in
    valid) printf 'Server = https://new.example/$repo/os/$arch\\n' > "$target" ;;
    invalid) printf '<html>network portal</html>\\n' > "$target" ;;
    http) printf 'Server = http://unsafe.example/$repo/os/$arch\\n' > "$target" ;;
    timeout) exit 124 ;;
esac
''')
        result = self.run_code('''run_as_root() { "$@"; }
optimize_arch_mirrors Chile "$MIRROR_DESTINATION"
''', REFLECTOR_MODE=mode, MIRROR_DESTINATION=str(destination))
        return result, destination, old

    def test_valid_mirrors_replace_list_and_keep_mode(self):
        result, destination, _ = self.mirror("valid")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("https://new.example", destination.read_text())
        self.assertEqual(destination.stat().st_mode & 0o777, 0o644)
        self.assertIn("validada y publicada", result.stdout)
        self.assertFalse(list(self.work.glob("mirrorlist.black-ice-*")))

    def test_invalid_or_timed_out_mirrors_preserve_previous_list(self):
        for mode in ("invalid", "http", "timeout"):
            with self.subTest(mode=mode):
                result, destination, old = self.mirror(mode)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(destination.read_text(), old)
                self.assertNotIn("validada y publicada", result.stdout)
                self.assertIn("se conserva la anterior", result.stderr)
                self.assertFalse(list((self.work / "cache/tmp/work").iterdir()))

    def test_no_working_mirrorlist_stops_installation(self):
        result, destination, _ = self.mirror("invalid", existing=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(destination.exists())
        self.assertIn("No hay una lista HTTPS válida", result.stderr)


if __name__ == "__main__":
    unittest.main()
