#!/bin/bash
# modules/05_bootloader.sh ( Robust Install)

banner "PASO 6" "Gestor de Arranque (GRUB)"

log_info "Instalando paquetes GRUB..."
# Nota: Ya instalados en base, pero aseguramos
# Nota: Ya instalados en base, pero aseguramos
pacstrap /mnt grub efibootmgr

# --- VARIABLES POR DEFECTO (FAILSAFE) ---
# Aseguramos que todas las variables tengan valor para evitar crash por 'set -u'
NVME_STABILITY="${NVME_STABILITY:-no}"
ENCRYPT="${ENCRYPT:-false}"
ENABLE_LUKS="${ENABLE_LUKS:-no}"
FILESYSTEM="${FILESYSTEM:-ext4}"
BOOT_MODE="${BOOT_MODE:-UEFI}"
KEYMAP="${KEYMAP:-us}"
# ----------------------------------------

# Obtener UUID de la partición Root (para cryptdevice)
# Si es NVMe, PART_ROOT ya está configurado en 01_disk.sh
log_info "Identificando UUID de la partición raíz (${PART_ROOT:-})..."
# Force refresh of device identifiers to avoid caching issues
udevadm settle
partprobe "$PART_ROOT" 2>/dev/null || true
sleep 2

# Paranoid UUID extraction (Try blkid, fallback to lsblk)
ROOT_UUID=$(blkid -s UUID -o value "${PART_ROOT:-}")
if [ -z "$ROOT_UUID" ]; then
    ROOT_UUID=$(lsblk -no UUID "${PART_ROOT:-}")
fi

if [ -z "$ROOT_UUID" ]; then
    log_warn "No se pudo obtener el UUID de $PART_ROOT. Usando nombre de dispositivo directo."
    ROOT_UUID="${PART_ROOT:-}"
fi

cat <<EOF > /mnt/root/grub_install.sh
#!/bin/bash
set -e

echo "[INFO] Iniciando instalación de GRUB ($BOOT_MODE)..."

# Soporte para cryptodisk debe estar antes de grub-install
if [ "$ENCRYPT" == "true" ] || [ "$ENABLE_LUKS" == "yes" ]; then
    echo "[INFO] Habilitando soporte de disco cifrado en GRUB EARLY..."
    echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub
fi

if [ "$BOOT_MODE" == "UEFI" ]; then
    # Instalación UEFI profesional
    # --- Soporte de Teclado Early (para LUKS) ---
    echo "[INFO] Configurando mapeo de teclado early ($KEYMAP)..."
    mkdir -p /boot/grub/layouts
    # Búsqueda más robusta de keymaps en el sistema de origen
    # Búsqueda más robusta de keymaps en el sistema de origen
    MAP_PATH=\$(find /usr/share/kbd/keymaps/ -type f -name "${KEYMAP}.map.gz" | head -n 1)
    GRUB_KEYMAP_CREATED="false"
    
    if [ -n "\$MAP_PATH" ]; then
        echo "[INFO] Usando mapa: \$MAP_PATH"
        
        # Grub mklayout suele fallar con .gz o formatos de consola directos.
        # Intentamos descomprimir primero
        cp "\$MAP_PATH" /tmp/temp_map.gz
        gunzip /tmp/temp_map.gz
        
        if grub-mklayout -i /tmp/temp_map -o /boot/grub/layouts/default.gkb; then
            GRUB_KEYMAP_CREATED="true"
        else
             echo "[WARN] Fallo al generar layout GRUB. Usando fallback estándar."
        fi
        rm -f /tmp/temp_map
    else
        echo "[WARN] No se encontró el mapa de teclado para GRUB. Usando US por defecto."
    fi
    
    # Escribir comandos de teclado en la configuración de GRUB SOLO si se creó el mapa
    if [ "\$GRUB_KEYMAP_CREATED" == "true" ]; then
        echo "GRUB_TERMINAL_INPUT=at_keyboard" >> /etc/default/grub
        # Instalación con módulos de teclado
        grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=BLACK-ICE --recheck --removable --modules="at_keyboard keylayouts"
    else
        # Fallback seguro sin at_keyboard (usa driver firmware)
        echo "[INFO] Usando driver de teclado genérico (Firmware)..."
        echo "[INFO] NOTA: En este modo, el teclado en GRUB será US (QWERTY)."
        grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=BLACK-ICE --recheck --removable
    fi
