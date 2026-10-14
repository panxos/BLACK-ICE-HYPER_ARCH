import importlib.machinery
import importlib.util
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "dotfiles/bin/black-ice-hypr"
loader = importlib.machinery.SourceFileLoader("hypr_ipc", str(SCRIPT))
spec = importlib.util.spec_from_loader(loader.name, loader)
ipc = importlib.util.module_from_spec(spec)
loader.exec_module(ipc)


class HyprlandIPCTests(unittest.TestCase):
    def call(self, provider, *args, failure=False, ipc_error=False):
        parent = Path.home() / ".cache/tmp/work"
        parent.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=parent) as directory:
            root = Path(directory)
            backend = root / "hyprctl"
            backend.write_text('''#!/bin/bash
if [[ "$1" == status ]]; then printf 'configProvider: %s\\n' "$PROVIDER"; exit 0; fi
printf '%s\\n' "$@" > "$IPC_ARGUMENTS"
[[ "$IPC_ERROR" == 1 ]] && printf "Hyprland IPC didn't respond in time\\n"
exit "$IPC_FAILURE"
''')
            backend.chmod(0o755)
            result = subprocess.run(["python3", str(SCRIPT), *args], capture_output=True, text=True,
                                    check=False, env={**os.environ, "PATH": str(root) + ":" + os.environ["PATH"],
                                                      "PROVIDER": provider, "IPC_ARGUMENTS": str(root / "arguments"),
                                                      "IPC_ERROR": "1" if ipc_error else "0",
                                                      "IPC_FAILURE": "7" if failure else "0"})
            arguments = (root / "arguments").read_text().splitlines() if (root / "arguments").exists() else []
            return result, arguments

    def test_hyprlang_retains_legacy_dispatch(self):
        result, arguments = self.call("hyprlang", "focusmonitor", "DP-1")
        self.assertEqual(result.returncode, 0)
        self.assertEqual(arguments, ["dispatch", "focusmonitor", "DP-1"])

    def test_lua_exec_quotes_command_without_code_injection(self):
        result, arguments = self.call("lua", "exec", 'printf "test"; echo café')
        self.assertEqual(result.returncode, 0)
        self.assertEqual(arguments, ["eval", 'hl.exec_cmd("printf \\"test\\"; echo café")'])

    def test_lua_focus_uses_typed_dispatcher(self):
        result, arguments = self.call("lua", "focusmonitor", "DP-1")
        self.assertEqual(result.returncode, 0)
        self.assertEqual(arguments, ["eval", 'hl.dispatch(hl.dsp.focus({monitor="DP-1"}))'])

    def test_failed_dispatch_is_reported(self):
        result, _ = self.call("lua", "workspace", "2", failure=True)
        self.assertEqual(result.returncode, 7)

    def test_lua_screen_wakeup_uses_supported_dispatcher(self):
        result, arguments = self.call("lua", "dpms", "on")
        self.assertEqual(result.returncode, 0)
        self.assertEqual(arguments, ["eval", 'hl.dispatch(hl.dsp.dpms({action="enable"}))'])

    def test_ipc_timeout_with_zero_exit_status_is_still_a_failure(self):
        result, _ = self.call("lua", "dpms", "on", ipc_error=True)
        self.assertNotEqual(result.returncode, 0)

    def test_invalid_geometry_and_control_characters_are_rejected(self):
        for action, argument in (("resizewindowpixel", 'exact 12 24,address:0x1);os.exit()'),
                                 ("exec", "bad\ncommand")):
            result, arguments = self.call("lua", action, argument)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(arguments, [])

    def test_window_geometry_supports_negative_monitor_coordinates(self):
        result, arguments = self.call("lua", "movewindowpixel", "exact -1920 40,address:0xabcd")
        self.assertEqual(result.returncode, 0)
        self.assertIn('x=-1920,y=40,relative=false', arguments[1])


if __name__ == "__main__":
    unittest.main()
