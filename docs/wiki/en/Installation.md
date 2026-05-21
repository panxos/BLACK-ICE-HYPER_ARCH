# 📦 Installation Guide - BLACK-ICE ARCH

This guide walks you through the complete installation of BLACK-ICE ARCH.

---

## 📋 System Requirements

### Minimum Hardware

| Component | Specification |
|-----------|---------------|
| **CPU** | Dual Core 64-bit (x86_64) |
| **RAM** | 4 GB |
| **Storage** | 20 GB SSD |
| **GPU** | Intel/AMD integrated |
| **Network** | WiFi or Ethernet |

### Recommended Hardware

| Component | Specification |
|-----------|---------------|
| **CPU** | Quad Core or better |
| **RAM** | 16 GB or more |
| **Storage** | 100 GB NVMe SSD |
| **GPU** | Dedicated AMD or NVIDIA |
| **Network** | Wired Ethernet (1 Gbps) |

### Required Software

- **Arch Linux ISO** (latest version)
- **Bootable USB** (minimum 2 GB)
- **Internet connection** (required)

---

## 🚀 Method 1: Quick Install (Recommended)

### One Command

The fastest way to install BLACK-ICE ARCH:

```bash
curl -L http://is.gd/blackice | bash
```

### What does bootstrap do?

The `bootstrap.sh` script automatically:

1. ✅ **Verifies environment** - Confirms you're on Arch Linux LiveCD
2. ✅ **Checks Internet** - Verifies connectivity
3. ✅ **Installs dependencies** - Installs git if not present
4. ✅ **Clones repository** - Downloads BLACK-ICE ARCH from GitHub
5. ✅ **Sets permissions** - Makes scripts executable
6. ✅ **Runs installer** - Launches `install.sh` automatically

### Alternative URLs

```bash
# Full GitHub URL
curl -L https://raw.githubusercontent.com/panxos/BLACK-ICE-HYPER_ARCH/main/bootstrap.sh | bash
```

---

## 📦 Method 2: Manual Installation

### Step 1: Prepare Bootable USB

#### On Linux

```bash
# Download Arch Linux ISO
wget https://archlinux.org/iso/latest/archlinux-x86_64.iso

# Identify your USB
lsblk

# Write ISO to USB (replace sdX with your device)
sudo dd bs=4M if=archlinux-x86_64.iso of=/dev/sdX status=progress oflag=sync
```

#### On Windows

