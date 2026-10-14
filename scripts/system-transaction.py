#!/usr/bin/python3 -I
"""Operaciones privilegiadas limitadas: paquetes, puntos de recuperación y diagnóstico."""
import argparse
import fcntl
import hashlib
import json
import os
import platform
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

STATE = Path("/var/lib/black-ice/transactions")
RECOVERY = Path("/.snapshots/black-ice-recovery")
CATALOG = Path("/usr/share/black-ice/apps.json")


def run(*args, timeout=1800):
    result = subprocess.run(args, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=timeout, check=False)
    if result.returncode:
        raise RuntimeError(f"{args[0]}: {result.stdout[-2500:]}")
    return result.stdout.strip()


def atomic(path, value):
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    fd, name = tempfile.mkstemp(dir=path.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            json.dump(value, stream, ensure_ascii=False, indent=2)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(name, path)
    finally:
        Path(name).unlink(missing_ok=True)


def mount_field(path, field):
    return run("findmnt", "-nro", field, "-T", path, timeout=10)


def preflight():
    if Path("/var/lib/pacman/db.lck").exists():
        raise RuntimeError("Pacman está ocupado; no se elimina su bloqueo")
    if shutil.disk_usage("/").free < 3 * 1024**3:
        raise RuntimeError("Se requieren al menos 3 GiB libres en la raíz")
    if Path("/boot/efi").is_dir() and not os.path.ismount("/boot/efi"):
        raise RuntimeError("La ESP /boot/efi no está montada")
    for supply in Path("/sys/class/power_supply").glob("*"):
        capacity = supply / "capacity"
        status = supply / "status"
        if capacity.exists() and status.exists() and status.read_text().strip() == "Discharging" and int(capacity.read_text()) < 30:
            raise RuntimeError("Conecta la alimentación: batería inferior al 30%")


def checkpoint():
    preflight()
    if mount_field("/", "FSTYPE") != "btrfs":
        raise RuntimeError("Recuperación completa disponible solo en Btrfs; no se cambió el sistema")
    root_uuid = mount_field("/", "UUID")
    root_id = run("btrfs", "inspect-internal", "rootid", "/", timeout=10)
    for path in ("/usr", "/etc", "/var/lib/pacman"):
        if mount_field(path, "UUID") != root_uuid or mount_field(path, "FSROOT") != mount_field("/", "FSROOT"):
            raise RuntimeError(f"{path} está fuera del snapshot raíz")
        if run("btrfs", "inspect-internal", "rootid", path, timeout=10) != root_id:
            raise RuntimeError(f"{path} pertenece a un subvolumen anidado fuera del snapshot raíz")
    if mount_field("/", "FSROOT") != "/@" or mount_field("/.snapshots", "FSROOT") != "/@snapshots":
        raise RuntimeError("La recuperación requiere subvolúmenes @ y @snapshots")
    number = run("snapper", "--no-dbus", "-c", "root", "create", "--read-only", "--print-number", "--description", "BLACK-ICE pre-transacción", timeout=30)
    if not number.isdigit():
        raise RuntimeError("Snapper no devolvió un identificador válido")
    destination = RECOVERY / number
    destination.mkdir(parents=True, mode=0o700)
    archive = destination / "boot.tar"
    run("tar", "-C", "/boot", "-cpf", str(archive), ".", timeout=120)
    with archive.open("rb") as stream:
        archive_hash = hashlib.file_digest(stream, "sha256").hexdigest()
    manifest = {"schema": 1, "snapshot": number, "root_uuid": root_uuid,
        "esp_uuid": mount_field("/boot/efi", "UUID") if os.path.ismount("/boot/efi") else "",
        "boot_uuid": mount_field("/boot", "UUID") if os.path.ismount("/boot") else "",
        "boot_sha256": archive_hash,
        "packages_sha256": hashlib.sha256(run("pacman", "-Q").encode()).hexdigest(),
        "created": time.time(), "verified": False,
        "source_boot_id": Path("/proc/sys/kernel/random/boot_id").read_text().strip(),
        "kernel_releases": sorted(path.parent.name for path in Path("/usr/lib/modules").glob("*/pkgbase")),
        "boot_files": {str(path.relative_to("/boot")): hashlib.sha256(path.read_bytes()).hexdigest()
                       for path in Path("/boot").rglob("*") if path.is_file() and
                       (path.name.startswith(("vmlinuz", "initramfs")) or path.suffix.lower() == ".efi")}}
    atomic(destination / "manifest.json", manifest)
    return manifest


def recovery_status():
    return [json.loads(p.read_text()) for p in sorted(RECOVERY.glob("*/manifest.json"))]


def portable_fstab(path):
    rows = []
    for line in path.read_text().splitlines():
        fields = line.split()
        if not line.lstrip().startswith("#") and len(fields) >= 4 and fields[2] == "btrfs":
            options = fields[3].split(",")
            if any(option.startswith("subvol=") for option in options):
                fields[3] = ",".join(option for option in options if not option.startswith("subvolid="))
                line = "\t".join(fields)
        rows.append(line)
    path.write_text("\n".join(rows) + "\n")


def verify_recovery(number):
    manifest_path = RECOVERY / number / "manifest.json"
    manifest = json.loads(manifest_path.read_text())
    current_boot = Path("/proc/sys/kernel/random/boot_id").read_text().strip()
    if not manifest.get("restored_at") or current_boot == manifest.get("source_boot_id"):
        raise RuntimeError("Este punto todavía no fue restaurado y arrancado")
    if mount_field("/", "UUID") != manifest["root_uuid"]:
        raise RuntimeError("UUID de raíz distinto")
    if hashlib.sha256(run("pacman", "-Q").encode()).hexdigest() != manifest["packages_sha256"]:
        raise RuntimeError("La lista/versiones de paquetes no corresponde al punto restaurado")
    if platform.release() not in manifest.get("kernel_releases", []):
        raise RuntimeError("El kernel arrancado no corresponde al punto restaurado")
    for relative, expected in manifest.get("boot_files", {}).items():
        path = Path("/boot") / relative
        if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != expected:
            raise RuntimeError(f"No corresponde el archivo de arranque: {relative}")
    run("pacman", "-Qk", "filesystem", "bash", "glibc", timeout=60)
    run("grub-script-check", "/boot/grub/grub.cfg", timeout=10)
    manifest["verified"] = True
    manifest["verified_at"] = time.time()
    manifest["boot_id"] = current_boot
    atomic(manifest_path, manifest)
    return manifest


def restore_offline(number, device_uuid):
    if not Path("/run/archiso/bootmnt").exists():
        raise RuntimeError("Restaura desde la ISO de Arch, nunca desde la raíz en ejecución")
    device = run("blkid", "-U", device_uuid, timeout=10)
    if run("lsblk", "-nr", "-o", "MOUNTPOINTS", device, timeout=10).strip():
        raise RuntimeError("Desmonta todos los subvolúmenes del destino antes de restaurar")
    top = Path("/run/black-ice-recovery")
    top.mkdir(exist_ok=True, mode=0o700)
    run("mount", "-o", "subvolid=5", device, str(top))
    mounted = []
    try:
        metadata = top / "@snapshots/black-ice-recovery" / number
        manifest = json.loads((metadata / "manifest.json").read_text())
        if manifest["root_uuid"] != device_uuid:
            raise RuntimeError("El punto pertenece a otro disco")
        archive = metadata / "boot.tar"
        with archive.open("rb") as stream:
            if hashlib.file_digest(stream, "sha256").hexdigest() != manifest["boot_sha256"]:
                raise RuntimeError("Respaldo de arranque dañado")
        snapshot = top / "@snapshots" / number / "snapshot"
        run("btrfs", "subvolume", "show", str(snapshot))
        saved = top / f"@before-recovery-{time.time_ns()}"
        (top / "@").rename(saved)
        try:
            run("btrfs", "subvolume", "snapshot", str(snapshot), str(top / "@"))
        except Exception:
            saved.rename(top / "@")
            raise
        portable_fstab(top / "@/etc/fstab")
        for key, relative in (("boot_uuid", "boot"), ("esp_uuid", "boot/efi")):
            if manifest[key]:
                target = top / "@" / relative
                target.mkdir(parents=True, exist_ok=True)
                run("mount", run("blkid", "-U", manifest[key], timeout=10), str(target))
                mounted.append(target)
        run("tar", "-C", str(top / "@/boot"), "-xpf", str(archive), timeout=120)
        manifest.update(restored_at=time.time(), previous_root=saved.name, verified=False)
        atomic(metadata / "manifest.json", manifest)
        return {"restored": number, "previous_root": saved.name, "next": "Reinicia y ejecuta verify-recovery"}
    finally:
        for target in reversed(mounted):
            run("umount", str(target))
        run("umount", str(top))


def package_operation(operation, packages):
    catalog = {app["id"] for app in json.loads(CATALOG.read_text())["apps"]}
    if not packages or not set(packages) <= catalog:
        raise ValueError("Paquetes fuera del catálogo instalado")
    if any(not re.fullmatch(r"[a-zA-Z0-9@_+.-]+", p) or p.startswith("-") for p in packages):
        raise ValueError("Identificador de paquete inválido")
    preflight()
    if operation == "remove-preview":
        return run("pacman", "-R", "--print", "--print-format", "%n", "--", *packages)
    if operation == "install":
        for package in packages:
            run("pacman", "-Si", "--", package, timeout=20)
    point = checkpoint() if mount_field("/", "FSTYPE") == "btrfs" else None
    transaction = STATE / f"{time.time_ns()}.json"
    record = {"schema": 1, "operation": operation, "packages": packages, "state": "running", "recovery": point, "started": time.time()}
    atomic(transaction, record)
    try:
        flags = ["-Syu", "--needed"] if operation == "install" else ["-R"]
        result = run("pacman", *flags, "--noconfirm", "--", *packages)
        if operation == "install":
            run("pacman", "-Q", "--", *packages)
        record.update(state="done", output=result[-2000:])
    except Exception as error:
        record.update(state="failed", error=str(error)[-2500:])
        raise
    finally:
        record["finished"] = time.time()
        atomic(transaction, record)
    return record


def update_system():
    point = checkpoint()
    transaction = STATE / f"{time.time_ns()}.json"
    record = {"schema": 1, "operation": "update", "state": "running", "recovery": point, "started": time.time()}
    atomic(transaction, record)
    try:
        run("pacman", "-Syu", "--noconfirm")
        run("pacman", "-Qk", "filesystem", "bash", "glibc", timeout=60)
        run("grub-script-check", "/boot/grub/grub.cfg", timeout=10)
        record.update(state="done", rollback_verified=False)
    except Exception as error:
        record.update(state="failed", error=str(error)[-2500:])
        raise
    finally:
        record["finished"] = time.time()
        atomic(transaction, record)
    return record


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("operation", choices=["checkpoint", "update", "status", "install", "remove-preview", "remove", "restore-offline", "verify-recovery",
                                              "tor-preview", "tor-enable", "tor-disable", "tor-verify", "tor-logs", "sddm-theme"])
    parser.add_argument("packages", nargs="*")
    parser.add_argument("--snapshot", default="")
    parser.add_argument("--uuid", default="")
    parser.add_argument("--confirm", default="")
    args = parser.parse_args()
    if os.geteuid() != 0:
        parser.error("Requiere el helper instalado con privilegios")
    os.environ.update(PATH="/usr/sbin:/usr/bin:/sbin:/bin", LC_ALL="C")
    os.umask(0o077)
    STATE.mkdir(parents=True, exist_ok=True, mode=0o700)
    try:
        with (STATE / "lock").open("a") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            if args.operation in {"restore-offline", "verify-recovery"} and not args.snapshot.isdigit():
                raise ValueError("Snapshot numérico requerido")
            if args.operation.startswith("tor-"):
                result = run("/usr/lib/black-ice/system-tor", args.operation.removeprefix("tor-"), timeout=240)
                print(result)
                return 0
            if args.operation == "sddm-theme":
                if len(args.packages) != 1:
                    raise ValueError("Indica una vista previa SDDM")
                result = run("/usr/lib/black-ice/system-sddm-theme", args.packages[0], timeout=60)
            elif args.operation == "checkpoint":
                result = checkpoint()
            elif args.operation == "status":
                result = recovery_status()
            elif args.operation == "restore-offline":
                if args.confirm != args.snapshot:
                    raise ValueError("Confirma el identificador con --confirm")
                result = restore_offline(args.snapshot, args.uuid)
            elif args.operation == "verify-recovery":
                result = verify_recovery(args.snapshot)
            elif args.operation == "update":
                result = update_system()
            else:
                result = package_operation(args.operation, args.packages)
            print(json.dumps(result, ensure_ascii=False))
    except (OSError, ValueError, RuntimeError, subprocess.TimeoutExpired) as error:
        print(str(error), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
