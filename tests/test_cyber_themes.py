import importlib.machinery
import importlib.util
import json
import os
import re
import tempfile
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]


def load(name, path):
    loader = importlib.machinery.SourceFileLoader(name,str(path))
    spec = importlib.util.spec_from_loader(name,loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


backend = load("cyber_waybar",ROOT / "dotfiles/bin/black-ice-waybar")
installer = load("cyber_installer",ROOT / "scripts/install-cyber-themes.py")
REQUIRED = {"custom/local_ip","custom/public_ip","custom/vpn","custom/settarget","custom/docker","custom/kvm","custom/updates",
            "custom/player","custom/weather","custom/launcher","hyprland/workspaces","network","bluetooth","pulseaudio","battery","clock","custom/control","custom/power","tray"}


def modules(bars):
    found = set()
    for bar in bars:
        def visit(name, bar=bar):
            found.add(name)
            if name.startswith("group/"):
                for child in bar[name]["modules"]:
                    visit(child)
        for key in ("modules-left","modules-center","modules-right"):
            for name in bar[key]:
                visit(name)
    return found


class CatalogTests(unittest.TestCase):
    def test_bar_windows_do_not_draw_full_width_rules(self):
        for path in (ROOT / 'dotfiles/waybar/themes').glob('*/style.css'):
            with self.subTest(theme=path.parent.name):
                for selector, declarations in re.findall(r'([^{}]+)\{([^{}]*)\}', path.read_text()):
                    if 'window#waybar' in selector:
                        self.assertNotRegex(declarations, r'border-(?:top|bottom)\s*:')

    def test_themed_launchers_remain_visible_and_keep_security_modules(self):
        names = {'MK11-SubZero': 'mortal-kombat', 'MK11-Scorpion': 'mortal-kombat',
                 'Supra-MK4': 'toyota', 'Civic-Si-Mugen': 'honda', 'Skyline-GTR-R34': 'nissan',
                 'Matrix-Hacker': 'matrix-code', 'Kevin-Mitnick-Condor': 'condor'}
        for name, emblem in names.items():
            with self.subTest(theme=name):
                folder = ROOT / 'dotfiles/waybar/themes' / name
                metadata = json.loads((folder / 'theme.json').read_text())
                self.assertEqual(metadata['launcher'], emblem)
                bars = json.loads((folder / 'config.jsonc').read_text())
                self.assertTrue(REQUIRED <= modules(bars))
                self.assertTrue(all(b['custom/launcher']['format'] for b in bars))
                self.assertIn('assets/launcher.svg', (folder / 'style.css').read_text())
                svg = ET.fromstring((folder / 'assets/launcher.svg').read_text())
                self.assertTrue(svg.get('viewBox'))
                if emblem == 'mortal-kombat':
                    self.assertEqual(svg.get('width'), '64')
                    self.assertEqual(svg.get('height'), '64')
                self.assertNotIn('<script', (folder / 'assets/launcher.svg').read_text())
                self.assertFalse(any('href' in key for item in svg.iter() for key in item.attrib))

    def test_removable_timeouts_migrate_only_known_generated_configuration(self):
        old = "program_options:\n  file_manager: dolphin\nnotifications:\n  device_added: false\n  device_mounted: 8000\n  device_unmounted: 4000\n  device_removed: 4000\n  job_failed: 0\nnotification_actions:\n  device_mounted: [browse, terminal]\n"
        converted = installer.migrate_removable_config(old)
        self.assertIn("  device_mounted: 8\n", converted)
        self.assertIn("  device_unmounted: 4\n", converted)
        self.assertIn("  device_removed: 4\n", converted)
        self.assertIn("  job_failed: -1\n", converted)
        self.assertIn("  device_mounted: [browse, terminal]", converted)
        self.assertEqual(installer.migrate_removable_config(converted), converted)
        personal = old.replace("device_mounted: 8000", "device_mounted: 12")
        self.assertEqual(installer.migrate_removable_config(personal), personal)
        self.assertEqual(installer.migrate_removable_config(""), "")

    def test_motion_migration_is_idempotent_and_preserves_custom_values(self):
        legacy = 'animation = borderangle, 1, 8, linear, loop\nanimation = workspaces, 1, 6, default\n'
        converted = installer.migrate_motion(legacy, "hyprlang")
        self.assertIn('borderangle, 0', converted)
        self.assertIn('workspaces, 1, 2, default', converted)
        self.assertEqual(installer.migrate_motion(converted, "hyprlang"), converted)
        personal = 'animation = workspaces, 1, 4, custom\n'
        self.assertEqual(installer.migrate_motion(personal, "hyprlang"), personal)
        lua = 'hl.animation({\n leaf = "borderangle",\n enabled = true,\n speed = 8,\n bezier = "linear",\n style = "loop",\n})\nhl.animation({\n leaf = "workspaces",\n enabled = true,\n speed = 6,\n bezier = "default",\n})'
        converted = installer.migrate_motion(lua, "lua")
        self.assertIn('enabled = false', converted)
        self.assertIn('speed = 2', converted)
        self.assertEqual(installer.migrate_motion(converted, "lua"), converted)

    def test_reviewed_layouts_keep_workspaces_on_top(self):
        for name, count in [("Mr-Robot", 1), ("Mr-Robot-Safehouse", 1), ("Fsociety", 1), ("MK11-Scorpion", 1), ("s4vitar-darkness", 1)]:
            with self.subTest(theme=name):
                path = ROOT / "dotfiles/waybar/themes" / name
                bars = json.loads((path / "config.jsonc").read_text())
                self.assertEqual(len(bars), count)
                desktop = next(b for b in bars if "hyprland/workspaces" in modules([b]))
                self.assertEqual(desktop["position"], "top")
                self.assertTrue(REQUIRED <= modules(bars))
                metadata = json.loads((path / "theme.json").read_text())
                if name in {"Mr-Robot", "Mr-Robot-Safehouse", "Fsociety"}:
                    self.assertEqual(metadata["shape"], "angular")
                    self.assertTrue(desktop["custom/launcher"]["format"])
                    self.assertTrue((path / "assets/fsociety.svg").is_file())
                elif name == "s4vitar-darkness":
                    self.assertEqual(metadata["shape"], "capsule")

    def test_tokyo_workspaces_have_distinct_kanji_and_bundled_font(self):
        folder = ROOT / "dotfiles/waybar/themes/Emilia-TokyoNight"
        bars = json.loads((folder / "config.jsonc").read_text())
        icons = bars[0]["hyprland/workspaces"]["format-icons"]
        self.assertEqual([icons[str(i)] for i in range(1, 6)], list("一二三四五"))
        self.assertNotIn("active", icons)
        self.assertIn('font-family:"Noto Sans JP"', (folder / "style.css").read_text())
        self.assertTrue((ROOT / "assets/fonts/noto-sans-jp/OFL.txt").is_file())
        self.assertEqual(json.loads((folder / "theme.json").read_text())["shape"], "angular")

    def test_all_catalog_themes_render_bars_on_three_monitors(self):
        monitors = [{"name":"eDP-1", "width":1366, "height":768, "scale":1},
                    {"name":"DP-3", "width":1920, "height":1080, "scale":1},
                    {"name":"DP-5", "width":1920, "height":1080, "scale":1}]
        for path in (ROOT / "dotfiles/waybar/themes").glob("*/config.jsonc"):
            with self.subTest(theme=path.parent.name):
                bars = backend.config(path, monitors)
                self.assertEqual({bar["output"] for bar in bars}, {m["name"] for m in monitors})
                for monitor in monitors:
                    self.assertTrue(REQUIRED <= modules([b for b in bars if b["output"] == monitor["name"]]))

    def test_code_workspace_icons_use_installed_symbol_font(self):
        for name in ("Fsociety", "Matrix-Hacker", "Mr-Robot", "Mr-Robot-Safehouse"):
            folder = ROOT / "dotfiles/waybar/themes" / name
            bars = json.loads((folder / "config.jsonc").read_text())
            icons = bars[0]["hyprland/workspaces"]["format-icons"]
            self.assertEqual(icons["default"], "\uf120")
            self.assertEqual(icons["active"], "\uf121")
            self.assertEqual(icons["persistent"], icons["default"])
            self.assertIn('#workspaces button label { font-family:"JetBrainsMono Nerd Font"', (folder / "style.css").read_text())

    def test_all_themes_keep_security_and_remove_hardware_duplicates(self):
        paths = list((ROOT / "dotfiles/waybar/themes").glob("*/config.jsonc"))
        catalog = json.loads((ROOT / "dotfiles/waybar/cyber-catalog.json").read_text())
        self.assertEqual({p.parent.name for p in paths}, set(catalog))
        for path in paths:
            bars = json.loads(path.read_text())
            self.assertTrue(REQUIRED <= modules(bars),path.parent.name)
            self.assertFalse({"cpu","memory","disk","custom/hardware_temp"} & modules(bars))
            for bar in bars:
                self.assertFalse({"cpu","memory","disk","custom/hardware_temp"} & set(bar))

    def test_monitor_layout_keeps_features_and_does_not_change_source(self):
        path = ROOT / "dotfiles/waybar/themes/Obsidian-Angular/config.jsonc"
        before = path.read_bytes()
        monitors = [{"name":"wide","width":2560,"height":1440,"scale":1},
                    {"name":"portrait","width":1920,"height":1080,"scale":1.25,"transform":1}]
        bars = backend.config(path,monitors)
        self.assertEqual(len(bars),4)
        for name in ("wide","portrait"):
            selected = [bar for bar in bars if bar["output"] == name]
            self.assertTrue(REQUIRED <= modules(selected))
        self.assertIn("group/addresses",bars[3]["modules-center"])
        self.assertEqual(before,path.read_bytes())

    def test_catalog_varies_shapes_fonts_and_all_wallpapers_exist(self):
        catalog = json.loads((ROOT / "dotfiles/waybar/cyber-catalog.json").read_text())
        self.assertEqual(len({p["shape"] for p in catalog.values()}),6)
        self.assertEqual({p["font"] for p in catalog.values()},{"Roboto","Inter","Ubuntu Sans","Oxanium","Rajdhani","Barlow Condensed","Share Tech Mono"})
        for profile in catalog.values():
            if profile["wallpaper"] != "black-ice-obsidian.png":
                self.assertTrue(any((ROOT / folder / profile["wallpaper"]).is_file()
                                    for folder in ("assets/wallpapers/cyber", "dotfiles/wallpapers")))

    def test_each_layout_preserves_workspace_position_and_all_modules_when_compact(self):
        layouts = json.loads((ROOT / "dotfiles/waybar/layout-map.json").read_text())
        self.assertEqual(set(layouts.values()),{"dual-top","dual-bottom","single-top","single-bottom"})
        for name,layout in layouts.items():
            path = ROOT / "dotfiles/waybar/themes" / name / "config.jsonc"
            for width in (600,900,1366):
                bars = backend.config(path,[{"name":"test","width":width,"height":768,"scale":1}])
                self.assertTrue(REQUIRED <= modules(bars),name)
                self.assertEqual(len(bars),1 if layout.startswith("single") else 2)
                workspace = next(bar for bar in bars if "hyprland/workspaces" in modules([bar]))
                self.assertEqual(workspace["position"],"bottom" if layout.endswith("bottom") else "top")
                self.assertEqual(workspace["modules-center"],["hyprland/workspaces"],name)
                for bar in bars:
                    self.assertTrue(bar["fixed-center"])
                    if "tray" in modules([bar]):
                        self.assertIn("tray",bar["modules-right"],name)
                    self.assertNotIn("hyprland/workspaces",bar["modules-left"])
                    self.assertNotIn("hyprland/workspaces",bar["modules-right"])
                self.assertEqual(bars[0]["custom/control"]["format"],"\uf013")
            css = (path.parent / "style.css").read_text()
            self.assertIn('#custom-vpn.connected { color:#9fef00;',css)
            self.assertIn('#custom-vpn.disconnected { color:#ff6b6b;',css)
            self.assertTrue((path.parent / "assets/hackthebox-connected.svg").is_file())


class BackendTests(unittest.TestCase):
    def test_copy_address_notifies_after_success_and_never_on_failed_copy(self):
        with patch.dict(backend.MODULES, local=lambda: {"address": "192.0.2.18"}), patch.object(backend.subprocess, "run") as run, patch.object(backend, "command") as notify:
            backend.copy_address("local")
            self.assertEqual(run.call_args.kwargs["input"], "192.0.2.18")
            self.assertIn("IP copiada", notify.call_args.args[0])
            run.side_effect = OSError("clipboard unavailable")
            notify.reset_mock()
            with self.assertRaises(OSError):
                backend.copy_address("local")
            notify.assert_not_called()

    def test_copy_absent_address_keeps_clipboard_and_explains(self):
        with patch.dict(backend.MODULES, vpn=lambda: {"address": ""}), patch.object(backend.subprocess, "run") as run, patch.object(backend, "command") as notify:
            backend.copy_address("vpn")
            run.assert_not_called()
            self.assertIn("Sin IP disponible", notify.call_args.args[0])

    def test_optional_services_follow_installation_and_removal(self):
        for name in ("docker", "kvm"):
            with patch.object(backend.shutil, "which", return_value=None), patch.object(backend, "command") as command:
                self.assertEqual(backend.service(name)["text"], "")
                command.assert_not_called()
            with patch.object(backend.shutil, "which", return_value="/usr/bin/tool"), patch.object(backend, "command", return_value=(0, "")):
                self.assertTrue(backend.service(name)["text"])
            with patch.object(backend.shutil, "which", return_value=None):
                self.assertEqual(backend.service(name)["text"], "")

    def test_optional_services_check_presence_at_every_interval(self):
        for path in (ROOT / "dotfiles/waybar/themes").glob("*/config.jsonc"):
            for bar in backend.config(path, [{"name": "test", "width": 1366}]):
                for name, binary in (("docker", "docker"), ("kvm", "virsh")):
                    item = bar["custom/" + name]
                    self.assertIn("command -v " + binary, item["exec-if"])
                    self.assertEqual(item["interval"], 15)
                    self.assertTrue(item["hide-empty-text"])

    def setUp(self):
        base = Path(os.environ.get("BLACK_ICE_TEST_WORK",Path.home()/".cache/tmp/work"))
        base.mkdir(parents=True,exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(prefix="cyber-backend-",dir=base)
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def test_target_special_characters_produce_valid_json_and_only_ip_for_copy(self):
        target = self.root / "target"
        target.write_text('192.0.2.18 Benjie "TI" <b>\nsegunda línea')
        with patch.object(backend,"TARGET",target):
            value = json.loads(json.dumps(backend.target()))
        self.assertEqual(value["address"],"192.0.2.18")
        self.assertNotIn("<b>",value["tooltip"])
        self.assertNotIn("\n",value["text"])

    def test_other_tunnels_never_activate_lab_vpn(self):
        addresses = [{"ifname":"benjie-lab","addr_info":[{"local":"198.51.100.2","scope":"global"}]}]
        links = [{"ifname":"benjie-lab","linkinfo":{"info_kind":"wireguard"},"flags":["UP"],"operstate":"UNKNOWN"},
                 {"ifname":"tun0","flags":["UP"],"operstate":"DOWN"}]
        with patch.object(backend,"network",return_value=(addresses,links,[])):
            value = backend.vpn()
        self.assertEqual(value["address"],"")
        self.assertEqual(value["class"],"disconnected")
        self.assertEqual(value["text"],"No conectado")

    def test_lab_vpn_requires_up_tun0_with_valid_global_address(self):
        addresses = [{"ifname":"tun0","addr_info":[{"local":"198.51.100.2","scope":"global"}]}]
        for flags,state,has_address,connected in [(["UP"],"UNKNOWN",True,True),(["UP"],"UP",True,True),
                                                 ([],"DOWN",True,False),(["UP"],"DOWN",True,False),(["UP"],"UNKNOWN",False,False)]:
            links = [{"ifname":"tun0","flags":flags,"operstate":state}]
            with self.subTest(flags=flags,state=state,has_address=has_address), patch.object(backend,"network",return_value=(addresses if has_address else [],links,[])):
                value = backend.vpn()
                self.assertEqual(value["class"],"connected" if connected else "disconnected")
                self.assertEqual(value["address"],"198.51.100.2" if connected else "")
                self.assertEqual(value["text"],"198.51.100.2" if connected else "No conectado")

    def test_empty_or_absent_target_uses_no_target(self):
        path = self.root / "target"
        with patch.object(backend,"TARGET",path):
            for value in (None,""," \n"):
                if value is not None:
                    path.write_text(value)
                result = backend.target()
                self.assertEqual(result["class"],"inactive")
                self.assertIn("No target",result["text"])

    def test_local_address_uses_physical_default_route(self):
        addresses = [{"ifname":"wg0","addr_info":[{"local":"198.51.100.2","scope":"global"}]},
                     {"ifname":"eth0","addr_info":[{"local":"192.0.2.2","scope":"global"}]}]
        links = [{"ifname":"wg0","linkinfo":{"info_kind":"wireguard"}}]
        routes = [{"dev":"wg0","metric":0},{"dev":"eth0","metric":10}]
        with patch.object(backend,"network",return_value=(addresses,links,routes)):
            self.assertEqual(backend.local_ip()["address"],"192.0.2.2")

    def test_service_failure_never_reports_zero_running(self):
        with patch.object(backend.shutil,"which",return_value="/usr/bin/tool"), patch.object(backend,"command",return_value=(1,"")):
            for name in ("docker","kvm"):
                self.assertEqual(backend.service(name)["class"],"unavailable")
                self.assertIn("N/D",backend.service(name)["text"])

    def test_checkupdates_empty_and_error_are_distinct(self):
        with patch.object(backend,"command",return_value=(2,"")):
            self.assertEqual(backend.updates()["class"],"cleaned")
        with patch.object(backend,"command",return_value=(1,"")):
            self.assertEqual(backend.updates()["class"],"unavailable")

    def test_corrupt_public_cache_and_network_failure_never_reuse_stale_ip(self):
        for cached in [[],{"ip":"203.0.113.4","time":"incorrecto","identity":["",""]}]:
            (self.root / "public.json").write_text(json.dumps(cached))
            with patch.object(backend,"CACHE",self.root), patch.object(backend,"local_ip",return_value={}), patch.object(backend,"vpn",return_value={}), patch.object(backend.urllib.request,"urlopen",side_effect=OSError("offline")):
                value = backend.public_ip()
            self.assertEqual(value["class"],"disconnected")
            self.assertEqual(value["address"],"")

    def test_cancelled_target_prompt_preserves_original(self):
        target = self.root / "target"
        target.write_text("192.0.2.18 apolo.lab\n")
        with patch.object(backend,"TARGET",target), patch.object(backend,"command",return_value=(1,"")):
            self.assertEqual(backend.choose_target(),0)
        self.assertEqual(target.read_text(),"192.0.2.18 apolo.lab\n")


class InstallerTests(unittest.TestCase):
    def setUp(self):
        base = Path(os.environ.get("BLACK_ICE_TEST_WORK",Path.home()/".cache/tmp/work"))
        base.mkdir(parents=True,exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(prefix="cyber-installer-",dir=base)
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name) / "home"
        self.instance = installer.Installer(ROOT,self.home)
        self.old = self.home / ".config/waybar/themes/Anubis-Death/config.jsonc"
        self.old.parent.mkdir(parents=True)
        self.old.write_text("configuración personal anterior")
        self.extra = self.old.parent / "personal.txt"
        self.extra.write_text("preferencia personal")
        self.pref = self.home / ".local/state/black-ice/conky.json"
        self.pref.parent.mkdir(parents=True)
        self.pref.write_text(json.dumps({"enabled":False,"themes":{"Anubis-Death":{"variant":"orbit","color":"acid","offset_x":20}}}))

    def test_catalog_migration_is_reversible_and_preserves_hidden_overrides(self):
        original = self.pref.read_bytes()
        self.instance.apply(activate=False)
        value = json.loads(self.pref.read_text())
        self.assertFalse(value["enabled"])
        self.assertEqual(value["themes"]["Anubis-Sethek"],value["themes"]["Anubis-Death"])
        self.assertFalse(self.old.exists())
        self.assertFalse(self.extra.exists())
        self.assertFalse(self.instance.rollback())
        self.assertEqual(self.old.read_text(),"configuración personal anterior")
        self.assertEqual(self.extra.read_text(),"preferencia personal")
        self.assertEqual(self.pref.read_bytes(),original)

    def test_reapply_retains_original_and_rollback_keeps_later_edit(self):
        first = self.instance.apply(activate=False)
        second = self.instance.apply(activate=False)
        self.assertEqual(first["entries"],second["entries"])
        changed = self.home / ".config/waybar/themes/Mr-Robot/style.css"
        changed.write_text("edición posterior")
        self.assertIn(str(changed),self.instance.rollback())
        self.assertEqual(changed.read_text(),"edición posterior")

    def test_polkit_style_migration_preserves_custom_startup_and_permissions(self):
        hypr = self.home / ".config/hypr"
        hypr.mkdir(parents=True)
        conf = hypr / "hyprland.conf"
        lua = hypr / "hyprland.lua"
        idle = hypr / "hypridle.conf"
        idle_original = "general {\n after_sleep_cmd = hyprctl dispatch dpms on\n}\n# preferencia personal\n"
        idle.write_text(idle_original)
        originals = {conf: "exec-once = /usr/lib/polkit-kde-authentication-agent-1\nexec-once = mi-agente-personal --opcion\n",
                     lua: 'hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")\nhl.exec_cmd("mi-agente-personal --opcion")\n'}
        preview = 'bash -c \'sleep 8 && [ ! -f ~/.config/waybar/themes/Horus-Cyber/preview.png ] && ~/.config/bin/gen_theme_previews\''
        originals[conf] += "exec-once = " + preview + "\n"
        originals[lua] += 'hl.exec_cmd("' + preview + '")\n'
        for path, content in originals.items():
            path.write_text(content)
            path.chmod(0o600)
        self.instance.apply(activate=False)
        self.assertIn("black-ice-hypr dpms on", idle.read_text())
        self.assertIn("preferencia personal", idle.read_text())
        for path in originals:
            self.assertIn("QT_STYLE_OVERRIDE=Fusion", path.read_text())
            self.assertIn("mi-agente-personal --opcion", path.read_text())
            self.assertNotIn("gen_theme_previews", path.read_text())
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)
        self.assertFalse(self.instance.rollback())
        self.assertEqual(idle.read_text(), idle_original)
        for path, content in originals.items():
            self.assertEqual(path.read_text(), content)

    def test_retired_symlink_does_not_modify_external_files(self):
        folder = self.home / ".config/waybar/themes/Horus-Cyber"
        outside = self.home / "personal"
        outside.mkdir()
        (outside / "style.css").write_text("contenido externo")
        folder.symlink_to(outside,target_is_directory=True)
        self.instance.apply(activate=False)
        self.assertFalse(folder.exists())
        self.assertEqual((outside / "style.css").read_text(),"contenido externo")
        self.assertFalse(self.instance.rollback())
        self.assertEqual(folder.resolve(),outside)

    def test_catalog_never_writes_system_and_invalid_selection_falls_back(self):
        saved = self.home / ".config/waybar/default_theme"
        saved.parent.mkdir(parents=True,exist_ok=True)
        saved.write_text("../../outside")
        self.assertEqual(self.instance.selected(),"Anubis-Sethek")
        self.assertTrue(all(path.is_relative_to(self.home) for path in self.instance.build()))


if __name__ == "__main__":
    unittest.main()
