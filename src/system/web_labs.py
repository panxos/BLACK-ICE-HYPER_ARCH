"""Aplicaciones vulnerables publicadas únicamente en localhost."""
import json
import time
import urllib.error
import urllib.request
from urllib.parse import urlsplit

WEB = {
    "juiceshop": {"title": "OWASP Juice Shop", "image": "docker.io/bkimminich/juice-shop:v19.2.1",
                  "description": "Práctica web en tu navegador. Solo localhost, sin salida a Internet. Datos propios del laboratorio.",
                  "engine": "podman", "cpus": 1, "memory_mib": 768, "disk_gib": 2,
                  "user": "65532:65532", "directory": "/juice-shop", "ports": [3000], "path": "/"},
    "webgoat": {"title": "OWASP WebGoat + WebWolf", "image": "docker.io/webgoat/webgoat:v2026.5",
                "description": "Lecciones web guiadas. WebGoat y WebWolf solo en localhost, sin salida a Internet.",
                "engine": "podman", "cpus": 1, "memory_mib": 1536, "disk_gib": 3,
                "user": "1001:1001", "directory": "/home/webgoat", "ports": [8080, 9090], "path": "/WebGoat/"},
}


class LocalRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, request, response, code, message, headers, newurl):
        old, new = urlsplit(request.full_url), urlsplit(newurl)
        if new.scheme != "http" or new.netloc != old.netloc:
            raise ValueError("La aplicación intentó redirigir la comprobación fuera de localhost")
        return super().redirect_request(request, response, code, message, headers, newurl)


class WebLabs:
    def __init__(self, manager):
        self.manager = manager

    def arguments(self, spec):
        choice = WEB[spec["template"]]
        spec["web"] = {"network": "ice-net-" + spec["id"], "volume": "ice-data-" + spec["id"],
                       "directory": choice["directory"], "ports": choice["ports"], "path": choice["path"]}
        web = spec["web"]
        try:
            self.manager.run(["podman", "network", "create", "--internal", "--disable-dns", "--opt", "no_default_route=true",
                              "--label", "black-ice.id=" + spec["id"], web["network"]])
            self.manager.run(["podman", "volume", "create", "--label", "black-ice.id=" + spec["id"], web["volume"]])
        except Exception:
            spec["cleanup_pending"] = True
            registered = self.manager.labs()
            registered["labs"][spec["name"]] = spec
            self.manager.write("labs", registered)
            raise
        args = ["--network", web["network"], "--volume", web["volume"] + ":" + web["directory"],
                "--workdir", web["directory"], "--env", "HOME=" + web["directory"]]
        for port in web["ports"]:
            args += ["--publish", f"127.0.0.1::{port}"]
        return args

    def verify(self, spec, inspected):
        web = spec["web"]
        host = inspected["HostConfig"]
        networks = inspected.get("NetworkSettings", {}).get("Networks", {})
        if set(networks) != {web["network"]}:
            raise ValueError("El laboratorio web tiene redes no autorizadas")
        network = json.loads(self.manager.run(["podman", "network", "inspect", web["network"]]))[0]
        if not network.get("internal") or network.get("dns_enabled") or network.get("labels", {}).get("black-ice.id") != spec["id"]:
            raise ValueError("La red web perdió el aislamiento interno")
        if network.get("options", {}).get("no_default_route") != "true":
            raise ValueError("La red web permite una ruta predeterminada")
        actual = {mount["Destination"]: mount.get("Name") for mount in inspected.get("Mounts", []) if mount.get("Type") != "tmpfs"}
        if actual != {web["directory"]: web["volume"]} or host.get("Binds") and any(
                not value.startswith(web["volume"] + ":") for value in host["Binds"]):
            raise ValueError("El laboratorio web tiene montajes ajenos")
        volume = json.loads(self.manager.run(["podman", "volume", "inspect", web["volume"]]))[0]
        if volume.get("Labels", {}).get("black-ice.id") != spec["id"]:
            raise ValueError("El volumen web no corresponde al laboratorio")
        bindings = host.get("PortBindings", {})
        if set(bindings) != {str(port) + "/tcp" for port in web["ports"]}:
            raise ValueError("El laboratorio web publica puertos inesperados")
        for values in bindings.values():
            if len(values) != 1 or values[0].get("HostIp") != "127.0.0.1":
                raise ValueError("El laboratorio web está expuesto fuera de localhost")

    def url(self, spec, port=None):
        self.manager.verify_container_limits(spec)
        selected = port or spec["web"]["ports"][0]
        data = json.loads(self.manager.run(["podman", "inspect", spec["resource"]]))[0]
        if not data["State"]["Running"]:
            raise ValueError("El laboratorio web está apagado")
        values = data["NetworkSettings"]["Ports"][str(selected) + "/tcp"]
        if len(values) != 1 or values[0]["HostIp"] != "127.0.0.1":
            raise ValueError("El puerto web dejó de estar limitado a localhost")
        number = int(values[0]["HostPort"])
        if not 1024 <= number <= 65535:
            raise ValueError("Puerto local inválido")
        path = "/WebWolf/" if selected == 9090 else spec["web"]["path"]
        return f"http://127.0.0.1:{number}{path}"

    def ready(self, spec, timeout=180):
        url = self.url(spec)
        opener = urllib.request.build_opener(urllib.request.ProxyHandler({}), LocalRedirect())
        started = time.monotonic()
        while time.monotonic() - started < timeout:
            try:
                with opener.open(url, timeout=3) as response:
                    if response.status == 200 and response.url.startswith(url.rsplit(spec["web"]["path"], 1)[0] + "/"):
                        return url
            except (OSError, urllib.error.URLError):
                pass
            data = json.loads(self.manager.run(["podman", "inspect", spec["resource"]]))[0]
            if not data["State"]["Running"]:
                break
            time.sleep(2)
        logs = self.manager.run(["podman", "logs", "--tail", "20", spec["resource"]])
        raise RuntimeError("La aplicación web no respondió. Registro:\n" + logs[-1800:])

    def cleanup(self, spec):
        for kind, key in (("volume", "volume"), ("network", "network")):
            name = spec["web"][key]
            inventory = json.loads(self.manager.run(["podman", kind, "ls", "--format", "json"]))
            if name not in {item.get("Name", item.get("name")) for item in inventory}:
                continue
            data = json.loads(self.manager.run(["podman", kind, "inspect", name]))[0]
            labels = data.get("Labels", data.get("labels", {}))
            if labels.get("black-ice.id") != spec["id"]:
                raise ValueError("Recurso web ajeno; no se eliminará")
            self.manager.run(["podman", kind, "rm", name])
