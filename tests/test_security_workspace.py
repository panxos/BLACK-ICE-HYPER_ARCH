"""Fugas, suplantación de recursos, evidencias alteradas y límites de caché."""
import copy
import hashlib
import importlib.machinery
import importlib.util
import json
import os
import sys
import tempfile
import time
import unittest
import urllib.request
from pathlib import Path
from unittest.mock import Mock, patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src/system"))
from cases import Cases
from forensics import PROFILES, status
from manager import Manager
from privacy_ui import DEFAULT_PALETTE, theme_css, theme_palette
from storage import Storage
from system_privacy import SystemPrivacy
from web_labs import LocalRedirect, WebLabs


class PrivacyThemeTests(unittest.TestCase):
    def test_tor_dialog_uses_every_current_theme_palette(self):
        theme_root = ROOT / "dotfiles/waybar/themes"
        themes = sorted(theme_root.glob("*/palette.json"))
        self.assertEqual(len(themes), 54)
        for path in themes:
            palette = json.loads(path.read_text())
            css = theme_css(palette)
            for key, fallback in DEFAULT_PALETTE.items():
                self.assertIn(palette.get(key, fallback), css, path.parent.name)
            self.assertIn("#state.protected", css)
            self.assertIn("#state.blocked", css)

    def test_invalid_palette_uses_safe_defaults(self):
        css = theme_css({"bg": "url(file:///etc/passwd)", "acc1": "#ffffff"})
        self.assertIn(DEFAULT_PALETTE["bg"], css)
        self.assertIn("#ffffff", css)

    def test_saved_palette_reads_user_appearance_state(self):
        with tempfile.TemporaryDirectory() as temporary:
            state = Path(temporary)
            palette = {"bg": "#101112", "acc1": "#33aaff", "acc2": "#bb77ee",
                       "fg": "#f0f1f2", "dim": "#999a9b"}
            appearance = state / "black-ice/appearance.json"
            appearance.parent.mkdir()
            appearance.write_text(json.dumps({"palette": palette}))
            with patch.dict(os.environ, {"XDG_STATE_HOME": str(state)}):
                self.assertEqual(theme_palette(), palette)


class WorkspaceBase(unittest.TestCase):
    def setUp(self):
        directory = Path.home() / ".cache/tmp/work"
        directory.mkdir(parents=True, exist_ok=True)
        temporary = tempfile.TemporaryDirectory(dir=directory)
        self.addCleanup(temporary.cleanup)
        self.base = Path(temporary.name)
        self.manager = Manager(self.base / "state", ROOT / "config/apps.json", self.base / "config")

