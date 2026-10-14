#!/usr/bin/env python3
"""Registro atómico de módulos; nunca contiene contraseñas ni ejecuta comandos."""
import argparse
import hashlib
import json
import os
import tempfile
import time
from pathlib import Path


def save(path, value):
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    fd, name = tempfile.mkstemp(dir=path.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            json.dump(value, stream, ensure_ascii=False)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(name, path)
    finally:
        Path(name).unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("operation", choices=["init", "status", "begin", "done"])
    parser.add_argument("--state", type=Path, required=True)
    parser.add_argument("--identity", required=True)
    parser.add_argument("--fingerprint", required=True)
    parser.add_argument("--module", default="")
    parser.add_argument("--source", type=Path)
    parser.add_argument("--fresh", action="store_true")
    args = parser.parse_args()
    if args.fresh and args.operation != "init":
        parser.error("--fresh solo se permite al iniciar un despliegue nuevo")
    state = json.loads(args.state.read_text()) if args.state.exists() and not args.fresh else {
        "schema": 1, "identity": args.identity, "fingerprint": args.fingerprint, "modules": {}}
    if (state["identity"], state["fingerprint"]) != (args.identity, args.fingerprint):
        parser.error("Destino o configuración distintos: no se permite reutilizar este registro")
    digest = hashlib.sha256(args.source.read_bytes()).hexdigest() if args.source else ""
    previous = state["modules"].get(args.module, {})
    if args.operation == "status":
        return 0 if previous.get("status") == "done" and previous.get("sha256") == digest else 1
    if args.operation != "init":
        state["modules"][args.module] = {"status": "done" if args.operation == "done" else "running",
            "sha256": digest, "updated": time.time(), "attempts": previous.get("attempts", 0) + (args.operation == "begin")}
    save(args.state, state)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
