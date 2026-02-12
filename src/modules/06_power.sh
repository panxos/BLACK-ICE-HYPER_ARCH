#!/bin/bash
# modules/06_power.sh - Configuración de Gestión de Energía y Rendimiento
# Author: Francisco Aravena (P4nX0Z)
# Modified: 2026-02-11 — Fix: Detección completa de hardware, lm_sensors, perfiles de energía

banner "PASO 6" "Optimización de Energía y Rendimiento"

# --- Detección de hardware (VM/Desktop/Laptop) ---
# detect_power_profile() — Detecta tipo de dispositivo y asigna perfil inicial
detect_power_profile() {
    if systemd-detect-virt -q 2>/dev/null; then
        POWER_PROFILE="performance"  # VM → siempre alto rendimiento
        DEVICE_TYPE="vm"
        VIRT_NAME=$(systemd-detect-virt)
    elif [[ -d /sys/class/power_supply/BAT0 ]] || [[ -d /sys/class/power_supply/BAT1 ]]; then
        POWER_PROFILE="auto"  # Laptop → perfiles dinámicos
        DEVICE_TYPE="laptop"
        VIRT_NAME="none"
    else
        POWER_PROFILE="performance"  # Desktop/servidor → alto rendimiento
        DEVICE_TYPE="desktop"
        VIRT_NAME="none"
    fi
    log_info "Dispositivo: $DEVICE_TYPE | Perfil inicial: $POWER_PROFILE | Virt: $VIRT_NAME"
}

detect_power_profile

# --- Instalar paquetes comunes de gestión de energía ---
log_info "Instalando paquetes de monitoreo y gestión de energía..."

# Paquetes comunes para TODOS los sistemas
POWER_COMMON_PKGS=("lm_sensors" "cpupower" "acpi" "acpid")

# thermald solo para hardware Intel real (no VMs)
CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo 2>/dev/null | awk '{print $3}')
if [[ "$CPU_VENDOR" == "GenuineIntel" ]] && [[ "$DEVICE_TYPE" != "vm" ]]; then
    POWER_COMMON_PKGS+=("thermald")
fi

for pkg in "${POWER_COMMON_PKGS[@]}"; do
    if command -v pacstrap &>/dev/null; then
        # Fase install.sh (chroot): usar pacstrap
        pacstrap /mnt "$pkg" 2>/dev/null || log_warn "$pkg no disponible en pacstrap"
    else
        log_warn "pacstrap no disponible — paquetes de energía se instalarán en deploy"
        break
    fi
done

# --- Configuración por tipo de dispositivo ---
case "$DEVICE_TYPE" in
    laptop)
        log_info "Configurando TLP para gestión adaptativa de energía (laptop)..."

        # Instalar TLP (no auto-cpufreq — elegimos TLP)
        pacstrap /mnt tlp tlp-rdw 2>/dev/null || log_warn "TLP no disponible en pacstrap"

        # Crear configuración optimizada de TLP
        mkdir -p /mnt/etc/tlp.d
        cat > /mnt/etc/tlp.d/01-black-ice.conf << 'EOF'
# BLACK-ICE ARCH - TLP Configuration
# Optimizado para máximo rendimiento en AC y máxima duración en batería

# CPU Scaling Governor
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=powersave

# CPU Energy/Performance Policy (Intel)
CPU_ENERGY_PERF_POLICY_ON_AC=performance
CPU_ENERGY_PERF_POLICY_ON_BAT=power

# CPU Boost (Turbo)
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=0

# Platform Profile (AMD)
PLATFORM_PROFILE_ON_AC=performance
PLATFORM_PROFILE_ON_BAT=low-power

# Processor Performance (Intel)
CPU_MIN_PERF_ON_AC=0
CPU_MAX_PERF_ON_AC=100
CPU_MIN_PERF_ON_BAT=0
CPU_MAX_PERF_ON_BAT=50

# GPU Power Management
RADEON_DPM_PERF_LEVEL_ON_AC=auto
RADEON_DPM_PERF_LEVEL_ON_BAT=low

# WiFi Power Saving
WIFI_PWR_ON_AC=off
WIFI_PWR_ON_BAT=on

# Audio Power Saving
SOUND_POWER_SAVE_ON_AC=0
SOUND_POWER_SAVE_ON_BAT=1

# Runtime PM para dispositivos PCI
RUNTIME_PM_ON_AC=on
RUNTIME_PM_ON_BAT=auto

# USB Autosuspend
USB_AUTOSUSPEND=1
USB_EXCLUDE_BTUSB=1
USB_EXCLUDE_PHONE=1

# Disk
DISK_DEVICES="nvme0n1 sda"
DISK_APM_LEVEL_ON_AC="254 254"
DISK_APM_LEVEL_ON_BAT="128 128"

# SATA Link Power Management
SATA_LINKPWR_ON_AC="max_performance"
SATA_LINKPWR_ON_BAT="min_power"
EOF

        # Habilitar TLP y enmascarar conflictos
        arch-chroot /mnt systemctl enable tlp.service
        arch-chroot /mnt systemctl mask systemd-rfkill.service systemd-rfkill.socket

        # Activar sensores de hardware
        log_info "Configurando detección automática de sensores..."
        arch-chroot /mnt /bin/bash -c "sensors-detect --auto" 2>/dev/null || true

        success "TLP configurado con perfiles AC/Batería optimizados (laptop)"
        ;;

    desktop)
        log_info "Configurando CPUpower para máximo rendimiento (desktop)..."

        cat > /mnt/etc/default/cpupower << 'EOF'
# BLACK-ICE ARCH - CPUpower Configuration
# Desktop/Workstation: Rendimiento máximo constante

governor='performance'
min_freq="0"
max_freq="0"
EOF

        arch-chroot /mnt systemctl enable cpupower.service
        # Desactivar TLP si por error quedó habilitado
        arch-chroot /mnt systemctl mask tlp.service 2>/dev/null || true

        success "CPUpower configurado en modo Performance (desktop)"
        ;;

    vm)
        log_info "Configurando CPUpower para VM (Performance)..."

        cat > /mnt/etc/default/cpupower << 'EOF'
# BLACK-ICE ARCH - CPUpower Configuration (VM)
# VMs siempre en modo rendimiento máximo
governor='performance'
EOF

        arch-chroot /mnt systemctl enable cpupower.service 2>/dev/null || log_warn "CPUpower no disponible en esta VM"
        # Desactivar power saving innecesario en VMs
        arch-chroot /mnt systemctl mask tlp.service 2>/dev/null || true

        success "Governor de rendimiento configurado para VM ($VIRT_NAME)"
        ;;
esac

# --- Habilitar servicios comunes ---
log_info "Habilitando servicios de monitoreo..."
arch-chroot /mnt systemctl enable acpid.service 2>/dev/null || true

# --- Configurar zram (compresión de RAM) para todos los sistemas ---
log_info "Configurando zram para optimización de memoria..."
cat > /mnt/etc/systemd/zram-generator.conf << 'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF

# --- Exportar variables para uso en deploy ---
# Guardamos el tipo de dispositivo para que deploy_hyprland.sh pueda usarlo
echo "DEVICE_TYPE=$DEVICE_TYPE" >> "/mnt/etc/black-ice.env"
echo "POWER_PROFILE=$POWER_PROFILE" >> "/mnt/etc/black-ice.env"

success "Gestión de energía configurada correctamente ($DEVICE_TYPE: $POWER_PROFILE)"
