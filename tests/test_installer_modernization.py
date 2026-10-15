import importlib.util
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("app_selector", ROOT / "scripts/select-apps.py")
selector = importlib.util.module_from_spec(spec)
spec.loader.exec_module(selector)


class AppSelectionTests(unittest.TestCase):
    def test_minimal_has_no_optional_apps(self):
        self.assertEqual(selector.selection("minimal", [], []), [])

    def test_groups_and_individual_apps_are_deduplicated(self):
        chosen = selector.selection("desktop", ["Browsers"], ["firefox", "nmap"])
        self.assertEqual(chosen.count("firefox"), 1)
        self.assertIn("brave-bin", chosen)
        self.assertIn("nmap", chosen)
        self.assertNotIn("anydesk-bin", chosen)

    def test_unknown_selection_is_rejected(self):
        with self.assertRaises(ValueError):
            selector.selection("minimal", [], ["x;touch /bad"])

    def test_full_includes_every_app_once(self):
        self.assertEqual(set(selector.selection("full", [], [])), set(selector.APPS))

    def test_save_load_and_private_plan(self):
        parent = Path.home() / ".cache/tmp/work"
        parent.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=parent) as directory:
            plan = Path(directory) / "plan.json"
            result = subprocess.run(["python3", str(ROOT / "scripts/select-apps.py"), "--profile", "pentest", "--output", str(plan)], capture_output=True, text=True, check=True)
            self.assertEqual(plan.stat().st_mode & 0o777, 0o600)
            self.assertEqual(json.loads(result.stdout), json.loads(plan.read_text()))
            result = subprocess.run(["python3", str(ROOT / "scripts/select-apps.py"), "--load", str(plan), "--packages"], capture_output=True, text=True, check=True)
            self.assertIn("nmap", result.stdout.splitlines())
            self.assertNotIn("sliver", result.stdout.splitlines())

    def test_preview_does_not_run_installation_commands(self):
        result = subprocess.run(["bash", str(ROOT / "deploy_hyprland.sh"), "--dry-run", "--profile", "minimal"], capture_output=True, text=True, check=True, env={**os.environ, "HOME": "/nonexistent/black-ice-preview"})
        self.assertIn('"apps": []', result.stdout)
        self.assertIn("No se modificó", result.stdout)


class DiskSafetyTests(unittest.TestCase):
    def check(self, kind="disk", mounts="", readonly="0"):
        script = '''
source "$1/src/lib/install-safety.sh"
log_error() { echo "$*" >&2; }
lsblk() {
    case "$*" in
        *TYPE*) echo "$KIND" ;;
        *MOUNTPOINTS*) echo "$MOUNTS" ;;
        *RO*) echo "$READONLY" ;;
    esac
}
validate_target_disk /dev/null
'''
        # Sustituir solo la prueba de bloque; nunca crear ni tocar discos.
        script = script.replace('source "$1/src/lib/install-safety.sh"', (ROOT / "src/lib/install-safety.sh").read_text().replace('[[ -b "$disk" ]]', '[[ -c "$disk" ]]'))
        return subprocess.run(["bash", "-c", script], env={**os.environ, "KIND": kind, "MOUNTS": mounts, "READONLY": readonly}, text=True, capture_output=True, check=False).returncode

    def test_empty_writable_disk_is_allowed(self):
        self.assertEqual(self.check(), 0)

    def test_mounted_or_swap_disk_is_rejected(self):
        for mount in ("/", "/mnt", "[SWAP]", "\n/boot\n"):
            self.assertNotEqual(self.check(mounts=mount), 0)

    def test_partition_and_readonly_are_rejected(self):
        self.assertNotEqual(self.check(kind="part"), 0)
        self.assertNotEqual(self.check(readonly="1"), 0)


