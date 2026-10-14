"""Perfiles opcionales, recursos administrados y casos desde el centro de sistema."""
import json
import subprocess
from pathlib import Path


def build(box, manager, window, worker, button, ask, report):
    import gi
    gi.require_version("Gtk", "3.0")
    from black_ice_i18n import translate
    from cases import Cases
    from forensics import PROFILES, install, status
    from gi.repository import GLib, Gtk
    from storage import Storage
    from system_privacy import SystemPrivacy as Privacy
    cases, storage = Cases(manager), Storage(manager)
    privacy = Privacy(manager)

    def label(text):
        widget = Gtk.Label(label=text, xalign=0, wrap=True)
        widget.set_max_width_chars(100)
        box.pack_start(widget, False, False, 0)

    def row():
        widget = Gtk.Box(spacing=8)
        box.pack_start(widget, False, False, 0)
        return widget

    results = Gtk.TextView(editable=False, monospace=True, wrap_mode=Gtk.WrapMode.WORD_CHAR)
    def show(result):
        results._black_ice_message = result if isinstance(result, str) else None
        results.get_buffer().set_text(json.dumps(result, ensure_ascii=False, indent=2) if not isinstance(result, str) else translate(result))

    label("Privacidad · Tor")
    label("Tor para las aplicaciones TCP del sistema, desde cualquier terminal. DNS protegido; IPv6, UDP restante y reenvío bloqueados.")
    controls = row()
    button(controls, "Abrir controles de Tor", lambda: subprocess.Popen(
        [str(Path.home() / ".local/bin/black-ice-privacy"), "menu"], start_new_session=True,
        stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL))
    button(controls, "Apagar Tor", lambda: worker(privacy.disable, lambda _: show("Tor apagado. Conexión habitual restaurada.")))
    controls = row()
    controls.pack_start(Gtk.Label(label="Mostrar Tor en la barra"), False, False, 0)
    visibility = Gtk.Switch()
    visibility.set_active(privacy.visible())
    visibility.set_tooltip_text("Ocultar el indicador no apaga Tor. Para detenerlo, usa Apagar Tor.")
    controls.pack_start(visibility, False, False, 0)
    def change_visibility(switch, active):
        previous = privacy.visible()
        switch.set_sensitive(False)
        def finish():
            switch.handler_block(visibility_handler)
            switch.set_active(privacy.visible())
            switch.set_state(privacy.visible())
            switch.handler_unblock(visibility_handler)
            switch.set_sensitive(True)
            return False
        def operation():
            try:
                result = privacy.set_visible(active)
                manager.run([str(Path.home() / ".local/bin/waybar_start.sh")], timeout=30)
                return result
            except (OSError, ValueError, RuntimeError, subprocess.TimeoutExpired):
                privacy.set_visible(previous)
                raise
            finally:
                GLib.idle_add(finish)
        def complete(_):
            show("Indicador de Tor " + ("visible." if active else "oculto. Esto no cambia la conexión Tor."))
        worker(operation, complete)
        return True
    visibility_handler = visibility.connect("state-set", change_visibility)
    label("Forense · instalación opcional")
    forensic = Gtk.ComboBoxText()
    for key, choice in PROFILES.items():
        forensic.append(key, choice["title"])
    forensic.set_active(0)
    controls = row()
    controls.pack_start(forensic, True, True, 0)
    def forensic_check():
        selected = forensic.get_active_id()
        worker(lambda: status(manager, selected), show)
    button(controls, "Comprobar", forensic_check)
    def forensic_details():
        selected = forensic.get_active_id()
        worker(lambda: [manager.details(name) for name in PROFILES[selected]["packages"]], show)
    button(controls, "Fuente / tamaño", forensic_details)
    def forensic_install():
        selected = forensic.get_active_id()
        if not ask("Se actualizará el sistema y se instalará este perfil opcional:\n" + ", ".join(PROFILES[selected]["packages"])):
            return
        def operation():
            job = install(manager, selected)
            jobs = manager.run_jobs()
            done = next(item for item in jobs if item["id"] == job["id"])
            if done["state"] != "done":
                raise RuntimeError(done.get("error", "El perfil no terminó de instalarse"))
            return status(manager, selected)
        worker(operation, show)
    button(controls, "Instalar perfil…", forensic_install)
    label("Recursos · caché propia y apagado de laboratorios")
    controls = row()
    cache = Gtk.SpinButton.new_with_range(256, 131072, 256)
    cache.set_value(storage.policy()["cache_mib"])
    ttl = Gtk.SpinButton.new_with_range(15, 1440, 15)
    ttl.set_value(storage.policy()["ttl_minutes"])
    for text, field in (("Caché MiB", cache), ("Apagar tras min", ttl)):
        controls.pack_start(Gtk.Label(label=text), False, False, 0)
        controls.pack_start(field, False, False, 0)
    def save_policy():
        limit, minutes = cache.get_value_as_int(), ttl.get_value_as_int()
        worker(lambda: storage.configure(limit, minutes), show)
    button(controls, "Guardar", save_policy)
    controls = row()
    button(controls, "Consultar uso", lambda: worker(storage.status, show))
    button(controls, "Aplicar vencimientos", lambda: worker(manager.expire_labs, show))
    def cleanup():
        def review(plan):
            if not plan:
                show("No hay imágenes ni ISOs propias sin uso para limpiar.")
                return
            dialog = Gtk.Dialog(title="Caché propia sin uso", transient_for=window, modal=True)
            dialog.add_button("Cancelar", Gtk.ResponseType.CANCEL)
            dialog.add_button("Eliminar seleccionados", Gtk.ResponseType.OK)
            dialog.set_default_size(680, 380)
            scroll = Gtk.ScrolledWindow()
            listing = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8, margin=12)
            scroll.add(listing)
            choices = []
            for item in plan:
                check = Gtk.CheckButton(label=item["kind"] + " · " + item["label"])
                listing.pack_start(check, False, False, 0)
                choices.append((check, item))
            dialog.get_content_area().pack_start(scroll, True, True, 0)
            dialog.show_all()
            response = dialog.run()
            selected = [item for check, item in choices if check.get_active()]
            dialog.destroy()
            if response == Gtk.ResponseType.OK and selected:
                worker(lambda: storage.cleanup(selected), show)
        worker(storage.cleanup_plan, review)
    button(controls, "Revisar limpieza…", cleanup)
    label("Casos · alcance, VPN y evidencias")
    controls = row()
    selected_case = Gtk.ComboBoxText()
    controls.pack_start(selected_case, True, True, 0)
    def reload_cases(*_):
        selected_case.remove_all()
        for path in sorted((manager.root / "cases").glob("*/case.json")):
            if not path.parent.is_symlink():
                selected_case.append(path.parent.name, path.parent.name)
        selected_case.set_active(0)
    reload_cases()
    button(controls, "Actualizar lista", reload_cases)
    name = Gtk.Entry(placeholder_text="Nombre: benjie-auditoria")
    scope = Gtk.Entry(placeholder_text="Alcance autorizado: hosts, IP o CIDR separados por coma")
    vpn = Gtk.Entry(placeholder_text="UUID VPN requerido (opcional)")
    for field in (name, scope, vpn):
        box.pack_start(field, False, False, 0)
    def create():
        key, allowed, connection = name.get_text().strip(), [value.strip() for value in scope.get_text().split(",")], vpn.get_text().strip()
        def complete(result):
            reload_cases()
            selected_case.set_active_id(key)
            show(result)
        worker(lambda: cases.create(key, allowed, connection), complete)
    button(row(), "Crear caso", create)
    target = Gtk.Entry(placeholder_text="Objetivo para comprobar alcance y VPN")
    note = Gtk.Entry(placeholder_text="Nota privada del caso")
    box.pack_start(target, False, False, 0)
    box.pack_start(note, False, False, 0)
    controls = row()
    def action(kind):
        key = selected_case.get_active_id()
        if not key:
            report("Selecciona o crea un caso")
            return
        value = target.get_text() if kind == "preflight" else note.get_text()
        worker(lambda: cases.verify(key) if kind == "verify" else getattr(cases, kind)(key, value), show)
    button(controls, "Comprobar alcance / VPN", lambda: action("preflight"))
    button(controls, "Guardar nota", lambda: action("note"))
    button(controls, "Verificar integridad", lambda: action("verify"))
    def choose_file(export=False):
        key = selected_case.get_active_id()
        if not key:
            report("Selecciona un caso")
            return
        dialog = Gtk.FileChooserDialog(title="Exportar resumen saneado" if export else "Copiar evidencia al caso", transient_for=window,
                                       action=Gtk.FileChooserAction.SAVE if export else Gtk.FileChooserAction.OPEN)
        dialog.add_buttons("Cancelar", Gtk.ResponseType.CANCEL, "Seleccionar", Gtk.ResponseType.OK)
        response = dialog.run()
        filename = dialog.get_filename()
        dialog.destroy()
        if response == Gtk.ResponseType.OK and filename:
            if export and not ask("El resumen incluirá hashes, tamaños y resultado de integridad.\nSe omiten alcance, VPN, notas, nombres originales y contenido de evidencias."):
                return
            worker(lambda: cases.export(key, filename) if export else cases.evidence(key, filename), show)
    controls = row()
    button(controls, "Importar evidencia…", choose_file)
    button(controls, "Exportar resumen saneado…", lambda: choose_file(True))
    label("Los hashes detectan modificaciones; no constituyen una firma digital ni reemplazan un procedimiento formal de custodia.")
    scroll = Gtk.ScrolledWindow()
    scroll.set_min_content_height(200)
    scroll.add(results)
    box.pack_start(scroll, True, True, 0)
