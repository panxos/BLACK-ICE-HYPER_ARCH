# Pending work and acceptance criteria

[Español](PENDING.md) · [Guide](GUIDE.en.md)

Local candidate 4.0.0-dev.2, updated 2026-10-14. This list separates pending acceptance from future proposals. A proposal is not implemented functionality, and VM evidence is not physical hardware acceptance.

## Release blockers

| Area | Remaining work | Acceptance evidence |
|---|---|---|
| Installation | Repeat the complete empty-disk cycle after adding `uwsm` as a critical dependency | Empty disk, login, network, software and a second run preserving data; the previous clean cycle exposed the missing `uwsm` dependency at SDDM startup and the source is now fixed |
| Matrix | BIOS, ext4, LUKS and supported combinations | Reproducible installation, reboot and recovery records |
| Transactions | Disk exhaustion, failed hooks and interruptions inside operations | Controlled aborts and actual recovery without false success |
| Recovery | Boot-file retention, quotas and further failure cases | Restored kernel, packages, ESP and consistent personal data |
| Software | Selected optional applications and AUR sources | Installation/startup checks for each selection, errors and retries |
| Hardware | Battery/AC, lid, suspend and recovery | Physical checks; hypervisor pause does not replace suspend |
| Displays | Hotplug, mixed scaling and HiDPI | Physical reconnection with correct sessions, bars and wallpaper |
| USB | Reconnection and notification actions | Real mount, file-manager/terminal actions and retained history |
| Responsiveness | Workspace switching under load and prolonged idle | Physical review and comparable evidence |
| Performance | Equivalent baseline and Conky on/off consumption | Three sustained ten-minute samples under equal conditions |
| Licensing | General project license | Explicit decision and license file |
| Resources | Redistribution of wallpapers, logos and other external assets | Provenance, permissions and removal from distribution where required |
| Distribution | Final package and clean installation of new components | Manifest, matching hashes, binaries and services |
| CI | First remote execution of the local definition | Passing checks and rejection of an invalid change |
| Publication | Diff review, commit/tag/release | Later authorization and closure of the blockers above |

## Additional security acceptance

| Area | Remaining work | Acceptance evidence |
|---|---|---|
| Tor | Sustained physical-machine and real network/VPN scenarios | No direct fallback, correct states and verified recovery |
| Greeter and wallpaper | Visually confirm SDDM and the desktop at the next QA VM login | Mr-Robot and its wallpaper are configured; the session was not restarted after the fixes |
| Forensic profiles | Install and use every optional profile | Package, executable, probe and actual exercise per tool |
| Web laboratories | Final acceptance after control updates | Localhost exposure, isolation, data, expiration and QA cleanup |
| Cache/expiration | Reconnection, reboot and further limits | Active service, actual expiration and cleanup of owned resources only |
| Nested KVM | Expand the already tested live guest | Complete guest OS, internal limits and snapshot/restore |
| VPN | Own endpoint and unrelated profile | Real connection/reconnection without borrowing another case's target or connection |
| Cases | Broader operational exercises | Scope, VPN, altered evidence and reviewed exports |

System Tor already passed ordinary TCP, redirected DNS, daemon failure, blocked UDP/IPv6/forwarding, shutdown and reboot checks in the VM, with filtering before NetworkManager. The former Podman/Kitty console was removed; the control does not open a terminal and Tor applies to system applications within the documented scope. This does not establish absolute anonymity or replace Tor Browser.

On 2026-10-14, a clean UEFI/Btrfs installation without LUKS, a preserving resume, and the minimal deployment through its configured acceptance stop were tested. The first login exposed the missing `uwsm` dependency for SDDM's Hyprland session; it was added to the package list and critical-package check, and the QA VM now boots with it. Repeat the full installation and deployment cycle from the start using this corrected candidate.

## Visual and content review

- Human approval of Mr-Robot likenesses and Condor/Condor Noir tributes.
- Exact s4vitar reference, final similarity and wallpaper provenance.
- Recover and compare the approved Anubis master from the second machine when available, without sending files to that machine.
- Yael/Varinka review and login/lock testing across multiple physical displays.
- Native-detail 4K resources; existing upscaled derivatives must remain labeled accordingly.
- Continue reviewing both languages when adding controls; external translations and third-party greeters depend on their own catalogs.
- Control and all twenty Conky layouts now follow the selected language. Automated tests cover rendered labels; review the final appearance in a fresh graphical session after deploying the updated files.

## Future proposals

| Proposal | Implementation still required or incomplete |
|---|---|
| Unified updater | Coordinated package, dotfile and migration transactions |
| Software center | Full reviewed uninstall, history, per-job progress and queue archive |
| Real quotas | Continuous physical image, ISO and data limits per project |
| Exportable diagnostics | General IP/path/token sanitization and preview |
| Downloadable resource packs | Selected resources only, integrity and retries |
| Periodic recovery drills | Automated clone restore and boot report |
| Project workspaces | Open notes/terminals/tools and confirm the target VPN |
| Tor Browser | Optional integration retaining browser-specific defenses |
| Expanded forensics | E01 acquisition, YARA/TestDisk and further exercises |
| Laboratories | AD templates and a specifically validated malware sandbox |
| Universal editor | Separate Hyprland project; name, stack and prototype undecided |

## Continuity

Replication to the second workstation remains explicitly deferred. A synchronized project directory does not prove delivery or publication.

Some historical task lists are stale: Git recovery, Lua and old previews have later evidence or replacement mechanisms. Reconcile and archive those records; do not rerun the removed preview generator or return to 3.x versions.

Private session details and machine evidence are intentionally excluded from this public list.
