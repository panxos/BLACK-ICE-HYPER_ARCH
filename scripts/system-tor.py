#!/usr/bin/python3 -I
"""Proxy Tor del sistema con filtro independiente y salida directa bloqueada."""
import argparse
import fcntl
import hashlib
import ipaddress
import json
import os
import pwd
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path("/var/lib/black-ice/tor")
RUNTIME = Path("/run/black-ice")
FLAG = ROOT / "enabled"
TABLE = "black_ice_tor"
CHECK = "https://check.torproject.org/api/ip"


def run(args: list[str], timeout: int = 30, input_text: str | None = None) -> str:
    result = subprocess.run(args, input=input_text, capture_output=True, text=True, timeout=timeout, check=False)
    if result.returncode:
        raise RuntimeError((result.stderr or result.stdout)[-1500:] or "Command failed: " + args[0])
    return result.stdout.strip()


def write(path: Path, value: dict | str, mode: int = 0o644) -> None:
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o755)
    fd, name = tempfile.mkstemp(dir=path.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            stream.write(value if isinstance(value, str) else json.dumps(value, ensure_ascii=False))
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(name, mode)
        os.replace(name, path)
    finally:
        Path(name).unlink(missing_ok=True)


def publish(phase: str, error: str = "", ip: str = "") -> dict:
    enabled = FLAG.exists()
    result = {"mode": "system", "enabled": enabled, "phase": phase, "error": error,
              "ip": ip, "checked": time.time(), "scope": "system_tcp_ipv4" if enabled else "disabled",
              "ipv6": "blocked" if enabled else "normal", "udp": "dns_only" if enabled else "normal",
              "forwarding": "blocked" if enabled else "normal"}
    write(RUNTIME / "tor.json", result)
    return result


def rules(uid: int) -> str:
    if not isinstance(uid, int) or uid <= 0:
        raise ValueError("Tor must have its own non-root UID")
    return f"""destroy table inet {TABLE}
table inet {TABLE} {{
    chain route_output {{
        type nat hook output priority dstnat - 10; policy accept;
        meta skuid {uid} return
        meta nfproto ipv4 ip daddr 127.0.0.0/8 return
        meta nfproto ipv4 udp dport 53 counter redirect to :19053
        meta nfproto ipv4 meta l4proto tcp counter redirect to :19040
    }}
    chain guard_output {{
        type filter hook output priority filter + 10; policy drop;
        oifname "lo" accept
        ct status dnat ip daddr 127.0.0.1 tcp dport 19040 accept
        ct status dnat ip daddr 127.0.0.1 udp dport 19053 accept
        meta nfproto ipv4 meta skuid {uid} meta l4proto tcp accept
        meta nfproto ipv4 ip daddr 255.255.255.255 udp sport 68 udp dport 67 accept
        counter reject with icmpx type admin-prohibited
    }}
    chain guard_forward {{
        type filter hook forward priority filter + 10; policy drop;
        counter drop
    }}
}}
"""


def effective_hash() -> str:
    text = run(["nft", "-s", "-n", "list", "table", "inet", TABLE])
    return hashlib.sha256(text.encode()).hexdigest()


def apply_filter() -> dict:
    uid = pwd.getpwnam("black-ice-tor").pw_uid
    text = rules(uid)
    run(["nft", "--check", "-f", "-"], input_text=text)
    run(["nft", "-f", "-"], input_text=text)
    write(ROOT / "rules.sha256", effective_hash(), 0o600)
    return publish("preparing")


def verify() -> dict:
    if not FLAG.exists():
        return publish("off")
    try:
        expected = (ROOT / "rules.sha256").read_text()
        try:
            actual = effective_hash()
        except RuntimeError:
            actual = "missing"
        if actual != expected:
            apply_filter()
            raise RuntimeError("Tor firewall changed; the blocking rules were restored")
        run(["systemctl", "is-active", "black-ice-tor.service"], timeout=5)
        last_error = None
        for attempt in range(2):
            try:
                data = json.loads(run(["curl", "--noproxy", "*", "--ipv4", "--connect-timeout", "8",
                                       "--max-time", "25", "--fail", "--silent", "--show-error", CHECK], timeout=30))
                if data.get("IsTor") is not True or not ipaddress.ip_address(data["IP"]).is_global:
                    raise RuntimeError("The ordinary system connection did not confirm a Tor exit")
                return publish("protected", ip=data["IP"])
            except (OSError, KeyError, ValueError, RuntimeError, subprocess.TimeoutExpired) as error:
                last_error = error
                if attempt == 0:
                    time.sleep(1)
        raise RuntimeError(str(last_error))
    except (OSError, KeyError, ValueError, RuntimeError, subprocess.TimeoutExpired) as error:
        return publish("blocked", str(error)[-600:])


def enable() -> dict:
    run(["runuser", "-u", "black-ice-tor", "--", "tor", "--verify-config", "-f", "/etc/black-ice/torrc"])
    apply_filter()
    write(FLAG, "enabled\n")
    try:
        run(["systemctl", "enable", "black-ice-tor-firewall.service", "black-ice-tor-guard.service"])
        run(["systemctl", "start", "black-ice-tor.service", "black-ice-tor-guard.service"])
        deadline = time.monotonic() + 180
        while time.monotonic() < deadline:
            result = verify()
            if result["phase"] == "protected":
                return result
            time.sleep(2)
        raise RuntimeError("Tor did not connect; direct traffic remains blocked. Retry or explicitly disable Tor.")
    except (OSError, RuntimeError, subprocess.TimeoutExpired) as error:
        publish("blocked", str(error)[-600:])
        raise


def disable() -> dict:
    run(["systemctl", "stop", "black-ice-tor-guard.service", "black-ice-tor.service"])
    run(["systemctl", "disable", "black-ice-tor-guard.service", "black-ice-tor-firewall.service"])
    run(["nft", "-f", "-"], input_text=f"destroy table inet {TABLE}\n")
    FLAG.unlink(missing_ok=True)
    run(["systemctl", "stop", "black-ice-tor-firewall.service"])
    return publish("off")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("preview", "enable", "disable", "verify", "firewall", "watch", "logs"))
    args = parser.parse_args()
    if os.geteuid() != 0:
        parser.error("Use the installed privileged helper")
    os.environ.update(PATH="/usr/sbin:/usr/bin:/sbin:/bin", LC_ALL="C")
    ROOT.mkdir(parents=True, exist_ok=True, mode=0o755)
    if args.action == "preview":
        print(rules(pwd.getpwnam("black-ice-tor").pw_uid))
        return 0
    if args.action == "firewall":
        if FLAG.exists():
            apply_filter()
        return 0
    if args.action == "watch":
        while True:
            with (ROOT / "lock").open("a") as lock:
                try:
                    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
                    verify()
                except BlockingIOError:
                    pass
            time.sleep(10)
    if args.action == "logs":
        print(run(["journalctl", "-u", "black-ice-tor.service", "--no-pager", "-n", "40"]))
        return 0
    with (ROOT / "lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        result = {"enable": enable, "disable": disable, "verify": verify}[args.action]()
        print(json.dumps(result))
        return 1 if result["phase"] == "blocked" else 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, KeyError, ValueError, RuntimeError, subprocess.TimeoutExpired) as error:
        print(str(error), file=sys.stderr)
        raise SystemExit(1) from None
