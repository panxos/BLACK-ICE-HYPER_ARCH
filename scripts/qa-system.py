#!/usr/bin/env python3
"""Evidencia de QA: comandos de lectura, mediciones y pendientes explícitos."""
import argparse
import hashlib
import json
import os
import platform
import statistics
import subprocess
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def check(name, args, timeout=60, accepted=(0,)):
    start = time.monotonic()
    try:
        result = subprocess.run(args, capture_output=True, text=True, timeout=timeout, check=False)
        return {"name": name, "status": "passed" if result.returncode in accepted else "failed",
                "seconds": round(time.monotonic() - start, 3), "exit": result.returncode,
                "evidence": (result.stdout + result.stderr)[-6000:]}
    except (OSError, subprocess.TimeoutExpired) as error:
        return {"name": name, "status": "failed", "evidence": str(error)}


def cpu():
    fields = [int(value) for value in Path("/proc/stat").read_text().splitlines()[0].split()[1:]]
    return sum(fields[:8]), fields[3] + fields[4]


def memory():
    fields = {line.split(":")[0]: int(line.split()[1]) for line in Path("/proc/meminfo").read_text().splitlines()}
    return round((fields["MemTotal"] - fields["MemAvailable"]) / 1024, 1)


def measure(seconds, runs):
    samples = []
    for attempt in range(runs):
        previous = cpu()
        usage, ram = [], []
        for _ in range(seconds):
            time.sleep(1)
            current = cpu()
            total = current[0] - previous[0]
            usage.append(100 * (1 - (current[1] - previous[1]) / total) if total else 0)
            ram.append(memory())
            previous = current
        samples.append({"run": attempt + 1, "duration_seconds": seconds,
                        "cpu_percent_median": round(statistics.median(usage), 2), "memory_mib_median": statistics.median(ram)})
    return samples


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--desktop", action="store_true")
    parser.add_argument("--unit", action="store_true")
    parser.add_argument("--performance", action="store_true")
    parser.add_argument("--seconds", type=int, default=600)
    parser.add_argument("--runs", type=int, default=3)
    args = parser.parse_args()
    if not 1 <= args.seconds <= 3600 or not 1 <= args.runs <= 5:
        parser.error("Duración 1–3600 segundos; 1–5 ejecuciones")
    started = time.time()
    digest = hashlib.sha256()
    for path in sorted((ROOT / "src").rglob("*")):
        if path.is_file() and "__pycache__" not in path.parts:
            digest.update(str(path.relative_to(ROOT)).encode())
            digest.update(path.read_bytes())
    report = {"schema": 1, "version": (ROOT / "VERSION").read_text().strip(), "source_sha256": digest.hexdigest(),
              "environment": {"kernel": platform.release(), "architecture": platform.machine()}, "started": started, "checks": []}
    checks = report["checks"]
    checks.append(check("virtualization", ["systemd-detect-virt"], accepted=(0, 1)))
    checks.append(check("root-layout", ["findmnt", "-nro", "FSTYPE,FSROOT", "/"]))
    checks.append(check("system-units", ["systemctl", "--failed", "--no-legend"]))
    if checks[-1].get("evidence", "").strip():
        checks[-1]["status"] = "failed"
    checks.append(check("boot-time", ["systemd-analyze", "time"]))
    if args.unit:
        checks.append(check("unit-tests", ["python3", "-m", "unittest", "discover", "-s", str(ROOT / "tests"), "-p", "test_*.py"], timeout=300))
        checks.append(check("gtk-navigation", ["xvfb-run", "-a", "python3", "-m", "unittest", "discover", "-s", str(ROOT / "tests"), "-p", "test_control_navigation.py"], timeout=60))
    if args.desktop:
        checks.append(check("hyprland-config", ["hyprctl", "configerrors"]))
        if checks[-1].get("evidence", "").strip() not in {"", "[]"}:
            checks[-1]["status"] = "failed"
        checks.append(check("monitors", ["hyprctl", "monitors", "-j"]))
        checks.append(check("desktop-doctor", [str(Path.home() / ".local/bin/black-ice-doctor")]))
    if args.performance:
        report["performance"] = measure(args.seconds, args.runs)
        report["performance_baseline_comparison"] = "not_verified"
    report["not_verified"] = ["physical_ac_battery_suspend", "physical_lid_hotplug", "bios_ext4_luks_matrix"]
    report["finished"] = time.time()
    args.output.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    fd, temporary = tempfile.mkstemp(dir=args.output.parent)
    with os.fdopen(fd, "w") as stream:
        json.dump(report, stream, ensure_ascii=False, indent=2)
    os.replace(temporary, args.output)
    failed = sum(item["status"] == "failed" for item in checks)
    print(f"QA: {len(checks) - failed} aprobados, {failed} fallidos; pendientes explícitos en {args.output}")
    return bool(failed)


if __name__ == "__main__":
    raise SystemExit(main())