class WorkspaceTests(WorkspaceBase):
    def test_case_scope_rejects_similar_host_and_requires_exact_vpn_activation(self):
        cases = Cases(self.manager)
        connection = "ac092c0e-0891-498b-9fe1-67aa8d6f1b7e"
        cases.create("benjie", ["apolo.lab", "192.0.2.0/24"], connection)
        with patch.object(self.manager, "vpn_identity", return_value={"path": "active"}):
            self.assertTrue(cases.preflight("benjie", "192.0.2.14")["allowed"])
            self.assertTrue(cases.preflight("benjie", "apolo.lab")["allowed"])
            self.assertFalse(cases.preflight("benjie", "apolo.lab.evil.test")["allowed"])
            self.assertFalse(cases.preflight("benjie", "198.51.100.1")["allowed"])
        with patch.object(self.manager, "vpn_identity", side_effect=RuntimeError("inactive")):
            self.assertFalse(cases.preflight("benjie", "apolo.lab")["allowed"])

    def test_evidence_copy_preserves_original_and_export_omits_private_content(self):
        cases = Cases(self.manager)
        cases.create("benjie", ["192.0.2.0/24"])
        cases.note("benjie", "password=private-note")
        original = self.base / "sensitive-name.pcap"
        original.write_bytes(b"private original capture")
        initial = original.stat().st_mode
        cases.evidence("benjie", original)
        self.assertEqual(original.read_bytes(), b"private original capture")
        self.assertEqual(original.stat().st_mode, initial)
        self.assertTrue(cases.verify("benjie")["valid"])
        destination = self.base / "summary.json"
        result = cases.export("benjie", destination)
        serialized = destination.read_text()
        for private in ("benjie", "192.0.2.0/24", "private-note", "sensitive-name", "private original"):
            self.assertNotIn(private, serialized)
        self.assertEqual(result["evidence"][0]["sha256"], hashlib.sha256(original.read_bytes()).hexdigest())
        self.assertEqual(destination.stat().st_mode & 0o777, 0o600)

    def test_altered_evidence_and_manifest_are_detected(self):
        cases = Cases(self.manager)
        cases.create("almendra", ["apolo.lab"])
        original = self.base / "evidence.bin"
        original.write_bytes(b"before")
        case = cases.evidence("almendra", original)
        stored = self.manager.root / "cases/almendra/evidence" / case["evidence"][0]["id"]
        stored.chmod(0o600)
        stored.write_bytes(b"after")
        self.assertFalse(cases.verify("almendra")["valid"])
        with self.assertRaisesRegex(ValueError, "integridad"):
            cases.export("almendra", self.base / "invalid.json")
        case["scope"] = ["evil.test"]
        (self.manager.root / "cases/almendra/case.json").write_text(json.dumps(case))
        self.assertIn("El manifiesto del caso cambió fuera del registro", cases.verify("almendra")["errors"])

    def test_symlink_device_and_invalid_scope_are_rejected(self):
        cases = Cases(self.manager)
        with self.assertRaises(ValueError):
            cases.create("benjie", ["192.0.2.1/24"])
        cases.create("benjie", ["apolo.lab"])
        file = self.base / "original"
        file.write_text("evidence")
        link = self.base / "symlink"
        link.symlink_to(file)
        for source in (link, Path("/dev/null")):
            with self.assertRaises(ValueError):
                cases.evidence("benjie", source)
        self.assertEqual(cases.read("benjie")["evidence"], [])

    def test_forensic_profiles_are_optional_and_missing_executable_is_not_ready(self):
        catalog = self.manager.catalog()
        self.assertTrue(all(set(choice["packages"]) <= catalog.keys() for choice in PROFILES.values()))
        with patch.object(self.manager, "installed", return_value={"volatility3"}), patch("forensics.shutil.which", return_value=None):
            self.assertFalse(status(self.manager, "memory")["ready"])
        self.assertFalse((self.manager.root / "jobs.json").exists())

    def test_managed_podman_never_replaces_legacy_store(self):
        args = ["podman", "ps"]
        self.assertIn(str(self.manager.root / "containers"), self.manager.podman_args(args))
        self.assertEqual(self.manager.podman_args(args, "legacy"), args)
        self.assertEqual(self.manager.podman_args(["docker", "ps"]), ["docker", "ps"])

    def test_cache_policy_and_cleanup_reject_foreign_files(self):
        storage = Storage(self.manager)
        with self.assertRaises(ValueError):
            storage.configure(255, 120)
        with self.assertRaises(ValueError):
            storage.configure(256, 14)
        foreign = self.base / "foreign.iso"
        foreign.write_bytes(b"keep")
        with self.assertRaises(ValueError):
            storage.cleanup([{"kind": "iso", "id": "../../foreign.iso"}])
        self.assertEqual(foreign.read_bytes(), b"keep")

    def test_preparation_is_terminated_when_budget_fails(self):
        storage = Storage(self.manager)
        pid_file = self.base / "pid"
        script = "import os,time,pathlib;pathlib.Path(" + repr(str(pid_file)) + ").write_text(str(os.getpid()));time.sleep(30)"
        calls = [0]
        def check():
            calls[0] += 1
            if calls[0] > 2:
                raise RuntimeError("budget")
        with patch.object(storage, "check", side_effect=check), self.assertRaisesRegex(RuntimeError, "budget"):
            storage.guarded([sys.executable, "-c", script], 10)
        if pid_file.exists():
            with self.assertRaises(ProcessLookupError):
                os.kill(int(pid_file.read_text()), 0)

    def test_expiry_stops_only_registered_expired_lab(self):
        state = self.manager.labs()
        state["labs"] = {"benjie": {"expires": time.time() - 1}, "almendra": {"expires": time.time() + 600}}
        self.manager.write("labs", state)
        with patch("laboratories.Laboratories.status", return_value={"running": True}), patch.object(self.manager, "lab_action") as action:
            self.assertEqual(self.manager.expire_labs()["expired"], ["benjie"])
            action.assert_called_once_with("benjie", "stop", "")


