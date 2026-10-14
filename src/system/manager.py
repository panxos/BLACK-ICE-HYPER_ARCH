"""Backend personal para software, proyectos y laboratorios de BLACK-ICE."""
import fcntl
import hashlib
import ipaddress
import json
import os
import re
import subprocess
import tempfile
import time
import uuid
import xml.etree.ElementTree as ET
from contextlib import contextmanager
from pathlib import Path

HELPER = "/usr/lib/black-ice/system-transaction"


def command(args, timeout=30):
    result = subprocess.run(args, capture_output=True, text=True, timeout=timeout, check=False,
                            env=dict(os.environ, LC_ALL="C"))
    if result.returncode:
        raise RuntimeError((result.stderr or result.stdout)[-2500:] or f"Falló {args[0]}")
    return result.stdout.strip()


def atomic(path, value):
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    fd, temporary = tempfile.mkstemp(dir=path.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            stream.write(value if isinstance(value, str) else json.dumps(value, ensure_ascii=False, indent=2))
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
    finally:
        Path(temporary).unlink(missing_ok=True)


def identifier(value):
    if not re.fullmatch(r"[a-z0-9][a-z0-9_-]{0,47}", value):
        raise ValueError("Usa 1–48 letras minúsculas, números, guiones o guion bajo")
    return value


def target(value):
    value = value.strip()
    if not value:
        return ""
    try:
        return str(ipaddress.ip_address(value))
    except ValueError:
        if len(value) <= 253 and all(re.fullmatch(r"[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?", label) for label in value.rstrip(".").split(".")):
            return value.rstrip(".")
        raise ValueError("Objetivo inválido: indica IP o hostname") from None


class Manager:
    def __init__(self, state=None, catalog=None, config=None):
        home = Path.home()
        self.root = Path(state or Path(os.environ.get("XDG_STATE_HOME", home / ".local/state")) / "black-ice/system")
        self.root.mkdir(parents=True, exist_ok=True, mode=0o700)
        self.config = Path(config or os.environ.get("XDG_CONFIG_HOME", home / ".config"))
        self.catalog_path = Path(catalog or Path(os.environ.get("XDG_DATA_HOME", home / ".local/share")) / "black-ice/software/config/apps.json")

    @contextmanager
    def locked(self, name="state"):
        with (self.root / f"{name}.lock").open("a") as lock:
            try:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                raise RuntimeError("Ya hay una operación en ejecución") from None
            yield

    def read(self, name, default):
        path = self.root / f"{name}.json"
        return json.loads(path.read_text()) if path.exists() else default

    def write(self, name, value):
        atomic(self.root / f"{name}.json", value)

    def podman_args(self, args: list[str], store: str = "managed") -> list[str]:
        if args[0] != "podman" or store == "legacy" or "--root" in args:
            return args
        runtime = Path(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}"))
        return ["podman", "--root", str(self.root / "containers"), "--runroot", str(runtime / "black-ice-containers"), *args[1:]]

    def run(self, args: list[str], timeout: int = 30, store: str = "managed") -> str:
        prepared = self.podman_args(args, store)
        if args[0] == "podman" and any(operation in args[1:3] for operation in ("pull", "build", "load")):
            from storage import Storage
            return Storage(self).guarded(prepared, timeout)
        return command(prepared, timeout)

    def catalog(self):
        return {item["id"]: item for item in json.loads(self.catalog_path.read_text())["apps"]}

    def installed(self, packages):
        result = subprocess.run(["pacman", "-Qq", "--", *packages], capture_output=True, text=True, timeout=15, check=False)
        return set(result.stdout.splitlines())

    def details(self, package):
        if package not in self.catalog():
            raise ValueError("Aplicación fuera del catálogo")
        try:
            info = command(["pacman", "-Si", "--", package])
            source = "Repositorio firmado"
        except RuntimeError:
            info = "No está en los repositorios configurados. Revisa el PKGBUILD e instala con paru desde una terminal, como usuario normal."
            source = "AUR / repositorio no disponible"
        return {"app": self.catalog()[package], "installed": package in self.installed([package]), "source": source, "details": info}

    def enqueue(self, packages, operation="install"):
        packages = list(dict.fromkeys(packages))
        if not packages or not set(packages) <= self.catalog().keys() or operation not in {"install", "remove"}:
            raise ValueError("Selección inválida")
        with self.locked():
            jobs = self.read("jobs", [])
            if len(jobs) >= 200:
                raise ValueError("La cola alcanzó 200 trabajos; archiva los terminados antes de continuar")
            job = {"schema": 1, "id": str(uuid.uuid4()), "operation": operation, "packages": packages,
                       "state": "pending", "created": time.time(), "attempts": 0, "cancel_requested": False}
            jobs.append(job)
            self.write("jobs", jobs)
            return job

    def change_job(self, job_id, operation):
        with self.locked():
            jobs = self.read("jobs", [])
            job = next((j for j in jobs if j["id"] == job_id), None)
            if not job:
                raise ValueError("Trabajo inexistente")
            if operation == "cancel":
                job["cancel_requested"] = True
                if job["state"] != "running":
                    job["state"] = "cancelled"
            elif operation == "retry" and job["state"] in {"failed", "interrupted"}:
                job.update(state="pending", cancel_requested=False)
            else:
                raise ValueError("Este trabajo no se puede reintentar")
            self.write("jobs", jobs)

    def run_jobs(self, executor=None):
        executor = executor or (lambda op, packages: command(["pkexec", HELPER, op, *packages], timeout=7200))
        with self.locked("worker"):
            with self.locked():
                jobs = self.read("jobs", [])
                for job in jobs:
                    if job["state"] == "running":
                        job["state"] = "interrupted"
                        job["error"] = "Operación interrumpida; revisa pacman y reintenta. No se borró ningún bloqueo."
                self.write("jobs", jobs)
            for job_id in [j["id"] for j in jobs if j["state"] == "pending"]:
                with self.locked():
                    jobs = self.read("jobs", [])
                    job = next(j for j in jobs if j["id"] == job_id)
                    if job["cancel_requested"]:
                        continue
                    installed = self.installed(job["packages"])
                    packages = [p for p in job["packages"] if (p in installed) == (job["operation"] == "remove")]
                    job.pop("finished", None)
                    job.pop("output", None)
                    job.update(state="running", attempts=job["attempts"] + 1, started=time.time(), step="Transacción de paquetes", error="")
                    self.write("jobs", jobs)
                try:
                    output = executor(job["operation"], packages) if packages else "Estado ya reconciliado"
                    installed = self.installed(job["packages"])
                    if (job["operation"] == "install" and not set(job["packages"]) <= installed) or (job["operation"] == "remove" and set(job["packages"]) & installed):
                        raise RuntimeError("Pacman no confirma el estado esperado")
                    result = {"state": "done", "output": output[-2000:]}
                except (OSError, RuntimeError, subprocess.TimeoutExpired) as error:
                    result = {"state": "failed", "error": str(error)[-2500:]}
                with self.locked():
                    jobs = self.read("jobs", [])
                    current = next(j for j in jobs if j["id"] == job_id)
                    current.update(result, finished=time.time())
                    self.write("jobs", jobs)
            return self.read("jobs", [])

    def save_project(self, name, address="", vpn="", notes=""):
        identifier(name)
        address = target(address)
        if vpn:
            try:
                vpn = str(uuid.UUID(vpn))
            except ValueError:
                raise ValueError("Usa el UUID de un perfil VPN de NetworkManager") from None
        if len(notes) > 4000:
            raise ValueError("Notas limitadas a 4000 caracteres")
        with self.locked():
            projects = self.read("projects", {"schema": 1, "active": "", "projects": {}})
            projects["projects"][name] = {**projects["projects"].get(name, {}), "target": address, "vpn": vpn, "notes": notes, "updated": time.time()}
            self.write("projects", projects)
            if projects.get("active") == name:
                atomic(self.config / "bin/target", (address + " " + name).strip() + "\n")
        return projects

    def activate_project(self, name):
        if not isinstance(name, str):
            raise TypeError("Selecciona un proyecto")
        with self.locked():
            projects = self.read("projects", {"schema": 1, "active": "", "projects": {}})
            if name and name not in projects["projects"]:
                raise ValueError("Proyecto inexistente")
            projects["active"] = name
            self.write("projects", projects)
            project = projects["projects"].get(name, {})
            atomic(self.config / "bin/target", (project.get("target", "") + " " + name).strip() + "\n")
        return projects

    def export_project(self, name, destination):
        projects = self.read("projects", {})
        if name not in projects.get("projects", {}):
            raise ValueError("Proyecto inexistente")
        atomic(Path(destination), {"schema": 1, "name": name, "target": projects["projects"][name]["target"]})

    def export_lab(self, name, destination):
        lab = self.labs()["labs"].get(name)
        if not lab:
            raise ValueError("Laboratorio inexistente")
        keys = ("name", "template", "cpus", "memory_mib", "disk_gib", "network") if lab.get("template") else (
            "name", "engine", "image", "cpus", "memory_mib", "disk_gib", "network", "sha256")
        atomic(Path(destination), {key: lab[key] for key in keys if key in lab})

    def active_target(self):
        projects = self.read("projects", {})
        name = projects.get("active", "")
        if name:
            return projects["projects"][name].get("target", ""), name
        path = self.config / "bin/target"
        parts = path.read_text().strip().split(maxsplit=1) if path.exists() else []
        return (target(parts[0]), parts[1] if len(parts) > 1 else "") if parts else ("", "")

    def set_target(self, address, label=""):
        address = target(address)
        if label and not re.fullmatch(r"[\w.-]{1,48}", label):
            raise ValueError("Nombre de objetivo inválido")
        with self.locked():
            projects = self.read("projects", {})
            name = projects.get("active", "")
            if name:
                projects["projects"][name]["target"] = address
                self.write("projects", projects)
            atomic(self.config / "bin/target", (address + " " + label).strip() + "\n")

    def vpn_identity(self, connection):
        path = command(["nmcli", "-g", "GENERAL.DBUS-PATH", "connection", "show", "--active", "uuid", connection])
        if not re.fullmatch(r"/org/freedesktop/NetworkManager/ActiveConnection/[0-9]+", path):
            raise RuntimeError("La VPN no tiene una activación identificable")
        owner = command(["busctl", "--system", "call", "org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus", "GetNameOwner", "s", "org.freedesktop.NetworkManager"])
        return {"path": path, "owner": owner, "boot": Path("/proc/sys/kernel/random/boot_id").read_text().strip()}

    def vpn(self, operation):
        with self.locked("vpn"):
            projects = self.read("projects", {})
            active = projects.get("projects", {}).get(projects.get("active"), {})
            connection = active.get("vpn", "")
            own = self.read("vpn", {})
            if operation == "disconnect":
                if not own.get("uuid"):
                    raise ValueError("No hay VPN iniciada por BLACK-ICE")
                active = command(["nmcli", "-t", "-f", "UUID", "connection", "show", "--active"]).splitlines()
                if own["uuid"] not in active:
                    self.write("vpn", {})
                    return
                identity = self.vpn_identity(own["uuid"])
                if identity != own.get("identity"):
                    raise RuntimeError("La VPN fue reiniciada fuera de BLACK-ICE; se conserva")
                command(["nmcli", "connection", "down", "apath", identity["path"]], timeout=45)
                self.write("vpn", {})
            elif operation == "connect":
                if not connection:
                    raise ValueError("El proyecto no tiene un perfil VPN")
                if command(["nmcli", "-g", "connection.type", "connection", "show", "uuid", connection]) != "vpn":
                    raise ValueError("El UUID no corresponde a un perfil VPN")
                externally_active = command(["nmcli", "-t", "-f", "UUID", "connection", "show", "--active"]).splitlines()
                if connection in externally_active:
                    if own.get("uuid") != connection or self.vpn_identity(connection) != own.get("identity"):
                        raise RuntimeError("La VPN ya fue iniciada fuera de BLACK-ICE; se conserva")
                    return
                if own.get("uuid") and own["uuid"] != connection and own["uuid"] in externally_active:
                    raise RuntimeError("Desconecta primero la VPN del proyecto anterior")
                command(["nmcli", "connection", "up", "uuid", connection], timeout=90)
                self.write("vpn", {"uuid": connection, "project": projects["active"], "identity": self.vpn_identity(connection)})
            else:
                raise ValueError("Acción VPN inválida")

    def vpn_status(self):
        try:
            interfaces = json.loads(command(["ip", "-j", "addr", "show", "dev", "tun0"]))
            addresses = [a["local"] for interface in interfaces for a in interface.get("addr_info", [])
                         if "UP" in interface.get("flags", []) and interface.get("operstate") != "DOWN" and
                         a.get("family") == "inet" and not ipaddress.ip_address(a["local"]).is_loopback]
        except (OSError, ValueError, RuntimeError):
            addresses = []
        return {"connected": bool(addresses), "interface": "tun0", "addresses": addresses}

    def labs(self):
        return self.read("labs", {"schema": 1, "budget": {"cpus": 4, "memory_mib": 4096, "disk_gib": 60}, "labs": {}})

    def validate_lab(self, spec, registered):
        identifier(spec["name"])
        if spec["engine"] not in {"kvm", "podman", "docker"} or spec.get("network", "none") not in {"none", "nat", "local"}:
            raise ValueError("Motor o red inválidos")
        if spec.get("network") == "local" and (spec["engine"] != "podman" or spec.get("template") not in {"juiceshop", "webgoat"}):
            raise ValueError("La red local requiere una plantilla web oficial")
        for resource in ("cpus", "memory_mib", "disk_gib"):
            if type(spec[resource]) is not int or spec[resource] <= 0:
                raise ValueError("Recursos enteros positivos requeridos")
            reserved = sum(item[resource] for item in registered["labs"].values())
            if self.read("privacy", {}).get("enabled"):
                reserved += {"cpus": 2, "memory_mib": 768, "disk_gib": 0}[resource]
            if reserved + spec[resource] > registered["budget"][resource]:
                raise ValueError(f"Presupuesto excedido: {resource}")
        if spec["name"] in registered["labs"]:
            raise ValueError("Ya existe este laboratorio")

    def verify_container_limits(self, lab):
        inspected = json.loads(self.run([lab["engine"], "inspect", lab["resource"]], store=lab.get("store", "legacy")))[0]
        config = inspected["HostConfig"]
        cpu_limit = config.get("NanoCpus", 0) / 1_000_000_000
        if not cpu_limit and config.get("CpuPeriod"):
            cpu_limit = config.get("CpuQuota", 0) / config["CpuPeriod"]
        if (config.get("Memory") != lab["memory_mib"] * 1024**2 or cpu_limit != lab["cpus"] or
                not config.get("ReadonlyRootfs") or config.get("Privileged") or config.get("PidsLimit") != 256):
            raise RuntimeError("El motor no aplicó los límites y aislamiento solicitados")
        if inspected.get("Config", {}).get("Labels", {}).get("black-ice.id") != lab["id"]:
            raise RuntimeError("El contenedor no corresponde al registro")
        if lab.get("network", "none") == "none" and config.get("NetworkMode") != "none":
            raise RuntimeError("El contenedor tiene acceso de red no autorizado")
        dropped = [str(value).upper() for value in config.get("CapDrop", [])]
        expanded_podman = lab["engine"] == "podman" and bool(dropped) and "EffectiveCaps" in inspected and "BoundingCaps" in inspected
        if config.get("CapAdd") or inspected.get("EffectiveCaps") or inspected.get("BoundingCaps") or ("ALL" not in dropped and not expanded_podman):
            raise RuntimeError("El contenedor conserva capacidades no autorizadas")
        if not any(value in {"no-new-privileges", "no-new-privileges=true"} for value in config.get("SecurityOpt", [])):
            raise RuntimeError("El contenedor permite obtener nuevos privilegios")
        if lab.get("web"):
            from web_labs import WebLabs
            WebLabs(self).verify(lab, inspected)
        elif config.get("Binds") or config.get("VolumesFrom") or config.get("PortBindings") or any(
                mount.get("Type") != "tmpfs" for mount in inspected.get("Mounts", [])):
            raise RuntimeError("El contenedor tiene montajes o puertos fuera del aislamiento")
        if any(config.get(key) == "host" for key in ("PidMode", "IpcMode", "UTSMode", "UsernsMode")):
            raise RuntimeError("El contenedor comparte un espacio de nombres del equipo")
        if lab.get("user") and inspected.get("Config", {}).get("User") != lab["user"]:
            raise RuntimeError("El usuario del contenedor cambió")

    def kvm_display(self) -> tuple[str, str]:
        capabilities = ET.fromstring(command(["virsh", "-c", "qemu:///session", "domcapabilities", "--virttype", "kvm", "--arch", "x86_64"]))
        videos = {value.text for value in capabilities.findall("./devices/video/enum[@name='modelType']/value")}
        graphics = {value.text for value in capabilities.findall("./devices/graphics/enum[@name='type']/value")}
        video = next((value for value in ("virtio", "vga") if value in videos), None)
        display = next((value for value in ("spice", "vnc") if value in graphics), None)
        if not video or not display:
            raise RuntimeError("QEMU no ofrece consola gráfica compatible. Instala qemu-full y vuelve a comprobar requisitos.")
        return video, display

    def verify_kvm_limits(self, lab):
        actual = ET.fromstring(command(["virsh", "-c", "qemu:///session", "dumpxml", lab["resource"]]))
        memory = actual.find("memory")
        memory_mib = int(memory.text) / (1024 if memory.get("unit", "KiB") == "KiB" else 1)
        if memory_mib != lab["memory_mib"] or int(actual.findtext("vcpu")) != lab["cpus"]:
            raise RuntimeError("La VM no conserva los límites de CPU/RAM registrados")
        disk = actual.find("./devices/disk[@device='disk']/source")
        if disk is None or disk.get("file") != lab["disk"]:
            raise RuntimeError("El disco de la VM no corresponde al registro")
        sources = actual.findall("./devices/disk/source")
        expected = {lab["disk"], *([lab["iso"]] if lab.get("iso") else [])}
        if len(sources) != len(expected) or {source.get("file") for source in sources} != expected:
            raise RuntimeError("La VM tiene discos fuera del registro")
        interfaces = actual.findall("./devices/interface")
        if interfaces and (lab.get("network", "none") != "nat" or len(interfaces) != 1 or interfaces[0].get("type") != "user"):
            raise RuntimeError("La VM no conserva la red aislada/NAT registrada")
        if any(actual.findall("./devices/" + tag) for tag in ("filesystem", "hostdev", "redirdev")):
            raise RuntimeError("La VM tiene acceso a dispositivos o carpetas del equipo")
        if lab.get("iso"):
            cdrom = actual.find("./devices/disk[@device='cdrom']/source")
            if cdrom is None or cdrom.get("file") != lab["iso"]:
                raise RuntimeError("La ISO de la VM cambió")
            with Path(lab["iso"]).open("rb") as stream:
                if hashlib.file_digest(stream, "sha256").hexdigest() != lab["iso_sha256"]:
                    raise RuntimeError("La ISO de la VM no supera la verificación")

    def create_lab(self, spec):
        with self.locked("resources"), self.locked("labs"):
            registered = self.labs()
            self.validate_lab(spec, registered)
            spec = dict(spec)
            spec["resource"] = "black-ice-" + spec["name"] + "-" + uuid.uuid4().hex[:8]
            spec["id"] = str(uuid.uuid4())
            spec["created"] = time.time()
            from storage import Storage
            spec.setdefault("ttl_minutes", Storage(self).policy()["ttl_minutes"])
            if type(spec["ttl_minutes"]) is not int or not 15 <= spec["ttl_minutes"] <= 1440:
                raise ValueError("Vencimiento inválido: entre 15 y 1440 minutos")
            if spec["engine"] == "kvm":
                video, display = self.kvm_display()
                image = Path(spec["image"]).expanduser()
                if image.is_symlink() or not image.is_file() or not re.fullmatch(r"[a-f0-9]{64}", spec.get("sha256", "")):
                    raise ValueError("Imagen y SHA256 requeridos")
                image = image.resolve(strict=True)
                with image.open("rb") as stream:
                    if hashlib.file_digest(stream, "sha256").hexdigest() != spec["sha256"]:
                        raise ValueError("El hash de la imagen no coincide")
                info = json.loads(command(["qemu-img", "info", "--output=json", str(image)]))
                if info.get("backing-filename") or info.get("format") != "qcow2" or info["virtual-size"] > spec["disk_gib"] * 1024**3:
                    raise ValueError("Usa qcow2 autónomo dentro del presupuesto de disco")
                disks = self.root / "disks"
                disks.mkdir(exist_ok=True, mode=0o700)
                disk = disks / (spec["id"] + ".qcow2")
                command(["cp", "--reflink=auto", "--", str(image), str(disk)], timeout=120)
                command(["qemu-img", "resize", str(disk), f"{spec['disk_gib']}G"])
                spec["disk"] = str(disk)
                domain = ET.Element("domain", type="kvm")
                ET.SubElement(domain, "name").text = spec["resource"]
                ET.SubElement(domain, "uuid").text = spec["id"]
                ET.SubElement(domain, "memory", unit="MiB").text = str(spec["memory_mib"])
                ET.SubElement(domain, "vcpu").text = str(spec["cpus"])
                operating_system = ET.SubElement(domain, "os")
                ET.SubElement(operating_system, "type", arch="x86_64").text = "hvm"
                devices = ET.SubElement(domain, "devices")
                drive = ET.SubElement(devices, "disk", type="file", device="disk")
                ET.SubElement(drive, "driver", name="qemu", type="qcow2")
                ET.SubElement(drive, "source", file=str(disk))
                ET.SubElement(drive, "target", dev="vda", bus="virtio")
                if spec.get("iso"):
                    iso = Path(spec["iso"])
                    if iso.is_symlink() or not iso.is_file() or not re.fullmatch(r"[a-f0-9]{64}", spec.get("iso_sha256", "")):
                        raise ValueError("ISO y SHA256 requeridos")
                    with iso.open("rb") as stream:
                        if hashlib.file_digest(stream, "sha256").hexdigest() != spec["iso_sha256"]:
                            raise ValueError("La ISO no supera la verificación")
                    cdrom = ET.SubElement(devices, "disk", type="file", device="cdrom")
                    ET.SubElement(cdrom, "driver", name="qemu", type="raw")
                    ET.SubElement(cdrom, "source", file=str(iso))
                    ET.SubElement(cdrom, "target", dev="sda", bus="sata")
                    ET.SubElement(cdrom, "readonly")
                    ET.SubElement(operating_system, "boot", dev="cdrom")
                    ET.SubElement(operating_system, "boot", dev="hd")
                if spec.get("network") == "nat":
                    ET.SubElement(ET.SubElement(devices, "interface", type="user"), "model", type="virtio")
                ET.SubElement(devices, "graphics", type=display, autoport="yes", listen="127.0.0.1")
                ET.SubElement(ET.SubElement(devices, "video"), "model", type=video)
                ET.SubElement(ET.SubElement(devices, "console", type="pty"), "target", type="serial", port="0")
                xml = self.root / (spec["id"] + ".xml")
                atomic(xml, ET.tostring(domain, encoding="unicode"))
                defined = False
                try:
                    command(["virsh", "-c", "qemu:///session", "define", str(xml)])
                    defined = True
                    self.verify_kvm_limits(spec)
                except Exception:
                    if defined:
                        command(["virsh", "-c", "qemu:///session", "undefine", spec["resource"]])
                    disk.unlink(missing_ok=True)
                    raise
                finally:
                    xml.unlink(missing_ok=True)
            else:
                image = spec["image"]
                if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._:/-]*@sha256:[a-f0-9]{64}", image):
                    raise ValueError("Usa una imagen fijada por digest: registro/imagen@sha256:…")
                engine = spec["engine"]
                spec["store"] = "managed" if engine == "podman" else "legacy"
                info = json.loads(self.run([engine, "info", "--format", "json" if engine == "podman" else "{{json .}}" ]))
                if engine == "podman" and not info.get("host", {}).get("security", {}).get("rootless"):
                    raise ValueError("Podman debe ejecutarse sin root")
                if engine == "docker" and "name=rootless" not in info.get("SecurityOptions", []):
                    raise ValueError("Se requiere Docker rootless para aplicar el aislamiento de laboratorios")
                if (engine == "podman" and info.get("host", {}).get("cgroupVersion") != "v2") or (engine == "docker" and str(info.get("CgroupVersion")) != "2"):
                    raise ValueError("Los límites rootless requieren cgroups v2")
                spec.setdefault("user", "1000:1000")
                if not re.fullmatch(r"[1-9][0-9]{0,8}:[1-9][0-9]{0,8}", spec["user"]):
                    raise ValueError("Usa UID:GID numéricos sin root")
                if spec.get("network") == "local":
                    from web_labs import WebLabs
                    extra = WebLabs(self).arguments(spec)
                    spec["cleanup_pending"] = True
                    registered["labs"][spec["name"]] = spec
                    self.write("labs", registered)
                else:
                    extra = ["--workdir", "/tmp", "--env", "HOME=/tmp", "--network", "none" if spec.get("network", "none") == "none" else "pasta" if engine == "podman" else "bridge"]
                self.run([engine, "create", "--interactive", "--tty", "--name", spec["resource"], "--label", "black-ice.id=" + spec["id"],
                         "--cpus", str(spec["cpus"]), "--memory", f"{spec['memory_mib']}m", "--memory-swap", f"{spec['memory_mib']}m",
                         "--pids-limit", "256", "--read-only", "--cap-drop=ALL", "--security-opt=no-new-privileges",
                         "--tmpfs", f"/tmp:size={min(spec['disk_gib'] * 1024, 512)}m,mode=1777", "--user", spec["user"],
                         *extra, image, *spec.get("command", [])], timeout=300)
                try:
                    self.verify_container_limits(spec)
                except Exception:
                    self.run([engine, "rm", spec["resource"]])
                    raise
            spec["limits_verified"] = True
            spec.pop("cleanup_pending", None)
            registered["labs"][spec["name"]] = spec
            self.write("labs", registered)
            return spec

    def lab_action(self, name, operation, confirm=""):
        with self.locked("labs"):
            registered = self.labs()
            if name not in registered["labs"]:
                raise ValueError("Este recurso no pertenece a BLACK-ICE")
            lab = registered["labs"][name]
            if operation not in {"start", "stop", "force-stop", "delete"}:
                raise ValueError("Acción inválida")
            if operation in {"force-stop", "delete"} and confirm != name:
                raise ValueError("Confirma el nombre para forzar el apagado o eliminar este laboratorio")
            if lab["engine"] == "kvm":
                base = ["virsh", "-c", "qemu:///session"]
                if command([*base, "domuuid", lab["resource"]]) != lab["id"]:
                    raise ValueError("La identidad de la VM no corresponde al registro")
                if operation == "start":
                    self.verify_kvm_limits(lab)
                if operation == "delete" and command([*base, "domstate", lab["resource"]]).strip() != "shut off":
                    raise ValueError("Apaga la VM antes de eliminar su definición y disco")
                command([*base, {"start": "start", "stop": "shutdown", "force-stop": "destroy", "delete": "undefine"}[operation], lab["resource"]])
                if operation == "delete":
                    disk = Path(lab["disk"])
                    if disk.parent != self.root / "disks" or disk.name != lab["id"] + ".qcow2":
                        raise ValueError("Ruta de disco fuera del registro")
                    disk.unlink()
            else:
                engine = lab["engine"]
                missing_web = operation == "delete" and lab.get("web") and lab["resource"] not in self.run(
                    [engine, "ps", "--all", "--format", "{{.Names}}"], store=lab.get("store", "legacy")).splitlines()
                if not missing_web:
                    label = self.run([engine, "inspect", "--format", '{{index .Config.Labels "black-ice.id"}}', lab["resource"]], store=lab.get("store", "legacy"))
                    if label != lab["id"]:
                        raise ValueError("La identidad del contenedor no corresponde al registro")
                    if operation == "start":
                        self.verify_container_limits(lab)
                    self.run([engine, {"start": "start", "stop": "stop", "force-stop": "kill", "delete": "rm"}[operation], lab["resource"]], store=lab.get("store", "legacy"))
                if operation == "delete" and lab.get("web"):
                    from web_labs import WebLabs
                    WebLabs(self).cleanup(lab)
            if operation == "start":
                lab["expires"] = time.time() + lab.get("ttl_minutes", 120) * 60
                lab.pop("expiry_requested", None)
                self.write("labs", registered)
            if operation == "delete":
                del registered["labs"][name]
                self.write("labs", registered)
            return {"lab": name, "operation": operation}

    def expire_labs(self) -> dict:
        expired, errors = [], []
        for name, lab in self.labs()["labs"].items():
            if not lab.get("expires") or lab["expires"] > time.time():
                continue
            try:
                from laboratories import Laboratories
                if Laboratories(self, self.run).status(name)["running"]:
                    operation = "force-stop" if lab.get("expiry_requested", 0) and time.time() - lab["expiry_requested"] > 60 else "stop"
                    self.lab_action(name, operation, name if operation == "force-stop" else "")
                    if operation == "stop":
                        with self.locked("labs"):
                            state = self.labs()
                            if name in state["labs"]:
                                state["labs"][name].setdefault("expiry_requested", time.time())
                                self.write("labs", state)
                    expired.append(name)
            except (OSError, ValueError, RuntimeError, subprocess.TimeoutExpired) as error:
                errors.append({"name": name, "error": str(error)})
        result = {"checked": time.time(), "expired": expired, "errors": errors}
        self.write("maintenance", result)
        return result
