"""Almacenamiento administrado, límites de preparación y limpieza revisable."""
import os
import signal
import subprocess
import time
from collections import deque
from pathlib import Path


def allocated(directory: Path) -> int:
    total = 0
    if not directory.is_dir() or directory.is_symlink():
        return total
    for base, directories, files in os.walk(directory, followlinks=False):
        directories[:] = [name for name in directories if not (Path(base) / name).is_symlink()]
        for name in files:
            try:
                item = (Path(base) / name).lstat()
                total += item.st_blocks * 512
            except FileNotFoundError:
                continue
    return total


class Storage:
    def __init__(self, manager):
        self.manager = manager

    def policy(self) -> dict:
        return {"cache_mib": 8192, "ttl_minutes": 120, **self.manager.read("resource-policy", {})}

    def configure(self, cache_mib: int, ttl_minutes: int) -> dict:
        if type(cache_mib) is not int or not 256 <= cache_mib <= 131072:
            raise ValueError("La caché admite entre 256 y 131072 MiB")
        if type(ttl_minutes) is not int or not 15 <= ttl_minutes <= 1440:
            raise ValueError("El vencimiento admite entre 15 y 1440 minutos")
        if self.status()["cache_bytes"] > cache_mib * 1024**2:
            raise ValueError("Limpia la caché antes de reducir su límite por debajo del uso actual")
        result = {"cache_mib": cache_mib, "ttl_minutes": ttl_minutes}
        self.manager.write("resource-policy", result)
        return result

    def status(self) -> dict:
        cache = sum(allocated(self.manager.root / name) for name in ("containers", "assets", "privacy-build"))
        policy = self.policy()
        return {"cache_bytes": cache, "cache_limit_bytes": policy["cache_mib"] * 1024**2,
                "disk_bytes": allocated(self.manager.root / "disks"), "ttl_minutes": policy["ttl_minutes"],
                "within_budget": cache <= policy["cache_mib"] * 1024**2}

    def check(self) -> None:
        result = self.status()
        if not result["within_budget"]:
            raise RuntimeError("La caché administrada alcanzó su límite. Revisa Recursos → Limpiar caché.")
        info = os.statvfs(self.manager.root)
        if info.f_bavail * info.f_frsize < 256 * 1024**2:
            raise RuntimeError("Quedan menos de 256 MiB libres; libera espacio antes de preparar imágenes")

    def guarded(self, args: list[str], timeout: int) -> str:
        self.check()
        output = deque(maxlen=128)
        process = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                   env=dict(os.environ, LC_ALL="C"), start_new_session=True)

        os.set_blocking(process.stdout.fileno(), False)

        def consume():
            for _ in range(128):
                try:
                    block = os.read(process.stdout.fileno(), 4096)
                except BlockingIOError:
                    break
                if not block:
                    break
                output.append(block)
        started = time.monotonic()
        error = None
        try:
            while process.poll() is None:
                consume()
                self.check()
                if time.monotonic() - started > timeout:
                    raise TimeoutError("La preparación superó el tiempo permitido; puedes volver a intentarlo")
                time.sleep(.25)
            consume()
            self.check()
        except (OSError, RuntimeError, TimeoutError) as caught:
            error = caught
            if process.poll() is None:
                os.killpg(process.pid, signal.SIGTERM)
                try:
                    process.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    os.killpg(process.pid, signal.SIGKILL)
                    process.wait(timeout=10)
        finally:
            process.stdout.close()
        if error:
            raise error
        text = b"".join(output).decode(errors="replace")
        if process.returncode:
            raise RuntimeError(text[-2500:] or "No se completó la preparación de la imagen")
        return text.strip()

    def track_image(self, image: str, inspected=None) -> None:
        import json
        if inspected is None:
            inspected = json.loads(self.manager.run(["podman", "image", "inspect", image]))[0]
        identity = inspected.get("Id")
        if not identity:
            return
        with self.manager.locked("images"):
            images = self.manager.read("managed-images", {})
            images[identity] = {"image": image, "created": time.time()}
            self.manager.write("managed-images", images)

    def cleanup_plan(self) -> list[dict]:
        import json
        plan = []
        if (self.manager.root / "containers").exists():
            containers = json.loads(self.manager.run(["podman", "ps", "--all", "--format", "json"]))
            used = {item.get("ImageID", "").removeprefix("sha256:") for item in containers}
            for identity, item in self.manager.read("managed-images", {}).items():
                if identity.removeprefix("sha256:") not in used:
                    plan.append({"kind": "image", "id": identity, "label": item["image"]})
        used_iso = {lab.get("iso") for lab in self.manager.labs()["labs"].values()}
        for iso in (self.manager.root / "assets").glob("*.iso"):
            if str(iso) not in used_iso and not iso.is_symlink():
                plan.append({"kind": "iso", "id": iso.name, "label": iso.name, "bytes": iso.stat().st_size})
        return plan

    def cleanup(self, selected: list[dict]) -> dict:
        allowed = {(item["kind"], item["id"]): item for item in self.cleanup_plan()}
        removed, errors = [], []
        for item in selected:
            key = (item.get("kind"), item.get("id"))
            if key not in allowed:
                raise ValueError("La selección cambió o contiene recursos ajenos; vuelve a consultar la caché")
            try:
                if key[0] == "image":
                    self.manager.run(["podman", "image", "rm", key[1]])
                    with self.manager.locked("images"):
                        images = self.manager.read("managed-images", {})
                        images.pop(key[1], None)
                        self.manager.write("managed-images", images)
                else:
                    iso = self.manager.root / "assets" / key[1]
                    if iso.parent != self.manager.root / "assets" or iso.is_symlink():
                        raise ValueError("Ruta fuera de la caché administrada")
                    iso.unlink()
                removed.append(key[1])
            except (OSError, ValueError, RuntimeError, subprocess.TimeoutExpired) as error:
                errors.append({"id": key[1], "error": str(error)})
        return {"removed": removed, "errors": errors, "storage": self.status()}
