# Security workspace

[Español](SECURITY_WORKSPACE.md) · [Guide](GUIDE.en.md) · [Pending work](PENDING.en.md)

The candidate combines network privacy, optional forensic profiles, local laboratories and case management. Each indicator has a defined scope; none proves that the computer is invulnerable.

## System Tor

Use **installed applications and any ordinary terminal**. The Tor button does not open a special Bash console. Click to request activation/shutdown; right click opens controls. Its typography and colors follow the theme, with short `○ Tor`, `◌ Tor`, `● Tor` or `! Tor` labels. Details live in the tooltip.

**Control → System → Security** can stop Tor and change **Show Tor in the bar**. Hiding the indicator preserves the Tor state. Visibility applies globally to every theme, including compact layouts.

| State | Meaning |
|---|---|
| Off | System Tor mode is disabled |
| Connecting | Preparing the filter/client |
| Active | Effective rules, service and Tor exit verified |
| Unverified | Failed check or result older than 45 seconds |

The dedicated `black-ice-tor` user runs a separate client, limited to 512 MiB, one CPU and 128 tasks. The `inet black_ice_tor` table does not replace the existing firewall. When enabled, its filter persists before networking on boot.

Activation affects traffic from every account on the machine. Language and visibility are per-user preferences; they do not create independent Tor connections.

| Traffic | Active policy |
|---|---|
| Local process IPv4 TCP | Redirected to `127.0.0.1:19040` (TransPort) |
| IPv4 UDP DNS | Redirected to `127.0.0.1:19053` (DNSPort) |
| Dedicated Tor UID TCP | Allowed to build Tor circuits |
| Loopback | Allowed |
| Broadcast IPv4 DHCP, 68→67 | Explicit local exception |
| IPv6 and other UDP/ICMP | Blocked |
| Forwarded guest bridge traffic | Blocked |

Rootless containers using user-owned sockets follow the local-process policy; this differs from bridge forwarding. Virtual machines are not advertised as routed through Tor: forwarded traffic is blocked.

Existing connections may break on activation. VPNs, QUIC, calls, discovery and UDP/raw-packet tools may fail. Private-address TCP is not silently exempted: Tor does not replace local laboratory access. Treat VPN and Tor as separate modes.

Tor does not remove hostnames, usernames, content or application identifiers. An ordinary browser retains its identifying characteristics; use Tor Browser for its dedicated defenses. This mode does not defend against compromised root access, a manipulated kernel or malware. [Tor manual](https://man.archlinux.org/man/tor.1.en), [Tor Browser safety](https://support.torproject.org/tor-browser/security/using-tb-safely/).

## Enable, verify and disable

```bash
black-ice-privacy enable
black-ice-privacy status
black-ice-privacy verify
curl --noproxy '*' https://check.torproject.org/api/ip
black-ice-privacy disable
```

Activation, shutdown and requested verification use normal `pkexec` authorization. Missing Tor/nftables requirements are installed through the existing restricted helper. The privileged components must be installed; copying the button alone is insufficient.

Verification uses ordinary `curl` without an explicit proxy to test the system path. Active status requires `IsTor: true` and a global exit address. The guard also compares its table fingerprint; changed or missing rules trigger restoration and a failed state. This is not a defense against root manipulating the guard.

**Filtering remains if Tor stops.** There is no automatic fallback to direct access. Explicitly disable Tor to restore normal networking. Administrative recovery from a local terminal:

```bash
sudo /usr/lib/black-ice/system-tor disable
```

This removes only the mode's table and stops/disables its services. It does not flush the ruleset or stop unrelated Tor services. Direct access returns through an explicit action.

## Updating the controls

From the repository checkout used to install BLACK-ICE, fetch the improvement and preview the files it will update:

```bash
git pull --ff-only
python3 scripts/install-security-workspace.py --dry-run
python3 scripts/install-security-workspace.py
sudo bash scripts/install-system-tor.sh
~/.local/bin/waybar_start.sh
```

Run `git pull` inside the correct checkout and the installers as the regular desktop user, except the Tor installer, which requires `sudo`. The first installer includes `black-ice-control`, modules, commands, languages and styles; it rejects linked destinations and rolls files back after a write failure. The Tor installer updates root-owned components and **does not activate traffic rules**. This does not reinstall Arch. Tor remains optional and requires activation.

The old Podman Tor environment protected only its own terminal and was removed from the candidate and installer. When upgrading an older installation, local files and resources from that environment are not imported into the new daemon; inspect the private store before cleaning up old data.

## Laboratories and resources

Alpine, Debian and Alpine live support command/system practice. Juice Shop and WebGoat use official digest-pinned images, internal networks and localhost ports. WebGoat needs UID/GID 1001; indiscriminately replacing it prevented access to its JAR.

Managed resources have identities, limits, engine checks and dedicated storage. Review tracked cache images/ISOs before selected cleanup; there is no global prune. Preparation stops when budgets are exceeded, but **subsequent data is not subject to a continuous physical quota**.

New laboratories expire after 120 minutes by default, configurable from 15 to 1440. The service stops registered expired resources without deleting their definitions/data. Without the service, apply expiration through Control or the CLI.

```bash
black-ice-system resources status
black-ice-system resources configure --cache-mib 8192 --ttl-minutes 120
black-ice-system resources cleanup-plan
black-ice-system resources expire
```

## Optional forensics

Disk/recovery, memory, metadata, firmware and Autopsy profiles reuse the application catalog. **Source / size** queries provenance; **Check** distinguishes package installation, executable presence and startup response. Profiles are not installed by default. A successful `--help` does not validate a real forensic analysis.

```bash
black-ice-system forensics profiles
black-ice-system forensics status memory
black-ice-system forensics install memory
black-ice-system jobs run
```

The last command processes pending jobs, so review the queue first. Full profile acceptance and E01, YARA/TestDisk and malware sandbox extensions remain under [pending work](PENDING.en.md).

## Cases and evidence

Cases contain authorized exact hostnames or IP/CIDR targets, optional VPN UUID requirements and private notes. Preflight checks scope and active connections; it does not automatically restrict external tools.

Regular evidence files are copied with SHA-256, budgets and a chained log. Verification detects changes. Sanitized summaries omit notes, scope, VPN, original filenames and identifiers while retaining integrity metadata. Chained hashes are not digital signatures.

## Verified behavior

In the VM, Benjie's ordinary TCP connection confirmed Tor; external DNS was redirected; UDP and IPv6 were rejected; forwarded traffic from a test network incremented the drop counter. Stopping Tor preserved filtering and blocked ordinary connections. Re-enabling and shutdown restored the corresponding modes. After reboot, filtering was active before NetworkManager and an ordinary connection confirmed Tor again.

Installation matrices, physical hardware, quotas, forensic profile acceptance and publication remain open. See [the full list](PENDING.en.md); one VM is not presented as validation of every machine.
