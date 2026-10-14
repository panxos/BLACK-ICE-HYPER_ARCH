"""Idioma persistente y traducción de propiedades de presentación GTK."""
from __future__ import annotations

import json
import os
import re
import tempfile
import weakref
from functools import lru_cache
from pathlib import Path


def preference_path() -> Path:
    return Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "black-ice/language.json"


def language() -> str:
    override = os.environ.get("BLACK_ICE_LANGUAGE")
    if override in {"es", "en"}:
        return override
    path = preference_path()
    if path.exists():
        selected = json.loads(path.read_text()).get("language")
        if selected not in {"es", "en"}:
            raise ValueError("Unsupported language")
        return selected
    locale = os.environ.get("LC_ALL") or os.environ.get("LC_MESSAGES") or os.environ.get("LANG", "en")
    return "es" if locale.lower().startswith("es") else "en"


def set_language(selected: str) -> None:
    if selected not in {"es", "en"}:
        raise ValueError("Unsupported language")
    path = preference_path()
    if path.is_symlink() or any(parent.is_symlink() for parent in path.parents):
        raise ValueError("Language preferences must not use symbolic links")
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    descriptor, name = tempfile.mkstemp(dir=path.parent)
    try:
        with os.fdopen(descriptor, "w") as stream:
            json.dump({"language": selected}, stream)
        os.replace(name, path)
    finally:
        Path(name).unlink(missing_ok=True)


@lru_cache(maxsize=1)
def catalog() -> dict[str, str]:
    source = Path(__file__).resolve().parents[2] / "config/i18n/en.json"
    installed = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share")) / "black-ice/i18n/en.json"
    return json.loads((source if source.is_file() else installed).read_text())


def translate(text: str, selected: str | None = None) -> str:
    if not text:
        return text
    selected = selected or language()
    entries = catalog()
    if selected == "es":
        entries = {english: spanish for spanish, english in entries.items()}
    if text in entries:
        return entries[text]
    if "\n" in text:
        return "\n".join(translate(line, selected) for line in text.split("\n"))
    if " · " in text:
        return " · ".join(translate(part, selected) for part in text.split(" · "))
    number = re.fullmatch(r"(\d+(?:\.\d+)? )(.*)", text)
    if number and number[2] in entries:
        return number[1] + entries[number[2]]
    for original, replacement in sorted(entries.items(), key=lambda item: len(item[0]), reverse=True):
        if text.startswith(original + ":") or original.endswith(" ") and text.startswith(original):
            return replacement + text[len(original):]
    return text


class Presentation:
    def __init__(self, window) -> None:
        from gi.repository import GLib, Gtk
        self.gtk = Gtk
        self.selected = language()
        self.properties = weakref.WeakKeyDictionary()
        self.rendered = weakref.WeakKeyDictionary()
        self.models = {}
        self.updating = False
        self.window = weakref.ref(window)
        self.walk(window)
        self.timer = GLib.timeout_add(1000, self.refresh)

    def update_property(self, widget, name: str, *_args) -> None:
        if self.updating:
            return
        source = widget.get_property(name)
        if not isinstance(source, str) or not source:
            return
        saved = self.properties.setdefault(widget, {})
        rendered = self.rendered.setdefault(widget, {})
        if name in saved and source == rendered.get(name):
            return
        saved[name] = source
        translated = translate(source, self.selected)
        rendered[name] = translated
        self.updating = True
        try:
            if translated != source:
                widget.set_property(name, translated)
        finally:
            self.updating = False

    def walk(self, widget) -> None:
        Gtk = self.gtk
        if widget not in self.properties:
            self.properties[widget] = {}
            widget._black_ice_i18n_sources = self.properties[widget]
            names = ["tooltip-text"]
            if isinstance(widget, (Gtk.Label, Gtk.Button, Gtk.Expander, Gtk.Frame)):
                names.append("label")
            if isinstance(widget, (Gtk.Window, Gtk.HeaderBar)):
                names.append("title")
            if isinstance(widget, Gtk.HeaderBar):
                names.append("subtitle")
            if isinstance(widget, Gtk.Entry):
                names.append("placeholder-text")
            for name in names:
                widget.connect("notify::" + name, lambda obj, _spec, prop=name: self.update_property(obj, prop))
                self.update_property(widget, name)
        if isinstance(widget, Gtk.ComboBoxText):
            model = widget.get_model()
            saved = self.models.setdefault(model, {})
            for row in model:
                index = row.path.to_string()
                current = str(row[0])
                original, rendered = saved.get(index, (current, current))
                if current != rendered:
                    original = current
                identifier = str(row[1]) if model.get_n_columns() > 1 else ""
                if original == identifier:
                    translated = original
                elif identifier and original.startswith(identifier + " · "):
                    translated = identifier + translate(original[len(identifier):], self.selected)
                else:
                    translated = translate(original, self.selected)
                saved[index] = (original, translated)
                if current != translated:
                    row[0] = translated
        if isinstance(widget, Gtk.TextView) and isinstance(getattr(widget, "_black_ice_message", None), str):
            buffer = widget.get_buffer()
            translated = translate(widget._black_ice_message, self.selected)
            if buffer.get_text(buffer.get_start_iter(), buffer.get_end_iter(), True) != translated:
                buffer.set_text(translated)
        if isinstance(widget, Gtk.Container):
            for child in widget.get_children():
                self.walk(child)
        if isinstance(widget, Gtk.Notebook):
            for index in range(widget.get_n_pages()):
                label = widget.get_tab_label(widget.get_nth_page(index))
                if label is not None:
                    self.walk(label)

    def refresh(self) -> bool:
        window = self.window()
        if window is None or not window.get_visible():
            return False
        selected = language()
        if selected != self.selected:
            self.selected = selected
            self.updating = True
            try:
                for widget, properties in list(self.properties.items()):
                    for name, original in properties.items():
                        translated = translate(original, selected)
                        self.rendered.setdefault(widget, {})[name] = translated
                        if widget.get_property(name) != translated:
                            widget.set_property(name, translated)
            finally:
                self.updating = False
        for top in self.gtk.Window.list_toplevels():
            self.walk(top)
        return True


def bind(window) -> Presentation:
    binding = Presentation(window)
    window._black_ice_language = binding
    return binding
