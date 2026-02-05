#!/bin/bash
# modules/06_power.sh - Configuración de Gestión de Energía

banner "PASO 6" "Optimización de Energía y Rendimiento"

# Detectar tipo de hardware
VIRT_TYPE=$(systemd-detect-virt)
IS_LAPTOP=false

if [ -d /sys/class/power_supply/BAT* ] || [ -d /sys/class/power_supply/battery ]; then
    IS_LAPTOP=true
fi

if [ "$IS_LAPTOP" = true ]; then
    log_info "Configurando TLP para gestión adaptativa de energía..."
    
    # Crear configuración optimizada de TLP
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

    # Habilitar TLP
    arch-chroot /mnt systemctl enable tlp.service
    arch-chroot /mnt systemctl mask systemd-rfkill.service systemd-rfkill.socket
    
    success "TLP configurado con perfiles AC/Batería optimizados"
    
elif [ "$VIRT_TYPE" = "none" ]; then
    # Desktop: Governor de rendimiento fijo
    log_info "Configurando CPUpower para máximo rendimiento..."
    
    cat > /mnt/etc/default/cpupower << 'EOF'
# BLACK-ICE ARCH - CPUpower Configuration
# Desktop/Workstation: Rendimiento máximo constante

governor='performance'
min_freq="0"
max_freq="0"
EOF

    arch-chroot /mnt systemctl enable cpupower.service
    success "CPUpower configurado en modo Performance"
    
else
    # VM: Governor de rendimiento
    log_info "Configurando CPUpower para VM (Performance)..."
    
    cat > /mnt/etc/default/cpupower << 'EOF'
# BLACK-ICE ARCH - CPUpower Configuration (VM)
governor='performance'
EOF

    arch-chroot /mnt systemctl enable cpupower.service 2>/dev/null || log_warn "CPUpower no disponible en esta VM"
    success "Governor de rendimiento configurado para VM"
fi

# Configurar zram (compresión de RAM) para todos los sistemas
log_info "Configurando zram para optimización de memoria..."
cat > /mnt/etc/systemd/zram-generator.conf << 'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF

success "Gestión de energía configurada correctamente"
