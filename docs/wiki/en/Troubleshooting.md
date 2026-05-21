# 🔧 Troubleshooting - BLACK-ICE ARCH

Complete guide for resolving common issues in BLACK-ICE ARCH.

---

## 📋 Table of Contents

- [Installation Issues](#-installation-issues)
- [Network Issues](#-network-issues)
- [Display Issues](#-display-issues)
- [Audio Issues](#-audio-issues)
- [Theme Issues](#-theme-issues)
- [Performance Issues](#-performance-issues)
- [Tool Issues](#-tool-issues)
- [Logs & Diagnostics](#-logs--diagnostics)

---

## 🚨 Installation Issues

### No Internet Connection

**Symptom**: Installer can't download packages

**WiFi fix**:

```bash
iwctl
device list
station wlan0 scan
station wlan0 get-networks
station wlan0 connect "YOUR_NETWORK"
exit
ping -c 3 archlinux.org
```

**Ethernet fix**:

```bash
dhcpcd
ip link
ip addr
systemctl restart NetworkManager
```

### Git Not Found

**Error**: `bash: git: command not found`

```bash
pacman -Sy git
```

### pacstrap Failed

**Error**: `failed to commit transaction (conflicting files)`

```bash
# Update mirrors
reflector --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# Clear cache
pacman -Scc

# Retry
./install.sh
```

### GRUB Not Installing

**Error**: `grub-install: error: cannot find EFI directory`

**UEFI fix**:

```bash
[ -d /sys/firmware/efi ] && echo "UEFI" || echo "BIOS"

mount /dev/sdX1 /boot/efi
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
```

**BIOS fix**:

```bash
grub-install --target=i386-pc /dev/sdX
grub-mkconfig -o /boot/grub/grub.cfg
```

### Disk Not Detected

```bash
lsblk
fdisk -l
dmesg | grep sd
lsblk | grep nvme
```

---

## 🌐 Network Issues

### WiFi Not Working After Install

```bash
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager
nmcli device wifi connect "YOUR_NETWORK" password "YOUR_PASSWORD"
nmcli device status
```

### Ethernet Not Getting IP

```bash
ip link show
sudo ip link set enp0s3 up
sudo dhcpcd enp0s3
# Or use NetworkManager:
sudo nmcli device connect enp0s3
```

### DNS Not Resolving

```bash
cat /etc/resolv.conf
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf
sudo systemctl restart NetworkManager
```

### VPN Not Connecting

```bash
# OpenVPN
sudo pacman -S openvpn
sudo openvpn --config file.ovpn

# WireGuard
sudo pacman -S wireguard-tools
sudo wg-quick up wg0
```

---

## 🖥️ Display Issues

### Black Screen After Install

From TTY (Ctrl+Alt+F2):

```bash
which Hyprland   # check if installed
cd BLACK-ICE-HYPER_ARCH
./deploy_hyprland.sh

sudo systemctl enable sddm
sudo systemctl start sddm
```

### Waybar Not Appearing

```bash
killall waybar
sleep 1 && waybar &
waybar -l debug          # check errors
cat ~/.config/waybar/config
```

### Wrong Resolution

```bash
hyprctl monitors
nano ~/.config/hypr/hyprland.conf

# Add/modify:
monitor=DP-1,1920x1080@60,0x0,1

hyprctl reload
```

### Multi-Monitor Not Working

```bash
nano ~/.config/hypr/hyprland.conf

# Example 2 monitors:
monitor=DP-1,1920x1080@60,0x0,1
monitor=HDMI-A-1,1920x1080@60,1920x0,1

hyprctl reload
```

### Tearing / Stuttering

```bash
nano ~/.config/hypr/hyprland.conf

# Add:
misc {
    vrr = 1
}

hyprctl reload
```

---

## 🔊 Audio Issues

### No Sound

```bash
pactl info
pactl list sinks short
pactl set-sink-volume @DEFAULT_SINK@ 50%
pactl set-sink-mute @DEFAULT_SINK@ 0
```

### Audio Crackling

```bash
sudo nano /etc/pulse/daemon.conf

# Uncomment and set:
default-sample-rate = 48000
alternate-sample-rate = 44100

systemctl --user restart pulseaudio
```

### Microphone Not Working

```bash
pactl list sources short
pactl set-source-mute @DEFAULT_SOURCE@ 0
pactl set-source-volume @DEFAULT_SOURCE@ 80%
```

### Change Audio Device

```bash
pactl list sinks short
pactl set-default-sink SINK_NAME

# GUI option:
sudo pacman -S pavucontrol
pavucontrol
```

---

## 🎨 Theme Issues

### KDE Apps Not Using Dark Theme

```bash
cp ~/BLACK-ICE-HYPER_ARCH/dotfiles/qt5ct/qt5ct.conf ~/.config/qt5ct/
cp ~/BLACK-ICE-HYPER_ARCH/dotfiles/qt6ct/qt6ct.conf ~/.config/qt6ct/

echo $QT_QPA_PLATFORMTHEME   # should show: qt6ct
# Super + Shift + R to reload Hyprland
```

### GTK Apps Not Using Theme

```bash
gsettings get org.gnome.desktop.interface gtk-theme

gsettings set org.gnome.desktop.interface gtk-theme 'Sweet-Dark'
gsettings set org.gnome.desktop.interface icon-theme 'candy-icons'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
```

### Icons Not Showing

```bash
pacman -Q candy-icons-git
paru -S candy-icons-git

gsettings set org.gnome.desktop.interface icon-theme 'candy-icons'
gtk-update-icon-cache -f -t ~/.icons/candy-icons
```

### Fonts Look Bad

```bash
sudo pacman -S ttf-jetbrains-mono-nerd

nano ~/.config/kitty/kitty.conf
# Set: font_family JetBrains Mono Nerd Font

# Ctrl+Shift+F5 to reload Kitty
```

---

## ⚡ Performance Issues

### High CPU Usage

```bash
htop
ps aux | grep -i hypr
top -o %CPU
```

Disable animations:

```bash
nano ~/.config/hypr/hyprland.conf

animations {
    enabled = no
}

decoration {
    blur {
        enabled = no
    }
}

hyprctl reload
```

### High RAM Usage

```bash
free -h
sudo sync
sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'
```

### Slow System (No Swap)

```bash
# For btrfs (needs nodatacow):
sudo btrfs subvolume create /swap
sudo truncate -s 0 /swap/swapfile
sudo chattr +C /swap/swapfile
sudo fallocate -l 4G /swap/swapfile
sudo chmod 600 /swap/swapfile
sudo mkswap /swap/swapfile
sudo swapon /swap/swapfile

# For ext4:
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make permanent:
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### Battery Draining Fast (Laptop)

```bash
sudo pacman -S tlp tlp-rdw
sudo systemctl enable tlp
sudo systemctl start tlp
brightnessctl set 50%
```

---

## 🛠️ Tool Issues

### Tool Not Found

```bash
which tool-name
pacman -Q tool-name

sudo pacman -S tool-name
# Or from AUR:
paru -S tool-name
```

### Burp Suite Won't Start

```bash
java -version
sudo pacman -S jdk-openjdk
burpsuite
```

### Metasploit Not Working

```bash
sudo systemctl start postgresql
sudo msfdb init
msfconsole
```

### Wireshark Permission Denied

```bash
sudo usermod -aG wireshark $USER
newgrp wireshark
sudo setcap cap_net_raw,cap_net_admin=eip /usr/bin/dumpcap
```

---

## 📊 Logs & Diagnostics

### View System Logs

```bash
sudo journalctl -xe
sudo journalctl -n 100
cat ~/.config/hypr/hyprland.log
cat ~/black_ice_install.log
```

### Check Service Status

```bash
systemctl status NetworkManager
systemctl status sddm
systemctl --user status pulseaudio
```

### System Information

```bash
fastfetch
lspci && lsusb && lscpu
free -h
df -h && lsblk
```

### Hyprland Debug

```bash
hyprctl version
hyprctl monitors
hyprctl workspaces
hyprctl reload
```

---

## 🆘 Emergency Commands

### Access TTY

```
Ctrl + Alt + F2   # TTY2
Ctrl + Alt + F1   # Back to GUI
```

### Restart Critical Services

```bash
sudo systemctl restart NetworkManager
sudo systemctl restart sddm
systemctl --user restart pulseaudio pipewire
```

### System Recovery (from LiveCD)

```bash
mount /dev/sdX2 /mnt
mount /dev/sdX1 /mnt/boot/efi
arch-chroot /mnt

# Repair GRUB:
grub-install --target=x86_64-efi --efi-directory=/boot/efi
grub-mkconfig -o /boot/grub/grub.cfg

exit
reboot
```

### Report a Bug

Include this info in your report:

```bash
uname -a
hyprctl version
pacman -Q | grep hyprland
journalctl -xe | tail -50
```

---

<div align="center">

**[🏠 Back to Wiki](Home.md)** | **[❓ FAQ](FAQ.md)**

**Problem not solved? [Open an issue](https://github.com/panxos/BLACK-ICE-HYPER_ARCH/issues)**

</div>
