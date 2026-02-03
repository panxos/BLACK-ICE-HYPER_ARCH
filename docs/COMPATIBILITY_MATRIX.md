![BLACK-ICE ARCH Banner](images/banner.png)

# BLACK-ICE ARCH - Compatibility Matrix

## Platform Support

BLACK-ICE ARCH has been tested and verified to work across multiple virtualization platforms and bare metal hardware. The installer automatically detects the environment and applies optimized configurations.

### ✅ Fully Supported Platforms

| Platform | Disk Detection | Graphics | Guest Tools | Auto-Config | Status |
|----------|----------------|----------|-------------|-------------|--------|
| **Bare Metal** | ✅ SATA/NVMe/MMC | ✅ Native GPU | N/A | ✅ Yes | **Verified** |
| **KVM/QEMU** | ✅ VirtIO (/dev/vda) | ✅ WLR Fix | qemu-guest-agent | ✅ Yes | **Verified** |
| **Xen** | ✅ Xen (/dev/xvda) | ✅ WLR Fix | xe-guest-utilities | ✅ Yes | **Verified** |
| **VMware** | ✅ SATA/NVMe | ✅ WLR Fix | open-vm-tools | ✅ Yes | **Verified** |
| **VirtualBox** | ✅ SATA | ✅ WLR Fix | virtualbox-guest-utils | ✅ Yes | **Verified** |
| **Hyper-V** | ✅ SCSI/VirtIO | ✅ WLR Fix | hyperv | ✅ Yes | **Verified** |

### Disk Support Matrix

| Disk Type | Device Path | Partition Naming | Supported |
|-----------|-------------|------------------|-----------|
| SATA/SCSI | `/dev/sda` | `/dev/sda1`, `/dev/sda2` | ✅ |
| NVMe | `/dev/nvme0n1` | `/dev/nvme0n1p1`, `/dev/nvme0n1p2` | ✅ |
| VirtIO (KVM) | `/dev/vda` | `/dev/vda1`, `/dev/vda2` | ✅ |
| Xen Virtual | `/dev/xvda` | `/dev/xvda1`, `/dev/xvda2` | ✅ |
| MMC/eMMC | `/dev/mmcblk0` | `/dev/mmcblk0p1`, `/dev/mmcblk0p2` | ✅ |

## Hardware Detection

### CPU Microcode

- **Intel**: Automatically installs `intel-ucode`
- **AMD**: Automatically installs `amd-ucode`

### Graphics Optimization

#### Bare Metal

- Native GPU drivers (Intel, AMD, NVIDIA)
- Full hardware acceleration
- No cursor workarounds needed

#### Virtual Machines

- **Automatic Detection**: Uses `systemd-detect-virt`
- **Graphics Fix**: Injects `WLR_NO_HARDWARE_CURSORS=1` in:
  - `~/.zprofile` (session-wide)
  - `~/.config/hypr/hyprland.conf` (Hyprland-specific)
- **Prevents**: Black screen, cursor flickering, rendering issues

### Virtualization-Specific Packages

```bash
# KVM/QEMU
qemu-guest-agent

# Xen
xe-guest-utilities

# VMware
open-vm-tools
xf86-video-vmware

# VirtualBox
virtualbox-guest-utils

# Hyper-V
hyperv
```

## Boot Modes

| Mode | Partition Scheme | Bootloader | Supported |
|------|------------------|------------|-----------|
| **UEFI** | GPT (EFI 512MB + Root) | GRUB with LUKS | ✅ |
| **BIOS Legacy** | GPT (BIOS Boot 8MB + Root) | GRUB with LUKS | ✅ |

## Encryption Support

- **LUKS2**: Full disk encryption with PBKDF2
- **Encrypted Boot**: GRUB unlocks LUKS partition
- **Keyboard Layout**: US layout in GRUB (pre-boot), configurable post-boot

## Filesystem Support

| Filesystem | Snapshots | Compression | Recommended Use |
|------------|-----------|-------------|-----------------|
| **btrfs** | ✅ Yes | ✅ zstd | **Recommended** (snapshots) |
| **ext4** | ❌ No | ❌ No | Stable, traditional |
| **xfs** | ❌ No | ❌ No | High performance |
| **f2fs** | ❌ No | ❌ No | Flash storage optimized |

## Network Requirements

### Installation

- Active internet connection (Ethernet or WiFi)
- Access to Arch Linux mirrors
- Access to BlackArch repository
- Access to Chaotic-AUR

### Post-Installation

- NetworkManager (auto-configured)
- WiFi persistence via `nmcli`
- Bluetooth via `bluez` + `blueman`

## Known Limitations

### VMware/VirtualBox

- 3D acceleration may be limited
- Requires `WLR_NO_HARDWARE_CURSORS=1` (auto-applied)
- Recommended: 4GB+ RAM, 2+ CPU cores

### Xen

- Requires PV or HVM with PV drivers
- VirtIO disk drivers recommended

### Hyper-V

- Generation 2 VMs recommended (UEFI)
- Secure Boot must be disabled

## Verification Commands

Test your environment after installation:

```bash
# Check virtualization type
systemd-detect-virt

# Verify disk detection
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT

# Check graphics environment variable
echo $WLR_NO_HARDWARE_CURSORS

# Verify guest tools (if VM)
systemctl status qemu-guest-agent  # KVM
systemctl status vmtoolsd           # VMware
systemctl status vboxservice        # VirtualBox
```

## Troubleshooting

### Black Screen on VM

**Symptom**: Hyprland starts but screen is black or flickering  
**Solution**: Verify `WLR_NO_HARDWARE_CURSORS=1` is set

```bash
grep WLR_NO_HARDWARE_CURSORS ~/.zprofile
```

### Disk Not Detected

**Symptom**: Installer doesn't show your disk  
**Solution**: Verify disk type is supported

```bash
lsblk -d -o NAME,SIZE,MODEL
```

### GRUB Keyboard Layout

**Symptom**: Can't type LUKS password in GRUB  
**Solution**: GRUB uses US layout. If your password has special characters (like `-`), use the US key position.

---

**Last Updated**: 2026-02-03  
**Tested Platforms**: Bare Metal, KVM, Xen, VMware Workstation 17, VirtualBox 7.0, Hyper-V (Windows 11)
