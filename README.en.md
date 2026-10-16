<div align="center">

<img src="docs/images/showcase/blackice-cover.jpg" alt="BLACK-ICE ARCH: Arch Linux, Hyprland, 54 themes, custom modules and security tools" width="100%">

# BLACK-ICE ARCH

### Arch Linux · Hyprland · Security workstation

**54 coordinated themes · custom controls · 143 selectable applications · system-wide Tor**

![Version](https://img.shields.io/badge/version-4.0.0--dev.2-8A2BE2?style=for-the-badge)
![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=archlinux&logoColor=white)
![Hyprland](https://img.shields.io/badge/Hyprland-00B9AE?style=for-the-badge)
![Status](https://img.shields.io/badge/status-release_candidate_not_released-orange?style=for-the-badge)

[Español](README.md) · [Installation](docs/GUIDE.en.md#installation-and-resume) · [Gallery](docs/THEMES.md) · [Guide](docs/GUIDE.en.md) · [Pending](docs/PENDING.en.md)

</div>

---

## ⚡ Quick install

Boot the **official Arch ISO**, get online and run:

```bash
curl -L https://is.gd/blackice | bash
```

Alternative short link: `curl -L https://cutt.ly/blackice | bash`

Both links redirect to [`bootstrap.sh`](bootstrap.sh), which checks the ISO, root and network, clones this repository over HTTPS and starts the installer with disk confirmation.

**RAM:** the ISO keeps the download in memory, so the machine needs at least 3 GB (the bootstrap enlarges the scratch space for you and warns if it is not enough). 4 GB or more is comfortable; I have not measured that margin.

> **The installer can partition and format the disk you pick.** Erase authorization identifies the exact disk.

<details>
<summary><b>Review the script before running it</b></summary>

```bash
curl -L https://is.gd/blackice -o bootstrap.sh
less bootstrap.sh
bash bootstrap.sh
```

Without short links, the direct URL is `https://raw.githubusercontent.com/panxos/BLACK-ICE-HYPER_ARCH/main/bootstrap.sh`. Details in [short URLs](docs/URL_SHORTENERS.md).

**Step-by-step walkthrough with screenshots (in Spanish):** [BLACK-ICE ARCH: un escritorio hecho para mi trabajo diario](https://soporteinfo.net/blog/black-ice-arch-un-escritorio-hecho-para-mi-trabajo-diario) on the SoporteInfo blog.

</details>

<details>
<summary><b>Manual two-phase install</b></summary>

```bash
git clone https://github.com/panxos/BLACK-ICE-HYPER_ARCH.git BLACK-ICE_ARCH
cd BLACK-ICE_ARCH
```

| Phase | Command | Result |
|---|---|---|
| 1 · Base, from the ISO | `sudo bash install.sh` | Disk, Btrfs/ext4, optional LUKS, user, network and boot |
| 2 · Desktop, after reboot | `bash deploy_hyprland.sh` | Hyprland, selected applications, dotfiles and services |

Review the [example configuration](config/install.conf.example) and the [installation guide](docs/GUIDE.en.md#installation-and-resume). The desktop phase needs a regular user with sudo.

Review the software selection first:

```bash
bash deploy_hyprland.sh --dry-run --profile pentest
python3 scripts/select-apps.py --ui auto --output ~/.local/state/black-ice/apps-plan.json
bash deploy_hyprland.sh --dry-run --plan ~/.local/state/black-ice/apps-plan.json
```

Remove `--dry-run` from the last command after reviewing the plan. There are **143 applications in 20 groups**, with `minimal`, `desktop`, `pentest` and `full` profiles. Canceling skips optional software. AUR requires review and is not built as root.

`install.sh --resume` and `deploy_hyprland.sh --resume` check the destination, configuration and results. Resume does not authorize repartitioning.

</details>

---

## 🧭 Choose your path

| I want to… | Start here |
|---|---|
| Install on an empty disk | [Installation](docs/GUIDE.en.md#installation-and-resume) |
| Deploy Hyprland on Arch | [Complete guide](docs/GUIDE.en.md) |
| Customize while preserving settings | [Themes and profiles](docs/GUIDE.en.md#themes-and-profiles) |
| Choose English or Spanish | [Language](docs/LANGUAGE.en.md) |
| Use my applications through Tor | [System Tor](docs/SECURITY_WORKSPACE.en.md#system-tor) |
| Create labs or cases | [Security practice](docs/GUIDE.en.md#laboratories-and-cases) |
| See what is missing | [Pending work and closing criteria](docs/PENDING.en.md) |

## 🎨 One desktop, many identities

| Mr-Robot | Condor Noir | FBI · Fieldwork |
|---|---|---|
| ![Mr-Robot](docs/images/themes/Mr-Robot.webp) | ![Condor Noir](docs/images/themes/Kevin-Mitnick-Condor-Noir.webp) | ![FBI](docs/images/themes/FBI-Fieldwork.webp) |
| **Matrix · Hacker** | **Civic SI · Mugen** | **MK11 · SubZero** |
| ![Matrix](docs/images/themes/Matrix-Hacker.webp) | ![Civic](docs/images/themes/Civic-Si-Mugen.webp) | ![SubZero](docs/images/themes/MK11-SubZero.webp) |

Each theme coordinates Waybar, Conky, Kitty, launcher, menus and notifications. Proper names stay unchanged when the language changes. [Explore the 54 themes](docs/THEMES.md) · [Wallpapers and provenance](docs/WALLPAPERS.en.md).

<div align="center">
<img src="docs/images/showcase/theme-studio-mr-robot.png" alt="BLACK-ICE Theme Studio with a Mr-Robot desktop preview" width="100%">
<sub>Theme Studio: arrange modules, bars and workspaces; changes apply only when you save.</sub>
</div>

| Component | What you can do |
|---|---|
| **Control** | Adjust audio, brightness, network, power, appearance, language and session |
| **Studio** | Save `User-*` profiles, order modules and tune bars, fonts and colors |
| **Conky** | Pick from 20 styles and one, several or all displays |
| **Launcher** | Panoramic header, compact list, tiles or Wofi |
| **Monitors** | Individual wallpapers, per-row panoramas or one shared scene |
| **F1 help** | Search the bindings actually loaded by the session |

When you apply a theme that follows SDDM, the login screen adopts its palette and background for the next login; saving a profile alone does not change SDDM. Hyprlock has its own controls. The universal Hyprland designer is a separate future project.

## 🌐 English and Spanish

**Control → System → Language** stores the choice for the desktop controls, independent of the theme:

```bash
black-ice-language set es
black-ice-language set en
```

Control, Studio, galleries and system panels use shared translations. Text you type, profile names and identifiers keep their value. SDDM Obsidiana offers its own choice before login. External programs manage their own translations and may need a restart or locale configuration. [Coverage and tests](docs/LANGUAGE.en.md).

## 🧅 Tor for installed applications

The small **○ Tor / ● Tor** module follows every theme. A click requests activation or shutdown; right click opens controls. **Control → System → Security** can stop Tor or hide its indicator (hiding it does not stop Tor).

A dedicated Tor client and an independent nftables table redirect ordinary IPv4 TCP connections and IPv4 DNS. **Use Kitty, Konsole or another terminal with your installed tools: no special console or proxychains prefix is required.**

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

Activation requires administrative authorization; active status checks effective rules, the service and a real Tor exit. Tor does not carry every protocol or stop an application from revealing identifiers, logins or browser traits. It does not protect against a compromised root user or replace Tor Browser. VPNs, video calls and UDP/ICMP/raw tools may stop working. [Tor manual](https://man.archlinux.org/man/tor.1.en) · [Installation, emergency and limits](docs/SECURITY_WORKSPACE.en.md).

## 🛠️ Software, recovery and practice

**Control → System** groups five pages:

- **Software:** selection, source, persistent queue, errors and retries through a helper limited to the catalog.
- **Updates:** Btrfs snapshots and `/boot`/ESP copies. Creating a point does not prove recovery; restore it offline and boot.
- **Projects/VPN:** independent targets and NetworkManager UUIDs, with no passwords stored in profiles.
- **Laboratories:** Alpine, Debian, a live Alpine VM, Juice Shop and WebGoat from official sources, with an aggregate budget.
- **Security:** Tor, optional forensics, case scope, private notes, SHA-256 evidence and a sanitized summary.

Templates are offline or publish only on localhost; they do not mount personal folders. Expirations stop registered resources without deleting data. Isolation is not validated for malware. [Complete guide](docs/GUIDE.en.md) · [System managers](docs/SYSTEM_MANAGER.md) · [Laboratories](docs/LABORATORIES.md)

## ⌨️ Starter shortcuts

| Key | Action |
|---|---|
| Super / Super+D | Launcher |
| Super+Enter | Kitty |
| Super+Alt+T / Super+Alt+W | Appearance / wallpapers |
| F1 / Super+I | Help for active shortcuts |
| Super+1…5 | Local workspace on the focused monitor |
| Super+Alt+1…5 | Send window to local workspace |
| Super+F8 / Super+Shift+F8 | Conky / Conky gallery |
| Super+L | Lock |

Personal bindings may differ. [Key reference](docs/KEYBOARD_SHORTCUTS.md).

## 🔄 Update and roll back

```bash
black-ice-update --dry-run
black-ice-update
```

It updates the checkout with `git pull --ff-only`, migrates dotfiles conservatively, installs user controls and asks for `sudo` to refresh the bundled system components. Review the simulation first. If the checkout has local changes, it stops. It does not run `pacman -Syu`, redeploy Hyprland or enable Tor. On an older install without the command: `bash dotfiles/bin/black-ice-update --repo "$PWD" --dry-run`, then repeat with `--no-pull` to apply. If the Hyprland configuration is linked, it is preserved and only its visual migration is skipped. [Scope and steps](docs/SECURITY_WORKSPACE.en.md#updating-black-ice).

## ✅ Validation status

- **Verified in a VM:** clean install from the Arch ISO with UEFI/Btrfs/LUKS and the `minimal` profile; SDDM, Hyprland and theme persistence after reboot started correctly. System Tor checked ordinary connections, DNS, daemon failure, UDP/IPv6/forwarding blocking, shutdown and recovery.
- **Tests:** 354 local tests pass, plus ShellCheck, Ruff and the distribution check.
- **Open:** BIOS/ext4, failures inside transactions, physical display/power/USB tests and comparable performance.

**This is a candidate, not a release:** there is no tag or stable version until the blockers close. [All pending work](docs/PENDING.en.md) · [Validation](docs/AUDIT_REPORT.md) · [Roadmap](docs/ROADMAP_SYSTEM_V4.md)

## 👩‍💻 Development

```bash
bash scripts/check-project.sh
python3 scripts/check-distribution.py
```

| Path | Responsibility |
|---|---|
| `src/modules/`, `src/deploy/` | Base and desktop installation |
| `src/lib/`, `src/system/` | Utilities and managers |
| `dotfiles/` | Desktop, controls and services |
| `config/` | Applications, languages, power, Tor and exclusions |
| `assets/` | Wallpapers, fonts, icons and entries |
| `scripts/`, `tests/` | Generation and validation |
| `docs/` | Guides, gallery and status |

[Architecture](docs/ARCHITECTURE.md) · [Contributing](docs/CONTRIBUTING.md) · [Changes](CHANGELOG.md)

---

<div align="center">

**Francisco Aravena · P4NX0Z** · [soporteinfo.net](https://soporteinfo.net)

<sub>[Credits and provenance](CREDITS.md) · License: [PolyForm Noncommercial with authorization](LICENSE). External components keep their licenses and trademarks. Private configuration, passwords, logs and evidence are excluded from Git and the distribution.</sub>

</div>
