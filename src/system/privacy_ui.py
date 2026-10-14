"""Controles de Tor con estado comprobado y alcance visible."""
import json
import os
import re
import subprocess
import threading
from pathlib import Path

DEFAULT_PALETTE = {
    "bg": "#0c1118",
    "acc1": "#27c6ed",
    "acc2": "#ae90e8",
    "fg": "#e6edf3",
    "dim": "#a4b5c2",
}


def theme_palette() -> dict[str, str]:
    state_root = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state"))
    try:
        stored = json.loads((state_root / "black-ice/appearance.json").read_text()).get("palette", {})
    except (OSError, ValueError, AttributeError):
        stored = {}
    return {
        key: value if isinstance(value, str) and re.fullmatch(r"#[0-9a-fA-F]{6}", value) else fallback
        for key, fallback in DEFAULT_PALETTE.items()
        for value in [stored.get(key, fallback)]
    }


def theme_css(palette: dict[str, str] | None = None) -> str:
    colors = {**DEFAULT_PALETTE, **(palette or {})}
    colors = {
        key: value if isinstance(value, str) and re.fullmatch(r"#[0-9a-fA-F]{6}", value) else DEFAULT_PALETTE[key]
        for key, value in colors.items()
        if key in DEFAULT_PALETTE
    }
    colors = {key: colors.get(key, fallback) for key, fallback in DEFAULT_PALETTE.items()}
    return f"""
        window {{ background: {colors['bg']}; color: {colors['fg']}; }}
        #frame {{ border: 1px solid {colors['dim']}; border-top: 3px solid {colors['acc1']}; padding: 26px; }}
        #eyebrow {{ color: {colors['acc2']}; font-family: monospace; font-size: 12px; }}
        #title {{ font-size: 28px; font-weight: 700; }}
        #state {{ font-family: monospace; font-size: 16px; color: {colors['acc1']}; padding: 14px 0; }}
        #state.off {{ color: {colors['dim']}; }}
        #state.preparing {{ color: {colors['acc2']}; }}
        #state.protected {{ color: {colors['acc1']}; }}
        #state.blocked {{ color: #ef8d9d; }}
        #detail {{ color: {colors['fg']}; font-size: 13px; }}
        button {{ background: {colors['bg']}; color: {colors['fg']}; border: 1px solid {colors['dim']}; padding: 10px 14px; }}
        button:hover {{ border-color: {colors['acc1']}; }}
        button:focus {{ border-color: {colors['acc2']}; }}
        button:disabled {{ opacity: .45; }}
    """


def show(privacy):
    import gi
    gi.require_version("Gtk", "3.0")
    from gi.repository import Gdk, GLib, Gtk
    from system_privacy import SCOPE
    window = Gtk.Window(title="BLACK-ICE / Tor")
    window.set_default_size(600, 420)
    window.set_resizable(False)
    window.set_position(Gtk.WindowPosition.CENTER)
    window.connect("destroy", Gtk.main_quit)
    css = Gtk.CssProvider()
    css.load_from_data(theme_css().encode())
    Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
    box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12, margin=16)
    box.set_name("frame")
    window.add(box)
    for text, name in (("Tor del sistema", "title"),):
        label = Gtk.Label(label=text, xalign=0)
        label.set_name(name)
        box.pack_start(label, False, False, 0)
    state = Gtk.Label(xalign=0)
    state.set_name("state")
    box.pack_start(state, False, False, 0)
    detail = Gtk.Label(label=SCOPE, xalign=0, wrap=True, selectable=True)
    detail.set_name("detail")
    detail.set_max_width_chars(65)
    box.pack_start(detail, False, False, 0)
    feedback = Gtk.Label(xalign=0, wrap=True, selectable=True)
    feedback.set_max_width_chars(65)
    box.pack_start(feedback, True, True, 0)
    buttons = []
    busy = [False]
    closed = [False]
    last_error = [""]
    window.connect("destroy", lambda *_: closed.__setitem__(0, True))
    window.connect("delete-event", lambda *_: busy[0])

    def refresh():
        if closed[0]:
            return False
        data = privacy.state()
        phase = data.get("phase", "off")
        state.set_text({"off": "[ OFFLINE ]  ENTORNO APAGADO", "preparing": "[ HANDSHAKE ]  PREPARANDO ENLACE",
                        "protected": "[ VERIFIED ]  TOR ACTIVO", "blocked": "[ BLOCKED ]  ENLACE SIN VERIFICAR"}.get(phase, "[ ERROR ]"))
        context = state.get_style_context()
        for item in ("protected", "blocked"):
            context.remove_class(item)
        context.add_class(phase)
        if not busy[0]:
            feedback.set_text(last_error[0] or (("Salida: " + data["ip"] + "\nRed directa deshabilitada · DNS a través de Tor")
                              if phase == "protected" else data.get("error") or "Activa Tor para usar tus aplicaciones y terminales habituales."))
        return True

    def message(text):
        if not closed[0]:
            feedback.set_text(str(text)[-1200:])
        return False

    def work(operation):
        if busy[0]:
            return
        busy[0] = True
        last_error[0] = ""
        for widget in buttons:
            widget.set_sensitive(False)
        def complete():
            busy[0] = False
            if not closed[0]:
                for widget in buttons:
                    widget.set_sensitive(True)
                refresh()
            return False
        def execute():
            try:
                operation()
            except (OSError, ValueError, RuntimeError, subprocess.TimeoutExpired) as error:
                last_error[0] = str(error)
                GLib.idle_add(message, str(error))
            finally:
                GLib.idle_add(complete)
        threading.Thread(target=execute, daemon=False).start()

    row = Gtk.Box(spacing=8)
    box.pack_start(row, False, False, 0)
    for text, action in (("Activar Tor", lambda: privacy.enable(lambda update: GLib.idle_add(message, update))),
                         ("Apagar Tor", privacy.disable)):
        button = Gtk.Button(label=text)
        button.connect("clicked", lambda _, action=action: work(action))
        row.pack_start(button, True, True, 0)
        buttons.append(button)
    second = Gtk.Box(spacing=8)
    box.pack_start(second, False, False, 0)
    def logs():
        text = privacy.logs()
        def show_logs():
            if closed[0]:
                return False
            dialog = Gtk.Dialog(title="Tor / registro", transient_for=window, modal=True)
            dialog.add_button("Cerrar", Gtk.ResponseType.CLOSE)
            dialog.set_default_size(720, 440)
            scroll = Gtk.ScrolledWindow()
            view = Gtk.TextView(editable=False, monospace=True, wrap_mode=Gtk.WrapMode.WORD_CHAR)
            view.get_buffer().set_text(text)
            scroll.add(view)
            dialog.get_content_area().pack_start(scroll, True, True, 0)
            dialog.show_all()
            dialog.run()
            dialog.destroy()
            return False
        GLib.idle_add(show_logs)
    for text, action in (("Verificar ahora", privacy.request_verify), ("Ver registro", logs)):
        button = Gtk.Button(label=text)
        button.connect("clicked", lambda _, action=action: work(action))
        second.pack_start(button, True, True, 0)
        buttons.append(button)
    refresh()
    GLib.timeout_add_seconds(2, refresh)
    from black_ice_i18n import bind
    bind(window)
    window.show_all()
    Gtk.main()
    return 0
