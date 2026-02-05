#!/bin/bash
# modules/02_base.sh ( Cyberpunk Edition)

banner "PASO 3" "Inyección de Núcleos y Sistema Base"

# 1. Normalización de Kernel
case "${KERNEL:-}" in
    linux-zen)       SELECTED_KERNEL="linux-zen";;
    linux-hardened)  SELECTED_KERNEL="linux-hardened";;
    *)               SELECTED_KERNEL="linux";;
esac

# 2. Modo Interactivo si no hay kernel predefinido
if [ -z "${KERNEL:-}" ] && [ "${AUTO_MODE:-}" != "true" ]; then
    echo -e "${NEON_PURPLE}┌──────────────────────────────────────────────┐${NC}"
    echo -e "${NEON_PURPLE}│${NC}  ${BOLD}SELECCIÓN DE NÚCLEO (KERNEL)              ${NC} ${NEON_PURPLE}│${NC}"
    echo -e "${NEON_PURPLE}└──────────────────────────────────────────────┘${NC}"
    
    SELECTED_KERNEL=$(ask_option "Elige la arquitectura del kernel:" "linux" "linux-zen" "linux-hardened")
fi

success "Núcleo seleccionado: ${NEON_BLUE}$SELECTED_KERNEL${NC}"

# 3. Construcción de lista de paquetes base
PACKAGES="base base-devel linux-firmware dialog efibootmgr grub git go nano networkmanager sudo vim openssh man-db man-pages texinfo lvm2 screen expect cryptsetup kbd sof-firmware iwd smartmontools xdg-user-dirs wireless_tools wpa_supplicant"

# Añadir Kernel y sus Headers correspondientes
PACKAGES="$PACKAGES $SELECTED_KERNEL ${SELECTED_KERNEL}-headers"

# 4. Detección de Hardware y Optimización de Virtualización
log_info "Escaneando entorno de hardware/virtualización..."
VIRT_TYPE=$(systemd-detect-virt)

if [ "$VIRT_TYPE" != "none" ]; then
    log_info "Entorno Virtualizado detectado: ${NEON_BLUE}$VIRT_TYPE${NC}"
    case "$VIRT_TYPE" in
        kvm|qemu)
            PACKAGES="$PACKAGES virtio-vga-gl qemu-guest-agent spice-vdagent"
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
else
    if grep -q "GenuineIntel" /proc/cpuinfo; then
        PACKAGES="$PACKAGES intel-ucode"
        log_info "CPU Intel detectada: Inyectando intel-ucode"
    elif grep -q "AuthenticAMD" /proc/cpuinfo; then
        PACKAGES="$PACKAGES amd-ucode"
        log_info "CPU AMD detectada: Inyectando amd-ucode"
    fi
fi

# 5. Herramientas de Sistema de Archivos
case "${FILESYSTEM:-}" in
    btrfs) PACKAGES="$PACKAGES btrfs-progs";;
    xfs)   PACKAGES="$PACKAGES xfsprogs";;
    f2fs)  PACKAGES="$PACKAGES f2fs-tools";;
esac

# 6. Ejecutar pacstrap con Bucle de Reintento
# 6. Ejecutar pacstrap con Protocolo de Resiliencia Nuclear
ATTEMPT=1
while true; do
    log_info "Iniciando descarga masiva de paquetes de base (Intento $ATTEMPT)..."
    
    if pacstrap /mnt $PACKAGES; then
        success "Núcleo del sistema inyectado correctamente."
        # Restaurar SigLevel si fue modificado
        sed -i 's/^SigLevel = Optional TrustAll/#SigLevel = Required DatabaseOptional/' /etc/pacman.conf 2>/dev/null
        break
    else
        log_error "Fallo en pacstrap (Intento $ATTEMPT)."
        
        # Protocolo de Emergencia por niveles
        if [ $ATTEMPT -eq 1 ]; then
            log_info "Protocolo Nivel 1: Limpieza de caché y re-poblado de llaves..."
            rm -rf /mnt/var/cache/pacman/pkg/* 2>/dev/null
            pacman-key --init >/dev/null 2>&1
            pacman-key --populate archlinux >/dev/null 2>&1
            pacman -Sy --noconfirm archlinux-keyring >/dev/null 2>&1
        elif [ $ATTEMPT -eq 2 ]; then
            log_warn "Protocolo Nivel 2: Los espejos regionales fallan. Cambiando a Espejos Globales (Worldwide)..."
            # Forzar reflector a buscar los 20 mirrors más rápidos del mundo
            reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist >/dev/null 2>&1
        elif [ $ATTEMPT -eq 3 ]; then
            echo -e "\n${RED}╔══════════════════════════════════════════════════════╗${NC}"
            echo -e "${RED}║${NC}  ${BOLD}PROTOCOLO NUCLEAR PGP REQUERIDO                     ${NC} ${RED}║${NC}"
            echo -e "${RED}╚══════════════════════════════════════════════════════╝${NC}"
            echo -e "${YELLOW}[WARN] Las firmas PGP siguen fallando a pesar de la limpieza.${NC}"
            echo -e "${YELLOW}Esto ocurre si la ISO es incompatible con las llaves nuevas.${NC}"
            
            local BYPASS="No"
            if [ "${AUTO_MODE:-}" == "true" ]; then
                BYPASS="Si"
                log_info "Modo Automático: Activando bypass de PGP temporalmente."
            else
                BYPASS=$(ask_option "¿Activar bypass de PGP para la instalación inicial? (Se corregirá tras el reboot)" "Si" "No")
            fi

            if [ "$BYPASS" == "Si" ]; then
                log_warn "Relajando SigLevel en /etc/pacman.conf (Host)..."
                # Modificar SigLevel del sistema host temporalmente para que pacman del live ISO permita instalar
                sed -i 's/^SigLevel.*/SigLevel = Optional TrustAll/' /etc/pacman.conf
                sed -i 's/^#SigLevel/SigLevel/' /etc/pacman.conf
            else
                log_error "Instalación abortada por fallos de firma persistentes."
                exit 1
            fi
        else
            log_error "Fallo crítico persistente tras 3 intentos. Abortando."
            exit 1
        fi
        
        ((ATTEMPT++))
        log_info "Reintentando en 5 segundos..."
        sleep 5
    fi
done
