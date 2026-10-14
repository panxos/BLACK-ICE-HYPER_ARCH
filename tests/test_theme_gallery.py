"""La galería debe abrir aunque una miniatura esté bloqueada."""
import importlib.machinery
import importlib.util
import os
import tempfile
import threading
import time
import unittest
from pathlib import Path
from unittest.mock import patch

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("GdkPixbuf", "2.0")
from gi.repository import GdkPixbuf, Gtk

ROOT = Path(__file__).resolve().parents[1]
loader = importlib.machinery.SourceFileLoader("theme_gallery", str(ROOT / "dotfiles/bin/theme_visual"))
spec = importlib.util.spec_from_loader(loader.name, loader)
gallery = importlib.util.module_from_spec(spec)
loader.exec_module(gallery)


@unittest.skipUnless(os.environ.get("GDK_BACKEND") == "x11" and Gtk.init_check()[0], "Requiere pantalla GTK aislada; ejecutar con Xvfb")
class GalleryTests(unittest.TestCase):
    def test_slow_image_does_not_block_window_and_worker_stops(self):
        gate = threading.Event()
        entered = threading.Event()

        def slow(_self, _theme):
            entered.set()
            gate.wait(5)

        with patch.object(gallery, "get_themes", return_value=["Benjie", "Almendra"]), patch.object(gallery.ThemeSelector, "_load_preview", slow):
            start = time.monotonic()
            window = gallery.ThemeSelector()
            try:
                self.assertLess(time.monotonic() - start, 2)
                self.assertTrue(window.get_visible())
                self.assertTrue(entered.wait(1))
                self.assertEqual(window.preview_jobs.qsize(), 1)
            finally:
                window.closed.set()
                gate.set()
                window.preview_worker.join(2)
                window.disconnect_by_func(Gtk.main_quit)
                window.destroy()
            self.assertFalse(window.preview_worker.is_alive())

    def test_thumbnail_cache_is_invalidated_when_wallpaper_changes(self):
        with tempfile.TemporaryDirectory(dir=Path.home() / ".cache/tmp/work") as directory, patch.dict(os.environ, XDG_CACHE_HOME=directory):
            source = Path(directory) / "image.png"
            image = GdkPixbuf.Pixbuf.new(GdkPixbuf.Colorspace.RGB, False, 8, 400, 200)
            image.fill(0xff0000ff)
            image.savev(str(source), "png", [], [])
            gallery.ThemeSelector._thumbnail(None, source)
            cache = Path(directory) / "black-ice/theme-thumbnails"
            self.assertEqual(len(list(cache.glob("*.png"))), 1)
            gallery.ThemeSelector._thumbnail(None, source)
            self.assertEqual(len(list(cache.glob("*.png"))), 1)
            image.fill(0x0000ffff)
            image.savev(str(source), "png", [], [])
            os.utime(source, ns=(source.stat().st_atime_ns, source.stat().st_mtime_ns + 1000000))
            result = gallery.ThemeSelector._thumbnail(None, source)
            self.assertEqual(len(list(cache.glob("*.png"))), 2)
            self.assertEqual(result.get_pixels()[:3], bytes([0, 0, 255]))
