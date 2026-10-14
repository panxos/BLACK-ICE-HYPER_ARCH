import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEPLOYMENT = (ROOT / "src/deploy/01_hyprland_base.sh").read_text()


class SessionLaunchTests(unittest.TestCase):
    def test_uwsm_is_installed_and_required_for_the_sddm_session(self):
        packages = re.search(r"HYPRLAND_PKGS=\(\n(.*?)\n\)", DEPLOYMENT, re.DOTALL)
        critical = re.search(r'CRITICAL_PKGS=\(([^\n]+)\)', DEPLOYMENT)
        self.assertIsNotNone(packages)
        self.assertIsNotNone(critical)
        self.assertIn('"uwsm"', packages.group(1))
        self.assertIn('"uwsm"', critical.group(1))


if __name__ == "__main__":
    unittest.main()
