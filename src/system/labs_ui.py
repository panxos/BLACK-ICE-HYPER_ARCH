"""Asistente GTK de laboratorios con plantillas y consola integrada."""
import hashlib
import subprocess
import threading
from pathlib import Path

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import GLib, Gtk
from laboratories import TEMPLATES, Laboratories


class LabsPanel(Gtk.Box):
    def __init__(self, manager, run, window, report):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        self.manager = manager
        self.assistant = Laboratories(manager, run)
        self.window = window
        self.report = report
        self.busy = False
        self.closed = False
        self.state_cache = {}
        self.actions = []
        window.connect("destroy", lambda *_: setattr(self, "closed", True))
        window.connect("delete-event", self.prevent_busy_close)
        self.label("Crea un entorno separado para practicar comandos o probar scripts.")
        self.label("Terminales sin red; prácticas web solo en localhost. Sin carpetas del equipo. No está validado para malware.")
        self.choice = Gtk.ComboBoxText()
        for key, template in TEMPLATES.items():
            self.choice.append(key, template["title"])
        self.field(self, "¿Qué necesitas?", self.choice)
        self.description = self.label("")
        self.resources = self.label("")
        self.requirements_label = self.label("")
        self.name = Gtk.Entry(text=self.next_name())
        self.field(self, "Nombre del laboratorio", self.name)
        self.choice.connect("changed", self.select_template)
        self.choice.set_active(0)
        self.spinner = Gtk.Spinner()
        self.pack_start(self.spinner, False, False, 0)
        row = Gtk.Box(spacing=8)
        self.pack_start(row, False, False, 0)
        self.add_button(row, "Comprobar requisitos", self.check_requirements)
        self.add_button(row, "Instalar requisitos…", self.install_requirements)
        self.create_button = self.add_button(row, "Crear y abrir…", self.create_guided)
        self.advanced = Gtk.Expander(label="Importar imagen propia (avanzado)")
        self.build_advanced()
        self.pack_start(self.advanced, False, False, 0)
        self.pack_start(Gtk.Separator(), False, False, 0)
        self.label("Tus laboratorios")
        self.selection = Gtk.ComboBoxText()
        self.selection.connect("changed", self.show_selected)
        self.pack_start(self.selection, False, False, 0)
        self.state_label = self.label("")
        operations = Gtk.Box(spacing=8)
        self.pack_start(operations, False, False, 0)
        for label, operation in (("Abrir", self.open_selected), ("Apagar", lambda: self.action("stop")),
                                 ("Actualizar estado", self.refresh_status), ("Eliminar…", lambda: self.action("delete"))):
            self.add_button(operations, label, operation)
        force = Gtk.Box(spacing=8)
        self.pack_start(force, False, False, 0)
        self.add_button(force, "Forzar apagado…", lambda: self.action("force-stop"))
        self.label("Presupuesto agregado: 4 vCPU · 4 GiB RAM · 60 GiB de discos reservados. "
                   "Tor del sistema se gestiona fuera de estos laboratorios. Caché y vencimientos: pestaña Seguridad.")
        self.refresh_list()

    def label(self, text: str):
        widget = Gtk.Label(label=text, xalign=0)
        widget.set_line_wrap(True)
        widget.set_max_width_chars(95)
        self.pack_start(widget, False, False, 0)
        return widget

    def field(self, box, label: str, widget) -> None:
        row = Gtk.Box(spacing=12)
        caption = Gtk.Label(label=label, xalign=0)
        caption.set_mnemonic_widget(widget)
        caption.set_size_request(190, -1)
        row.pack_start(caption, False, False, 0)
        row.pack_start(widget, True, True, 0)
        box.pack_start(row, False, False, 0)

    def add_button(self, box, label: str, operation):
        button = Gtk.Button(label=label)
        button.connect("clicked", lambda *_: operation())
        box.pack_start(button, False, False, 0)
        self.actions.append(button)
        return button

    def next_name(self) -> str:
        existing = self.manager.labs()["labs"]
        index = 1
        while f"benjie-lab-{index}" in existing:
            index += 1
        return f"benjie-lab-{index}"

    def prevent_busy_close(self, *_):
        if self.busy:
            self.report("Espera a que termine la operación del laboratorio antes de cerrar.")
        return self.busy

    def select_template(self, *_):
        template = TEMPLATES[self.choice.get_active_id()]
        self.description.set_text(template["description"])
        self.resources.set_text(f"{template['cpus']} vCPU · {template['memory_mib']} MiB RAM · "
                                f"{template['disk_gib']} GiB reservados · " + ("solo localhost" if self.choice.get_active_id() in {"juiceshop", "webgoat"} else "red deshabilitada"))
        self.requirements_label.set_text("Comprueba los requisitos antes de crear. La imagen se descarga únicamente al confirmar.")

    def ask(self, message: str) -> bool:
        dialog = Gtk.MessageDialog(transient_for=self.window, modal=True, message_type=Gtk.MessageType.QUESTION,
                                   buttons=Gtk.ButtonsType.OK_CANCEL, text=message)
        response = dialog.run()
        dialog.destroy()
        return response == Gtk.ResponseType.OK

    def progress(self, message: str) -> None:
        def update():
            if not self.closed:
                self.requirements_label.set_text(message)
        GLib.idle_add(update)

    def work(self, operation, complete=None) -> None:
        if self.busy:
            return
        self.busy = True
        self.spinner.start()
        for action in self.actions:
            action.set_sensitive(False)

        def finish(result, error):
            self.busy = False
            if self.closed:
                return False
            self.spinner.stop()
            for action in self.actions:
                action.set_sensitive(True)
            if error:
                self.requirements_label.set_text(error)
                self.report(error)
                self.refresh_list()
            elif complete:
                complete(result)
            return False

        def execute():
            try:
                result = operation()
            except (OSError, TypeError, ValueError, RuntimeError, subprocess.TimeoutExpired) as error:
                GLib.idle_add(finish, None, str(error)[-900:])
            else:
                GLib.idle_add(finish, result, None)
        threading.Thread(target=execute, daemon=False).start()

    def check_requirements(self) -> None:
        def complete(result):
            message = "Todo listo para crear este laboratorio." if result["ready"] else "Pendiente: " + "; ".join(result["packages"] + result["problems"])
            self.requirements_label.set_text(message)
        selected = self.choice.get_active_id()
        self.work(lambda: self.assistant.requirements(selected), complete)

    def install_requirements(self) -> None:
        selected = self.choice.get_active_id()
        def review(result):
            if not result["packages"]:
                self.requirements_label.set_text("No faltan paquetes. " + "; ".join(result["problems"]))
                return
            packages = result["packages"]
            if self.ask("Se actualizará el sistema y se instalarán estos requisitos:\n" + ", ".join(packages) + "\n\nLa autorización normal sigue siendo necesaria."):
                def install():
                    job = self.manager.enqueue(packages)
                    jobs = self.manager.run_jobs()
                    result = next(item for item in jobs if item["id"] == job["id"])
                    if result["state"] != "done":
                        raise RuntimeError(result.get("error", "La instalación no se completó"))
                    return result
                self.work(install, lambda _: self.check_requirements())
        self.work(lambda: self.assistant.requirements(selected), review)

    def create_guided(self) -> None:
        selected, name = self.choice.get_active_id(), self.name.get_text().strip()
        try:
            self.assistant.plan(selected, name)
        except (TypeError, ValueError) as error:
            self.report(str(error))
            return
        template = TEMPLATES[selected]
        if not self.ask(f"Crear {name} · {template['title']}\n\n{self.resources.get_text()}\n\n"
                        "Se descargará la imagen oficial si no está preparada. Después se abrirá su terminal o navegador.\n"
                        "Las prácticas web conservan sus datos hasta eliminar el laboratorio; las terminales son temporales."):
            return
        def create():
            lab = self.assistant.create(selected, name, self.progress)
            self.progress("Laboratorio creado. Iniciando y abriendo la consola…")
            return lab, self.assistant.open_command(name)
        def complete(result):
            lab, command = result
            self.refresh_list(lab["name"])
            self.spawn_console(command)
            self.name.set_text(self.next_name())
            self.requirements_label.set_text("Laboratorio listo. Usa Abrir para volver a su consola.")
        self.work(create, complete)

    def spawn_console(self, command: list[str]) -> None:
        try:
            subprocess.Popen(command, start_new_session=True, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except OSError as error:
            self.report("El laboratorio está creado; no se pudo abrir la consola: " + str(error))

    def refresh_list(self, preferred=None) -> None:
        selected = preferred or self.selection.get_active_id()
        self.selection.remove_all()
        for name, lab in self.manager.labs()["labs"].items():
            state = self.state_cache.get(name, "Estado sin consultar")
            self.selection.append(name, f"{name} · {lab['engine']} · {state}")
        self.selection.set_active_id(selected or "")
        if not self.selection.get_active_id():
            self.selection.set_active(0)
        self.show_selected()

    def show_selected(self, *_):
        name = self.selection.get_active_id()
        self.state_label.set_text(self.state_cache.get(name, "Pulsa Actualizar estado para consultar el motor.") if name else "Todavía no tienes laboratorios. Elige una plantilla arriba.")

    def refresh_status(self) -> None:
        names = list(self.manager.labs()["labs"])
        def complete(states):
            self.state_cache = {name: value["state"] for name, value in states.items()}
            self.refresh_list()
        self.work(lambda: {name: self.assistant.status(name) for name in names}, complete)

    def open_selected(self) -> None:
        name = self.selection.get_active_id()
        if not name:
            self.report("Selecciona un laboratorio")
            return
        self.work(lambda: self.assistant.open_command(name), lambda result: (self.spawn_console(result), self.refresh_status()))

    def action(self, operation: str) -> None:
        name = self.selection.get_active_id()
        if not name:
            self.report("Selecciona un laboratorio")
            return
        if operation in {"delete", "force-stop"} and not self.ask(
                f"{'Eliminar' if operation == 'delete' else 'Forzar apagado de'} {name}\n\n"
                "Se perderán los datos sin guardar. Para eliminarlo debe estar apagado."):
            return
        def complete(_):
            self.refresh_list()
            self.refresh_status()
        self.work(lambda: self.manager.lab_action(name, operation, name if operation in {"delete", "force-stop"} else ""), complete)

    def build_advanced(self) -> None:
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8, margin=10)
        self.advanced.add(box)
        self.engine = Gtk.ComboBoxText()
        for key, label in (("kvm", "Máquina virtual qcow2"), ("podman", "Contenedor Podman"), ("docker", "Contenedor Docker rootless")):
            self.engine.append(key, label)
        self.engine.set_active(0)
        self.field(box, "Motor", self.engine)
        self.image = Gtk.Entry()
        self.field(box, "Archivo qcow2 o imagen@sha256", self.image)
        self.add_button(box, "Elegir archivo qcow2…", self.choose_image)
        self.advanced_fields = {}
        for key, label, default in (("cpus", "vCPU", 1), ("memory_mib", "RAM (MiB)", 1024), ("disk_gib", "Disco reservado (GiB)", 20)):
            entry = Gtk.SpinButton.new_with_range(1, 61440, 1)
            entry.set_value(default)
            self.field(box, label, entry)
            self.advanced_fields[key] = entry
        self.add_button(box, "Importar imagen propia…", self.import_image)

    def choose_image(self) -> None:
        dialog = Gtk.FileChooserDialog(title="Elegir imagen qcow2", transient_for=self.window, action=Gtk.FileChooserAction.OPEN)
        dialog.add_buttons("Cancelar", Gtk.ResponseType.CANCEL, "Elegir", Gtk.ResponseType.OK)
        if dialog.run() == Gtk.ResponseType.OK:
            self.image.set_text(dialog.get_filename())
        dialog.destroy()

    def import_image(self) -> None:
        spec = {key: widget.get_value_as_int() for key, widget in self.advanced_fields.items()}
        spec.update(name=self.name.get_text().strip(), image=self.image.get_text().strip(), engine=self.engine.get_active_id(), network="none")
        try:
            self.manager.validate_lab(spec, self.manager.labs())
        except (TypeError, ValueError) as error:
            self.report(str(error))
            return
        if not self.ask("Importar una imagen de confianza sin acceso a red. El hash local se calcula automáticamente; "
                        "eso comprueba integridad, no la procedencia del archivo.\n\n" + spec["name"]):
            return
        def create():
            if spec["engine"] == "kvm":
                with Path(spec["image"]).expanduser().open("rb") as stream:
                    spec["sha256"] = hashlib.file_digest(stream, "sha256").hexdigest()
            return self.manager.create_lab(spec)
        self.work(create, lambda lab: self.refresh_list(lab["name"]))
