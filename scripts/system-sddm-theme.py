#!/usr/bin/python3 -I
"""Instala el perfil visual de SDDM desde una vista previa validada."""
import configparser
import json
import os
import pwd
import re
import shutil
import sys
import tempfile
from pathlib import Path

ROOT = Path("/usr/share/sddm/themes")
SOURCE = ROOT / "black-ice-obsidian"
TARGET = ROOT / "black-ice-personal"
CONFIGS = (Path("/etc/sddm.conf.d/theme.conf"), Path("/etc/sddm.conf.d/zz-black-ice-personal.conf"), Path("/etc/sddm.conf"))
BACKUP = Path("/var/lib/black-ice/sddm-original.json")
COLOR_KEYS = {"accent", "secondary", "foreground", "muted", "surface"}
FONT_KEYS = {"font", "bodyFont"}
OTHER_KEYS = {"background", "backgroundMode", "backgroundPanorama", "backgroundAnchor", "showAvatar"}
IMAGE = re.compile(r"(?:background|panorama)\.(?:png|jpe?g|webp|avif)", re.IGNORECASE)


def preview_for_uid(path: Path, uid: int) -> tuple[Path, Path]:
    home = Path(pwd.getpwuid(uid).pw_dir).resolve(strict=True)
    root = home / ".cache/black-ice/theme-studio"
    expected = root / "sddm-apply"
    if path.is_symlink():
        raise ValueError("La vista previa SDDM no puede ser un enlace")
    for item in (home / ".cache", home / ".cache/black-ice", root, expected):
        if item.is_symlink():
            raise ValueError("La vista previa SDDM contiene una ruta enlazada")
    resolved = path.resolve(strict=True)
    if resolved != expected or not resolved.is_dir():
        raise ValueError("Ruta de vista previa SDDM inválida")
    for item in resolved.rglob("*"):
        if item.is_symlink() or not (item.is_file() or item.is_dir()):
            raise ValueError("La vista previa SDDM contiene archivos no regulares")
    return home, resolved


def validate_config(preview: Path) -> tuple[configparser.ConfigParser, list[tuple[str, Path]]]:
    path = preview / "theme.conf"
    if not path.is_file() or path.stat().st_size > 65536:
        raise ValueError("Configuración SDDM ausente o demasiado grande")
    config = configparser.ConfigParser(interpolation=None)
    config.optionxform = str
    config.read(path)
    if set(config.sections()) != {"General"}:
        raise ValueError("La vista previa solo puede cambiar la sección General")
    general = config["General"]
    if set(general) - COLOR_KEYS - FONT_KEYS - OTHER_KEYS:
        raise ValueError("La vista previa incluye opciones SDDM no permitidas")
    for key in COLOR_KEYS:
        if key in general and not re.fullmatch(r"#[0-9a-fA-F]{6}", general[key]):
            raise ValueError("Color SDDM inválido: " + key)
    for key in FONT_KEYS:
        if key in general and not re.fullmatch(r"[A-Za-z0-9 ._-]{1,80}", general[key]):
            raise ValueError("Fuente SDDM inválida: " + key)
    if general.get("backgroundMode", "auto") not in {"auto", "mirror", "panorama", "scene"}:
        raise ValueError("Modo de fondo SDDM inválido")
    if general.get("backgroundAnchor", "center") not in {"center", "top"}:
        raise ValueError("Anclaje de fondo SDDM inválido")
    if general.get("showAvatar", "true").lower() not in {"true", "false"}:
        raise ValueError("showAvatar SDDM inválido")
    images = []
    for key in ("background", "backgroundPanorama"):
        name = general.get(key, "")
        if not name or name == "assets/wallpaper.png":
            continue
        if "/" in name or not IMAGE.fullmatch(name):
            raise ValueError("Nombre de imagen SDDM inválido")
        image = preview / name
        if image.is_symlink() or not image.is_file() or image.stat().st_size > 100 * 1024 * 1024:
            raise ValueError("Imagen SDDM ausente o demasiado grande")
        images.append((name, image))
    return config, images


def atomic_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, name = tempfile.mkstemp(dir=path.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(name, 0o644)
        os.replace(name, path)
    finally:
        Path(name).unlink(missing_ok=True)


def install(preview: Path, uid: int) -> None:
    _, preview = preview_for_uid(preview, uid)
    config, images = validate_config(preview)
    if not (SOURCE / "Main.qml").is_file() or SOURCE.is_symlink():
        raise ValueError("Tema base de SDDM ausente")
    stage = Path(tempfile.mkdtemp(prefix=".black-ice-personal-", dir=ROOT))
    backup_target = ROOT / (".black-ice-personal-old-" + str(os.getpid()))
    try:
        shutil.rmtree(stage)
        shutil.copytree(SOURCE, stage)
        for name, image in images:
            shutil.copyfile(image, stage / name)
        with (stage / "theme.conf").open("w") as stream:
            config.write(stream)
        for item in stage.rglob("*"):
            item.chmod(0o644 if item.is_file() else 0o755)
        stage.chmod(0o755)
        if TARGET.exists():
            if TARGET.is_symlink() or not TARGET.is_dir():
                raise ValueError("El destino de SDDM no es un directorio regular")
            os.replace(TARGET, backup_target)
        try:
            os.replace(stage, TARGET)
        except Exception:
            if backup_target.exists():
                os.replace(backup_target, TARGET)
            raise
        if backup_target.exists():
            shutil.rmtree(backup_target)
    finally:
        if stage.exists():
            shutil.rmtree(stage)
    paths = list(CONFIGS)
    paths = [path for path in paths if path != CONFIGS[2] or path.exists()]
    backup = BACKUP
    if backup.is_symlink() or any(path.is_symlink() for path in paths):
        raise ValueError("La configuración de SDDM contiene enlaces no permitidos")
    backup.parent.mkdir(parents=True, exist_ok=True)
    if not backup.exists():
        backup.write_text(json.dumps({str(path): path.read_text() if path.exists() else None for path in paths}))
        backup.chmod(0o600)
    for path in paths:
        parser = configparser.ConfigParser(interpolation=None)
        parser.optionxform = str
        parser.read(path)
        if not parser.has_section("Theme"):
            parser.add_section("Theme")
        parser["Theme"]["Current"] = "black-ice-personal"
        import io
        output = io.StringIO()
        parser.write(output, space_around_delimiters=False)
        atomic_text(path, output.getvalue())


def main() -> int:
    if os.geteuid() != 0 or len(sys.argv) != 2:
        print("Uso privilegiado requerido", file=sys.stderr)
        return 2
    try:
        uid = int(os.environ.get("PKEXEC_UID", "0"))
        if uid <= 0:
            raise ValueError("No se identificó la cuenta solicitante")
        install(Path(sys.argv[1]), uid)
    except (OSError, ValueError, configparser.Error) as error:
        print(str(error), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