else
    # BIOS Legacy install
    echo "[INFO] Instalando GRUB en $DISK (BIOS Legacy)..."
    grub-install --target=i386-pc --modules="part_gpt part_msdos at_keyboard keylayouts" --recheck ${DISK:-}
fi

# Configuración de parámetros del kernel
GRUB_PARAMS="loglevel=3 nvme_load=YES"

# Aplicar fix de estabilidad NVMe si está habilitado
if [ "$NVME_STABILITY" == "yes" ]; then
    echo "[INFO] Habilitando protocolo de estabilidad NVMe (Disable APST)..."
    GRUB_PARAMS="\$GRUB_PARAMS nvme_core.default_ps_max_latency_us=0"
fi

if [ "$ENCRYPT" == "true" ] || [ "$ENABLE_LUKS" == "yes" ]; then
    echo "[INFO] Configurando cifrado LUKS en GRUB..."
    GRUB_PARAMS="\$GRUB_PARAMS cryptdevice=UUID=$ROOT_UUID:cryptroot root=/dev/mapper/cryptroot"
fi

# Aplicar fix de BTRFS subvolume si aplica
if [ "$FILESYSTEM" == "btrfs" ]; then
    echo "[INFO] Aplicando rootflags de BTRFS (@)..."
    GRUB_PARAMS="\$GRUB_PARAMS rootflags=subvol=@"
fi

# Aplicar parámetros a /etc/default/grub
sed -i "s|GRUB_CMDLINE_LINUX_DEFAULT=\".*\"|GRUB_CMDLINE_LINUX_DEFAULT=\"\$GRUB_PARAMS\"|" /etc/default/grub

# Soporte para cryptodisk ya habilitado arriba

# --- ESTÉTICA GRUB (Protocolo Cyberpunk) ---
echo "[INFO] Configurando estética de GRUB..."
# Instalar fuente para evitar errores tipográficos en temas
pacman -S --needed --noconfirm ttf-dejavu

mkdir -p /boot/grub/themes

# Intentar instalar tema Cyberpunk 'Tela'
(
    if command -v git >/dev/null; then
        rm -rf /tmp/grub-themes
        if git clone --depth 1 https://github.com/vinceliuice/grub2-themes.git /tmp/grub-themes; then
            cd /tmp/grub-themes
            # Instalación no interactiva del tema tela (cyberpunk)
            ./install.sh -t tela -s 1080p >/dev/null 2>&1
            
            # Asegurar que la ruta es correcta en /etc/default/grub
            THEME_PATH="/boot/grub/themes/tela/theme.txt"
            if [ -f "\$THEME_PATH" ]; then
                sed -i 's|^#GRUB_THEME=.*|GRUB_THEME="'\$THEME_PATH'"|' /etc/default/grub
                echo "GRUB_THEME=\"\$THEME_PATH\"" >> /etc/default/grub
            fi
        fi
    fi
) || echo "[WARN] Error en la sección de temas. Continuando con GRUB estándar..."

# --- GENERAR CONFIGURACIÓN FINAL ---
echo "[INFO] Generando grub.cfg..."
if ! grub-mkconfig -o /boot/grub/grub.cfg; then
    echo "[ERROR] Fallo al generar grub.cfg"
    exit 1
fi

# --- INYECTAR TECLADO EN GRUB.CFG (Para LUKS Early) ---
if [ "$ENCRYPT" == "true" ] && [ -f /mnt/boot/grub/layouts/default.gkb ]; then
    echo "[INFO] Inyectando comandos de teclado en grub.cfg..."
    # Insertar al principio para que afecte al prompt de password
    # Nota: El comando es 'keymap' pero el modulo es 'keylayouts'
    sed -i "1iinsmod keylayouts\ninsmod at_keyboard\nterminal_input at_keyboard\nkeymap /boot/grub/layouts/default.gkb" /boot/grub/grub.cfg
fi

echo "[SUCCESS] GRUB configurado correctamente."
EOF

chmod +x /mnt/root/grub_install.sh

# Fix root ownership temporarily if needed to ensure execute bit works in chroot
# (Usually not needed but let's be safe)

log_info "Ejecutando configuración de GRUB en el entorno chroot..."
if ! arch-chroot /mnt /root/grub_install.sh; then
    log_error "Error crítico en grub-install. Revisa los mensajes superiores."
    exit 1
fi

rm /mnt/root/grub_install.sh
success "Bootloader (GRUB) configurado con éxito."
