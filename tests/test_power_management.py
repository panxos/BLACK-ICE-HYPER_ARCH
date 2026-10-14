import os
import subprocess
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
PROFILE = REPO / "dotfiles/bin/power_profile"
MENU = REPO / "dotfiles/bin/power_profile_menu.sh"
GUARD = REPO / "dotfiles/hypr/scripts/ac_guard.sh"
POWER_MENU = REPO / "dotfiles/bin/power_menu.sh"


class PowerManagementTests(unittest.TestCase):
    def setUp(self) -> None:
        parent = Path.home() / ".cache/tmp/work"
        parent.mkdir(parents=True, exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(prefix="power-test-", dir=parent)
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.sys = self.root / "sys"
        self.cpu = self.sys / "devices/system/cpu/cpu0/cpufreq"
        self.cpu.mkdir(parents=True)
        self.supplies = self.root / "supplies"
        self.supplies.mkdir()
        self.log = self.root / "actions"
        self.log.touch()
        self.env = dict(os.environ, PATH=f"{self.bin}:/usr/bin:/bin",
                        BLACK_ICE_SYSFS_ROOT=str(self.sys),
                        BLACK_ICE_POWER_SUPPLY_ROOT=str(self.supplies),
                        ACTION_LOG=str(self.log), MOCK_TLP="0", MOCK_PPD="0",
                        MOCK_VM="0", MOCK_FAILURE="0", MOCK_CANCEL="0")
        self.stub("systemctl", '''
if [[ "$1" == is-active ]]; then
    case "$3" in
        tlp.service) [[ "$MOCK_TLP" == 1 ]]; exit ;;
        power-profiles-daemon.service) [[ "$MOCK_PPD" == 1 ]]; exit ;;
    esac
fi
printf 'systemctl %s\\n' "$*" >> "$ACTION_LOG"
''')
        self.stub("sudo", '''
[[ "$*" == '-n -v' ]] && exit 0
[[ "$1" == -n ]] && shift
exec "$@"
''')
        for name in ("tlp", "powerprofilesctl", "cpupower", "hyprctl", "brightnessctl"):
            self.stub(name, f'''printf '{name} %s\\n' "$*" >> "$ACTION_LOG"
if [[ "$MOCK_FAILURE" == 1 ]]; then echo 'fallo simulado' >&2; exit 3; fi
''')
        self.stub("systemd-detect-virt", '[[ "$MOCK_VM" == 1 ]]\n')
        self.stub("notify-send", 'printf "notify %s\\n" "$*" >> "$ACTION_LOG"\n')
        self.stub("wofi", '''
cat >/dev/null
[[ "$MOCK_CANCEL" == 1 ]] && exit 1
printf '%s\\n' "${MOCK_CHOICE:-⚖ Equilibrado}"
''')
        self.hardware("intel_pstate", "performance powersave")

    def stub(self, name: str, body: str) -> None:
        path = self.bin / name
        path.write_text("#!/bin/bash\n" + body)
        path.chmod(0o755)

    def hardware(self, driver: str, governors: str) -> None:
        (self.cpu / "scaling_driver").write_text(driver)
        (self.cpu / "scaling_available_governors").write_text(governors)

    def supply(self, name: str, **attributes: str) -> None:
        device = self.supplies / name
        device.mkdir()
        for key, value in attributes.items():
            (device / key).write_text(value)

    def run_script(self, script: Path, *args: str) -> subprocess.CompletedProcess:
        return subprocess.run(["bash", str(script), *args], env=self.env,
                              text=True, capture_output=True, timeout=10, check=False)

    def actions(self) -> str:
        return self.log.read_text()

    def test_intel_balanced_uses_supported_governor(self) -> None:
        result = self.run_script(PROFILE, "balanced")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("cpupower frequency-set -g powersave", self.actions())
        self.assertNotIn("schedutil", self.actions())

    def test_legacy_auto_uses_adaptive_governor(self) -> None:
        self.hardware("acpi-cpufreq", "performance schedutil powersave")
        self.assertEqual(self.run_script(PROFILE, "auto").returncode, 0)
        self.assertIn("frequency-set -g schedutil", self.actions())

    def test_legacy_saver_uses_supported_powersave(self) -> None:
        self.hardware("acpi-cpufreq", "performance schedutil powersave")
        self.assertEqual(self.run_script(PROFILE, "power-saver").returncode, 0)
        self.assertIn("frequency-set -g powersave", self.actions())

    def test_amd_does_not_receive_intel_limits(self) -> None:
        self.hardware("amd-pstate-epp", "performance powersave")
        result = self.run_script(PROFILE, "--print-config")
        self.assertEqual(result.returncode, 0)
        self.assertNotIn("CPU_MAX_PERF", result.stdout)
        self.assertIn("CPU_SCALING_GOVERNOR_ON_BAT=powersave", result.stdout)

    def test_tlp_takes_priority_over_ppd(self) -> None:
        self.env.update(MOCK_TLP="1", MOCK_PPD="1")
        self.assertEqual(self.run_script(PROFILE, "balanced").returncode, 0)
        self.assertIn("tlp balanced", self.actions())
        self.assertNotIn("powerprofilesctl", self.actions())

    def test_tlp_auto_restores_automatic_mode(self) -> None:
        self.env["MOCK_TLP"] = "1"
        self.assertEqual(self.run_script(PROFILE, "auto").returncode, 0)
        self.assertIn("tlp start", self.actions())

    def test_inactive_ppd_is_not_selected(self) -> None:
        self.assertEqual(self.run_script(PROFILE, "balanced").returncode, 0)
        self.assertNotIn("powerprofilesctl", self.actions())

    def test_active_ppd_reports_auto_unsupported(self) -> None:
        self.env["MOCK_PPD"] = "1"
        result = self.run_script(PROFILE, "auto")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("requiere TLP", result.stderr)
        self.assertEqual(self.actions(), "")

    def test_generated_config_maps_profiles_and_capabilities(self) -> None:
        (self.cpu / "energy_performance_available_preferences").write_text(
            "performance balance_performance power")
        platform = self.sys / "firmware/acpi"
        platform.mkdir(parents=True)
        (platform / "platform_profile_choices").write_text("balanced performance")
        result = self.run_script(PROFILE, "--print-config")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("TLP_PROFILE_AC=BAL", result.stdout)
        self.assertIn("TLP_PROFILE_BAT=SAV", result.stdout)
        self.assertIn("CPU_SCALING_GOVERNOR_ON_BAT=powersave", result.stdout)
        self.assertIn("PLATFORM_PROFILE_ON_SAV=balanced", result.stdout)
        self.assertNotIn("low-power", result.stdout)

    def test_missing_cpu_capabilities_do_not_invent_governor(self) -> None:
        self.hardware("unknown", "")
        result = self.run_script(PROFILE, "--print-config")
        self.assertEqual(result.returncode, 0)
        self.assertNotIn("CPU_SCALING_GOVERNOR", result.stdout)

    def test_usb_c_online_prevents_suspend(self) -> None:
        self.supply("BAT0", type="Battery", status="Discharging")
        self.supply("ucsi-source-0", type="USB", online="1")
        self.assertEqual(self.run_script(GUARD, "status").stdout.strip(), "ac")
        self.assertEqual(self.run_script(GUARD, "suspend").returncode, 0)
        self.assertEqual(self.actions(), "")

    def test_second_online_adapter_prevents_suspend(self) -> None:
        self.supply("BAT0", type="Battery", status="Discharging")
        self.supply("AC", type="Mains", online="0")
        self.supply("ADP1", type="Mains", online="1")
        self.run_script(GUARD, "suspend")
        self.assertEqual(self.actions(), "")

    def test_battery_discharge_allows_suspend(self) -> None:
        self.supply("BAT0", type="Battery", status="Discharging")
        self.supply("AC", type="Mains", online="0")
        self.assertEqual(self.run_script(GUARD, "status").stdout.strip(), "battery")
        self.assertEqual(self.run_script(GUARD, "suspend").returncode, 0)
        self.assertIn("systemctl suspend", self.actions())

    def test_unknown_supply_prevents_suspend(self) -> None:
        self.supply("BAT0", type="Battery", status="Discharging")
        self.supply("USB0", type="USB", online="unknown")
        self.run_script(GUARD, "suspend")
        self.assertEqual(self.actions(), "")

    def test_missing_supplies_prevent_suspend(self) -> None:
        self.assertEqual(self.run_script(GUARD, "status").stdout.strip(), "unknown")
        self.run_script(GUARD, "suspend")
        self.assertEqual(self.actions(), "")

    def test_vm_never_suspends(self) -> None:
        self.supply("BAT0", type="Battery", status="Discharging")
        self.env["MOCK_VM"] = "1"
        self.run_script(GUARD, "suspend")
        self.assertEqual(self.actions(), "")

    def test_peripheral_battery_does_not_block_system_battery(self) -> None:
        self.supply("BAT0", type="Battery", status="Discharging")
        self.supply("mouse", type="Battery", status="Full", scope="Device")
        self.assertEqual(self.run_script(GUARD, "status").stdout.strip(), "battery")

    def test_second_full_system_battery_does_not_block_discharge(self) -> None:
        self.supply("BAT0", type="Battery", status="Discharging")
        self.supply("BAT1", type="Battery", status="Full")
        self.assertEqual(self.run_script(GUARD, "status").stdout.strip(), "battery")

    def test_charging_battery_prevents_suspend_without_adapter_sensor(self) -> None:
        self.supply("BAT0", type="Battery", status="Discharging")
        self.supply("BAT1", type="Battery", status="Charging")
        self.run_script(GUARD, "suspend")
        self.assertEqual(self.actions(), "")

    def test_menu_cancellation_has_no_side_effect(self) -> None:
        self.env["MOCK_CANCEL"] = "1"
        self.assertEqual(self.run_script(MENU).returncode, 0)
        self.assertEqual(self.actions(), "")

    def test_menu_reports_backend_failure(self) -> None:
        self.env.update(MOCK_TLP="1", MOCK_FAILURE="1")
        result = self.run_script(MENU)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("No se aplicó el perfil", self.actions())
        self.assertIn("fallo simulado", self.actions())

    def test_menu_auto_calls_controller(self) -> None:
        self.env.update(MOCK_TLP="1", MOCK_CHOICE="↻ Automático")
        self.assertEqual(self.run_script(MENU).returncode, 0)
        self.assertIn("tlp start", self.actions())

    def power_menu_home(self) -> None:
        directory = self.root / ".local/bin"
        directory.mkdir(parents=True)
        controller = directory / "black-ice-control"
        controller.write_text('#!/bin/sh\nprintf "control %s\\n" "$*" >> "$ACTION_LOG"\nexit "${MOCK_CONTROL_EXIT:-0}"\n')
        controller.chmod(0o755)
        self.env.update(HOME=str(self.root))

    def test_power_menu_opens_native_session_page(self) -> None:
        self.power_menu_home()
        self.assertEqual(self.run_script(POWER_MENU).returncode, 0)
        self.assertEqual(self.actions(), "control session\n")

    def test_power_menu_propagates_controller_failure(self) -> None:
        self.power_menu_home()
        self.env["MOCK_CONTROL_EXIT"] = "7"
        self.assertEqual(self.run_script(POWER_MENU).returncode, 7)

    def test_missing_controller_does_not_run_power_commands(self) -> None:
        self.env["HOME"] = str(self.root)
        self.assertNotEqual(self.run_script(POWER_MENU).returncode, 0)
        self.assertEqual(self.actions(), "")

    @unittest.skipIf(os.geteuid() == 0, "La ruta de autorización es para sesiones sin root")
    def test_denied_authorization_does_not_apply_profile(self) -> None:
        self.env["MOCK_TLP"] = "1"
        self.stub("sudo", "exit 1\n")
        self.stub("pkexec", "echo 'autorización denegada' >&2; exit 126\n")
        result = self.run_script(PROFILE, "balanced")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("autorización denegada", result.stderr)
        self.assertEqual(self.actions(), "")


if __name__ == "__main__":
    unittest.main()
