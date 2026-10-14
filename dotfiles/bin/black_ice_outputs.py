"""Selección de salidas compartida por los configuradores de escritorio."""
import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk


class OutputChecks(Gtk.Box):
    def __init__(self, names, selected=(), changed=None):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        self.changed = changed
        self.checks = {}
        for name in dict.fromkeys([*names, *selected]):
            button = Gtk.CheckButton(label=name + (" · desconectada" if name not in names else ""))
            button.set_active(name in selected)
            self.pack_start(button, False, False, 0)
            self.checks[name] = button
            if changed:
                button.connect("toggled", changed)

    def set_selection(self, names):
        for name in names:
            if name not in self.checks:
                button = Gtk.CheckButton(label=name + " · desconectada")
                self.pack_start(button, False, False, 0)
                self.checks[name] = button
                if self.changed:
                    button.connect("toggled", self.changed)
                button.show()
        for name, button in self.checks.items():
            button.set_active(name in names)

    def get_text(self):
        return [name for name, button in self.checks.items() if button.get_active()]
