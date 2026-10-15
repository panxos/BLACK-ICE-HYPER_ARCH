#!/bin/bash
install_stage 4 'Idioma, región y sistema'
# modules/03_config.sh ( Plymouth Hooks)


if [ "${AUTO_MODE:-}" == "true" ]; then
    # Fallback for SYSTEM_LOCALE if not defined
    SYSTEM_LOCALE="${SYSTEM_LOCALE:-${SYSTEM_LANG:-es_CL}}"
    success "Configuración del sistema en modo automatizado:"
    success "  - Timezone: ${TIMEZONE:-}"
    success "  - Lang: ${SYSTEM_LANG:-}"
    success "  - Locale: ${SYSTEM_LOCALE:-${SYSTEM_LANG:-}}"
    success "  - Hostname: ${HOSTNAME:-}"
else
    # --- LANGUAGE & LOCALE SELECTION ---
    print_step 'Idioma y formatos regionales'
    echo -e "${CYAN}Puedes elegir el idioma del sistema (menús, errores) y${NC}"
    echo -e "${CYAN}el formato regional independiente (moneda, fecha, etc.)${NC}\n"

    # System Language
    echo -e "${BOLD}1. Idioma del Sistema (UI/Logs):${NC}"
    SYSTEM_LANG=$(ask_option "Elige el idioma del sistema:" "en_US" "es_CL" "es_ES")
    
    # Regional Formats (Defaulted by selected country)
    DEFAULT_LOCALE="es_CL"
    case "${SELECTED_COUNTRY:-}" in
        "United States") DEFAULT_LOCALE="en_US" ;;
        "Spain")         DEFAULT_LOCALE="es_ES" ;;
        "Brazil")        DEFAULT_LOCALE="pt_BR" ;;
        "Germany")       DEFAULT_LOCALE="de_DE" ;;
    esac

    echo -e "\n${BOLD}2. Formatos Regionales (Moneda/Fecha):${NC}"
    echo -e "${GREY}(Basado en tu elección de ${SELECTED_COUNTRY:-})${NC}"
    SYSTEM_LOCALE=$(ask_option "Confirma o elige los formatos regionales:" "$DEFAULT_LOCALE" "en_US" "es_CL" "es_ES")
    
    success "Configuración de localización fijada: Lang=$SYSTEM_LANG | Locale=$SYSTEM_LOCALE"
fi

# Fstab
log_info "Generando fstab..."
if grep -q "UUID=" /mnt/etc/fstab 2>/dev/null; then
    log_info "fstab ya contiene entradas — omitiendo regeneración"
else
    genfstab -U /mnt > /mnt/etc/fstab
fi
if [[ "${FILESYSTEM:-}" == btrfs ]]; then
    sed -i -E 's/(,?)subvolid=[0-9]+(,?)/\1/g; s/,,+/,/g' /mnt/etc/fstab
fi

# Chroot config setup with safe escaping
cat <<EOF > /mnt/root/chroot_config.sh
#!/bin/bash
set -e

# Escaped variables
TIMEZONE=$(printf '%q' "${TIMEZONE:-America/Santiago}")
SYSTEM_LANG=$(printf '%q' "${SYSTEM_LANG:-es_CL}")
SYSTEM_LOCALE=$(printf '%q' "${SYSTEM_LOCALE:-es_CL}")
KEYMAP=${KEYMAP:-es}
HOSTNAME=$(printf '%q' "${HOSTNAME:-black-ice}")

# Timezone
ln -sf "/usr/share/zoneinfo/\$TIMEZONE" /etc/localtime
hwclock --systohc

# Localization
grep -Fxq "\$SYSTEM_LANG.UTF-8 UTF-8" /etc/locale.gen || echo "\$SYSTEM_LANG.UTF-8 UTF-8" >> /etc/locale.gen
if [ "\$SYSTEM_LANG" != "\$SYSTEM_LOCALE" ]; then
    grep -Fxq "\$SYSTEM_LOCALE.UTF-8 UTF-8" /etc/locale.gen || echo "\$SYSTEM_LOCALE.UTF-8 UTF-8" >> /etc/locale.gen
fi
grep -Fxq "es_ES.UTF-8 UTF-8" /etc/locale.gen || echo "es_ES.UTF-8 UTF-8" >> /etc/locale.gen
grep -Fxq "en_US.UTF-8 UTF-8" /etc/locale.gen || echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen

