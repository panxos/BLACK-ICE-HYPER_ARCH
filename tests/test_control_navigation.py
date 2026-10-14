import importlib.machinery
import importlib.util
import os
import sys
import tempfile
import time
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "dotfiles/bin"))


@unittest.skipUnless(os.environ.get("DISPLAY"), "Requiere xvfb-run o una pantalla X11")
class ControlNavigationTests(unittest.TestCase):
    def test_all_sections_remain_selected_after_clicks_and_refresh(self):
        import gi
        gi.require_version("Gtk", "3.0")
        from gi.repository import Gtk
        path = Path(__file__).resolve().parents[1] / "dotfiles/bin/black-ice-control"
        loader = importlib.machinery.SourceFileLoader("control_navigation", str(path))
        spec = importlib.util.spec_from_loader(loader.name, loader)
        module = importlib.util.module_from_spec(spec)
        loader.exec_module(module)
        snapshot = {"volume": 40, "muted": False, "brightness": 60, "wifi": True,
                        "bluetooth": False, "power": "ac", "appearance": {}}

        def exercise():
            window = next(w for w in Gtk.Window.list_toplevels() if hasattr(w, "navigation"))
            try:
                for start in window.navigation:
                    window.navigate(start)
                    for destination, button in window.navigation.items():
                        button.clicked()
                        window.show_state(snapshot)
                        self.assertEqual(window.stack.get_visible_child_name(), destination)
                        self.assertEqual([k for k, b in window.navigation.items() if b.get_active()], [destination])
                        button.clicked()
                        self.assertTrue(button.get_active())
                self.assertFalse(window.suspend_button.get_sensitive())
                self.assertFalse(window.busy)
                window.revision += 1
                stale = {**snapshot, "volume": 90}
                window.show_state(stale, window.revision - 1)
                self.assertEqual(window.scales["volume"].get_value(), 40)
                window.busy = True
                window.show_state(stale)
                self.assertEqual(window.scales["volume"].get_value(), 40)
                window.busy = False
            finally:
                window.destroy()

        with patch.object(module, "command", return_value=(1, "")), \
                patch.object(module, "state", return_value=snapshot), \
                patch.object(Gtk, "main", side_effect=exercise), \
                patch.object(Gtk, "main_quit"):
            self.assertEqual(module.gui("network"), 0)

    def test_system_center_opens_all_pages_without_privileged_actions(self):
        import gi
        gi.require_version("Gtk", "3.0")
        from gi.repository import Gtk
        root = Path(__file__).resolve().parents[1]
        loader = importlib.machinery.SourceFileLoader("system_center_gui", str(root / "dotfiles/bin/black-ice-system"))
        spec = importlib.util.spec_from_loader(loader.name, loader)
        module = importlib.util.module_from_spec(spec)
        loader.exec_module(module)
        parent = Path.home() / ".cache/tmp/work"
        with tempfile.TemporaryDirectory(dir=parent) as directory:
            manager = module.Manager(Path(directory) / "state", root / "config/apps.json", Path(directory) / "config")
            def exercise():
                from black_ice_i18n import translate
                window = next(w for w in Gtk.Window.list_toplevels() if w.get_title() == translate("BLACK-ICE · Sistema"))
                try:
                    notebook = window.get_child().get_children()[0]
                    self.assertEqual(notebook.get_n_pages(), 5)
                    self.assertEqual(notebook.get_current_page(), 2)
                    for index in range(5):
                        notebook.set_current_page(index)
                        self.assertEqual(notebook.get_current_page(), index)
                    security = notebook.get_nth_page(4).get_child().get_child()
                    self.assertGreater(len(security.get_children()), 10)
                    self.assertTrue(all(widget.get_visible() for widget in security.get_children()))
                    from gi.repository import GLib
                    from system_privacy import SystemPrivacy
                    def descendants(widget):
                        yield widget
                        if isinstance(widget, Gtk.Container):
                            for child in widget.get_children():
                                yield from descendants(child)
                    widgets = list(descendants(security))
                    switch = next(widget for widget in widgets if isinstance(widget, Gtk.Switch))
                    shutdown = next(widget for widget in widgets if isinstance(widget, Gtk.Button) and widget.get_label() == translate("Apagar Tor"))
                    with patch.object(manager, "run", return_value="Waybar refreshed") as refresh, \
                            patch.object(SystemPrivacy, "disable", return_value={"enabled": False}) as disable:
                        for visible in (False, True):
                            switch.emit("state-set", visible)
                            deadline = time.monotonic() + 2
                            while not switch.get_sensitive() and time.monotonic() < deadline:
                                GLib.MainContext.default().iteration(False)
                                time.sleep(.005)
                            self.assertEqual(SystemPrivacy(manager).visible(), visible)
                            self.assertEqual(switch.get_state(), visible)
                        self.assertEqual(refresh.call_count, 2)
                        shutdown.clicked()
                        deadline = time.monotonic() + 2
                        while not disable.called and time.monotonic() < deadline:
                            GLib.MainContext.default().iteration(False)
                            time.sleep(.005)
                        disable.assert_called_once()
                finally:
                    window.destroy()
            with patch.object(Gtk, "main", side_effect=exercise), patch.object(Gtk, "main_quit"), patch.object(module, "command") as command:
                self.assertEqual(module.gui(manager, "projects"), 0)
                command.assert_not_called()
