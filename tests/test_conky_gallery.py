"""Aplicar estilos debe conservar la galería y mantener GTK disponible."""
import importlib.machinery
import importlib.util
import json
import os
import sys
import threading
import time
import unittest
from pathlib import Path
from subprocess import CompletedProcess
from unittest.mock import patch

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import GLib, Gtk

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "dotfiles/bin"))
loader = importlib.machinery.SourceFileLoader("conky_gallery", str(ROOT / "dotfiles/bin/conky_visual"))
spec = importlib.util.spec_from_loader(loader.name, loader)
gallery = importlib.util.module_from_spec(spec)
loader.exec_module(gallery)


@unittest.skipUnless(os.environ.get("GDK_BACKEND") == "x11" and Gtk.init_check()[0], "Requiere Xvfb")
class ConkyGalleryTests(unittest.TestCase):
    def setUp(self):
        self.prefs = {**gallery.monitor.DEFAULT, "variant": "fracture"}
        self.stack = []
        for item in (patch.object(gallery.monitor, "resolved_preferences", return_value=self.prefs),
                     patch.object(gallery.monitor, "hypr", return_value=[]),
                     patch.object(gallery.Gallery, "request_previews"),
                     patch.object(gallery.Gallery, "place", return_value=False)):
            item.start()
            self.stack.append(item)
        self.window = gallery.Gallery()
        self.window.disconnect_by_func(Gtk.main_quit)

    def tearDown(self):
        self.window.destroy()
        for item in reversed(self.stack):
            item.stop()

    def finish(self):
        until = time.monotonic() + 2
        while self.window.busy and time.monotonic() < until:
            GLib.MainContext.default().iteration(False)
            time.sleep(.002)
        self.assertFalse(self.window.busy)

    def test_repeat_apply_keeps_window_and_close_is_separate(self):
        with patch.object(gallery.subprocess, "run", return_value=CompletedProcess([], 0, "", "")) as run:
            for style in ("fracture", "orbit", "signal"):
                self.window.choose(None, style)
                self.window.apply.clicked()
                self.finish()
                self.assertTrue(self.window.get_visible())
                self.assertEqual(json.loads(run.call_args.args[0][-1])["variant"], style)
            self.assertEqual(run.call_count, 3)
        actions = self.window.apply.get_parent()
        from black_ice_i18n import translate
        close = next(button for button in actions.get_children() if button.get_label() == translate("Cerrar"))
        close.clicked()
        self.assertTrue(self.window.closed)

    def test_slow_apply_does_not_block_and_duplicate_click_is_ignored(self):
        gate = threading.Event()
        entered = threading.Event()

        def slow(*_args, **_kwargs):
            entered.set()
            gate.wait(2)
            return CompletedProcess([], 1, "", "Servicio no disponible")

        with patch.object(gallery.subprocess, "run", side_effect=slow) as run:
            started = time.monotonic()
            self.window.commit(None)
            self.assertLess(time.monotonic() - started, .2)
            self.assertTrue(entered.wait(1))
            try:
                self.window.commit(None)
                self.assertEqual(run.call_count, 1)
                self.assertFalse(self.window.apply.get_sensitive())
            finally:
                gate.set()
                self.finish()
        self.assertIn("Servicio no disponible", self.window.message.get_text())
        self.assertTrue(self.window.get_visible())
        self.assertTrue(self.window.apply.get_sensitive())

    def test_reset_refreshes_controls_without_closing(self):
        self.window.opacity.set_value(95)
        self.window.choose(None, "orbit")
        self.window.applied("reset-theme", True, "Predeterminado aplicado")
        self.assertEqual(self.window.selected, "fracture")
        self.assertEqual(self.window.opacity.get_value(), self.prefs["opacity"] * 100)
        self.assertTrue(self.window.get_visible())