# Set Language
echo "LANG=\$SYSTEM_LANG.UTF-8" > /etc/locale.conf
# Set Regional Formats if different
if [ "\$SYSTEM_LANG" != "\$SYSTEM_LOCALE" ]; then
    {
        echo "LC_ADDRESS=\$SYSTEM_LOCALE.UTF-8"
        echo "LC_IDENTIFICATION=\$SYSTEM_LOCALE.UTF-8"
        echo "LC_MEASUREMENT=\$SYSTEM_LOCALE.UTF-8"
        echo "LC_MONETARY=\$SYSTEM_LOCALE.UTF-8"
        echo "LC_NAME=\$SYSTEM_LOCALE.UTF-8"
        echo "LC_NUMERIC=\$SYSTEM_LOCALE.UTF-8"
        echo "LC_PAPER=\$SYSTEM_LOCALE.UTF-8"
        echo "LC_TELEPHONE=\$SYSTEM_LOCALE.UTF-8"
        echo "LC_TIME=\$SYSTEM_LOCALE.UTF-8"
    } >> /etc/locale.conf
fi

# vconsole.conf — teclado para consola, initramfs (LUKS) y SDDM
echo "KEYMAP=${KEYMAP:-es}" > /etc/vconsole.conf
if [ -f /usr/share/kbd/consolefonts/lat2-16.psfu.gz ]; then
    echo 'FONT=lat2-16' >> /etc/vconsole.conf
fi

# Verify vconsole creation
if [ ! -f /etc/vconsole.conf ]; then
    echo "[ERROR] Could not create /etc/vconsole.conf"
    exit 1
fi

# Hostname
echo "\$HOSTNAME" > /etc/hostname
grep -Fxq "127.0.0.1   localhost" /etc/hosts || echo "127.0.0.1   localhost" >> /etc/hosts
grep -Fxq "::1         localhost" /etc/hosts || echo "::1         localhost" >> /etc/hosts
grep -Fxq "127.0.1.1   \$HOSTNAME.localdomain \$HOSTNAME" /etc/hosts || echo "127.0.1.1   \$HOSTNAME.localdomain \$HOSTNAME" >> /etc/hosts

exit 0
EOF

# --- NETWORK PERSISTENCE (CRITICAL FOR WIFI) ---
log_info "Transfiriendo configuraciones de red (Wi-Fi persistence)..."
if [ -d /etc/NetworkManager/system-connections ]; then
    mkdir -p /mnt/etc/NetworkManager/system-connections
    cp -r /etc/NetworkManager/system-connections/* /mnt/etc/NetworkManager/system-connections/ 2>/dev/null || true
    chmod 600 /mnt/etc/NetworkManager/system-connections/* 2>/dev/null || true
    log_info "Credenciales NetworkManager transferidas."
fi

# Persistencia directa de IWD (iwctl)
if [ -d /var/lib/iwd ]; then
    mkdir -p /mnt/var/lib/iwd
    cp -r /var/lib/iwd/*.psk /mnt/var/lib/iwd/ 2>/dev/null || true
    chmod 600 /mnt/var/lib/iwd/*.psk 2>/dev/null || true
    log_info "Credenciales IWD (iwctl) transferidas."
    
    # : Migración Inteligente IWD -> NetworkManager
    # Convierte las credenciales activas del instalador a perfiles nativos de NM
    log_info "Migrando perfiles de IWD a NetworkManager (Auto-Connect)..."
    mkdir -p /mnt/etc/NetworkManager/system-connections
    
    if compgen -G "/var/lib/iwd/*.psk" > /dev/null; then
        for psk_file in /var/lib/iwd/*.psk; do
            [ -e "$psk_file" ] || continue
            
            # Extract SSID and Passphrase
            SSID=$(basename "$psk_file" .psk)
            # Intentar leer Passphrase (formato [Security])
            PASSPHRASE=$({ grep "Passphrase=" "$psk_file" || true; } | cut -d= -f2 | tr -d '\r')
            
            if [ -n "$PASSPHRASE" ]; then
                # Generar UUID único
                UUID=$(uuidgen)
                
                cat <<NM_EOF > "/mnt/etc/NetworkManager/system-connections/${SSID}.nmconnection"
[connection]
id=${SSID}
uuid=${UUID}
type=wifi
permissions=

[wifi]
mac-address-blacklist=
mode=infrastructure
ssid=${SSID}

[wifi-security]
auth-alg=open
key-mgmt=wpa-psk
psk=${PASSPHRASE}

[ipv4]
dns-search=
method=auto

[ipv6]
addr-gen-mode=stable-privacy
dns-search=
method=auto
NM_EOF
                chmod 600 "/mnt/etc/NetworkManager/system-connections/${SSID}.nmconnection"
                log_success "Perfil WiFi '${SSID}' convertido a NetworkManager."
            fi
        done
    else
        log_info "No se detectaron perfiles activos de IWD para migrar."
    fi
fi

# Configurar NetworkManager para usar IWD como backend
mkdir -p /mnt/etc/NetworkManager/conf.d
cat > /mnt/etc/NetworkManager/conf.d/wifi_backend.conf <<EOF
[device]
wifi.backend=iwd
EOF
log_info "NetworkManager configurado para usar iwd."

log_info "Sincronizando configuración regional y de red en chroot..."
arch-chroot /mnt /bin/bash /root/chroot_config.sh
rm /mnt/root/chroot_config.sh

# Initramfs (Standard + Encryption)
# Initramfs (Nuclear Option for NVMe/VMD + Universal Support)
# Agregamos módulos comunes para que el script sea universal (Intel, AMD, VM, USB-C)
UNIVERSAL_MODULES="vmd nvme xhci_pci usb_storage sd_mod atkbd intel_agp i915 amdgpu radeon virtio virtio_pci virtio_blk"
sed -i "s/^MODULES=.*/MODULES=($UNIVERSAL_MODULES)/" /mnt/etc/mkinitcpio.conf

