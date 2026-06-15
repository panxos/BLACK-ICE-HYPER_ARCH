#!/bin/bash
# modules/01_disk.sh


if [ -n "${TARGET_DISK:-}" ]; then
    # Modo automatizado
    DISK="/dev/$TARGET_DISK"
    
    if [ ! -b "$DISK" ]; then
        log_error "El disco $DISK no existe."
        exit 1
    fi
    
    log_warn "ATENCIÓN: EL DISCO $DISK SERÁ FORMATEADO. TODOS LOS DATOS SE PERDERÁN."
    success "Disco seleccionado: $DISK (modo automatizado)"
    
    # Configuración de cifrado desde variables
    if [ "${ENABLE_LUKS:-}" == "yes" ]; then
        ENCRYPT="true"
        LUKS_PASS="${LUKS_PASSWORD:-}"
        if [ -z "$LUKS_PASS" ]; then
            log_error "ENABLE_LUKS=yes pero LUKS_PASSWORD está vacío en install.conf — abortando"
            exit 1
        fi
        success "Cifrado LUKS habilitado (modo automatizado)"
    else
        ENCRYPT="false"
        log_info "Cifrado LUKS deshabilitado (modo automatizado)"
    fi
    
    success "Sistema de archivos: ${FILESYSTEM:-} (modo automatizado)"
    
