"""Perfiles optativos; la presencia del paquete y del ejecutable se comprueba aparte."""
import shutil
import subprocess

from manager import command

PROFILES = {
    "disk": {"title": "Disco y recuperación", "packages": ["sleuthkit", "foremost", "hexedit"]},
    "memory": {"title": "Memoria RAM", "packages": ["volatility3"]},
    "metadata": {"title": "Metadatos y archivos", "packages": ["perl-image-exiftool", "steghide", "stegseek"]},
    "firmware": {"title": "Firmware y binarios", "packages": ["binwalk"]},
    "autopsy": {"title": "Autopsy (pesado, opcional)", "packages": ["autopsy"]},
}
BINARIES = {"sleuthkit": "fls", "foremost": "foremost", "hexedit": "hexedit", "volatility3": "vol",
            "perl-image-exiftool": "exiftool", "steghide": "steghide", "stegseek": "stegseek", "binwalk": "binwalk", "autopsy": "autopsy"}
FLAGS = {"sleuthkit": "-V", "foremost": "-V", "hexedit": "-v", "perl-image-exiftool": "-ver", "autopsy": "-h", "binwalk": "--version"}


def status(manager, profile):
    choice = PROFILES[profile]
    installed = manager.installed(choice["packages"])
    packages = [{"id": name, "installed": name in installed, "executable": shutil.which(BINARIES[name])}
                for name in choice["packages"]]
    for item in packages:
        item["starts"] = False
        if item["installed"] and item["executable"]:
            try:
                item["probe"] = command([item["executable"], FLAGS.get(item["id"], "--help")], timeout=15)[-600:]
                item["starts"] = True
            except (OSError, RuntimeError, subprocess.TimeoutExpired) as error:
                item["probe"] = str(error)[-600:]
    return {**choice, "packages": packages, "ready": all(item["installed"] and item["executable"] and item["starts"] for item in packages)}


def install(manager, profile):
    if profile not in PROFILES:
        raise ValueError("Perfil forense desconocido")
    return manager.enqueue(PROFILES[profile]["packages"])
