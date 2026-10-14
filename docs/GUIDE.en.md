# BLACK-ICE ARCH user guide

[Español](GUIDE.md) · [Documentation](README.en.md) · [Pending work](PENDING.en.md)

This guide covers candidate 4.0.0-dev.2. The remote branch may contain an older revision. Evaluate the full installation in a disposable VM before using a machine with personal data.

## Installation and resume

Run the base phase as root from an official Arch ISO. Select the disk, filesystem, optional encryption, user and boot method. Erase confirmation identifies the disk. Local configuration comes from `config/install.conf.example`; passwords and private plans do not belong in Git.

After reboot, log in as the created user and run `bash deploy_hyprland.sh`. Deployment prepares repositories, Hyprland, terminal settings, themes, software, SDDM and services. Application selection supports profiles, groups and individual packages. Canceling skips optional software. Review AUR sources before automating them.

```bash
bash deploy_hyprland.sh --dry-run --profile minimal
bash deploy_hyprland.sh --profile minimal
bash deploy_hyprland.sh --resume
```

`--resume` checks fingerprints, destination identity and results before skipping modules. It does not automatically repeat partitioning. If pacman is busy, inspect or wait for its process; do not remove its lock. Expired sudo authorization triggers normal authentication.

## First login

Open Control from the gear or **Super+Alt+T**. System includes audio, brightness and [language](LANGUAGE.en.md). Appearance contains themes, launcher, wallpaper and Conky. Network and Bluetooth read available services; missing hardware is not shown as connected.

**Super+Enter** opens Kitty; **Super** or **Super+D** opens the launcher. **F1** reads loaded shortcuts. Personal bindings may differ, so that window is the session reference.

## Themes and profiles

The [gallery](THEMES.md) contains 54 themes. Applying one coordinates bars, terminal, menus, notifications and wallpapers. Originals remain available when creating profiles.

Start with a base theme in Studio, name your profile and adjust:

| Tab | Purpose |
|---|---|
| Profiles | Load, import/export and restore profiles |
| Positions | Arrange modules by zone and move Conky |
| Bars | Layout, geometry, height and opacity |
| Fonts and colors | Desktop/data typography and palette |
| Modules | Show, hide and restore modules |
| Wallpaper and Conky | Images, display geometry and telemetry |
| Login | Preview and prepare SDDM for the next login |

**Save profile** writes the profile. **Save and apply** also changes the desktop. Preview values are illustrative. Deleting a custom profile moves it to trash while preserving its wallpaper. Switch away from the active theme before deleting it.

Conky **Apply** keeps the gallery open. Choose one automatic display, every display or a list. Missing sensors are not fabricated: virtual machines display usage data or N/A as appropriate.

## Displays, wallpaper and workspaces

One display uses an individual image. Automatic panoramas split per row; Single scene spans the geometric union of displays. A laptop below the main row can retain a separate wallpaper in row mode. Mixed scaling and physical reconnection still require the checks listed under [pending work](PENDING.en.md).

Each display has five local workspaces. **Super+1…5** switches on the focused display; **Super+Alt+1…5** moves the window. Persistent identifiers keep workspace groups stable across reconnection.

## System Tor

The Tor button transparently proxies IPv4 TCP and DNS. Use your existing terminals and installed tools; the isolated Tor console was removed. IPv6, other UDP and forwarded guest traffic are blocked. Filtering remains if Tor fails; explicitly disabling Tor restores normal connectivity.

**Control → System → Security** provides shutdown and indicator visibility. Hiding the indicator does not disable Tor. Read [scope, setup and emergency instructions](SECURITY_WORKSPACE.en.md) before activation. This does not protect against malware, compromised root access or identification through application content.

## Software and recovery

The software center lists the catalog, sources, selection and jobs. The queue preserves failures and retries. An executable check does not prove every application function. Review dependency effects before removals or updates.

Whole-system recovery requires Btrfs with the supported layout. A point contains a root snapshot and boot/ESP archives. Restore from an ISO while the destination is offline and confirm the identifier. Verification requires a subsequent boot. Dotfile rollback does not recover packages, kernels or the ESP.

## Laboratories and cases

Choose a template and name in Laboratories, check requirements, then confirm **Create and open**. Alpine provides lightweight command practice; Debian includes Bash; Alpine live tests a VM; Juice Shop and WebGoat offer web exercises on localhost only. Import calculates a hash, but that hash does not establish image provenance.

The default budget is 4 vCPU, 4096 MiB RAM and 60 GiB reserved disks. Preparation shares a managed cache and checks limits; it does not impose a continuous filesystem quota. New resources have configurable expiration: the service stops them while retaining definitions and data. Deletion is separate.

Create a case in Security with authorized targets and an optional NetworkManager VPN UUID. Check scope/VPN before working. Import regular evidence files for SHA-256 copies and a chained log. Sanitized summaries omit identifying data and notes. They are not digital signatures and do not control external tools. Forensic profiles remain optional and have separate readiness checks. [Security workspace](SECURITY_WORKSPACE.en.md).

## Power, notifications and diagnostics

Automatic power mode distinguishes AC and battery. The existing policy limits suspend to battery; authentication is not weakened to fix visual issues. Verify suspend and reconnection on physical hardware.

The notification center keeps history. USB notifications offer file-manager/terminal actions; physical reconnection remains under acceptance. Docker and VM indicators appear when their tools are present, with periodic detection.

```bash
black-ice-doctor
black-ice-doctor --json
bash tests/post-install-validate.sh
```

Doctor checks specific components. Run installation validation as the desktop user. Passing does not replace physical testing or the full installation matrix.

## Reviewed updates

```bash
bash dotfiles/bin/dotfiles-update --no-pull --dry-run
bash dotfiles/bin/dotfiles-update --no-pull
```

Inspect the plan and retain rollback manifests. Lua migration prepares the next login without forcing the current session to close. Use [selective updates](SECURITY_WORKSPACE.en.md#updating-the-controls) for the new controls.

## Before publication

Run `bash scripts/check-project.sh`; all GTK tests run in Xvfb so test windows do not open on your desktop. Inspect the distribution and review [every remaining task](PENDING.en.md). The matrix, transaction failures, hardware, comparable performance and licensing still require acceptance. This candidate is neither declared bug-free nor a published release.