else
    # Modo interactivo
    
    # Obtener lista de discos (incluye SATA/NVMe/VirtIO/Xen)
    # Soporta: /dev/sda, /dev/nvme*, /dev/vda (KVM), /dev/xvda (Xen), /dev/mmcblk*
    print_step "ESCANEANDO HARDWARE: UNIDADES DISPONIBLES"
    mapfile -t DISK_LIST < <(lsblk -d -n -o NAME,SIZE,MODEL | grep -E "^(sd|nvme|vd|xvd|mmcblk)" | grep -v "loop" | grep -v "sr0")
    
    if [ ${#DISK_LIST[@]} -eq 0 ]; then
        log_error "No se encontraron unidades de almacenamiento."
        exit 1
    fi

    # Mostrar menú numerado Cyberpunk
    PS3=$(echo -e "\n${NEON_BLUE}[DISK]${NC} Selecciona el índice de la unidad: ")
    select d_opt in "${DISK_LIST[@]}"; do
        if [ -n "$d_opt" ]; then
            DISK_NAME=$(echo "$d_opt" | awk '{print $1}')
            DISK="/dev/$DISK_NAME"
            success "Unidad fijada en: ${NEON_BLUE}$DISK${NC}"
            break
        else
            log_warn "Índice no válido. Reintenta."
        fi
    done < /dev/tty
    
    if [ ! -b "$DISK" ]; then
        log_error "La unidad $DISK ha dejado de estar disponible."
        exit 1
    fi
    
    while true; do
        echo -e "\n${RED}╔══════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║${NC}  ${BOLD}¡ADVERTENCIA DE SEGURIDAD!                          ${NC} ${RED}║${NC}"
        echo -e "${RED}╠══════════════════════════════════════════════════════╣${NC}"
        echo -e "${RED}║${NC}  La unidad ${BOLD}$DISK${NC} será purgada completamente.      ${RED}║${NC}"
        echo -e "${RED}║${NC}  Todos los datos serán eliminados permanentemente.   ${RED}║${NC}"
        echo -e "${RED}╚══════════════════════════════════════════════════════╝${NC}"
        
        echo -ne "${YELLOW}[CONFIRM]${NC} Escribe ${BOLD}SI${NC} para continuar o ${BOLD}NO${NC} para abortar: "
        read -r CONFIRM < /dev/tty
        
        if [ "$CONFIRM" == "SI" ]; then
            log_info "Autorización concedida. Iniciando purga de datos..."
            break
        elif [ "$CONFIRM" == "NO" ]; then
            log_error "Protocolo de instalación cancelado por el operador."
            exit 0
        else
            log_error "Respuesta inválida. Se requiere confirmación explícita (SI/NO)."
            echo ""
        fi
    done
    
    # Encryption Choice
    
    if [[ $(ask_option "¿Deseas cifrar el núcleo del sistema? (Recomendado)" "Si" "No") == "Si" ]]; then
        ENCRYPT="true"
        echo -e "\n${NEON_PURPLE}┌────────────────────────────────────────────────────────┐${NC}"
        echo -e "${NEON_PURPLE}│${NC}  ${BOLD}PROTOCOLO DE SEGURIDAD: CIFRADO COMPLETO DE DISCO     ${NC} ${NEON_PURPLE}│${NC}"
        echo -e "${NEON_PURPLE}└────────────────────────────────────────────────────────┘${NC}"
        echo -e "${CYAN}Esta contraseña protege tu privacidad y archivos. Se te${NC}"
        echo -e "${CYAN}solicitará cada vez que enciendas el equipo.${NC}"
        echo -e "${YELLOW}¡IMPORTANTE! Si la pierdes, NO podrás recuperar tus datos.${NC}\n"
        while true; do
            LUKS_PASS=$(read_password "${NEON_BLUE}[LUKS]${NC} Establezca la contraseña de cifrado de disco: ")
            LUKS_PASS_CONFIRM=$(read_password "${NEON_BLUE}[LUKS]${NC} Confirme la contraseña de cifrado: ")
            if [ "$LUKS_PASS" == "$LUKS_PASS_CONFIRM" ] && [ -n "$LUKS_PASS" ]; then
                success "Contraseña de cifrado validada y sincronizada."
                break
            else
                log_error "Las contraseñas no coinciden o están vacías. Reintente."
            fi
        done
    else
        ENCRYPT="false"
        log_warn "Continuando sin cifrado de grado militar."
    fi
    
    # Filesystem Choice
    echo -e "${NEON_PURPLE}Recomendado: btrfs (Soporta Snapshots del Sistema)${NC}"
    
    FILESYSTEM=$(ask_option "Elige el sistema de archivos:" "btrfs" "ext4" "xfs" "f2fs")
    success "Arquitectura seleccionada: ${NEON_BLUE}$FILESYSTEM${NC}"
fi

# --- PARTITIONING ---
log_info "Iniciando particionado de $DISK..."
# Wipe functionality
wipefs -a "$DISK" >/dev/null 2>&1

# Layout
# UEFI: 1. EFI (512M) 2. ROOT (Rest)
# BIOS: 1. BIOS Boot (8M) 2. ROOT (Rest) [GPT Scheme]
sgdisk -Z "$DISK" >/dev/null 2>&1

if [ "$BOOT_MODE" == "UEFI" ]; then
    log_info "Protocolo UEFI activo: EFI (512M) + ROOT (MAX)..."
    sgdisk -n 1:0:+512M -t 1:ef00 "$DISK" >/dev/null 2>&1
    sgdisk -n 2:0:0     -t 2:8300 "$DISK" >/dev/null 2>&1
    
    PART_BOOT="${DISK}1"
    PART_ROOT="${DISK}2"
else
    log_info "Protocolo BIOS Legacy activo: BIOS Boot (8M) + ROOT (MAX)..."
    sgdisk -n 1:0:+8M   -t 1:ef02 "$DISK" >/dev/null 2>&1
    sgdisk -n 2:0:0     -t 2:8300 "$DISK" >/dev/null 2>&1
    
    PART_BIOS="${DISK}1"
    PART_ROOT="${DISK}2"
fi

# NVMe/MMC detection (use 'p' separator)
if [[ "$DISK" == *"nvme"* ]] || [[ "$DISK" == *"mmcblk"* ]]; then
    if [ "$BOOT_MODE" == "UEFI" ]; then
        PART_BOOT="${DISK}p1"
        PART_ROOT="${DISK}p2"
    else
        PART_BIOS="${DISK}p1"
        PART_ROOT="${DISK}p2"
    fi
# VirtIO/Xen detection (NO 'p' separator - use direct numbering)
elif [[ "$DISK" == *"vd"* ]] || [[ "$DISK" == *"xvd"* ]]; then
    if [ "$BOOT_MODE" == "UEFI" ]; then
        PART_BOOT="${DISK}1"
        PART_ROOT="${DISK}2"
    else
        PART_BIOS="${DISK}1"
        PART_ROOT="${DISK}2"
    fi
else
    # SATA estándar (/dev/sda, /dev/sdb, etc.) — sin prefijo 'p'
    if [ "$BOOT_MODE" == "UEFI" ]; then
        PART_BOOT="${DISK}1"
        PART_ROOT="${DISK}2"
    else
        PART_BIOS="${DISK}1"
        PART_ROOT="${DISK}2"
    fi
fi

# --- FORMATTING ---
if [ "$BOOT_MODE" == "UEFI" ]; then
    log_info "Formateando partición de arranque EFI..."
    mkfs.fat -F32 "$PART_BOOT" >/dev/null 2>&1
fi

if [ "$ENCRYPT" == "true" ]; then
    log_info "Iniciando despliegue de contenedor LUKS..."
    if ! cryptsetup -q luksFormat "$PART_ROOT" --type luks2 --pbkdf pbkdf2 <<< "$LUKS_PASS"; then
        log_error "LUKS encryption failed — luksFormat returned non-zero"
        exit 1
    fi
    if ! cryptsetup open "$PART_ROOT" cryptroot <<< "$LUKS_PASS"; then
        log_error "LUKS encryption failed — could not open cryptroot"
        exit 1
    fi
    ROOT_DEV="/dev/mapper/cryptroot"
else
    ROOT_DEV="$PART_ROOT"
fi

log_info "Aplicando sistema de archivos $FILESYSTEM..."
case "$FILESYSTEM" in
    btrfs)
        mkfs.btrfs -f "$ROOT_DEV" >/dev/null 2>&1
        mount "$ROOT_DEV" /mnt
        btrfs subvolume create /mnt/@ >/dev/null 2>&1
        btrfs subvolume create /mnt/@home >/dev/null 2>&1
        btrfs subvolume create /mnt/@snapshots >/dev/null 2>&1
        btrfs subvolume create /mnt/@var_log >/dev/null 2>&1
        btrfs subvolume create /mnt/@audit >/dev/null 2>&1
        btrfs subvolume create /mnt/@pkg >/dev/null 2>&1
        
        umount /mnt
        mount -o noatime,compress=zstd,subvol=@ "$ROOT_DEV" /mnt
        mkdir -p /mnt/{home,.snapshots,var/log,var/cache/pacman/pkg,boot}
        mount -o noatime,compress=zstd,subvol=@home "$ROOT_DEV" /mnt/home
        mount -o noatime,compress=zstd,subvol=@snapshots "$ROOT_DEV" /mnt/.snapshots
        mount -o noatime,compress=zstd,subvol=@var_log "$ROOT_DEV" /mnt/var/log
        
        mkdir -p /mnt/var/log/audit
        mount -o noatime,compress=zstd,subvol=@audit "$ROOT_DEV" /mnt/var/log/audit
        mount -o noatime,compress=zstd,subvol=@pkg "$ROOT_DEV" /mnt/var/cache/pacman/pkg
        ;;
    xfs)
        mkfs.xfs -f "$ROOT_DEV" >/dev/null 2>&1
        mount "$ROOT_DEV" /mnt
        mkdir -p /mnt/boot
        ;;
    f2fs)
        mkfs.f2fs -f "$ROOT_DEV" >/dev/null 2>&1
        mount "$ROOT_DEV" /mnt
        mkdir -p /mnt/boot
        ;;
    ext4)
        mkfs.ext4 -F "$ROOT_DEV" >/dev/null 2>&1
        mount "$ROOT_DEV" /mnt
        mkdir -p /mnt/boot
        ;;
esac

# Mount EFI Logic
if [ "$BOOT_MODE" == "UEFI" ]; then
    mkdir -p /mnt/boot/efi
    mount "$PART_BOOT" /mnt/boot/efi
fi

export ENCRYPT FILESYSTEM DISK PART_ROOT PART_BOOT PART_BIOS
success "Estructura de almacenamiento finalizada."
