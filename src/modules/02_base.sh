#!/bin/bash
install_stage 3 'Sistema base y kernel'
# modules/02_base.sh ( Cyberpunk Edition)

# --- Protocolo Anti-PGP Error (SOTA Fix) ---
log_info "Sincronizando reloj del sistema para validación PGP..."
timedatectl set-ntp true
log_info "Actualizando archlinux-keyring de la ISO..."
pacman -Sy --noconfirm archlinux-keyring || {
    log_warn "Fallo al actualizar keyring vía pacman. Intentando refresco manual..."
    pacman-key --init
    pacman-key --populate archlinux
}

# 1. Normalización de Kernel
case "${KERNEL:-}" in
    linux-zen)       SELECTED_KERNEL="linux-zen";;
    linux-hardened)  SELECTED_KERNEL="linux-hardened";;
    *)               SELECTED_KERNEL="linux";;
esac

# 2. Modo Interactivo si no hay kernel predefinido
if [ -z "${KERNEL:-}" ] && [ "${AUTO_MODE:-}" != "true" ]; then
    
    SELECTED_KERNEL=$(ask_option "Elige la arquitectura del kernel:" "linux" "linux-zen" "linux-hardened")
fi

export SELECTED_KERNEL
success "Núcleo seleccionado: ${NEON_BLUE}$SELECTED_KERNEL${NC}"

# 3. Construcción de lista de paquetes base
PACKAGES="base base-devel zram-generator inetutils rsync wget sshpass linux-firmware dialog efibootmgr grub git go nano networkmanager sudo vim openssh man-db man-pages texinfo lvm2 screen expect cryptsetup kbd sof-firmware iwd smartmontools xdg-user-dirs wireless_tools wpa_supplicant"

# Añadir Kernel y sus Headers correspondientes
PACKAGES="$PACKAGES $SELECTED_KERNEL ${SELECTED_KERNEL}-headers"

# 4. Detección de Hardware y Optimización de Virtualización
log_info "Escaneando entorno de hardware/virtualización..."
VIRT_TYPE=$(systemd-detect-virt || true)
IS_LAPTOP=false

# Detectar si es laptop (presencia de batería)
for _bat_path in /sys/class/power_supply/BAT0 /sys/class/power_supply/BAT1 /sys/class/power_supply/battery; do
    if [ -d "$_bat_path" ]; then IS_LAPTOP=true; break; fi
done
if [ "$IS_LAPTOP" = true ]; then
    log_info "Laptop detectado: Activando gestión de energía adaptativa"
fi

if [ "$VIRT_TYPE" != "none" ]; then
    log_info "Entorno Virtualizado detectado: ${NEON_BLUE}$VIRT_TYPE${NC}"
    case "$VIRT_TYPE" in
        kvm|qemu)
            PACKAGES="$PACKAGES  qemu-guest-agent spice-vdagent"
            log_info "Optimizaciones KVM (VirtIO) activadas"
            ;;
        vmware)
            PACKAGES="$PACKAGES open-vm-tools"
            log_info "Optimizaciones VMware (Open-VM-Tools) activadas"
            ;;
        microsoft)
            PACKAGES="$PACKAGES hyperv"
            log_info "Optimizaciones Hyper-V activadas"
            ;;
        xen|oracle)
            PACKAGES="$PACKAGES xf86-video-vmware virtualbox-guest-utils"
            log_info "Soporte para Xen/VirtualBox activado"
            ;;
    esac
    
    # VMs siempre en modo performance
    PACKAGES="$PACKAGES cpupower"
    log_info "Governor de CPU: Performance (VM)"
else
    # Hardware real: microcode + gestión de energía según tipo
    if grep -q "GenuineIntel" /proc/cpuinfo; then
        PACKAGES="$PACKAGES intel-ucode"
        log_info "CPU Intel detectada: Inyectando intel-ucode"
    elif grep -q "AuthenticAMD" /proc/cpuinfo; then
        PACKAGES="$PACKAGES amd-ucode"
        log_info "CPU AMD detectada: Inyectando amd-ucode"
    fi
    
    # Gestión de energía adaptativa
    if [ "$IS_LAPTOP" = true ]; then
        PACKAGES="$PACKAGES tlp tlp-rdw brightnessctl"
        log_info "Gestión de energía: TLP (adaptativo AC/Batería)"
    else
        PACKAGES="$PACKAGES cpupower"
        log_info "Gestión de energía: CPUpower (Performance)"
    fi
    
    # Multi-monitor para Wayland (solo hardware real)
    PACKAGES="$PACKAGES wlr-randr nwg-displays"
    log_info "Soporte multi-monitor: wlr-randr + nwg-displays"
fi

# 5. Herramientas de Sistema de Archivos
case "${FILESYSTEM:-}" in
    btrfs) PACKAGES="$PACKAGES btrfs-progs";;
    xfs)   PACKAGES="$PACKAGES xfsprogs";;
    f2fs)  PACKAGES="$PACKAGES f2fs-tools";;
esac

log_info "Instalando paquetes base; se conserva la caché si la operación se interrumpe..."
read -r -a base_packages <<< "$PACKAGES"
if ! pacstrap /mnt --needed "${base_packages[@]}"; then
    log_error "Pacstrap falló. Revisa el error anterior y usa --resume; no se borraron paquetes ni se desactivaron firmas."
    exit 1
fi
success "Núcleo del sistema inyectado correctamente."
