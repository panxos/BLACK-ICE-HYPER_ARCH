<div align="center">

# BLACK-ICE ARCH

### Arch Linux · Hyprland · A security workstation

**A security desktop with 54 themes, dedicated controls and selectable tools.**

[Español](README.md) · [Installation](docs/GUIDE.en.md#installation-and-resume) · [Gallery](docs/THEMES.md) · [Guide](docs/GUIDE.en.md) · [Pending work](docs/PENDING.en.md)

<img src="docs/images/showcase/desktop-mr-robot.png" alt="BLACK-ICE desktop running the Mr-Robot theme" width="100%">

<sub>Real capture from the validation VM · Hyprland · Mr-Robot theme</sub>

**4.0.0-dev.2 · candidate under validation · no release yet**

</div>

BLACK-ICE installs Arch Linux and sets up a Hyprland desktop with coordinated themes, security applications and administration tools. Install the entire system from an ISO or deploy the desktop on an existing Arch installation.

This README describes local changes under validation. Cloning the remote branch downloads published code; it does not guarantee access to this candidate.

## Choose your path

| I want to… | Start here |
|---|---|
| Install on an empty disk | [Installation](docs/GUIDE.en.md#installation-and-resume) |
| Deploy Hyprland on Arch | [Complete guide](docs/GUIDE.en.md) |
| Customize while preserving settings | [Themes and profiles](docs/GUIDE.en.md#themes-and-profiles) |
| Choose English or Spanish | [Language](docs/LANGUAGE.en.md) |
| Run installed applications through Tor | [System Tor](docs/SECURITY_WORKSPACE.en.md#system-tor) |
| Create laboratories or cases | [Security and practice](docs/GUIDE.en.md#laboratories-and-cases) |
| Review everything still open | [Pending work and acceptance criteria](docs/PENDING.en.md) |

## One desktop, many identities

| Mr-Robot | Condor Noir | FBI · Fieldwork |
|---|---|---|
| ![Mr-Robot](docs/images/themes/Mr-Robot.webp) | ![Condor Noir](docs/images/themes/Kevin-Mitnick-Condor-Noir.webp) | ![FBI](docs/images/themes/FBI-Fieldwork.webp) |
| Matrix · Hacker | Civic SI · Mugen | MK11 · SubZero |
| ![Matrix](docs/images/themes/Matrix-Hacker.webp) | ![Civic](docs/images/themes/Civic-Si-Mugen.webp) | ![SubZero](docs/images/themes/MK11-SubZero.webp) |

Themes coordinate Waybar, Conky, Kitty, the launcher, menus and notifications. Proper names remain unchanged when switching languages. [Browse all 54 themes](docs/THEMES.md).

<div align="center">
<img src="docs/images/showcase/theme-studio-mr-robot.png" alt="BLACK-ICE Theme Studio with a Mr-Robot desktop preview" width="100%">
<sub>Theme Studio arranges modules, bars and workspaces; changes take effect only after saving.</sub>
</div>

| Component | Available controls |
|---|---|
| Control | Audio, brightness, network, power, appearance and session |
| Studio | `User-*` profiles, module placement, bars, fonts and colors |
| Conky | 20 styles on one, several or all displays |
| Launcher | Panoramic banner, compact list, tiles or Wofi |
| Displays | Individual wallpaper, panoramas per row or a shared scene |
| F1 help | Search bindings actually loaded by the session |

Gallery captures use demonstration data in an isolated Waybar session. Themes use source images and scale them for display; the repository does not store enlarged copies that add no detail. [Wallpapers and sources](docs/WALLPAPERS.en.md).

Studio is a simple configurator. A universal Hyprland designer remains a separate future project. Applying a theme with SDDM follow enabled updates the greeter palette and wallpaper for the next login. Saving a profile alone does not change SDDM. Hyprlock also has dedicated controls.

## English and Spanish

**Control → System → Language** persists the choice independently of the theme. You can also run:

```bash
black-ice-language set en
black-ice-language set es
```

Control, Studio, galleries and system panels use shared translations. The visual review still found untranslated Control and Conky labels. Typed data, profile names and identifiers keep their original values. SDDM Obsidiana has its own choice before login. External applications manage translations and may need a restart or locale configuration. [Coverage and checks](docs/LANGUAGE.en.md).

## Two installation phases

You need repository access, Hyprland-compatible hardware and a reviewed destination disk. Use the official Arch ISO for the base phase and a regular user with sudo for the desktop.

```bash
git clone https://github.com/panxos/BLACK-ICE-HYPER_ARCH.git BLACK-ICE_ARCH
cd BLACK-ICE_ARCH
```

| Phase | Command | Result |
|---|---|---|
| Base, from the ISO | `sudo bash install.sh` | Disk, Btrfs/ext4, optional LUKS, user, network and boot |
| Desktop, after reboot | `bash deploy_hyprland.sh` | Hyprland, selected applications, dotfiles and services |

**The base phase can partition and format the selected disk.** Review the [example configuration](config/install.conf.example) and [installation guide](docs/GUIDE.en.md#installation-and-resume). Erase authorization identifies the exact disk.

Review the software selection first:

```bash
bash deploy_hyprland.sh --dry-run --profile pentest
python3 scripts/select-apps.py --ui auto --output ~/.local/state/black-ice/apps-plan.json
bash deploy_hyprland.sh --dry-run --plan ~/.local/state/black-ice/apps-plan.json
```

Remove `--dry-run` from the last command after reviewing the plan. There are **143 applications in 20 groups**, with `minimal`, `desktop`, `pentest` and `full` profiles. Canceling skips optional software. AUR requires review and is not built as root.

`install.sh --resume` and `deploy_hyprland.sh --resume` check the destination, configuration and results. Resume does not authorize repartitioning. [Installation details](docs/GUIDE.en.md#installation-and-resume).

## Tor for installed applications

The small **○ Tor / ● Tor** module follows every theme. A click requests activation or shutdown; right click opens controls. **Control → System → Security** can stop Tor or hide its indicator. Hiding the indicator does not stop Tor.

A dedicated Tor client and an independent nftables table redirect ordinary IPv4 TCP connections and IPv4 DNS. **Use Kitty, Konsole or another terminal with your installed tools. No special console or proxychains prefix is required.**

| While Tor is enabled | Behavior |
|---|---|
| Local IPv4 TCP | Transparent redirection through Tor |
| IPv4 UDP DNS | Redirection to Tor DNS |
| IPv6 and other UDP, including QUIC | Blocked |
| Traffic forwarded through guest bridges | Blocked |
| Loopback and broadcast IPv4 DHCP | Explicit local exceptions |
| Tor stops or verification fails | Filtering remains; no automatic direct fallback |

```bash
black-ice-privacy status
black-ice-privacy enable
curl --noproxy '*' https://check.torproject.org/api/ip
black-ice-privacy disable
```

Activation requires administrative authorization. Active status checks effective rules, the service and a Tor exit from an ordinary connection. Toggling Tor never opens a special console; use your regular terminals and apps, and turn Tor off from the same control.

Tor does not carry every protocol or prevent applications from exposing identifiers, logins or browser characteristics. It does not protect against compromised root access or replace Tor Browser. VPNs, calls and UDP/ICMP/raw-packet tools may stop working. [Tor manual](https://man.archlinux.org/man/tor.1.en) · [Setup, emergency shutdown and limits](docs/SECURITY_WORKSPACE.en.md).

## Software, recovery and practice

**Control → System** contains five pages:

- **Software:** selection, sources, persistent queue, errors and retries through a catalog-restricted helper.
- **Updates:** Btrfs snapshots and `/boot`/ESP archives. Creating a point does not prove recovery; restore it offline and boot afterward.
- **Projects/VPN:** separate targets and NetworkManager UUIDs without storing passwords in profiles.
- **Laboratories:** Alpine, Debian, Alpine live VM, Juice Shop and WebGoat from official sources with an aggregate budget.
- **Security:** Tor, optional forensics, case scope, private notes, SHA-256 evidence and sanitized summaries.

Templates are offline or expose localhost only. They do not mount personal folders. Preparation cache monitoring is not a continuous filesystem quota. Expiration stops registered resources without deleting their data. Isolation has not been validated for malware.

[Complete guide](docs/GUIDE.en.md) · [Security workspace](docs/SECURITY_WORKSPACE.en.md).

## Essential shortcuts

| Shortcut | Action |
|---|---|
| Super / Super+D | Launcher |
| Super+Enter | Kitty |
| Super+Alt+T / Super+Alt+W | Appearance / wallpapers |
| F1 / Super+I | Active shortcut help |
| Super+1…5 | Local workspace on the focused display |
| Super+Alt+1…5 | Move window to the local workspace |
| Super+F8 / Super+Shift+F8 | Conky / Conky gallery |
| Super+L | Lock |

Personal bindings may differ.

## Update and rollback

Inspect the plan from a reviewed checkout:

```bash
bash dotfiles/bin/dotfiles-update --no-pull --dry-run
bash dotfiles/bin/dotfiles-update --no-pull
```

Visual installers preserve preferences through manifests and protected rollback. [Update the new controls](docs/SECURITY_WORKSPACE.en.md#updating-the-controls) or inspect Lua migration before the next login. Dotfile rollback and whole-system recovery are different mechanisms.

## Validation status

Evidence covers an unencrypted UEFI/Btrfs KVM installation, resume, SDDM/Hyprland login and offline recovery followed by boot. System Tor checks cover ordinary connections, DNS, daemon failure, blocked UDP/IPv6 and forwarded traffic, shutdown and restored normal connectivity.

BIOS/ext4/LUKS, transaction failures, physical displays/power/USB, comparable performance and redistribution review remain open. CI has a local definition; its first remote execution is pending. **There is no release until the blocking criteria are met.**

[All pending work](docs/PENDING.en.md).

## Development

```bash
bash scripts/check-project.sh
python3 scripts/check-distribution.py
```

| Path | Responsibility |
|---|---|
| `src/modules/`, `src/deploy/` | Base and desktop installation |
| `src/lib/`, `src/system/` | Utilities and managers |
| `dotfiles/` | Desktop controls and services |
| `config/` | Applications, languages, power, Tor and exclusions |
| `assets/` | Wallpapers, fonts, icons and login themes |
| `scripts/`, `tests/` | Generation and validation |
| `docs/` | Guides, gallery and status |

[Architecture](docs/ARCHITECTURE.md) · [Contributing](docs/CONTRIBUTING.md) · [Changes](CHANGELOG.md)

## Author and resources

**Francisco Aravena · P4NX0Z** · [soporteinfo.net](https://soporteinfo.net)

[Credits and provenance](CREDITS.md). External components retain licenses and trademarks. The general project license and outstanding redistribution permissions must be resolved before publishing this candidate. Private configuration, passwords, logs and machine evidence are excluded from Git and the distribution.