# Order matters: base udev autodetect modconf block keyboard keymap consolefont
SED_HOOKS="base udev autodetect modconf block keyboard keymap consolefont"

if [ "${ENCRYPT:-}" == "true" ]; then
    SED_HOOKS="$SED_HOOKS encrypt"
fi

SED_HOOKS="$SED_HOOKS filesystems fsck"

log_info "Configurando hooks en /etc/mkinitcpio.conf..."
sed -i "s/^HOOKS=.*/HOOKS=($SED_HOOKS)/" /mnt/etc/mkinitcpio.conf

# Generate Initramfs (with verification)
# Step 1: Verify kernel presets exist (kernel package installed)
if [ ! -f "/mnt/etc/mkinitcpio.d/${SELECTED_KERNEL:-linux}.preset" ]; then
    log_error "CRÍTICO: No se encontró preset de kernel. El paquete '${SELECTED_KERNEL:-linux}' no se instaló correctamente."
    log_error "Verifica la conexión de red y ejecuta 'pacstrap /mnt ${SELECTED_KERNEL:-linux} ${SELECTED_KERNEL:-linux}-headers' manualmente."
    exit 1
fi

# Step 2: Run mkinitcpio with Self-Healing Logic
log_info "Generando initramfs (Protocolo de Resiliencia)..."

# Intentar generar initramfs
if ! arch-chroot /mnt /bin/bash -c "mkinitcpio -P"; then
    log_warn "Fallo detectado en mkinitcpio (posible corrupción o Bus Error)."
    log_info "Iniciando protocolo de auto-reparación: Re-sincronizando núcleo y herramientas..."
    
    # Reparación: Limpiar cache y forzar re-instalación de componentes de arranque
    arch-chroot /mnt /bin/bash -c "pacman -Syu --needed --noconfirm ${SELECTED_KERNEL:-linux} ${SELECTED_KERNEL:-linux}-headers linux-firmware mkinitcpio"
    
    log_info "Reintentando generación de initramfs tras reparación..."
    if ! arch-chroot /mnt /bin/bash -c "mkinitcpio -P"; then
        log_error "Error CRÍTICO: mkinitcpio sigue fallando tras auto-reparación."
        exit 1
    fi
fi

# Step 3: Validate initramfs was generated
if [ ! -f "/mnt/boot/initramfs-${SELECTED_KERNEL:-linux}.img" ]; then
     log_error "Error crítico: No se generó el archivo de imagen en /boot."
     exit 1
fi
log_info "Initramfs verificado y activo."

# --- SNAPPER CONFIGURATION (BTRFS only) ---
if [ "${FILESYSTEM:-}" == "btrfs" ]; then
    log_info "Configurando Snapper para BTRFS..."
    
    # Instalar snapper
    pacstrap /mnt snapper
    
    # Crear configuración de snapper en chroot
    arch-chroot /mnt /bin/bash << SNAPPER_EOF
set -euo pipefail
# Crear configuración de snapper para root
new_config=false
if [ ! -f /etc/snapper/configs/root ]; then
    new_config=true
    umount /.snapshots 2>/dev/null || true
    rmdir /.snapshots || { echo "Snapshots existentes: se conserva su contenido"; exit 1; }
    snapper --no-dbus -c root create-config /
    btrfs subvolume delete /.snapshots
    mkdir /.snapshots
    mount -a
fi

# Configurar políticas de snapper
if [[ "\$new_config" == true ]]; then
cat > /etc/snapper/configs/root << EOF
SUBVOLUME="/"
FSTYPE="btrfs"
QGROUP=""
SPACE_LIMIT="0.5"
FREE_LIMIT="0.2"
ALLOW_USERS=""
ALLOW_GROUPS=""
SYNC_ACL="no"
BACKGROUND_COMPARISON="yes"
NUMBER_CLEANUP="yes"
NUMBER_MIN_AGE="1800"
NUMBER_LIMIT="50"
NUMBER_LIMIT_IMPORTANT="10"
TIMELINE_CREATE="yes"
TIMELINE_CLEANUP="yes"
TIMELINE_MIN_AGE="1800"
TIMELINE_LIMIT_HOURLY="5"
TIMELINE_LIMIT_DAILY="7"
TIMELINE_LIMIT_WEEKLY="0"
TIMELINE_LIMIT_MONTHLY="0"
TIMELINE_LIMIT_YEARLY="0"
EMPTY_PRE_POST_CLEANUP="yes"
EMPTY_PRE_POST_MIN_AGE="1800"
EOF
fi

