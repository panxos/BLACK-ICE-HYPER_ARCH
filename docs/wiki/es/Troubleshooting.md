# 🔧 Solución de Problemas - BLACK-ICE ARCH

Guía completa para resolver problemas comunes en BLACK-ICE ARCH.

---

## 📋 Tabla de Contenidos

- [Problemas de Instalación](#-problemas-de-instalación)
- [Problemas de Red](#-problemas-de-red)
- [Problemas de Display](#-problemas-de-display)
- [Problemas de Audio](#-problemas-de-audio)
- [Problemas de Temas](#-problemas-de-temas)
- [Problemas de Rendimiento](#-problemas-de-rendimiento)
- [Problemas con Herramientas](#-problemas-con-herramientas)
- [Logs y Diagnóstico](#-logs-y-diagnóstico)

---

## 🚨 Problemas de Instalación

### No hay conexión a Internet

**Síntomas**: El instalador no puede descargar paquetes

**Solución WiFi**:

```bash
# Iniciar iwctl
iwctl

# Listar dispositivos
device list

# Escanear redes
station wlan0 scan

# Conectar
station wlan0 connect "TU_RED"

# Salir
exit

# Verificar
ping -c 3 archlinux.org
```

**Solución Ethernet**:

```bash
# Obtener IP
dhcpcd

# Verificar interfaz
ip link
ip addr

# Reiniciar NetworkManager
systemctl restart NetworkManager
```

### Git no encontrado

**Error**: `bash: git: command not found`

**Solución**:

```bash
pacman -Sy git
```

### Error en pacstrap

**Error**: `failed to commit transaction (conflicting files)`

**Solución**:

```bash
# Actualizar mirrors
reflector --country Chile,Argentina,Brazil \
  --age 12 --protocol https --sort rate \
  --save /etc/pacman.d/mirrorlist

# Limpiar cache
pacman -Scc

# Reintentar instalación
./install.sh
```

### GRUB no se instala

**Error**: `grub-install: error: cannot find EFI directory`

**Solución UEFI**:

```bash
# Verificar modo UEFI
[ -d /sys/firmware/efi ] && echo "UEFI" || echo "BIOS"

# Montar partición EFI
mount /dev/sdX1 /boot/efi

# Reinstalar GRUB
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
```

**Solución BIOS**:

```bash
# Instalar en disco (no partición)
grub-install --target=i386-pc /dev/sdX
grub-mkconfig -o /boot/grub/grub.cfg
```

### Disco no detectado

**Síntomas**: El instalador no muestra discos

**Solución**:

```bash
# Listar todos los discos
lsblk
fdisk -l

# Verificar que el disco está conectado
dmesg | grep sd

# Para NVMe
lsblk | grep nvme
```

---

## 🌐 Problemas de Red

### WiFi no funciona después de instalar

**Solución**:

```bash
# Habilitar NetworkManager
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager

# Conectar a red
nmcli device wifi connect "TU_RED" password "TU_PASSWORD"

# Verificar estado
nmcli device status
```

### Ethernet no obtiene IP

**Solución**:

```bash
# Verificar interfaz
ip link show

# Levantar interfaz
sudo ip link set enp0s3 up

# Obtener IP
sudo dhcpcd enp0s3

# O usar NetworkManager
sudo nmcli device connect enp0s3
```

### DNS no resuelve

**Solución**:

```bash
# Verificar resolv.conf
cat /etc/resolv.conf

# Configurar DNS manualmente
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf

# Reiniciar NetworkManager
sudo systemctl restart NetworkManager
```

### VPN no conecta

**Solución**:

```bash
# Instalar OpenVPN
sudo pacman -S openvpn

# Conectar
sudo openvpn --config archivo.ovpn

# Para WireGuard
sudo pacman -S wireguard-tools
sudo wg-quick up wg0
```

---

## 🖥️ Problemas de Display

### Pantalla negra después de instalar

**Causa**: Drivers de GPU o Hyprland no configurado

**Solución**:

```bash
# Desde TTY (Ctrl+Alt+F2)
# Login con tu usuario

# Verificar si Hyprland está instalado
which Hyprland

# Si no está, ejecutar deployment
cd BLACK-ICE_ARCH
./deploy_hyprland.sh

# Habilitar SDDM
sudo systemctl enable sddm
sudo systemctl start sddm
```

### Waybar no aparece

**Solución**:

```bash
# Matar Waybar
killall waybar

# Reiniciar con delay
sleep 1 && waybar &

# Verificar errores
waybar -l debug

# Verificar configuración
cat ~/.config/waybar/config
```

### Resolución incorrecta

**Solución**:

```bash
# Listar monitores
hyprctl monitors

# Editar hyprland.conf
nano ~/.config/hypr/hyprland.conf

# Agregar/modificar
monitor=DP-1,1920x1080@60,0x0,1

# Recargar
hyprctl reload
```

### Múltiples monitores no funcionan

**Solución**:

```bash
# Configurar en hyprland.conf
nano ~/.config/hypr/hyprland.conf

# Ejemplo para 2 monitores
monitor=DP-1,1920x1080@60,0x0,1
monitor=HDMI-A-1,1920x1080@60,1920x0,1

# Recargar
hyprctl reload
```

### Tearing o stuttering

**Solución**:

```bash
# Editar hyprland.conf
nano ~/.config/hypr/hyprland.conf

# Agregar
misc {
    vrr = 1
}

# Recargar
hyprctl reload
```

---

## 🔊 Problemas de Audio

### Sin sonido

**Solución**:

```bash
# Verificar PulseAudio/Pipewire
pactl info

# Listar sinks
pactl list sinks short

# Configurar volumen
pactl set-sink-volume @DEFAULT_SINK@ 50%

# Unmute
pactl set-sink-mute @DEFAULT_SINK@ 0
```

### Audio crackling

**Solución**:

```bash
# Editar daemon.conf
sudo nano /etc/pulse/daemon.conf

# Descomentar y modificar
default-sample-rate = 48000
alternate-sample-rate = 44100

# Reiniciar PulseAudio
systemctl --user restart pulseaudio
```

### Micrófono no funciona

**Solución**:

```bash
# Listar sources
pactl list sources short

# Unmute micrófono
pactl set-source-mute @DEFAULT_SOURCE@ 0

# Configurar volumen
pactl set-source-volume @DEFAULT_SOURCE@ 80%
```

### Cambiar dispositivo de audio

**Solución**:

```bash
# Listar dispositivos
pactl list sinks short

# Cambiar default
pactl set-default-sink NOMBRE_SINK

# Con pavucontrol (GUI)
sudo pacman -S pavucontrol
pavucontrol
```

---

## 🎨 Problemas de Temas

### Aplicaciones KDE no usan tema oscuro

**Solución**:

```bash
# Copiar configuraciones Qt
cp ~/BLACK-ICE_ARCH/dotfiles/qt5ct/qt5ct.conf ~/.config/qt5ct/
cp ~/BLACK-ICE_ARCH/dotfiles/qt6ct/qt6ct.conf ~/.config/qt6ct/

# Verificar variables de entorno
echo $QT_QPA_PLATFORMTHEME
# Debe mostrar: qt6ct

# Reiniciar Hyprland
Super + Shift + R
```

### GTK apps no usan tema

**Solución**:

```bash
# Verificar tema GTK
gsettings get org.gnome.desktop.interface gtk-theme

# Configurar Sweet-Dark
gsettings set org.gnome.desktop.interface gtk-theme 'Sweet-Dark'
gsettings set org.gnome.desktop.interface icon-theme 'candy-icons'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
```

### Iconos no se muestran

**Solución**:

```bash
# Verificar instalación
pacman -Q candy-icons-git

# Reinstalar si es necesario
yay -S candy-icons-git

# Configurar
gsettings set org.gnome.desktop.interface icon-theme 'candy-icons'

# Actualizar cache
gtk-update-icon-cache -f -t ~/.icons/candy-icons
```

### Fuentes se ven mal

**Solución**:

```bash
# Instalar fuentes
sudo pacman -S ttf-jetbrains-mono-nerd

# Configurar en Kitty
nano ~/.config/kitty/kitty.conf

# Modificar
font_family JetBrains Mono Nerd Font

# Recargar Kitty
Ctrl+Shift+F5
```

---

## ⚡ Problemas de Rendimiento

### Alto uso de CPU

**Diagnóstico**:

```bash
# Ver procesos
htop

# Procesos de Hyprland
ps aux | grep -i hypr

# Uso de CPU por proceso
top -o %CPU
```

**Solución**:

```bash
# Deshabilitar animaciones
nano ~/.config/hypr/hyprland.conf

# Modificar
animations {
    enabled = no
}

# Reducir blur
decoration {
    blur {
        enabled = no
    }
}

# Recargar
hyprctl reload
```

### Alto uso de RAM

**Solución**:

```bash
# Ver uso de memoria
free -h

# Limpiar cache
sudo sync
sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'

# Cerrar aplicaciones innecesarias
killall firefox
killall brave
```

### Sistema lento

**Solución**:

```bash
# Verificar swap
swapon --show

# Crear swap si no existe
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Hacer permanente
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### Batería se agota rápido (laptop)

**Solución**:

```bash
# Instalar TLP
sudo pacman -S tlp tlp-rdw

# Habilitar
sudo systemctl enable tlp
sudo systemctl start tlp

# Configurar
sudo nano /etc/tlp.conf

# Reducir brillo
brightnessctl set 50%
```

---

## 🛠️ Problemas con Herramientas

### Herramienta no se encuentra

**Solución**:

```bash
# Verificar instalación
which nombre-herramienta
pacman -Q nombre-herramienta

# Reinstalar
sudo pacman -S nombre-herramienta

# O desde AUR
yay -S nombre-herramienta
```

### Burp Suite no inicia

**Solución**:

```bash
# Verificar Java
java -version

# Instalar JDK si falta
sudo pacman -S jdk-openjdk

# Ejecutar Burp
burpsuite
```

### Metasploit no funciona

**Solución**:

```bash
# Iniciar servicio PostgreSQL
sudo systemctl start postgresql

# Inicializar base de datos
sudo msfdb init

# Ejecutar Metasploit
msfconsole
```

### Wireshark sin permisos

**Solución**:

```bash
# Agregar usuario al grupo wireshark
sudo usermod -aG wireshark $USER

# Relogin o ejecutar
newgrp wireshark

# Configurar permisos
sudo setcap cap_net_raw,cap_net_admin=eip /usr/bin/dumpcap
```

---

## 📊 Logs y Diagnóstico

### Ver logs del sistema

```bash
# Journalctl
sudo journalctl -xe

# Últimos 100 mensajes
sudo journalctl -n 100

# Logs de Hyprland
cat ~/.config/hypr/hyprland.log

# Logs de instalación
cat /var/log/black-ice-install.log
```

### Verificar estado de servicios

```bash
# NetworkManager
systemctl status NetworkManager

# SDDM
systemctl status sddm

# PulseAudio
systemctl --user status pulseaudio
```

### Información del sistema

```bash
# Información general
neofetch
fastfetch

# Hardware
lspci
lsusb
lscpu

# Memoria
free -h

# Disco
df -h
lsblk
```

### Verificar errores de Hyprland

```bash
# Ver configuración actual
hyprctl version
hyprctl monitors
hyprctl workspaces

# Recargar configuración
hyprctl reload

# Ver errores
hyprctl dispatch exit
# Luego revisar logs
```

---

## 🆘 Comandos de Emergencia

### Acceder a TTY

```
Ctrl + Alt + F2  # TTY2
Ctrl + Alt + F1  # Volver a GUI
```

### Reiniciar servicios críticos

```bash
# NetworkManager
sudo systemctl restart NetworkManager

# SDDM
sudo systemctl restart sddm

# PulseAudio
systemctl --user restart pulseaudio pipewire

# Hyprland (desde TTY)
killall Hyprland
Hyprland
```

### Recuperación del sistema

```bash
# Desde LiveCD
# Montar particiones
mount /dev/sdX2 /mnt
mount /dev/sdX1 /mnt/boot/efi

# Chroot
arch-chroot /mnt

# Reparar GRUB
grub-install --target=x86_64-efi --efi-directory=/boot/efi
grub-mkconfig -o /boot/grub/grub.cfg

# Salir y reiniciar
exit
reboot
```

---

## 📞 Obtener Ayuda

### Información para reportar bugs

Cuando reportes un bug, incluye:

```bash
# Información del sistema
uname -a
hyprctl version
pacman -Q | grep hyprland

# Logs relevantes
journalctl -xe | tail -50

# Configuración
cat ~/.config/hypr/hyprland.conf
```

### Recursos adicionales

- [GitHub Issues](https://github.com/panxos/BLACK-ICE-HYPER_ARCH/issues)
- [Arch Linux Wiki](https://wiki.archlinux.org/)
- [Hyprland Wiki](https://wiki.hyprland.org/)
- [FAQ](FAQ.md)

---

<div align="center">

**[🏠 Volver a Wiki](Home.md)** | **[❓ FAQ](FAQ.md)**

**¿No resolvió tu problema? [Abre un issue](https://github.com/panxos/BLACK-ICE-HYPER_ARCH/issues)**

</div>
