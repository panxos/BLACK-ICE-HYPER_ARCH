"""Plantillas y acceso a laboratorios propios, sin imágenes ni hashes manuales."""
import hashlib
import json
import os
import re
import shutil
import subprocess
import tempfile
import time
import urllib.request
from pathlib import Path

from web_labs import WEB, WebLabs

TEMPLATES = {
    "alpine": {"title": "Linux ligero", "engine": "podman", "image": "docker.io/library/alpine:3.24.2",
               "description": "Terminal Linux para practicar comandos. Sin Internet; archivos temporales en /tmp.",
               "cpus": 1, "memory_mib": 256, "disk_gib": 1, "shell": "/bin/sh"},
    "debian": {"title": "Linux completo", "engine": "podman", "image": "docker.io/library/debian:13-slim",
               "description": "Terminal Debian para probar scripts con Bash. Sin Internet; no incluye herramientas de pentesting.",
               "cpus": 1, "memory_mib": 512, "disk_gib": 1, "shell": "/bin/bash"},
    "alpine-vm": {"title": "Máquina virtual Linux", "engine": "kvm",
                  "description": "Alpine live: inicia en su consola como root, sin contraseña. Sin red; la sesión live se pierde al apagar.",
                  "url": "https://dl-cdn.alpinelinux.org/alpine/v3.24/releases/x86_64/alpine-virt-3.24.2-x86_64.iso",
                  "iso_sha256": "3ab424762af704b2c2a9e57df1dc37f982af260071504d977f2fb96822e7130b",
                  "cpus": 1, "memory_mib": 512, "disk_gib": 4},
}
TEMPLATES.update(WEB)