class FinalAuditTests(unittest.TestCase):
    def audit(self, encrypted=False, missing=None, crypt_argument=False):
        parent = Path.home() / ".cache/tmp/work"
        parent.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=parent) as directory:
            root = Path(directory)
            files = {
                "boot/vmlinuz-linux": "kernel",
                "boot/initramfs-linux.img": "initramfs",
                "boot/grub/grub.cfg": "cryptdevice=UUID=test" if crypt_argument else "menuentry test",
                "etc/fstab": "UUID=test / btrfs defaults 0 0",
            }
            for name, content in files.items():
                if name != missing:
                    path = root / name
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_text(content)
            return subprocess.run([
                "bash", "-euo", "pipefail", "-c",
                'source "$1"; audit_installed_system "$2" linux "$3"', "audit",
                str(ROOT / "src/lib/post-install-audit.sh"), str(root),
                "true" if encrypted else "false",
            ], capture_output=True, text=True, check=False)

    def test_unencrypted_installation_does_not_require_luks(self):
        self.assertEqual(self.audit().returncode, 0)

    def test_encrypted_installation_requires_unlock_argument(self):
        self.assertNotEqual(self.audit(encrypted=True).returncode, 0)
        self.assertEqual(self.audit(encrypted=True, crypt_argument=True).returncode, 0)

    def test_missing_boot_files_or_fstab_stop_installation(self):
        for path in ("boot/vmlinuz-linux", "boot/initramfs-linux.img", "boot/grub/grub.cfg", "etc/fstab"):
            with self.subTest(path=path):
                self.assertNotEqual(self.audit(missing=path).returncode, 0)


class KeyboardLayoutTests(unittest.TestCase):
    def test_console_layout_is_translated_for_xkb(self):
        for console, xkb in (("la-latin1", "latam"), ("br-abnt2", "br"), ("us", "us"), ("es", "es")):
            with self.subTest(console=console):
                result = subprocess.run([
                    "bash", "-c", 'source "$1"; console_to_xkb_layout "$2"', "keyboard",
                    str(ROOT / "src/lib/utils.sh"), console,
                ], capture_output=True, text=True, check=True)
                self.assertEqual(result.stdout.strip(), xkb)


class SnapperRegistrationTests(unittest.TestCase):
    def register(self, original):
        parent = Path.home() / ".cache/tmp/work"
        parent.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=parent) as directory:
            path = Path(directory) / "snapper"
            path.write_text(original)
            source = (ROOT / "src/modules/03_config.sh").read_text()
            program = source.split("python3 - <<'REGISTER_CONFIG'\n", 1)[1].split("\nREGISTER_CONFIG", 1)[0]
            program = program.replace("Path('/etc/conf.d/snapper')", f"Path({str(path)!r})")
            result = subprocess.run(["python3", "-c", program], capture_output=True, text=True, check=False)
            return result.returncode, path.read_text()

    def test_existing_snapshot_configs_are_preserved(self):
        code, content = self.register('# setting\nSNAPPER_CONFIGS="home"\n')
        self.assertEqual(code, 0)
        self.assertEqual(content, '# setting\nSNAPPER_CONFIGS="home root"\n')

    def test_registered_root_is_not_rewritten(self):
        original = '# setting\nSNAPPER_CONFIGS="root home"\n'
        self.assertEqual(self.register(original), (0, original))

    def test_malformed_registry_is_not_overwritten(self):
        original = 'SNAPPER_CONFIGS="home;bad"\n'
        code, content = self.register(original)
        self.assertNotEqual(code, 0)
        self.assertEqual(content, original)


class PackageSafetyTests(unittest.TestCase):
    def test_conflict_does_not_remove_packages_or_disable_verification(self):
        script = '''
source "$1/src/lib/utils.sh"
log_info() { :; }; log_success() { :; }; log_warn() { :; }; log_error() { :; }
sudo() { "$@"; }
pacman() {
    echo "pacman $*" >&2
    case "$1" in
        -Q) return 1 ;;
        -Si) return 0 ;;
        -S) echo 'packages are in conflict' >&2; return 1 ;;
        *) echo 'UNEXPECTED MUTATION' >&2; return 9 ;;
    esac
}
safe_install firefox
'''
        result = subprocess.run(["bash", "-c", script, "test", str(ROOT)], capture_output=True, text=True, check=False)
        self.assertEqual(result.returncode, 1)
        self.assertIn("packages are in conflict", result.stderr)
        for forbidden in ("-R", "--overwrite", "--skippgpcheck", "UNEXPECTED MUTATION"):
            self.assertNotIn(forbidden, result.stderr)

    def test_unreviewed_aur_is_skipped_in_unattended_mode(self):
        script = '''
source "$1/src/lib/utils.sh"
log_info() { :; }; log_success() { :; }; log_warn() { :; }; log_error() { :; }
pacman() { return 1; }
paru() { [[ "$1" == --version ]] && return 0; echo 'UNREVIEWED INSTALL' >&2; return 9; }
NON_INTERACTIVE=true
safe_install a-demo-package
'''
        result = subprocess.run(["bash", "-c", script, "test", str(ROOT)], capture_output=True, text=True, check=False)
        self.assertEqual(result.returncode, 1)
        self.assertNotIn("UNREVIEWED INSTALL", result.stderr)


