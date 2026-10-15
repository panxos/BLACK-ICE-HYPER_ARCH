#!/usr/bin/env python3
"""Coordina las actualizaciones acotadas de componentes BLACK-ICE."""

import argparse
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STATE_FILE = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "black-ice/repository"


def find_repository(explicit: str | None) -> Path:
    if explicit:
        path = Path(explicit).expanduser()
        if path.is_dir() and (path / ".git").exists() and (path / "scripts/black-ice-update.py").is_file():
            return path.resolve()
        raise ValueError("La ruta indicada no es un checkout Git válido de BLACK-ICE.")
    candidates = [explicit, os.environ.get("BLACK_ICE_REPO"),
                  STATE_FILE.read_text().strip() if STATE_FILE.is_file() else None,
                  str(Path.cwd()), str(ROOT)]
    for candidate in candidates:
        if not candidate:
            continue
        path = Path(candidate).expanduser()
        if path.is_dir() and (path / ".git").exists() and (path / "scripts/black-ice-update.py").is_file():
            return path.resolve()
    raise ValueError("No encuentro un checkout Git válido de BLACK-ICE. Indica --repo RUTA.")


def run(command: list[str], *, cwd: Path) -> int:
    try:
        return subprocess.run(command, cwd=cwd, check=False, timeout=300).returncode
    except subprocess.TimeoutExpired:
        print("El paso superó el límite de 300 segundos: " + " ".join(command), file=sys.stderr)
        return 124


def dirty_checkout(repo: Path) -> bool:
    try:
        result = subprocess.run(["git", "status", "--porcelain"], cwd=repo,
                                capture_output=True, text=True, check=False, timeout=30)
    except subprocess.TimeoutExpired as error:
        raise ValueError("Git tardó más de 30 segundos al revisar el checkout.") from error
    if result.returncode:
        raise ValueError("No pude consultar el estado Git del checkout.")
    return bool(result.stdout.strip())


def hyprland_config_is_linked() -> bool:
    config = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "hypr"
    return config.is_symlink() or (config / "hyprland.conf").is_symlink()


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", help="Ruta al checkout de BLACK-ICE")
    parser.add_argument("--dry-run", action="store_true", help="Muestra los pasos sin cambiar archivos ni descargar")
    parser.add_argument("--no-pull", action="store_true", help="Usa el checkout local sin consultar GitHub")
    args = parser.parse_args(argv)
    if os.geteuid() == 0:
        parser.error("Ejecuta black-ice-update como usuario del escritorio, sin sudo")

    try:
        repo = find_repository(args.repo)
        if not args.no_pull and not args.dry_run and dirty_checkout(repo):
            raise ValueError("El checkout tiene cambios locales. Revísalos o usa --no-pull con una copia revisada.")

        print(f"Checkout: {repo}")
        if not args.no_pull:
            if args.dry_run:
                print("[SIMULACIÓN] git pull --ff-only")
            else:
                result = run(["git", "pull", "--ff-only"], cwd=repo)
                if result:
                    return result

        dry = args.dry_run
        migration_options = ["--repo", str(repo), "--no-pull"]
        if hyprland_config_is_linked():
            migration_options.append("--skip-migration")
            print("Configuración Hyprland enlazada: se conservará y se omitirá solo la migración visual.")
        steps = [
            ("Migración conservadora y actualización de comandos", ["bash", "dotfiles/bin/dotfiles-update"] + migration_options + (["--dry-run"] if dry else [])),
            ("Controles y componentes del usuario", [sys.executable, "scripts/install-security-workspace.py"] + (["--dry-run"] if dry else [])),
        ]
        for label, command in steps:
            print(f"\n{label}:")
            result = run(command, cwd=repo)
            if result:
                print(f"Falló el paso: {label}. Los pasos siguientes no se ejecutaron.", file=sys.stderr)
                return result

        print("\nComponentes privilegiados: /usr/lib/black-ice/{system-transaction,system-sddm-theme,system-tor}, /usr/share/black-ice/apps.json y unidades Tor.")
        if dry:
            print("[SIMULACIÓN] sudo bash scripts/install-system-components.sh")
            print("La actualización no instala paquetes de Arch, no activa Tor y no reinicia la sesión.")
            return 0

        result = run(["sudo", "bash", "scripts/install-system-components.sh"], cwd=repo)
        if result:
            print("Falló la actualización privilegiada. Los pasos previos quedaron aplicados y son seguros para repetir.", file=sys.stderr)
            return result
        print("\nActualización BLACK-ICE terminada. Reinicia Waybar si el cambio incluye su módulo: ~/.local/bin/waybar_start.sh")
        return 0
    except (OSError, ValueError) as error:
        print(str(error), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
