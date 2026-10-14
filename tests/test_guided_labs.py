"""Plantillas, integridad y rechazo de cambios en el aislamiento real del motor."""
import copy
import hashlib
import io
import json
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import Mock, patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src/system"))
import laboratories
import manager


class GuidedLabsTests(unittest.TestCase):
    def setUp(self):
        workspace = Path.home() / ".cache/tmp/work"
        workspace.mkdir(parents=True, exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(dir=workspace)
        self.addCleanup(self.temp.cleanup)
        self.manager = manager.Manager(Path(self.temp.name) / "state", ROOT / "config/apps.json")
        self.run = Mock()
        self.assistant = laboratories.Laboratories(self.manager, self.run)

    def test_unknown_duplicate_and_excessive_budget_fail_before_download(self):
        with self.assertRaises(ValueError):
            self.assistant.create("unknown", "benjie")
        registered = self.manager.labs()
        registered["labs"]["benjie"] = {"cpus": 4, "memory_mib": 4096, "disk_gib": 60}
        self.manager.write("labs", registered)
        for name in ("benjie", "almendra"):
            with self.assertRaises(ValueError):
                self.assistant.create("alpine", name)
        self.run.assert_not_called()

    def test_missing_engine_has_actionable_packages_without_download(self):
        with patch.object(laboratories.shutil, "which", return_value=None), patch.object(laboratories.os, "geteuid", return_value=1000):
            result = self.assistant.requirements("alpine")
            self.assertEqual(result["packages"], ["podman"])
            self.assertFalse(result["ready"])
            with self.assertRaisesRegex(ValueError, "podman"):
                self.assistant.create("alpine", "benjie")
        self.run.assert_not_called()

    def test_rootful_engine_is_rejected(self):
        self.run.return_value = json.dumps({"host": {"security": {"rootless": False}, "cgroupVersion": "v2"}})
        with patch.object(laboratories.shutil, "which", return_value="/usr/bin/podman"), patch.object(laboratories.os, "geteuid", return_value=1000):
            result = self.assistant.requirements("alpine")
            self.assertFalse(result["ready"])
            self.assertIn("Podman debe funcionar sin root.", result["problems"])

    def test_official_tag_is_pinned_before_resource_creation(self):
        digest = "docker.io/library/alpine@sha256:" + "a" * 64
        self.run.side_effect = [RuntimeError("Image not found"), "pulled", json.dumps([{"RepoDigests": [digest]}])]
        with patch.object(self.assistant, "requirements", return_value={"ready": True}), \
                patch.object(self.manager, "create_lab", side_effect=lambda spec: spec):
            spec = self.assistant.create("alpine", "benjie")
        self.assertEqual(spec["image"], digest)
        self.assertEqual((spec["network"], spec["user"], spec["shell"]), ("none", "1000:1000", "/bin/sh"))

    def test_wrong_repository_digest_never_creates_resource(self):
        self.run.return_value = json.dumps([{"RepoDigests": ["evil.invalid/alpine@sha256:" + "a" * 64]}])
        with patch.object(self.assistant, "requirements", return_value={"ready": True}), patch.object(self.manager, "create_lab") as create:
            with self.assertRaisesRegex(ValueError, "digest"):
                self.assistant.create("alpine", "benjie")
            create.assert_not_called()

    def test_cached_verified_image_does_not_pull_or_require_registry(self):
        digest = "docker.io/library/alpine@sha256:" + "a" * 64
        self.run.return_value = json.dumps([{"RepoDigests": [digest]}])
        with patch.object(self.assistant, "requirements", return_value={"ready": True}), \
                patch.object(self.manager, "create_lab", side_effect=lambda spec: spec):
            lab = self.assistant.create("alpine", "benjie")
        self.assertEqual(lab["image"], digest)
        self.assertEqual(len(self.run.call_args_list), 1)
        self.assertNotIn("pull", self.run.call_args.args[0])

    def download(self, content, checksum):
        response = io.BytesIO(content)
        response.url = "https://dl-cdn.alpinelinux.org/alpine/fixture.iso"
        template = {"url": response.url, "iso_sha256": checksum}
        with patch.object(laboratories.urllib.request, "urlopen", return_value=response):
            return self.assistant.download_iso(template, Mock())

    def test_iso_is_published_after_hash_and_reused_without_network(self):
        content = b"official ISO fixture"
        checksum = hashlib.sha256(content).hexdigest()
        path = self.download(content, checksum)
        self.assertEqual(path.read_bytes(), content)
        with patch.object(laboratories.urllib.request, "urlopen") as network:
            cached = self.assistant.download_iso({"url": "https://invalid", "iso_sha256": checksum}, Mock())
        self.assertEqual(cached, path)
        network.assert_not_called()

    def test_bad_iso_leaves_no_partial_or_published_file(self):
        with self.assertRaisesRegex(ValueError, "SHA256"):
            self.download(b"corrupted", "a" * 64)
        self.assertEqual(list((self.manager.root / "assets").iterdir()), [])

    def test_altered_cached_iso_is_rejected_without_replacement(self):
        checksum = hashlib.sha256(b"original").hexdigest()
        path = self.download(b"original", checksum)
        path.write_bytes(b"altered")
        with self.assertRaisesRegex(ValueError, "guardada"):
            self.assistant.download_iso({"iso_sha256": checksum}, Mock())

    def inspected(self):
        return {"HostConfig": {"Memory": 256 * 1024**2, "NanoCpus": 1_000_000_000, "ReadonlyRootfs": True,
                               "Privileged": False, "PidsLimit": 256, "NetworkMode": "none", "CapDrop": ["ALL"],
                               "SecurityOpt": ["no-new-privileges"]},
                "Config": {"Labels": {"black-ice.id": "123"}, "User": "1000:1000"}, "Mounts": [], "State": {"Running": True}}

    def lab(self):
        return {"id": "123", "resource": "black-ice-benjie", "engine": "podman", "name": "benjie",
                "memory_mib": 256, "cpus": 1, "disk_gib": 1, "network": "none", "user": "1000:1000", "shell": "/bin/sh"}

    def test_network_privileges_mounts_ports_and_user_changes_are_rejected(self):
        changes = [("NetworkMode", "host"), ("CapDrop", []), ("SecurityOpt", []),
                   ("Binds", ["/home:/host"]), ("PortBindings", {"80/tcp": []}), ("PidMode", "host")]
        for key, value in changes:
            fixture = self.inspected()
            fixture["HostConfig"][key] = value
            with self.subTest(key=key), patch.object(manager, "command", return_value=json.dumps([fixture])), self.assertRaises(RuntimeError):
                self.manager.verify_container_limits(self.lab())
        for mutate in (lambda d: d["Config"].update(User="0"), lambda d: d.update(Mounts=[{"Type": "bind", "Source": "/home"}])):
            fixture = self.inspected()
            mutate(fixture)
            with patch.object(manager, "command", return_value=json.dumps([fixture])), self.assertRaises(RuntimeError):
                self.manager.verify_container_limits(self.lab())

    def test_open_rechecks_running_container_and_never_uses_host_shell(self):
        self.manager.write("labs", {"labs": {"benjie": self.lab()}})
        self.run.return_value = json.dumps([self.inspected()])
        with patch.object(manager, "command", return_value=self.run.return_value):
            args = self.assistant.open_command("benjie")
        self.assertEqual(args[-6:], ["podman", "exec", "--interactive", "--tty", "black-ice-benjie", "/bin/sh"])
        altered = copy.deepcopy(self.inspected())
        altered["HostConfig"]["NetworkMode"] = "host"
        with patch.object(manager, "command", return_value=json.dumps([altered])), self.assertRaises(RuntimeError):
            self.assistant.open_command("benjie")

    def test_podman_expanded_cap_drop_requires_empty_effective_and_bounding_caps(self):
        fixture = self.inspected()
        fixture["HostConfig"]["CapDrop"] = ["CAP_CHOWN", "CAP_SETUID"]
        fixture.update(EffectiveCaps=None, BoundingCaps=None)
        with patch.object(manager, "command", return_value=json.dumps([fixture])):
            self.manager.verify_container_limits(self.lab())
        fixture["BoundingCaps"] = ["CAP_NET_RAW"]
        with patch.object(manager, "command", return_value=json.dumps([fixture])), self.assertRaises(RuntimeError):
            self.manager.verify_container_limits(self.lab())

    def test_missing_resource_is_not_reported_as_running(self):
        self.manager.write("labs", {"labs": {"benjie": self.lab()}})
        self.run.side_effect = RuntimeError("No such container")
        result = self.assistant.status("benjie")
        self.assertFalse(result["running"])
        self.assertIn("No disponible", result["state"])

    def test_guided_export_does_not_include_cache_or_vm_disk_paths(self):
        lab = {**self.lab(), "template": "alpine-vm", "image": "/private/base.qcow2", "iso": "/private/source.iso"}
        self.manager.write("labs", {"labs": {"benjie": lab}})
        output = Path(self.temp.name) / "export.json"
        self.manager.export_lab("benjie", output)
        data = json.loads(output.read_text())
        self.assertEqual(data["template"], "alpine-vm")
        self.assertNotIn("image", data)
        self.assertNotIn("iso", data)

    def test_minimal_qemu_uses_available_vga_vnc_without_requiring_spice(self):
        capabilities = "<domainCapabilities><devices><video><enum name='modelType'><value>vga</value></enum></video>" \
                       "<graphics><enum name='type'><value>vnc</value></enum></graphics></devices></domainCapabilities>"
        with patch.object(manager, "command", return_value=capabilities):
            self.assertEqual(self.manager.kvm_display(), ("vga", "vnc"))
        with patch.object(manager, "command", return_value="<domainCapabilities/>"), self.assertRaisesRegex(RuntimeError, "qemu-full"):
            self.manager.kvm_display()

    def test_kvm_rejects_extra_host_disks_and_shared_folders(self):
        lab = {**self.lab(), "engine": "kvm", "disk": "/fixtures/benjie.qcow2"}
        prefix = "<domain><memory unit='MiB'>256</memory><vcpu>1</vcpu><devices>" \
                 "<disk device='disk'><source file='/fixtures/benjie.qcow2'/></disk>"
        for extra in ("", "<disk device='disk'><source dev='/dev/sda'/></disk>",
                      "<filesystem><source dir='/home'/></filesystem>"):
            with patch.object(manager, "command", return_value=prefix + extra + "</devices></domain>"):
                if extra:
                    with self.assertRaises(RuntimeError):
                        self.manager.verify_kvm_limits(lab)
                else:
                    self.manager.verify_kvm_limits(lab)


@unittest.skipUnless(os.environ.get("DISPLAY"), "Requiere Xvfb para el asistente GTK")
class GuidedLabsGtkTests(unittest.TestCase):
    setUp = GuidedLabsTests.setUp

    def test_cancel_creates_nothing_and_switching_presets_changes_resources(self):
        import gi
        gi.require_version("Gtk", "3.0")
        from gi.repository import Gtk
        from labs_ui import LabsPanel
        window = Gtk.Window()
        self.addCleanup(window.destroy)
        panel = LabsPanel(self.manager, self.run, window, Mock())
        window.add(panel)
        self.assertFalse(panel.advanced.get_expanded())
        self.assertEqual(panel.choice.get_active_id(), "alpine")
        self.assertIn("256 MiB", panel.resources.get_text())
        panel.choice.set_active_id("alpine-vm")
        self.assertIn("512 MiB", panel.resources.get_text())
        with patch.object(panel, "ask", return_value=False), patch.object(panel.assistant, "create") as create:
            panel.create_guided()
            create.assert_not_called()
        self.run.assert_not_called()


if __name__ == "__main__":
    unittest.main()
