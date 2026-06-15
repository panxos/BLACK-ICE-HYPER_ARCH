#!/bin/bash
# modules/05_bootloader.sh (Precision Bootloader Setup)

banner "PASO 6" "Gestor de Arranque (GRUB)"

# --- Asegurar Paquetes ---
log_info "Instalando paquetes críticos para el arranque..."
pacstrap /mnt grub efibootmgr ttf-dejavu 2>/dev/null

# --- Sincronización de Variables ---
: "${PART_ROOT:?PART_ROOT no está definido — abortando bootloader}"
NVME_STABILITY="${NVME_STABILITY:-no}"
ENCRYPT="${ENCRYPT:-false}"
ENABLE_LUKS="${ENABLE_LUKS:-no}"
FILESYSTEM="${FILESYSTEM:-ext4}"
BOOT_MODE="${BOOT_MODE:-UEFI}"
KEYMAP="${KEYMAP:-es}" # Usamos el keymap seleccionado

# Obtener UUID de la partición Root
udevadm settle
partprobe "$PART_ROOT" 2>/dev/null || true
sleep 1

ROOT_UUID=$(blkid -s UUID -o value "$PART_ROOT")
[ -z "$ROOT_UUID" ] && ROOT_UUID=$(lsblk -no UUID "$PART_ROOT")
if [ -z "$ROOT_UUID" ]; then
    log_error "No se pudo obtener UUID de $PART_ROOT — verifica que la partición existe"
    exit 1
fi

# --- Generación del Script de Chroot ---
cat <<EOF > /mnt/root/grub_setup.sh
#!/bin/bash
set -e

echo "[INFO] Iniciando configuración de GRUB ($BOOT_MODE)..."

# 1. Configuración de Teclado Early (Protocolo SOTA)
# Intentamos generar el mapa de teclado para GRUB
mkdir -p /boot/grub/layouts

# Buscamos el mapa de teclado en el sistema
MAP_PATH=\$(find /usr/share/kbd/keymaps/ -type f -name "${KEYMAP}.map.gz" 2>/dev/null | head -n 1)

if [ -n "\$MAP_PATH" ]; then
    echo "[INFO] Generando layout de teclado GRUB: ${KEYMAP} (\$MAP_PATH)"
    if zcat "\$MAP_PATH" | grub-mklayout -o /boot/grub/layouts/terminal_layout.gkb; then
        echo "[OK] Layout GRUB generado correctamente para: ${KEYMAP}"
    else
        echo "[WARN] grub-mklayout falló para '${KEYMAP}'. El menú GRUB usará teclado US."
        rm -f /boot/grub/layouts/terminal_layout.gkb
    fi
else
    echo "[WARN] No se encontró '${KEYMAP}.map.gz' en /usr/share/kbd/keymaps/. El menú GRUB usará teclado US."
fi

# 2. Configuración de /etc/default/grub
# Habilitar soporte de disco cifrado si aplica
if [ "$ENCRYPT" == "true" ] || [ "$ENABLE_LUKS" == "yes" ]; then
    echo "[INFO] Habilitando soporte de disco cifrado (CRYPTODISK)..."
    echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub
fi

# Parámetros del Kernel
GRUB_PARAMS="loglevel=3 quiet"
if [ "$ENCRYPT" == "true" ] || [ "$ENABLE_LUKS" == "yes" ]; then
    GRUB_PARAMS="\$GRUB_PARAMS cryptdevice=UUID=$ROOT_UUID:cryptroot root=/dev/mapper/cryptroot"
fi
[ "$FILESYSTEM" == "btrfs" ] && GRUB_PARAMS="\$GRUB_PARAMS rootflags=subvol=@"
[ "$NVME_STABILITY" == "yes" ] && GRUB_PARAMS="\$GRUB_PARAMS nvme_core.default_ps_max_latency_us=0"
# Deep sleep S3 para laptops
if [[ -d /sys/class/power_supply/BAT0 ]] || [[ -d /sys/class/power_supply/BAT1 ]]; then
    GRUB_PARAMS="\$GRUB_PARAMS mem_sleep_default=deep"
fi

sed -i "s|GRUB_CMDLINE_LINUX_DEFAULT=\".*\"|GRUB_CMDLINE_LINUX_DEFAULT=\"\$GRUB_PARAMS\"|" /etc/default/grub

# Configurar terminal de entrada
if [ -f /boot/grub/layouts/terminal_layout.gkb ]; then
    sed -i "s/#GRUB_TERMINAL_INPUT=console/GRUB_TERMINAL_INPUT=at_keyboard/" /etc/default/grub
    echo "insmod keylayouts" >> /etc/grub.d/40_custom
    echo "keymap /boot/grub/layouts/terminal_layout.gkb" >> /etc/grub.d/40_custom
fi

# 3. Solucionar error de 'console font'
echo "[INFO] Generando fuente unicode para GRUB..."
mkdir -p /boot/grub/fonts
grub-mkfont -s 16 -o /boot/grub/fonts/unicode.pf2 /usr/share/fonts/TTF/DejaVuSans.ttf 2>/dev/null || true

# 4. Instalación de GRUB
if [ "$BOOT_MODE" == "UEFI" ]; then
    echo "[INFO] Ejecutando grub-install (UEFI)..."
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=BLACK-ICE --recheck --removable --modules="at_keyboard keylayouts"
else
    echo "[INFO] Ejecutando grub-install (BIOS)..."
    grub-install --target=i386-pc --recheck $DISK --modules="at_keyboard keylayouts"
fi

# 5. Generar configuración final
echo "[INFO] Generando grub.cfg..."
grub-mkconfig -o /boot/grub/grub.cfg

echo "[SUCCESS] Configuración de arranque completada."
EOF

# --- Ejecución del Script ---
chmod +x /mnt/root/grub_setup.sh
log_info "Ejecutando configuración de GRUB en el entorno chroot..."

if ! arch-chroot /mnt /root/grub_setup.sh; then
    log_error "Fallo crítico en la configuración de GRUB."
    exit 1
fi

rm /mnt/root/grub_setup.sh
success "Gestor de Arranque configurado exitosamente."
