# 📦 Guía de Instalación - BLACK-ICE ARCH

Esta guía te llevará paso a paso a través del proceso de instalación de BLACK-ICE ARCH.

---

## 📋 Requisitos del Sistema

### Hardware Mínimo

| Componente | Especificación |
|------------|----------------|
| **CPU** | Dual Core 64-bit (x86_64) |
| **RAM** | 4 GB |
| **Almacenamiento** | 20 GB SSD |
| **GPU** | Intel/AMD integrada |
| **Red** | WiFi o Ethernet |

### Hardware Recomendado

| Componente | Especificación |
|------------|----------------|
| **CPU** | Quad Core o superior |
| **RAM** | 16 GB o más |
| **Almacenamiento** | 100 GB NVMe SSD |
| **GPU** | AMD o NVIDIA dedicada |
| **Red** | Ethernet cableado (1 Gbps) |

### Software Requerido

- **Arch Linux ISO** (última versión)
- **USB booteable** (mínimo 2 GB)
- **Conexión a Internet** (obligatorio)

---

## 🚀 Método 1: Instalación Rápida (Recomendado)

### Un Solo Comando

La forma más rápida de instalar BLACK-ICE ARCH:

```bash
curl -L http://is.gd/blackice | bash
```

### ¿Qué hace el bootstrap?

El script `bootstrap.sh` automáticamente:

1. ✅ **Verifica el entorno** - Confirma que estás en Arch Linux LiveCD
2. ✅ **Comprueba Internet** - Verifica conectividad
3. ✅ **Instala dependencias** - Instala git si no está presente
4. ✅ **Clona el repositorio** - Descarga BLACK-ICE ARCH desde GitHub
5. ✅ **Configura permisos** - Da permisos de ejecución a los scripts
6. ✅ **Ejecuta instalador** - Lanza `install.sh` automáticamente

### URLs Alternativas

```bash
# URL corta cutt.ly
curl -L https://cutt.ly/blackice | bash

# URL completa de GitHub
curl -L https://raw.githubusercontent.com/panxos/BLACK-ICE-HYPER_ARCH/main/bootstrap.sh | bash
```

---

## 📦 Método 2: Instalación Manual

### Paso 1: Preparar USB Booteable

#### En Linux

```bash
# Descargar ISO de Arch Linux
wget https://archlinux.org/iso/latest/archlinux-x86_64.iso

# Identificar tu USB
lsblk

# Escribir ISO al USB (reemplaza sdX con tu dispositivo)
sudo dd bs=4M if=archlinux-x86_64.iso of=/dev/sdX status=progress oflag=sync
```

#### En Windows

