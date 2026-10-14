"""Tor transparente para las aplicaciones normales del sistema."""
import json
import shutil
import time
from pathlib import Path

from black_ice_i18n import translate
from manager import HELPER, atomic, command

SCOPE = "TCP IPv4 del sistema mediante Tor. DNS mediante Tor; IPv6, UDP restante y tráfico reenviado bloqueados."
STATE = Path("/run/black-ice/tor.json")
FLAG = Path("/var/lib/black-ice/tor/enabled")


class SystemPrivacy:
    def __init__(self, manager):
        self.manager = manager

    def state(self) -> dict:
        if STATE.exists():
            data = json.loads(STATE.read_text())
        else:
            data = {"enabled": FLAG.exists(), "phase": "blocked" if FLAG.exists() else "off",
                    "error": "Estado del verificador pendiente" if FLAG.exists() else ""}
        if data.get("enabled") and data.get("phase") == "protected" and time.time() - data.get("checked", 0) > 45:
            data.update(phase="blocked", error="La verificación venció; no se confirma la salida Tor.")
        return data

    def waybar(self) -> dict:
        state = self.state()
        phase = state.get("phase", "off")
        marker = {"off": "○", "preparing": "◌", "protected": "●", "blocked": "!"}.get(phase, "!")
        label = {"off": "Apagado", "preparing": "Conectando", "protected": "Sistema mediante Tor", "blocked": "Sin verificar"}.get(phase, "Error")
        tooltip = "Tor · " + label + "\n" + SCOPE
        if state.get("ip"):
            tooltip += "\nSalida verificada: " + state["ip"]
        if state.get("error"):
            tooltip += "\n" + state["error"]
        tooltip += "\nClic: " + ("apagar y recuperar conexión normal" if state.get("enabled") else "activar para el sistema")
        tooltip += "\nClic derecho: controles. Utiliza tus terminales y aplicaciones habituales."
        return {"text": marker + " Tor", "class": phase, "alt": phase, "tooltip": translate(tooltip)}

    def action(self, name: str) -> dict:
        return json.loads(command(["pkexec", HELPER, "tor-" + name], timeout=240))

    def enable(self, progress=lambda text: None) -> dict:
        missing = [package for binary, package in (("tor", "tor"), ("nft", "nftables")) if not shutil.which(binary)]
        if missing:
            progress(translate("Instalando requisitos de Tor mediante autorización administrativa…"))
            command(["pkexec", HELPER, "install", *missing], timeout=7200)
        progress("Activando Tor del sistema mediante autorización administrativa…")
        return self.action("enable")

    def disable(self) -> dict:
        return self.action("disable")

    def toggle(self, progress=lambda text: None) -> dict:
        with self.manager.locked("privacy-toggle"):
            state = self.state()
            if state.get("enabled") and state.get("phase") != "blocked":
                return self.disable()
            return self.enable(progress)

    def verify(self) -> dict:
        return self.state()

    def request_verify(self) -> dict:
        return self.action("verify")

    def visible(self) -> bool:
        path = self.manager.config / "black-ice/privacy-ui.json"
        return json.loads(path.read_text()).get("visible", True) if path.exists() else True

    def set_visible(self, visible: bool) -> dict:
        if not isinstance(visible, bool):
            raise TypeError("La visibilidad debe ser verdadera o falsa")
        path = self.manager.config / "black-ice/privacy-ui.json"
        if path.is_symlink() or any(parent.is_symlink() for parent in path.parents):
            raise ValueError("La preferencia de Tor no puede escribirse mediante enlaces")
        atomic(path, {"visible": visible})
        return {"visible": visible, "enabled": self.state().get("enabled", False)}

    def terminal(self) -> list[str]:
        raise ValueError("Utiliza cualquier terminal o aplicación habitual. Tor activo no necesita una consola especial.")

    def logs(self) -> str:
        return command(["pkexec", HELPER, "tor-logs"], timeout=30)