class WebLabTests(WorkspaceBase):
    def test_interrupted_creation_keeps_record_and_cleanup_can_be_retried(self):
        web = WebLabs(self.manager)
        spec = {"id": "own", "name": "benjie", "resource": "ice-benjie", "engine": "podman", "store": "managed",
                "cpus": 1, "memory_mib": 768, "disk_gib": 2, "template": "juiceshop", "network": "local"}
        self.manager.run = Mock(side_effect=["network-created", RuntimeError("volume failed")])
        with self.assertRaisesRegex(RuntimeError, "volume failed"):
            web.arguments(spec)
        self.assertTrue(self.manager.labs()["labs"]["benjie"]["cleanup_pending"])
        def cleanup(args, **kwargs):
            if args[1] == "ps":
                return ""
            if args[2] == "ls":
                return json.dumps([] if args[1] == "volume" else [{"name": "ice-net-own"}])
            if args[2] == "inspect":
                return json.dumps([{"labels": {"black-ice.id": "own"}}])
            return ""
        self.manager.run.side_effect = cleanup
        self.manager.lab_action("benjie", "delete", "benjie")
        self.assertEqual(self.manager.labs()["labs"], {})
        self.assertTrue(any(call.args[0][:3] == ["podman", "network", "rm"] for call in self.manager.run.call_args_list))

    def test_cleanup_refuses_resource_with_another_owner(self):
        spec = {"id": "own", "web": {"volume": "data", "network": "net"}}
        self.manager.run = Mock(side_effect=[json.dumps([{"Name": "data"}]), json.dumps([{"Labels": {"black-ice.id": "foreign"}}])])
        with self.assertRaisesRegex(ValueError, "ajeno"):
            WebLabs(self.manager).cleanup(spec)
        self.assertFalse(any("rm" in call.args[0] for call in self.manager.run.call_args_list))

    def test_readiness_cannot_follow_external_redirects(self):
        handler = LocalRedirect()
        request = urllib.request.Request("http://127.0.0.1:12001/WebGoat/")
        for address in ("https://evil.test/", "http://127.0.0.1:12002/", "http://127.0.0.1:12001.evil.test/"):
            with self.subTest(address=address), self.assertRaises(ValueError):
                handler.redirect_request(request, None, 302, "Found", {}, address)
        redirected = handler.redirect_request(request, None, 302, "Found", {}, "http://127.0.0.1:12001/WebGoat/login")
        self.assertEqual(redirected.full_url, "http://127.0.0.1:12001/WebGoat/login")
    def test_external_port_network_or_mount_is_rejected(self):
        web = WebLabs(self.manager)
        spec = {"id": "own", "web": {"network": "private", "volume": "data", "directory": "/juice-shop", "ports": [3000]}}
        inspected = {"HostConfig": {"PortBindings": {"3000/tcp": [{"HostIp": "127.0.0.1", "HostPort": "10001"}]}},
                     "NetworkSettings": {"Networks": {"private": {}}},
                     "Mounts": [{"Type": "volume", "Name": "data", "Destination": "/juice-shop"}]}
        network = {"internal": True, "dns_enabled": False, "labels": {"black-ice.id": "own"}, "options": {"no_default_route": "true"}}
        def run(args):
            return json.dumps([network if args[1] == "network" else {"Labels": {"black-ice.id": "own"}}])
        self.manager.run = Mock(side_effect=run)
        web.verify(spec, inspected)
        for kind in ("port", "network", "mount"):
            altered = copy.deepcopy(inspected)
            if kind == "port":
                altered["HostConfig"]["PortBindings"]["3000/tcp"][0]["HostIp"] = "0.0.0.0"
            elif kind == "network":
                altered["NetworkSettings"]["Networks"]["external"] = {}
            else:
                altered["Mounts"].append({"Type": "bind", "Destination": "/home", "Name": "host"})
            with self.subTest(kind=kind), self.assertRaises(ValueError):
                web.verify(spec, altered)