1. Descargar [Rufus](https://rufus.ie/)
2. Seleccionar la ISO de Arch Linux
3. Seleccionar tu USB
4. Click en "START"

### Paso 2: Arrancar desde USB

1. Inserta el USB en tu computadora
2. Reinicia y accede al menú de boot (F12, F2, DEL, etc.)
3. Selecciona el USB como dispositivo de arranque
4. Selecciona "Arch Linux install medium" en el menú GRUB

### Paso 3: Conectar a Internet

#### WiFi

```bash
# Iniciar iwctl
iwctl

# Listar dispositivos WiFi
device list

# Escanear redes
station wlan0 scan

# Listar redes disponibles
station wlan0 get-networks

# Conectar a tu red
station wlan0 connect "NOMBRE_DE_TU_RED"

# Salir de iwctl
exit

# Verificar conexión
ping -c 3 archlinux.org
```

#### Ethernet

```bash
# Obtener IP automáticamente
dhcpcd

# Verificar conexión
ping -c 3 archlinux.org
```

### Paso 4: Clonar Repositorio

```bash
# Actualizar base de datos de paquetes
pacman -Sy

# Instalar git
pacman -S --needed --noconfirm git

# Clonar BLACK-ICE ARCH
git clone https://github.com/panxos/BLACK-ICE-HYPER_ARCH.git

# Entrar al directorio
cd BLACK-ICE_ARCH
```

### Paso 5: Ejecutar Instalador

```bash
# Dar permisos de ejecución
chmod +x install.sh

# Ejecutar instalador
./install.sh
```

---

## 🔧 Proceso de Instalación

### Fase 1: Verificación del Entorno

El instalador verificará:

- Sistema operativo (debe ser Arch Linux)
- Modo de arranque (UEFI o BIOS)
- Conexión a Internet
- Espacio en disco disponible

### Fase 2: Selección de Disco

```
Discos disponibles:
1. /dev/sda (500 GB SSD)
2. /dev/nvme0n1 (1 TB NVMe)

Selecciona el disco para instalar: 
```

⚠️ **ADVERTENCIA**: Todos los datos en el disco seleccionado serán **BORRADOS**.

### Fase 3: Configuración de Usuario

Se te pedirá:

- **Hostname**: Nombre de tu computadora
- **Usuario**: Tu nombre de usuario
- **Contraseña**: Contraseña segura
- **Zona horaria**: Tu zona horaria
- **Teclado**: Distribución de teclado (español por defecto)

### Fase 4: Particionado y Formateo

El instalador creará automáticamente:

#### Esquema UEFI

| Partición | Tamaño | Tipo | Punto de montaje |
|-----------|--------|------|------------------|
| EFI | 512 MB | FAT32 | /boot/efi |
| Root | Resto | ext4 | / |

#### Esquema BIOS

| Partición | Tamaño | Tipo | Punto de montaje |
|-----------|--------|------|------------------|
| Boot | 512 MB | ext4 | /boot |
| Root | Resto | ext4 | / |

### Fase 5: Instalación Base

El instalador instalará:

- Sistema base de Arch Linux
- Kernel Linux
- Firmware esencial
- Utilidades básicas
- Bootloader (GRUB)

**Tiempo estimado**: 10-15 minutos (depende de tu conexión)

### Fase 6: Configuración del Sistema

- Configuración de zona horaria
- Configuración de locale (español)
- Configuración de teclado
- Creación de usuario
- Configuración de sudo
- Habilitación de servicios

### Fase 7: Instalación de Bootloader

- Instalación de GRUB
- Configuración de GRUB
- Generación de initramfs
- Detección de otros sistemas operativos

### Fase 8: Finalización

```
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║     ✅ INSTALACIÓN BASE COMPLETADA EXITOSAMENTE           ║
║                                                            ║
║     El sistema se reiniciará en 10 segundos...            ║
║                                                            ║
║     Después del reinicio:                                 ║
║     1. Inicia sesión con tu usuario                       ║
║     2. Ejecuta: cd BLACK-ICE_ARCH                         ║
║     3. Ejecuta: ./deploy_hyprland.sh                      ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
```

---

## 🎮 Post-Instalación

### Primer Inicio de Sesión

1. **Retira el USB** cuando la computadora se reinicie
2. **Inicia sesión** con tu usuario y contraseña
3. **Conecta a Internet** (si usas WiFi)

### Deployment de Hyprland

```bash
# Navegar al directorio
cd BLACK-ICE_ARCH

# Ejecutar deployment
./deploy_hyprland.sh
```

El script de deployment instalará:

- ✅ Hyprland y componentes
- ✅ Waybar con configuración personalizada
- ✅ SDDM con tema cybersec
- ✅ Temas GTK/Qt (Sweet-Dark)
- ✅ Iconos (Candy Icons)
- ✅ Fuentes (JetBrains Mono Nerd Font)
- ✅ Terminal (Kitty)
- ✅ Utilidades y scripts

**Tiempo estimado**: 15-20 minutos

### Instalación de Herramientas de Seguridad

```bash
# Ejecutar instalador interactivo
sudo ./src/deploy/02_security_tools.sh
```

Opciones:

- **Instalación por categorías** - Selecciona categorías completas
- **Instalación individual** - Selecciona herramientas específicas
- **Instalar todo** - Instala las 104 herramientas

**Tiempo estimado**: 30-60 minutos (depende de las herramientas seleccionadas)

---

## ✅ Verificación Post-Instalación

### Verificar Hyprland

```bash
# Verificar versión de Hyprland
hyprctl version

# Debe mostrar: Hyprland v0.53.3 o superior
```

### Verificar Waybar

```bash
# Verificar que Waybar está corriendo
pgrep waybar

# Reiniciar Waybar si es necesario
killall waybar && sleep 1 && waybar &
```

### Verificar Temas

```bash
# Verificar tema GTK
gsettings get org.gnome.desktop.interface gtk-theme
# Debe mostrar: 'Sweet-Dark'

# Verificar iconos
gsettings get org.gnome.desktop.interface icon-theme
# Debe mostrar: 'candy-icons'
```

### Verificar Herramientas

```bash
# Verificar nmap
nmap --version

# Verificar metasploit
msfconsole --version

# Verificar burpsuite
which burpsuite
```

---

## 🔒 Opciones Avanzadas

### Cifrado LUKS (Opcional)

Para instalar con cifrado de disco completo:

```bash
# Ejecutar instalador con opción de cifrado
ENCRYPT=yes ./install.sh
```

Se te pedirá una contraseña de cifrado fuerte.

### Dual Boot con Windows

El instalador detectará automáticamente instalaciones de Windows y las agregará al menú de GRUB.

**Recomendaciones**:

- Instala Windows primero
- Deja espacio sin particionar para Arch
- El instalador usará el espacio libre

### Instalación en Máquina Virtual

BLACK-ICE ARCH funciona perfectamente en:

- VMware Workstation/Player
- VirtualBox
- KVM/QEMU
- Hyper-V

**Configuración recomendada para VM**:

- 4 GB RAM mínimo (8 GB recomendado)
- 2 CPU cores mínimo (4 recomendado)
- 30 GB disco mínimo
- Habilitar 3D acceleration

---

## 🆘 Solución de Problemas

### Error: "No se puede conectar a Internet"

```bash
# Verificar interfaz de red
ip link

# Reiniciar NetworkManager
systemctl restart NetworkManager

# Intentar conexión manual
dhcpcd
```

### Error: "Disco no encontrado"

```bash
# Listar todos los discos
lsblk

# Verificar que el disco está detectado
fdisk -l
```

### Error: "Fallo en pacstrap"

```bash
# Actualizar mirrors
reflector --country Chile,Argentina,Brazil --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# Reintentar instalación
./install.sh
```

### Error: "GRUB no se instala"

```bash
# Verificar modo de arranque
[ -d /sys/firmware/efi ] && echo "UEFI" || echo "BIOS"

# Para UEFI, verificar partición EFI
lsblk -f | grep vfat

# Para BIOS, verificar que el disco es correcto
fdisk -l
```

---

## 📚 Recursos Adicionales

- [Arch Linux Installation Guide](https://wiki.archlinux.org/title/Installation_guide)
- [Hyprland Wiki](https://wiki.hyprland.org/)
- [BLACK-ICE ARCH FAQ](FAQ.md)
- [Troubleshooting Completo](Troubleshooting.md)

---

<div align="center">

**[🏠 Volver a Wiki](Home.md)** | **[⚙️ Configuración →](Configuracion.md)**

</div>