python3 - <<'VALIDATE_SNAPSHOT_USERS'
import grp
import pwd
import re
import shlex
from pathlib import Path

path = Path('/etc/snapper/configs/root')
content = path.read_text()
for key, lookup in (('ALLOW_USERS', pwd.getpwnam), ('ALLOW_GROUPS', grp.getgrnam)):
    match = re.search(r'^' + key + r'=(.*)$', content, re.MULTILINE)
    if not match:
        continue
    tokens = shlex.split(match.group(1), comments=True)
    names = tokens[0].split() if tokens else []
    valid = []
    for name in names:
        try:
            lookup(name)
            valid.append(name)
        except KeyError:
            print('Snapper: se retira referencia a identidad inexistente:', name)
    if valid != names:
        content = re.sub(r'^' + key + r'=.*$', key + '="' + ' '.join(valid) + '"', content, flags=re.MULTILINE)
path.write_text(content)
VALIDATE_SNAPSHOT_USERS

python3 - <<'REGISTER_CONFIG'
from pathlib import Path
import re
import shlex

path = Path('/etc/conf.d/snapper')
content = path.read_text() if path.exists() else ''
match = re.search(r'^SNAPPER_CONFIGS=(.*)$', content, re.MULTILINE)
tokens = shlex.split(match.group(1), comments=True) if match else []
names = tokens[0].split() if tokens else []
if not all(re.fullmatch(r'[A-Za-z0-9_.-]+', name) for name in names):
    raise ValueError('Registro Snapper inválido; no se sobrescribió')
if 'root' not in names:
    names.append('root')
    value = 'SNAPPER_CONFIGS="' + ' '.join(names) + '"'
    content = re.sub(r'^SNAPPER_CONFIGS=.*$', value, content, flags=re.MULTILINE) if match else content.rstrip() + '\n' + value + '\n'
    path.write_text(content)
REGISTER_CONFIG

snapper --no-dbus -c root get-config >/dev/null
btrfs subvolume show /.snapshots >/dev/null

# Crear hooks de pacman para snapshots automáticos (DENTRO DEL SISTEMA DESTINO)
mkdir -p /etc/pacman.d/hooks

# Hook PRE-transacción
cat > /etc/pacman.d/hooks/00-snapper-pre.hook << EOF
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Package
Target = *

[Action]
Description = Creando snapshot pre-pacman con snapper...
When = PreTransaction
Exec = /usr/bin/snapper --no-dbus --config root create --cleanup-algorithm number --description "pacman pre-transaction"
EOF

# Hook POST-transacción
cat > /etc/pacman.d/hooks/99-snapper-post.hook << EOF
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Package
Target = *

[Action]
Description = Creando snapshot post-pacman con snapper...
When = PostTransaction
Exec = /usr/bin/snapper --no-dbus --config root create --cleanup-algorithm number --description "pacman post-transaction"
EOF

# Habilitar timers de snapper
systemctl enable snapper-timeline.timer
systemctl enable snapper-cleanup.timer

SNAPPER_EOF

    success "Snapper configurado con hooks de Pacman automáticos"
else
    log_info "Sistema de archivos ${FILESYSTEM:-} detectado - Snapper solo funciona con BTRFS, omitiendo configuración"
fi

# --- PACMAN CUSTOMIZATION (Colors + ILoveCandy) ---
log_info "Configurando Pacman (colores y animación)..."
arch-chroot /mnt /bin/bash << 'PACMAN_EOF'
# Habilitar Color e ILoveCandy en pacman.conf
sed -i 's/^#Color$/Color/' /etc/pacman.conf
sed -i '/^Color$/a ILoveCandy' /etc/pacman.conf
# Habilitar parallel downloads
sed -i 's/^#ParallelDownloads = 5$/ParallelDownloads = 5/' /etc/pacman.conf
PACMAN_EOF

# Enable Services (Inside Chroot)
log_info "Habilitando servicios (SSHD, NetworkManager)..."
arch-chroot /mnt /bin/bash << 'SERVICES_EOF'
systemctl enable NetworkManager
systemctl enable sshd
systemctl enable iwd
sed -i 's/^#PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
SERVICES_EOF

success "Sistema configurado (Locales, Hostname, Initramfs, Snapper, Pacman)"