class Laboratories:
    def __init__(self, manager, run):
        self.manager = manager
        self.run = run

    def requirements(self, template: str) -> dict:
        spec = TEMPLATES[template]
        commands = {"podman": "podman"} if spec["engine"] == "podman" else {
            "virsh": "libvirt", "qemu-img": "qemu-full", "qemu-system-x86_64": "qemu-full", "virt-viewer": "virt-viewer"}
        missing = sorted({package for binary, package in commands.items() if not shutil.which(binary)})
        problems = []
        if os.geteuid() == 0:
            problems.append("Abre Laboratorios como usuario normal, sin sudo.")
        if spec["engine"] == "kvm" and not os.access("/dev/kvm", os.R_OK | os.W_OK):
            problems.append("Tu sesión no tiene acceso a /dev/kvm. Comprueba virtualización y permisos del grupo kvm.")
        if not missing and not problems:
            try:
                if spec["engine"] == "podman":
                    info = json.loads(self.run(["podman", "info", "--format", "json"]))
                    if not info.get("host", {}).get("security", {}).get("rootless"):
                        problems.append("Podman debe funcionar sin root.")
                    if info.get("host", {}).get("cgroupVersion") != "v2":
                        problems.append("Los límites de recursos necesitan cgroups v2.")
                else:
                    self.run(["virsh", "-c", "qemu:///session", "list", "--all"])
                    self.manager.kvm_display()
            except (OSError, ValueError, RuntimeError, subprocess.TimeoutExpired) as error:
                problems.append(str(error))
        return {"ready": not missing and not problems, "packages": missing, "problems": problems}

    def plan(self, template: str, name: str) -> dict:
        if template not in TEMPLATES:
            raise ValueError("Plantilla desconocida")
        choice = TEMPLATES[template]
        spec = {key: choice[key] for key in ("engine", "cpus", "memory_mib", "disk_gib")}
        spec.update(name=name, network="local" if template in WEB else "none", template=template)
        self.manager.validate_lab(spec, self.manager.labs())
        return spec

    def download_iso(self, template: dict, progress) -> Path:
        assets = self.manager.root / "assets"
        assets.mkdir(mode=0o700, exist_ok=True)
        final = assets / (template["iso_sha256"] + ".iso")
        if final.is_file():
            with final.open("rb") as stream:
                if hashlib.file_digest(stream, "sha256").hexdigest() == template["iso_sha256"]:
                    return final
            raise ValueError("La ISO guardada no supera la verificación. Retírala y vuelve a preparar el laboratorio.")
        descriptor, name = tempfile.mkstemp(prefix="iso-", suffix=".part", dir=assets)
        temporary = Path(name)
        try:
            digest = hashlib.sha256()
            downloaded = 0
            started = time.monotonic()
            reported = -1
            with os.fdopen(descriptor, "wb") as output, urllib.request.urlopen(template["url"], timeout=30) as response:
                if not response.url.startswith("https://dl-cdn.alpinelinux.org/"):
                    raise ValueError("La descarga salió del proveedor oficial")
                while chunk := response.read1(1024 * 1024):
                    from storage import Storage
                    Storage(self.manager).check()
                    if time.monotonic() - started > 600:
                        raise TimeoutError("La descarga superó diez minutos; vuelve a intentarlo")
                    downloaded += len(chunk)
                    if downloaded > 256 * 1024**2:
                        raise ValueError("La ISO supera el límite de descarga de esta plantilla")
                    output.write(chunk)
                    digest.update(chunk)
                    if downloaded // 1024**2 != reported:
                        reported = downloaded // 1024**2
                        progress(f"Descargando ISO oficial: {reported} MiB")
                output.flush()
                os.fsync(output.fileno())
            if digest.hexdigest() != template["iso_sha256"]:
                raise ValueError("La ISO descargada no coincide con el SHA256 de la plantilla")
            os.replace(temporary, final)
            return final
        finally:
            temporary.unlink(missing_ok=True)

    def create(self, template: str, name: str, progress=lambda text: None) -> dict:
        spec = self.plan(template, name)
        requirements = self.requirements(template)
        if not requirements["ready"]:
            raise ValueError("Requisitos pendientes: " + ", ".join(requirements["packages"] + requirements["problems"]))
        choice = TEMPLATES[template]
        with self.manager.locked("lab-prepare"):
            progress("Comprobando imagen preparada…")
            if spec["engine"] == "podman":
                try:
                    image = json.loads(self.run(["podman", "image", "inspect", choice["image"]]))[0]
                except RuntimeError:
                    progress("Descargando imagen oficial; este paso requiere conexión del equipo.")
                    self.run(["podman", "pull", "--quiet", choice["image"]], timeout=600)
                    image = json.loads(self.run(["podman", "image", "inspect", choice["image"]]))[0]
                repository = choice["image"].rsplit(":", 1)[0]
                pinned = next((value for value in image.get("RepoDigests", [])
                               if re.fullmatch(re.escape(repository) + r"@sha256:[a-f0-9]{64}", value)), None)
                if not pinned:
                    raise ValueError("El motor no confirmó el digest de la imagen oficial")
                from storage import Storage
                Storage(self.manager).track_image(choice["image"], image)
                spec.update(image=pinned, user=choice.get("user", "1000:1000"))
                if template not in WEB:
                    spec.update(shell=choice["shell"], workdir="/tmp", command=["/bin/sh", "-c", "while :; do sleep 3600; done"])
            else:
                iso = self.download_iso(choice, progress)
                descriptor, name = tempfile.mkstemp(prefix="base-", suffix=".qcow2", dir=iso.parent)
                os.close(descriptor)
                base = Path(name)
                try:
                    self.run(["qemu-img", "create", "-f", "qcow2", str(base), f"{spec['disk_gib']}G"])
                    with base.open("rb") as stream:
                        checksum = hashlib.file_digest(stream, "sha256").hexdigest()
                    spec.update(image=str(base), sha256=checksum, iso=str(iso), iso_sha256=choice["iso_sha256"])
                    progress("Creando máquina virtual sin interfaces de red…")
                    return self.manager.create_lab(spec)
                finally:
                    base.unlink(missing_ok=True)
            progress("Creando aplicación web solo local…" if template in WEB else "Creando contenedor sin red ni carpetas compartidas…")
            return self.manager.create_lab(spec)

    def status(self, name: str) -> dict:
        lab = self.manager.labs()["labs"].get(name)
        if not lab:
            raise ValueError("Selecciona un laboratorio propio")
        try:
            if lab["engine"] == "kvm":
                if self.run(["virsh", "-c", "qemu:///session", "domuuid", lab["resource"]]) != lab["id"]:
                    raise ValueError("La identidad de la VM cambió")
                state = self.run(["virsh", "-c", "qemu:///session", "domstate", lab["resource"]]).strip()
                return {"running": state == "running", "state": "Encendido" if state == "running" else "Apagado" if state == "shut off" else state}
            inspected = json.loads(self.run([lab["engine"], "inspect", lab["resource"]], store=lab.get("store", "legacy")))[0]
            if inspected.get("Config", {}).get("Labels", {}).get("black-ice.id") != lab["id"]:
                raise ValueError("La identidad del contenedor cambió")
            running = bool(inspected.get("State", {}).get("Running"))
            return {"running": running, "state": "Encendido" if running else "Apagado"}
        except (OSError, RuntimeError, subprocess.TimeoutExpired) as error:
            return {"running": False, "state": "No disponible: " + str(error)[-200:]}

    def open_command(self, name: str) -> list[str]:
        lab = self.manager.labs()["labs"].get(name)
        if not lab:
            raise ValueError("Selecciona un laboratorio propio")
        if not self.status(name)["running"]:
            self.manager.lab_action(name, "start")
        elif lab["engine"] == "kvm":
            self.manager.verify_kvm_limits(lab)
        else:
            self.manager.verify_container_limits(lab)
        if lab.get("web"):
            return ["xdg-open", WebLabs(self.manager).ready(lab)]
        if lab["engine"] == "kvm":
            return ["virt-viewer", "--connect", "qemu:///session", "--attach", lab["id"]]
        shell = lab.get("shell", "/bin/sh")
        if shell not in {"/bin/sh", "/bin/bash"}:
            raise ValueError("Intérprete no permitido")
        launch = self.manager.podman_args([lab["engine"], "exec", "--interactive", "--tty", lab["resource"], shell], lab.get("store", "legacy"))
        return ["kitty", "--title", "Laboratorio · " + name, "-e", *launch]
