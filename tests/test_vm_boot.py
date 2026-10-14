import importlib.util
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("vm_boot", ROOT / "scripts/configure-vm-boot.py")
boot = importlib.util.module_from_spec(spec)
spec.loader.exec_module(boot)


class VmBootTests(unittest.TestCase):
    def test_preserves_disk_encryption_and_quoted_parameters(self):
        text = 'GRUB_CMDLINE_LINUX_DEFAULT="quiet cryptdevice=UUID=example:root rootflags=subvol=@ splash acpi_osi=\'quiet splash\'"\nGRUB_TIMEOUT=5\n'
        result = boot.without_splash(text)
        self.assertIn("cryptdevice=UUID=example:root rootflags=subvol=@", result)
        self.assertIn("acpi_osi='quiet splash'", result)
        self.assertIn("GRUB_TIMEOUT=5", result)
        self.assertNotIn('DEFAULT="quiet ', result)
        self.assertNotIn("@ splash ", result)

    def test_repeated_configuration_is_stable(self):
        text = 'GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 quiet rootflags=subvol=@"\n'
        result = boot.without_splash(text)
        self.assertEqual(result, boot.without_splash(result))

    def test_unknown_format_is_rejected(self):
        with self.assertRaises(ValueError):
            boot.without_splash("GRUB_CMDLINE_LINUX_DEFAULT=$CUSTOM\n")
