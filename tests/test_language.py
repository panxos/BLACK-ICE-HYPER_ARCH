"""Cambio de idioma sin alterar valores, identificadores ni datos personales."""
import json
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "dotfiles/bin"))
import black_ice_i18n as language


class LanguageTests(unittest.TestCase):
    def setUp(self):
        work = Path.home() / ".cache/tmp/work"
        work.mkdir(parents=True, exist_ok=True)
        temporary = tempfile.TemporaryDirectory(dir=work)
        self.addCleanup(temporary.cleanup)
        self.config = Path(temporary.name)
        environment = patch.dict(os.environ, {"XDG_CONFIG_HOME": str(self.config), "LC_ALL": "es_CL.UTF-8"})
        environment.start()
        self.addCleanup(environment.stop)

    def test_preference_overrides_locale_and_survives_new_read(self):
        self.assertEqual(language.language(), "es")
        language.set_language("en")
        self.assertEqual(language.language(), "en")
        self.assertEqual(json.loads(language.preference_path().read_text()), {"language": "en"})
        language.set_language("es")
        self.assertEqual(language.language(), "es")
        with self.assertRaises(ValueError):
            language.set_language("unknown")

    def test_symlink_cannot_replace_unrelated_preferences(self):
        other = self.config / "personal.json"
        other.write_text("keep")
        path = language.preference_path()
        path.parent.mkdir(parents=True)
        path.symlink_to(other)
        with self.assertRaises(ValueError):
            language.set_language("en")
        self.assertEqual(other.read_text(), "keep")

    def test_rendered_text_preserves_identifiers_and_dynamic_theme_name(self):
        self.assertEqual(language.translate("Tema actual: Mr-Robot", "en"), "Current theme: Mr-Robot")
        self.assertEqual(language.translate("User-Benjie", "en"), "User-Benjie")
        self.assertEqual(language.translate("Guardar", "es"), "Guardar")
        self.assertEqual(language.translate("Centro de software · instalar y reintentar", "en"),
                         "Software center · install and retry")

    def test_gtk_switches_live_without_translating_inputs_or_combo_ids(self):
        import gi
        gi.require_version("Gtk", "3.0")
        from gi.repository import Gtk
        if not Gtk.init_check()[0]:
            self.skipTest("No graphical display")
        window = Gtk.Window(title="BLACK-ICE · Sistema")
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        window.add(box)
        label = Gtk.Label(label="Guardar")
        entry = Gtk.Entry(text="Guardar", placeholder_text="Nombre del proyecto")
        combo = Gtk.ComboBoxText()
        combo.append("left", "Izquierda")
        combo.append("Guardar", "Guardar")
        combo.set_active_id("left")
        for widget in (label, entry, combo):
            box.pack_start(widget, False, False, 0)
        window.show_all()
        self.addCleanup(window.destroy)
        binding = language.bind(window)
        language.set_language("en")
        binding.refresh()
        self.assertEqual(label.get_label(), "Save")
        self.assertEqual(entry.get_text(), "Guardar")
        self.assertEqual(entry.get_placeholder_text(), "Project name")
        self.assertEqual(combo.get_active_id(), "left")
        self.assertEqual(combo.get_active_text(), "Left")
        self.assertEqual(combo.get_model()[1][0], "Guardar")
        label.set_text("Aplicar tema")
        self.assertEqual(label.get_text(), "Apply theme")
        language.set_language("es")
        binding.refresh()
        self.assertEqual(label.get_text(), "Aplicar tema")
        self.assertEqual(combo.get_active_text(), "Izquierda")