class OptionalWallpaperTests(unittest.TestCase):
    def run_theme(self, response):
        parent = Path.home() / ".cache/tmp/work"
        parent.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=parent) as directory:
            home = Path(directory)
            walls = home / "Pictures/wallpapers"
            walls.mkdir(parents=True)
            project = home / "project"
            source_wall = project / "assets/sddm/themes/black-ice-obsidian/assets/wallpaper.png"
            source_wall.parent.mkdir(parents=True)
            source_wall.write_bytes(b"shipped theme wallpaper")
            (home / ".settarget").write_text("existing-project-target\n")
            script = '''
set -euo pipefail
banner() { :; }; log_info() { :; }; log_success() { :; }
log_warn() { :; }; success() { :; }; safe_install() { :; }
chown() { :; }; pacman() { :; }; ping() { :; }
sudo() { [[ "$*" != *xdg-user-dir* ]] || printf '%s/Pictures\\n' "$USER_HOME"; }
curl() {
    if [[ "$*" == *api.github.com* ]]; then
        printf '%s' "$API_RESPONSE"
    else
        return 22
    fi
}
command() { [[ "$*" == *awww* ]] && return 1; builtin command "$@"; }
source "$MODULE"
'''
            result = subprocess.run(["bash", "-c", script], capture_output=True, text=True, check=False,
                                    env={**os.environ, "API_RESPONSE": response, "USER_HOME": str(home),
                                         "CURRENT_USER": "benjie", "DOTFILES_DIR": str(home / "dotfiles"),
                                         "SCRIPT_DIR": str(project),
                                         "MODULE": str(ROOT / "src/deploy/04_theme_setup.sh")})
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual((home / ".settarget").read_text(), "existing-project-target\n")
            self.assertEqual((walls / "black-ice-obsidian.png").read_bytes(), b"shipped theme wallpaper")
            self.assertFalse((walls / "black-ice-default.png").exists())

    def test_empty_optional_wallpaper_list_does_not_abort(self):
        self.run_theme("[]")

    def test_failed_optional_download_does_not_abort(self):
        self.run_theme('[{"download_url":"https://example.invalid/wallpaper.png"}]')

    def test_invalid_optional_api_response_does_not_abort(self):
        self.run_theme("upstream unavailable")


class ScriptDeploymentTests(unittest.TestCase):
    def test_repeat_deployment_replaces_managed_links_and_keeps_personal_scripts(self):
        parent = Path.home() / ".cache/tmp/work"
        parent.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=parent) as directory:
            root = Path(directory)
            source = root / "project/dotfiles/bin"
            source.mkdir(parents=True)
            (source / "music_widget").write_text("managed-script\n")
            home = root / "benjie"
            (home / "bin").mkdir(parents=True)
            destination = home / "bin/music_widget"
            destination.symlink_to(source / "music_widget")
            personal = home / "bin/personal-script"
            personal.write_text("keep\n")
            script = 'set -euo pipefail\nbanner() { :; }; chown() { :; }; log_info() { :; }; log_success() { :; };\n'
            script += (ROOT / "src/deploy/03_terminal_config.sh").read_text().split("# --- Instalar Zsh", 1)[0]
            env = {**os.environ, "SCRIPT_DIR": str(root / "project"), "DOTFILES_DIR": str(root / "project/dotfiles"),
                   "USER_HOME": str(home), "CURRENT_USER": "benjie"}
            for _ in range(2):
                result = subprocess.run(["bash", "-c", script], capture_output=True, text=True, env=env, check=False)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertFalse(destination.is_symlink())
                self.assertEqual(destination.read_text(), "managed-script\n")
                self.assertEqual((source / "music_widget").read_text(), "managed-script\n")
                self.assertEqual(personal.read_text(), "keep\n")


if __name__ == "__main__":
    unittest.main()
