import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("system_manager", ROOT / "src/system/manager.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
transaction_spec = importlib.util.spec_from_file_location("transaction", ROOT / "scripts/system-transaction.py")
transaction = importlib.util.module_from_spec(transaction_spec)
transaction_spec.loader.exec_module(transaction)


class ManagerTests(unittest.TestCase):
    def setUp(self):
        parent = Path.home() / ".cache/tmp/work"
        parent.mkdir(parents=True, exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(dir=parent)
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.manager = module.Manager(self.base / "state", ROOT / "config/apps.json", self.base / "config")

    def test_projects_survive_reopen_and_keep_targets_separate(self):
        self.manager.save_project("benjie", "10.10.10.1")
        self.manager.save_project("almendra", "lab.example")
        self.manager.activate_project("benjie")
        self.manager.set_target("10.10.10.2")
        reopened = module.Manager(self.manager.root, ROOT / "config/apps.json", self.manager.config)
        self.assertEqual(reopened.active_target(), ("10.10.10.2", "benjie"))
        reopened.activate_project("almendra")
        self.assertEqual(reopened.active_target(), ("lab.example", "almendra"))
        reopened.activate_project("")
        self.assertEqual(reopened.active_target(), ("", ""))

    def test_invalid_targets_and_profiles_do_not_touch_state(self):
        for value in (";touch /bad", "-bad", "a/../../etc", "$(id)", "10.0.0.1\nfoo"):
            with self.subTest(value=value), self.assertRaises(ValueError):
                self.manager.save_project("benjie", value)
        with self.assertRaises(ValueError):
            self.manager.save_project("../escape")
        with self.assertRaises(ValueError):
            self.manager.save_project("benjie", vpn="$(id)")
        self.assertFalse((self.manager.root / "projects.json").exists())

    def test_vpn_disconnect_does_not_stop_external_connection(self):
        with patch.object(module, "command") as command:
            with self.assertRaises(ValueError):
                self.manager.vpn("disconnect")
            command.assert_not_called()

    def test_vpn_existing_external_profile_is_preserved(self):
        vpn = "01234567-1234-1234-1234-0123456789ab"
        self.manager.save_project("benjie", vpn=vpn)
        self.manager.activate_project("benjie")
        with patch.object(module, "command", side_effect=["vpn", vpn]) as command:
            with self.assertRaises(RuntimeError):
                self.manager.vpn("connect")
            self.assertEqual(command.call_count, 2)

    def test_tunnel_without_address_is_disconnected(self):
        with patch.object(module, "command", return_value='[{"addr_info": []}]'):
            self.assertFalse(self.manager.vpn_status()["connected"])
        with patch.object(module, "command", return_value='[{"flags":["UP"],"addr_info": [{"family":"inet","local":"10.10.14.5"}]}]'):
            self.assertTrue(self.manager.vpn_status()["connected"])
        with patch.object(module, "command", return_value='[{"flags":[],"operstate":"DOWN","addr_info": [{"family":"inet","local":"10.10.14.5"}]}]'):
            self.assertFalse(self.manager.vpn_status()["connected"])

    def test_external_reactivation_of_same_vpn_is_not_disconnected(self):
        vpn = "01234567-1234-1234-1234-0123456789ab"
        self.manager.write("vpn", {"uuid": vpn, "identity": {"path":"old"}})
        with patch.object(module, "command", return_value=vpn) as command, patch.object(self.manager, "vpn_identity", return_value={"path":"new"}):
            with self.assertRaisesRegex(RuntimeError, "fuera"):
                self.manager.vpn("disconnect")
            self.assertEqual(command.call_count, 1)

    def test_saving_active_project_synchronizes_legacy_target(self):
        self.manager.save_project("benjie", "10.10.10.1")
        self.manager.activate_project("benjie")
        self.manager.save_project("benjie", "10.10.10.2")
        self.assertEqual((self.manager.config / "bin/target").read_text(), "10.10.10.2 benjie\n")

    def test_jobs_persist_and_verify_real_installed_state(self):
        job = self.manager.enqueue(["firefox", "firefox"])
        self.assertEqual(job["packages"], ["firefox"])
        with patch.object(self.manager, "installed", side_effect=[set(), {"firefox"}]):
            result = self.manager.run_jobs(lambda *_: "Instalado")
        self.assertEqual(result[0]["state"], "done")
        self.assertEqual(result[0]["attempts"], 1)
        self.assertEqual((self.manager.root / "jobs.json").stat().st_mode & 0o777, 0o600)

    def test_false_success_is_failure_and_can_retry(self):
        job = self.manager.enqueue(["firefox"])
        with patch.object(self.manager, "installed", return_value=set()):
            self.manager.run_jobs(lambda *_: "exit 0")
        self.assertEqual(self.manager.read("jobs", [])[0]["state"], "failed")
        self.manager.change_job(job["id"], "retry")
        with patch.object(self.manager, "installed", return_value={"firefox"}):
            result = self.manager.run_jobs(lambda *_: self.fail("No debe reinstalar un paquete reconciliado"))
        self.assertEqual(result[0]["state"], "done")

    def test_interrupted_job_is_not_restarted_blindly(self):
        job = self.manager.enqueue(["firefox"])
        job["state"] = "running"
        self.manager.write("jobs", [job])
        result = self.manager.run_jobs(lambda *_: self.fail("No ejecutar trabajo interrumpido sin reconciliación"))
        self.assertEqual(result[0]["state"], "interrupted")

    def test_cancelled_job_does_not_execute(self):
        job = self.manager.enqueue(["firefox"])
        self.manager.change_job(job["id"], "cancel")
        self.manager.run_jobs(lambda *_: self.fail("No debe ejecutar cancelado"))
        self.assertEqual(self.manager.read("jobs", [])[0]["state"], "cancelled")

    def test_unknown_packages_rejected(self):
        with self.assertRaises(ValueError):
            self.manager.enqueue(["--overwrite=*"])

    def test_mutual_exclusion(self):
        with self.manager.locked(), self.assertRaises(RuntimeError), self.manager.locked():
            self.fail("No debe obtener un segundo bloqueo")

    def test_lab_budget_and_ownership(self):
        spec = {"name":"benjie", "engine":"kvm", "cpus":5, "memory_mib":1024, "disk_gib":20}
        with self.assertRaises(ValueError):
            self.manager.validate_lab(spec, self.manager.labs())
        spec["cpus"] = 4
        registered = self.manager.labs()
        registered["labs"]["almendra"] = dict(spec, name="almendra", cpus=1)
        with self.assertRaises(ValueError):
            self.manager.validate_lab(spec, registered)
        with patch.object(module, "command") as command:
            with self.assertRaises(ValueError):
                self.manager.lab_action("vm-ajena", "delete", "vm-ajena")
            command.assert_not_called()

    def test_container_limits_are_checked_in_engine_output(self):
        lab = {"engine":"podman", "resource":"black-ice-benjie", "id":"123", "cpus":1, "memory_mib":256}
        inspected = [{"HostConfig":{"Memory":256 * 1024**2, "NanoCpus":1_000_000_000, "ReadonlyRootfs":True, "Privileged":False, "PidsLimit":256,
                                     "NetworkMode":"none", "CapDrop":["ALL"], "SecurityOpt":["no-new-privileges"]}, "Config":{"Labels":{"black-ice.id":"123"}}}]
        with patch.object(module, "command", return_value=json.dumps(inspected)):
            self.manager.verify_container_limits(lab)
        inspected[0]["HostConfig"]["Memory"] = 0
        with patch.object(module, "command", return_value=json.dumps(inspected)), self.assertRaises(RuntimeError):
            self.manager.verify_container_limits(lab)

    def test_checkpoint_cannot_be_marked_verified_before_restore(self):
        recovery = self.base / "recovery"
        (recovery / "1").mkdir(parents=True)
        (recovery / "1/manifest.json").write_text(json.dumps({"verified":False}))
        with patch.object(transaction, "RECOVERY", recovery), self.assertRaisesRegex(RuntimeError, "restaurado"):
            transaction.verify_recovery("1")
        self.assertFalse(json.loads((recovery / "1/manifest.json").read_text())["verified"])

    def test_project_export_excludes_vpn_and_private_notes(self):
        self.manager.save_project("benjie", "lab.example", "01234567-1234-1234-1234-0123456789ab", "nota privada")
        destination = self.base / "export.json"
        self.manager.export_project("benjie", destination)
        value = json.loads(destination.read_text())
        self.assertEqual(set(value), {"schema", "name", "target"})
        self.assertEqual(destination.stat().st_mode & 0o777, 0o600)

    def test_running_vm_cannot_be_deleted(self):
        lab = {"id":"123", "resource":"black-ice-benjie", "engine":"kvm", "disk":str(self.base / "outside")}
        registered = self.manager.labs()
        registered["labs"]["benjie"] = lab
        self.manager.write("labs", registered)
        with patch.object(module, "command", side_effect=["123", "running"]) as command:
            with self.assertRaises(ValueError):
                self.manager.lab_action("benjie", "delete", "benjie")
            self.assertEqual(command.call_count, 2)

    def test_vm_modified_above_budget_is_not_started(self):
        lab = {"id":"123", "resource":"black-ice-benjie", "engine":"kvm", "cpus":1, "memory_mib":1024, "disk":str(self.base / "disk")}
        registered = self.manager.labs()
        registered["labs"]["benjie"] = lab
        self.manager.write("labs", registered)
        xml = '<domain><memory unit="MiB">8192</memory><vcpu>1</vcpu></domain>'
        with patch.object(module, "command", side_effect=["123", xml]) as command:
            with self.assertRaisesRegex(RuntimeError, "límites"):
                self.manager.lab_action("benjie", "start")
            self.assertEqual(command.call_count, 2)

    def test_force_stop_requires_explicit_resource_confirmation(self):
        registered = self.manager.labs()
        registered["labs"]["benjie"] = {"id":"123", "engine":"kvm", "resource":"black-ice-benjie"}
        self.manager.write("labs", registered)
        with patch.object(module, "command") as command, self.assertRaisesRegex(ValueError, "Confirma"):
            self.manager.lab_action("benjie", "force-stop")
        command.assert_not_called()

    def test_machine_command_uses_stable_locale(self):
        with patch.dict(module.os.environ, {"LC_ALL":"es_CL.UTF-8"}):
            self.assertEqual(module.command([sys.executable, "-c", "import os; print(os.environ['LC_ALL'])"]), "C")

    def test_live_root_cannot_be_restored(self):
        with patch.object(transaction.Path, "exists", return_value=False), self.assertRaisesRegex(RuntimeError, "ISO"):
            transaction.restore_offline("1", "uuid")

    def test_non_btrfs_does_not_claim_recovery(self):
        with patch.object(transaction, "preflight"), patch.object(transaction, "mount_field", return_value="ext4"), self.assertRaisesRegex(RuntimeError, "Btrfs"):
            transaction.checkpoint()

    def test_nested_package_database_rejected(self):
        def field(path, value):
            if value == "FSTYPE":
                return "btrfs"
            if value == "UUID":
                return "uuid"
            return "/@var_lib" if path == "/var/lib/pacman" else "/@"
        with patch.object(transaction, "preflight"), patch.object(transaction, "mount_field", side_effect=field), patch.object(transaction, "run", return_value="256"), self.assertRaisesRegex(RuntimeError, "fuera"):
            transaction.checkpoint()

    def test_unmounted_nested_subvolume_is_not_included_in_checkpoint(self):
        def field(path, value):
            return {"FSTYPE": "btrfs", "UUID": "uuid", "FSROOT": "/@"}[value]
        def run(*args, **kwargs):
            return "257" if args[-1] == "/var/lib/pacman" else "256"
        with patch.object(transaction, "preflight"), patch.object(transaction, "mount_field", side_effect=field), patch.object(transaction, "run", side_effect=run), self.assertRaisesRegex(RuntimeError, "anidado"):
            transaction.checkpoint()

    def test_restored_subvolume_uses_path_instead_of_obsolete_id(self):
        fstab = self.base / "fstab"
        fstab.write_text("UUID=root / btrfs rw,subvolid=256,subvol=/@ 0 0\nUUID=root /home btrfs rw,subvolid=257,subvol=/@home 0 0\nUUID=esp /boot/efi vfat defaults 0 2\n")
        transaction.portable_fstab(fstab)
        content = fstab.read_text()
        self.assertNotIn("subvolid=", content)
        self.assertIn("subvol=/@home", content)
        self.assertIn("UUID=esp /boot/efi vfat defaults 0 2", content)


class ModuleJournalTests(unittest.TestCase):
    def test_failed_sourced_module_stops_before_checkpoint_and_dependents(self):
        parent = Path.home() / ".cache/tmp/work"
        with tempfile.TemporaryDirectory(dir=parent) as directory:
            base = Path(directory)
            (base / "bad.sh").write_text("false\ntouch \"$MARKER\"\n")
            script = '''set -euo pipefail
MODULE_ROOT="$1"
MODULE_STATE="$2/state.json"
MODULE_IDENTITY=uuid
MODULE_FINGERPRINT=config
MARKER="$2/unsafe-marker"
source "$1/src/lib/module-runner.sh"
log_info() { :; }
log_error() { :; }
verify_install_module() { return 0; }
run_install_module base "$2/bad.sh"
touch "$2/dependent"
'''
            result = subprocess.run(["bash", "-c", script, "bash", str(ROOT), str(base)], capture_output=True, text=True, check=False)
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse((base / "unsafe-marker").exists())
            self.assertFalse((base / "dependent").exists())
            self.assertEqual(json.loads((base / "state.json").read_text())["modules"]["base"]["status"], "running")

    def test_uuid_config_hash_and_interruption(self):
        parent = Path.home() / ".cache/tmp/work"
        with tempfile.TemporaryDirectory(dir=parent) as directory:
            state = Path(directory) / "state.json"
            script = Path(directory) / "module.sh"
            script.write_text("true\n")
            args = ["python3", str(ROOT / "scripts/module-state.py"), "--state", str(state), "--identity", "disk-uuid", "--fingerprint", "config-hash", "--module", "base", "--source", str(script)]
            def invoke(operation, options=None):
                return subprocess.run([*args, operation, *(options or [])], capture_output=True, text=True, check=False)
            self.assertEqual(invoke("begin").returncode, 0)
            self.assertEqual(invoke("status").returncode, 1)
            self.assertEqual(invoke("done").returncode, 0)
            self.assertEqual(invoke("status").returncode, 0)
            self.assertNotEqual(invoke("begin", ["--identity", "another-disk"]).returncode, 0)
            self.assertNotEqual(invoke("begin", ["--fingerprint", "other-config"]).returncode, 0)
            script.write_text("false\n")
            self.assertEqual(invoke("status").returncode, 1)
            self.assertEqual(json.loads(state.read_text())["identity"], "disk-uuid")