class SecurityInstallTests(WorkspaceBase):
    def installer(self):
        spec = importlib.util.spec_from_file_location("security_install", ROOT / "scripts/install-security-workspace.py")
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module

    def test_clean_user_receives_modules_commands_service_and_shared_style(self):
        module = self.installer()
        home = self.base / "home"
        with patch.dict(os.environ, {"XDG_DATA_HOME": str(home / ".local/share"), "XDG_CONFIG_HOME": str(home / ".config")}):
            module.install(module.files(home))
        self.assertTrue((home / ".local/share/black-ice/system/web_labs.py").is_file())
        self.assertTrue((home / ".local/share/black-ice/system/cases.py").is_file())
        self.assertFalse((home / ".local/share/black-ice/system/onion-shell.sh").exists())
        self.assertFalse((home / ".local/share/black-ice/system/privacy.py").exists())
        self.assertEqual((home / ".local/bin/black-ice-privacy").stat().st_mode & 0o777, 0o755)
        self.assertIn("black-ice-privacy watch", (home / ".config/systemd/user/black-ice-privacy.service").read_text())
        self.assertTrue((home / ".config/waybar/privacy.css").is_file())
        self.assertTrue((home / ".local/share/black-ice/software/scripts/select-apps.py").is_file())
        self.assertEqual(json.loads((home / ".local/share/black-ice/software/config/apps.json").read_text())["schema"], 1)
        self.assertFalse((home / ".config/waybar/config.jsonc").exists())

    def test_symlink_failure_rolls_back_previous_files(self):
        module = self.installer()
        existing = self.base / "existing"
        existing.write_text("personal previous")
        fresh = self.base / "fresh"
        link = self.base / "linked"
        link.symlink_to(existing)
        source = ROOT / "dotfiles/bin/black-ice-privacy"
        with self.assertRaisesRegex(ValueError, "Destino no regular"):
            module.install([(source, existing, 0o755), (source, fresh, 0o755), (source, link, 0o755)])
        self.assertEqual(existing.read_text(), "personal previous")
        self.assertFalse(fresh.exists())
        self.assertTrue(link.is_symlink())


class WaybarIntegrationTests(WorkspaceBase):
    def test_hidden_indicator_stays_hidden_in_every_theme_and_compact_layout(self):
        sys.path.insert(0, str(ROOT / "dotfiles/bin"))
        loader = importlib.machinery.SourceFileLoader("hidden_privacy_waybar", str(ROOT / "dotfiles/bin/black-ice-waybar"))
        module = importlib.util.module_from_spec(importlib.util.spec_from_loader(loader.name, loader))
        loader.exec_module(module)
        module.CONFIG = self.manager.config
        SystemPrivacy(self.manager).set_visible(False)
        for width in (None, 1920, 768):
            for path in (ROOT / "dotfiles/waybar/themes").glob("*/config.jsonc"):
                with self.subTest(theme=path.parent.name, width=width):
                    monitors = [] if width is None else [{"name": "eDP-1", "id": 0, "width": width, "height": 1080, "scale": 1}]
                    bars = module.config(path, monitors)
                    for bar in bars:
                        for zone in ("modules-left", "modules-center", "modules-right"):
                            self.assertNotIn("custom/privacy", bar.get(zone, []))
                        for key, definition in bar.items():
                            if key.startswith("group/"):
                                self.assertNotIn("custom/privacy", definition.get("modules", []))

    def test_privacy_control_is_available_in_every_theme_and_compact_layout(self):
        sys.path.insert(0, str(ROOT / "dotfiles/bin"))
        loader = importlib.machinery.SourceFileLoader("privacy_waybar", str(ROOT / "dotfiles/bin/black-ice-waybar"))
        module = importlib.util.module_from_spec(importlib.util.spec_from_loader(loader.name, loader))
        loader.exec_module(module)
        module.CONFIG = self.base / "config"
        for width in (1920, 768):
            for path in (ROOT / "dotfiles/waybar/themes").glob("*/config.jsonc"):
                with self.subTest(theme=path.parent.name, width=width):
                    bars = module.config(path, [{"name": "eDP-1", "id": 0, "width": width, "height": 1080, "scale": 1}])
                    visible = {name for bar in bars for zone in ("modules-left", "modules-center", "modules-right") for name in bar.get(zone, [])}
                    self.assertIn("custom/privacy", visible)
                    self.assertTrue(all(bar["custom/privacy"]["on-click"].endswith("black-ice-privacy toggle") for bar in bars))
                    self.assertTrue(all(bar["custom/privacy"]["on-click-right"].endswith("black-ice-privacy menu") for bar in bars))
