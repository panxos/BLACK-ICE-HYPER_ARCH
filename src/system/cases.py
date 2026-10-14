"""Alcance explícito, copia de evidencias y registro encadenado de integridad."""
import hashlib
import ipaddress
import json
import os
import stat
import time
import uuid
from pathlib import Path

from manager import atomic, identifier, target


def checksum(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, ensure_ascii=False, separators=(",", ":")).encode()).hexdigest()


class Cases:
    def __init__(self, manager):
        self.manager = manager

    def read(self, name):
        identifier(name)
        path = self.manager.root / "cases" / name
        if path.is_symlink() or not (path / "case.json").is_file():
            raise ValueError("Caso inexistente o ruta inválida")
        return json.loads((path / "case.json").read_text())

    def save(self, data, event):
        previous = data["events"][-1]["hash"] if data["events"] else "0" * 64
        entry = {"time": time.time(), "event": event, "previous": previous,
                 "manifest": checksum({key: value for key, value in data.items() if key != "events"})}
        data["events"].append({**entry, "hash": checksum(entry)})
        atomic(self.manager.root / "cases" / data["name"] / "case.json", data)
        return data

    def create(self, name, scope, vpn=""):
        identifier(name)
        if not scope or len(scope) > 256:
            raise ValueError("Indica al menos un host, IP o CIDR autorizado (máximo 256)")
        normalized = []
        for value in scope:
            normalized.append(str(ipaddress.ip_network(value, strict=True)) if "/" in value else target(value).lower())
        if any(not value for value in normalized):
            raise ValueError("El alcance no admite entradas vacías")
        if vpn:
            vpn = str(uuid.UUID(vpn))
        with self.manager.locked("cases"):
            directory = self.manager.root / "cases" / name
            directory.parent.mkdir(mode=0o700, exist_ok=True)
            directory.mkdir(mode=0o700)
            (directory / "evidence").mkdir(mode=0o700)
            return self.save({"name": name, "created": time.time(), "scope": sorted(set(normalized)), "vpn": vpn,
                              "notes": [], "evidence": [], "events": []}, "case-created")

    def preflight(self, name, candidate):
        data = self.read(name)
        candidate = target(candidate).lower()
        permitted = candidate in data["scope"]
        try:
            address = ipaddress.ip_address(candidate)
            permitted |= any(address in ipaddress.ip_network(value) for value in data["scope"] if "/" in value)
        except ValueError:
            pass
        try:
            vpn = self.manager.vpn_identity(data["vpn"]) if data["vpn"] else None
        except (OSError, RuntimeError):
            vpn = None
        return {"allowed": bool(permitted and (not data["vpn"] or vpn)), "in_scope": permitted,
                "vpn_required": bool(data["vpn"]), "vpn_active": bool(vpn), "target": candidate,
                "scope": "Esta comprobación no controla comandos externos a BLACK-ICE."}

    def note(self, name, text):
        if not text.strip() or len(text) > 16000:
            raise ValueError("La nota admite entre 1 y 16000 caracteres")
        with self.manager.locked("cases"):
            data = self.read(name)
            data["notes"].append({"time": time.time(), "text": text})
            return self.save(data, "note-added")

    def evidence(self, name, source):
        source = Path(source).expanduser()
        with self.manager.locked("cases"):
            data = self.read(name)
            if source.is_symlink():
                raise ValueError("La evidencia debe ser un archivo regular, sin enlace simbólico")
            descriptor = os.open(source, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
            destination = self.manager.root / "cases" / name / "evidence" / uuid.uuid4().hex
            try:
                before = os.fstat(descriptor)
                if not stat.S_ISREG(before.st_mode) or before.st_size > 8 * 1024**3:
                    raise ValueError("Usa un archivo regular de hasta 8 GiB")
                existing = sum(item["bytes"] for item in data["evidence"])
                if existing + before.st_size > 16 * 1024**3:
                    raise ValueError("El caso supera su límite de evidencias de 16 GiB")
                space = os.statvfs(destination.parent)
                if before.st_size + 256 * 1024**2 > space.f_bavail * space.f_frsize:
                    raise ValueError("Espacio insuficiente para conservar una copia de la evidencia")
                digest = hashlib.sha256()
                copied = 0
                with os.fdopen(descriptor, "rb", closefd=False) as original, destination.open("xb") as output:
                    while block := original.read(1024**2):
                        copied += len(block)
                        if copied > before.st_size:
                            raise ValueError("La evidencia cambió durante la copia")
                        output.write(block)
                        digest.update(block)
                    output.flush()
                    os.fsync(output.fileno())
                after = os.fstat(descriptor)
                if (before.st_size, before.st_mtime_ns, before.st_ctime_ns) != (after.st_size, after.st_mtime_ns, after.st_ctime_ns) or copied != before.st_size:
                    raise ValueError("La evidencia cambió durante la copia")
                destination.chmod(0o400)
                data["evidence"].append({"id": destination.name, "label": source.name, "bytes": copied,
                                         "sha256": digest.hexdigest(), "imported": time.time()})
                return self.save(data, "evidence-copied")
            except Exception:
                destination.unlink(missing_ok=True)
                raise
            finally:
                os.close(descriptor)

    def verify(self, name):
        data = self.read(name)
        errors = []
        previous = "0" * 64
        for index, event in enumerate(data["events"]):
            unsigned = {key: value for key, value in event.items() if key != "hash"}
            if event["previous"] != previous or checksum(unsigned) != event["hash"]:
                errors.append(f"Registro alterado: {index}")
            previous = event["hash"]
        manifest = checksum({key: value for key, value in data.items() if key != "events"})
        if not data["events"] or data["events"][-1]["manifest"] != manifest:
            errors.append("El manifiesto del caso cambió fuera del registro")
        for item in data["evidence"]:
            path = self.manager.root / "cases" / name / "evidence" / item["id"]
            if not item["id"].isalnum() or path.is_symlink() or not path.is_file():
                errors.append("Evidencia ausente o ruta inválida")
                continue
            with path.open("rb") as stream:
                digest = hashlib.file_digest(stream, "sha256").hexdigest()
            if digest != item["sha256"] or path.stat().st_size != item["bytes"]:
                errors.append("Evidencia alterada: " + item["id"])
        return {"valid": not errors, "errors": errors, "evidence_count": len(data["evidence"]), "events": len(data["events"])}

    def export(self, name, destination):
        result = self.verify(name)
        if not result["valid"]:
            raise ValueError("Corrige los errores de integridad antes de exportar")
        data = self.read(name)
        report = {"schema": 1, "kind": "sanitized-case-summary", "integrity": result,
                  "evidence": [{key: item[key] for key in ("id", "bytes", "sha256", "imported")} for item in data["evidence"]],
                  "excluded": ["case name", "scope", "VPN UUID", "notes", "original filenames", "evidence contents"]}
        destination = Path(destination).expanduser()
        if destination.exists() or destination.is_symlink():
            raise ValueError("Elige un archivo de salida nuevo")
        destination.parent.mkdir(parents=True, exist_ok=True)
        with destination.open("x") as output:
            os.chmod(destination, 0o600)
            json.dump(report, output, ensure_ascii=False, indent=2)
        return report
