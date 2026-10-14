"""Reanudación sobre Btrfs montado y rechazo de un disco con UUID duplicado."""
import os
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = (ROOT / "install.sh").read_text()
MOUNT_ONLY = SCRIPT[SCRIPT.index("mount_only() {"):SCRIPT.index('if [ "$SKIP_BASE" = false ]; then')]


class InstallResumeTests(unittest.TestCase):
    def resume(self, source):
        setup = '''set -euo pipefail
DISK=/dev/vda
FILESYSTEM=btrfs
BOOT_MODE=BIOS
log_info() { :; }
log_success() { printf 'RESUMED\\n'; }
log_error() { printf '%s\\n' "$*" >&2; }
cryptsetup() { return 1; }
mkdir() { :; }
mountpoint() { return 0; }
mount() { printf 'UNEXPECTED_MOUNT\\n' >&2; return 99; }
blkid() { printf 'shared-uuid\\n'; }
findmnt() {
    case "$*" in
        *UUID*) printf 'shared-uuid\\n' ;;
        *SOURCE*--nofsroot*) printf '%s\\n' "$TEST_SOURCE" ;;
        *MAJ:MIN*) printf '0:74\\n' ;;
        *) return 98 ;;
    esac
}
lsblk() { printf '254:2\\n'; }
'''
        return subprocess.run(["bash", "-c", setup + MOUNT_ONLY + "\nmount_only"],
                              env={**os.environ, "TEST_SOURCE": source},
                              text=True, capture_output=True, check=False)

    def test_existing_btrfs_mount_uses_backing_device(self):
        result = self.resume("/dev/vda2")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("RESUMED", result.stdout)

    def test_same_uuid_on_other_device_is_rejected(self):
        result = self.resume("/dev/vdb2")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("otro dispositivo", result.stderr)
        self.assertNotIn("RESUMED", result.stdout)


if __name__ == "__main__":
    unittest.main()