1. Download [Rufus](https://rufus.ie/)
2. Select the Arch Linux ISO
3. Select your USB drive
4. Click "START"

### Step 2: Boot from USB

1. Insert the USB into your computer
2. Restart and access the boot menu (F12, F2, DEL, etc.)
3. Select the USB as the boot device
4. Select "Arch Linux install medium" from the GRUB menu

### Step 3: Connect to Internet

#### WiFi

```bash
# Start iwctl
iwctl

# List WiFi devices
device list

# Scan for networks
station wlan0 scan

# List available networks
station wlan0 get-networks

# Connect to your network
station wlan0 connect "YOUR_NETWORK_NAME"

# Exit iwctl
exit

# Verify connection
ping -c 3 archlinux.org
```

#### Ethernet

```bash
# Get IP automatically
dhcpcd

# Verify connection
ping -c 3 archlinux.org
```

### Step 4: Clone Repository

```bash
# Update package database
pacman -Sy

# Install git
pacman -S --needed --noconfirm git

# Clone BLACK-ICE ARCH
git clone https://github.com/panxos/BLACK-ICE-HYPER_ARCH.git

# Enter directory
cd BLACK-ICE-HYPER_ARCH
```

### Step 5: Run Installer

```bash
# Make executable
chmod +x install.sh

# Run installer
./install.sh
```

---

## 🔧 Installation Process

### Phase 1: Environment Check

The installer verifies:

- Operating system (must be Arch Linux)
- Boot mode (UEFI or BIOS)
- Internet connection
- Available disk space

### Phase 2: Disk Selection

```
Available disks:
1. /dev/sda (500 GB SSD)
2. /dev/nvme0n1 (1 TB NVMe)

Select disk for installation: 
```

⚠️ **WARNING**: All data on the selected disk will be **ERASED**.

### Phase 3: User Configuration

You will be prompted for:

- **Hostname**: Your computer name
- **Username**: Your login username
- **Password**: Strong password
- **Timezone**: Your timezone
- **Keyboard**: Layout (default: en)

### Phase 4: Partitioning and Formatting

The installer automatically creates:

#### UEFI Scheme

| Partition | Size | Type | Mount Point |
|-----------|------|------|-------------|
| EFI | 512 MB | FAT32 | /boot/efi |
| Root | Remaining | btrfs/ext4 | / |

#### BIOS Scheme

| Partition | Size | Type | Mount Point |
|-----------|------|------|-------------|
| Boot | 512 MB | ext4 | /boot |
| Root | Remaining | btrfs/ext4 | / |

### Phase 5: Base Installation

The installer installs:

- Arch Linux base system
- Linux kernel
- Essential firmware
- Basic utilities
- Bootloader (GRUB)

**Estimated time**: 10-15 minutes (depends on connection speed)

### Phase 6: System Configuration

- Timezone configuration
- Locale setup
- Keyboard layout
- User creation
- Sudo configuration
- Service enabling

### Phase 7: Bootloader Installation

- GRUB installation
- GRUB configuration
- initramfs generation
- Other OS detection

### Phase 8: Completion

After successful installation, the system reboots automatically.

---

## 🎮 Post-Installation

### First Login

1. **Remove the USB** when the computer restarts
2. **Log in** with your username and password
3. **Connect to Internet** (if using WiFi)

### Deploy Hyprland Environment

```bash
# Navigate to directory
cd BLACK-ICE-HYPER_ARCH

# Run deployment
./deploy_hyprland.sh
```

The deployment script installs:

- ✅ Hyprland and components
- ✅ Waybar with custom configuration
- ✅ SDDM with cybersec theme
- ✅ GTK/Qt themes (Sweet-Dark)
- ✅ Icons (Candy Icons)
- ✅ Fonts (JetBrains Mono Nerd Font)
- ✅ Terminal (Kitty)
- ✅ Security tools (100+ tools)
- ✅ AI CLI tools (Claude Code, Gemini CLI)

**Estimated time**: 30-60 minutes

---

## ✅ Post-Installation Verification

### Verify Hyprland

```bash
hyprctl version
# Should show: Hyprland v0.53.3 or higher
```

### Verify Waybar

```bash
pgrep waybar
# Restart if needed:
killall waybar && sleep 1 && waybar &
```

### Verify Themes

```bash
gsettings get org.gnome.desktop.interface gtk-theme
# Should show: 'Sweet-Dark'
```

### Verify Security Tools

```bash
nmap --version
msfconsole --version
which burpsuite
```

---

## 🔒 Advanced Options

### LUKS Full Disk Encryption

To install with full disk encryption, set in `config/install.conf`:

```bash
ENABLE_LUKS=yes
LUKS_PASSWORD=your_strong_passphrase
```

Or let the installer prompt you interactively.

### Dual Boot with Windows

The installer automatically detects Windows installations and adds them to the GRUB menu.

**Recommendations**:
- Install Windows first
- Leave unpartitioned space for Arch
- The installer will use free space

### Virtual Machine Installation

BLACK-ICE ARCH works perfectly in:
- VMware Workstation/Player
- VirtualBox
- KVM/QEMU
- Hyper-V

The installer auto-detects the VM environment and installs appropriate guest tools.

**Recommended VM configuration**:
- 4 GB RAM minimum (8 GB recommended)
- 2 CPU cores minimum (4 recommended)
- 30 GB disk minimum
- Enable 3D acceleration

---

## 🆘 Troubleshooting

### Error: "Cannot connect to Internet"

```bash
ip link
systemctl restart NetworkManager
dhcpcd
```

### Error: "Disk not found"

```bash
lsblk
fdisk -l
```

### Error: "pacstrap failed"

```bash
# Update mirrors
reflector --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
./install.sh
```

### Error: "GRUB not installing"

```bash
# Check boot mode
[ -d /sys/firmware/efi ] && echo "UEFI" || echo "BIOS"
```

---

## 📚 Additional Resources

- [Arch Linux Installation Guide](https://wiki.archlinux.org/title/Installation_guide)
- [Hyprland Wiki](https://wiki.hyprland.org/)
- [BLACK-ICE ARCH FAQ](FAQ.md)
- [Troubleshooting Guide](Troubleshooting.md)

---

<div align="center">

**[🏠 Back to Wiki](Home.md)** | **[❓ FAQ →](FAQ.md)**

</div>
