#!/bin/bash
# ==============================================================================
# BLACK-ICE ARCH - Advanced Pentesting Environment Installer
# ==============================================================================
# Author: Francisco Aravena (Alias P4nx0s)
# GitHub: https://github.com/panxos
# Web:    www.soporteinfo.net
# ========================================================================

# --- Variables Globales ---
INSTALL_DIR=$(dirname "$(readlink -f "$0")")
BLACK_ICE_VERSION=$(<"$INSTALL_DIR/VERSION")
RESUME_MODULES=false
case "${1:-}" in
    --preview)
        # shellcheck source=src/lib/installer-preview.sh
        source "$INSTALL_DIR/src/lib/installer-preview.sh"
        black_ice_installer_preview
        exit $? ;;
    --banner)
        # shellcheck source=src/lib/banner.sh
        source "$INSTALL_DIR/src/lib/banner.sh"
        black_ice_banner "INSTALACIÓN BASE" "Arch Linux / sistema, discos y arranque" "$BLACK_ICE_VERSION"
        exit 0 ;;
    --resume) RESUME_MODULES=true ;;
    --version) printf '%s\n' "$BLACK_ICE_VERSION"; exit 0 ;;
    --help|--dry-run)
        printf 'BLACK-ICE %s · instalador base para ISO Arch\n' "$BLACK_ICE_VERSION"
        echo 'Flujo: validar entorno → seleccionar disco sin montajes → confirmar borrado → particionar → instalar → configurar.'
        echo 'Modo automático requiere CONFIRM_ERASE=/dev/disco en config/install.conf. --resume conserva particiones y comprueba UUID/configuración.'
        echo '--preview: recorre la interfaz con datos de demostración, sin instalar ni modificar discos.'
        exit 0 ;;
    '') ;;
    *) echo "Opción desconocida: $1" >&2; exit 2 ;;
esac
set -euo pipefail

# --- Importar Librerías  ---
source "$INSTALL_DIR/src/lib/colors.sh"
source "$INSTALL_DIR/src/lib/logging.sh"
source "$INSTALL_DIR/src/lib/utils.sh"
# shellcheck source=src/lib/privileges.sh
source "$INSTALL_DIR/src/lib/privileges.sh"
# shellcheck source=src/lib/repositories.sh
source "$INSTALL_DIR/src/lib/repositories.sh"
source "$INSTALL_DIR/src/lib/install-safety.sh"
require_live_environment
exec 8>/run/black-ice-install.lock
flock -n 8 || { log_error "Ya existe una instalación base en ejecución."; exit 1; }

# --- Logging Setup (Global Redirection) ---
exec 3>&1 # Save stdout
exec 4>&2 # Save stderr

# Redirigir stdout/stderr al archivo de log y pantalla
exec > >(tee -ai "$LOG_FILE") 2>&1
echo "--- BLACK-ICE INSTALLATION STARTED: $(date) ---"
log_info "Log de sesión: $LOG_FILE"

CONFIG_FILE="$INSTALL_DIR/config/install.conf"

# --- STRICT MODE ---
set -euo pipefail
# Los fallos críticos detienen la instalación antes de continuar con otro módulo.


# --- Detectar Configuración ---
if [ -f "$CONFIG_FILE" ]; then
    [[ $(stat -c %a "$CONFIG_FILE") == 600 && $(stat -c %u "$CONFIG_FILE") == "$EUID" ]] || {
        log_error "La configuración automática debe pertenecer a root y tener permisos 600."; exit 1;
    }
    log_info "Cargando configuración desde: $CONFIG_FILE"
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
    export AUTO_MODE=true
else
    log_warn "No se encontró configuración. Iniciando modo interactivo."
fi

# ...

# --- MAIN INSTALLATION FLOW ---

banner "INSTALACIÓN BASE" "Arch Linux / sistema, discos y arranque"

log_info "Preparando el entorno de instalación..."

# 1. Environment Checks & Network
install_stage 1 "Entorno y conectividad"
source "$INSTALL_DIR/src/modules/00_environment.sh"

# --- Check for Existing System (Idempotency) ---
if [[ "$RESUME_MODULES" == true ]]; then
    DISK="/dev/${TARGET_DISK:?Para reanudar indica TARGET_DISK en install.conf}"
    DISK="/dev/${DISK#/dev/}"
    SKIP_BASE=true
elif [ -f "/etc/black-ice-release" ] || [ -f "/mnt/etc/black-ice-release" ]; then
    log_warn "Sistema BLACK-ICE detectado."
    read -rp "¿Desea reinstalar el sistema base y formatear disco? (y/N) " REINSTALL_CHOICE < /dev/tty
    if [[ ! "$REINSTALL_CHOICE" =~ ^[Yy]$ ]]; then
        log_info "Saltando formateo e instalación base. Pasando a configuración..."
        SKIP_BASE=true
    else
        SKIP_BASE=false
    fi
else
    SKIP_BASE=false
fi

mount_only() {
    # Monta particiones existentes sin formatear — para modo de recuperación.
    # Exports: PART_ROOT, PART_EFI, ENCRYPT, FILESYSTEM
    if [ -z "${DISK:-}" ]; then
        log_error "DISK no definido. Especifícalo en install.conf o exporta DISK=/dev/sdX"
        exit 1
    fi

    # Auto-detect partition layout (NVMe uses pN suffix, SATA/USB usa N)
    if [[ "$DISK" == *"nvme"* ]] || [[ "$DISK" == *"mmcblk"* ]]; then
        PART_EFI="${DISK}p1"
        PART_ROOT="${DISK}p2"
    else
        PART_EFI="${DISK}1"
        PART_ROOT="${DISK}2"
    fi

    # Detect LUKS
    ENCRYPT=false
    local _real_root="$PART_ROOT"
    if cryptsetup isLuks "$PART_ROOT" 2>/dev/null; then
        ENCRYPT=true
        log_info "Recuperación: LUKS detectado en $PART_ROOT"
        if [[ ! -b /dev/mapper/cryptroot ]]; then
            read -rsp "Passphrase LUKS para $PART_ROOT: " _luks_pass < /dev/tty
            echo
            if ! echo "$_luks_pass" | cryptsetup open "$PART_ROOT" cryptroot; then
                log_error "Passphrase LUKS incorrecta"
                exit 1
            fi
        else
            local backing_device
            backing_device=$(LC_ALL=C cryptsetup status cryptroot | awk '/device:/ { print $2 }')
            [[ $(readlink -f "$backing_device") == "$(readlink -f "$PART_ROOT")" ]] || {
                log_error 'cryptroot pertenece a otro disco; se abortó sin modificarlo'; exit 1;
            }
        fi
        _real_root="/dev/mapper/cryptroot"
    fi

    # Mount root
    mkdir -p /mnt
    FILESYSTEM="${FILESYSTEM:-ext4}"
    if mountpoint -q /mnt; then
        [[ $(findmnt -nro UUID -T /mnt) == "$(blkid -s UUID -o value "$_real_root")" ]] || {
            log_error '/mnt corresponde a otro disco; se abortó sin modificarlo'; exit 1;
        }
        local mounted_device
        mounted_device=$(findmnt -nro SOURCE --nofsroot -T /mnt)
        [[ $(readlink -f "$mounted_device") == "$(readlink -f "$_real_root")" ]] || {
            log_error '/mnt corresponde a otro dispositivo, aunque comparta UUID'; exit 1;
        }
    elif [[ "$FILESYSTEM" == "btrfs" ]]; then
        mount -o subvol=@ "$_real_root" /mnt || { log_error "No se pudo montar btrfs @subvol"; exit 1; }
    else
        mount "$_real_root" /mnt || { log_error "No se pudo montar $_real_root en /mnt"; exit 1; }
    fi

    if [[ "$FILESYSTEM" == btrfs ]]; then
        local entry subvolume
        for entry in 'home:@home' '.snapshots:@snapshots' 'var/log:@var_log' 'var/log/audit:@audit' 'var/cache/pacman/pkg:@pkg'; do
            subvolume="${entry#*:}"
            entry="${entry%%:*}"
            mkdir -p "/mnt/$entry"
            mountpoint -q "/mnt/$entry" || mount -o "noatime,compress=zstd,subvol=$subvolume" "$_real_root" "/mnt/$entry"
        done
    fi

    # Mount EFI
    if [[ "$BOOT_MODE" == UEFI ]] && [ -b "$PART_EFI" ]; then
        mkdir -p /mnt/boot/efi
        if mountpoint -q /mnt/boot/efi; then
            [[ $(findmnt -nro UUID -T /mnt/boot/efi) == "$(blkid -s UUID -o value "$PART_EFI")" ]] || {
                log_error 'La ESP montada pertenece a otro disco'; exit 1;
            }
        else
            mount "$PART_EFI" /mnt/boot/efi
        fi
    fi

    PART_BOOT="$PART_EFI"
    ROOT_DEV="$_real_root"
    export PART_ROOT PART_BOOT PART_EFI ROOT_DEV ENCRYPT FILESYSTEM
    log_success "Recuperación: /mnt listo (${FILESYSTEM} en ${_real_root})"
}

if [ "$SKIP_BASE" = false ]; then
    # 2. Disk Partitioning (Secure Wipe & Encryption)
    install_stage 2 "Disco de destino y cifrado"
    source "$INSTALL_DIR/src/modules/01_disk.sh"

else
    log_info "Modo de recuperación/reconfiguración activo."
    mount_only
fi

MODULE_ROOT="$INSTALL_DIR"
MODULE_STATE=/mnt/var/lib/black-ice/install/modules.json
MODULE_IDENTITY=$(findmnt -nro UUID -T /mnt)
[[ -n "$MODULE_IDENTITY" ]] || { log_error 'No se pudo identificar UUID del destino'; exit 1; }
if [[ "$RESUME_MODULES" == true && ! -f "$MODULE_STATE" ]]; then
    log_error 'No hay registro de instalación. Inspecciona el disco antes de continuar; no se formateó.'
    exit 1
fi
MODULE_FINGERPRINT=$(printf '%s\n' "$BLACK_ICE_VERSION" "${TARGET_DISK:-$DISK}" "${FILESYSTEM:-ext4}" "${ENABLE_LUKS:-no}" "${KERNEL:-linux}" "${USERNAME:-}" "${KEYMAP:-us}" "${HOSTNAME:-black-ice}" "${TIMEZONE:-America/Santiago}" "${SYSTEM_LOCALE:-}" | sha256sum | cut -d' ' -f1)
export MODULE_ROOT MODULE_STATE MODULE_IDENTITY MODULE_FINGERPRINT
SELECTED_KERNEL="${KERNEL:-linux}"
USER_NAME="${USERNAME:-${USER_NAME:-}}"
source "$INSTALL_DIR/src/lib/module-runner.sh"
verify_install_module() {
    case "$1" in
        base) arch-chroot /mnt pacman -Q base "$SELECTED_KERNEL" >/dev/null && [[ -f /mnt/usr/bin/bash ]] ;;
        config) [[ -s /mnt/etc/fstab && -s /mnt/etc/locale.conf ]] && arch-chroot /mnt findmnt --verify --tab-file /etc/fstab >/dev/null ;;
        user) arch-chroot /mnt id "$USER_NAME" >/dev/null && arch-chroot /mnt visudo -cf /etc/sudoers >/dev/null ;;
        power) [[ -s /mnt/etc/systemd/zram-generator.conf && -s /mnt/etc/black-ice.env ]] ;;
        boot) [[ -s /mnt/boot/grub/grub.cfg ]] ;;
        final) [[ -f /mnt/etc/black-ice-release && -x "/mnt/home/$USER_NAME/BLACK-ICE_ARCH/deploy_hyprland.sh" ]] ;;
        *) return 1 ;;
    esac
}
module_journal init
run_install_module base "$INSTALL_DIR/src/modules/02_base.sh"

# 4. System Configuration
run_install_module config "$INSTALL_DIR/src/modules/03_config.sh"

# 5. User & Root Setup (Wheel/Sudoers)
run_install_module user "$INSTALL_DIR/src/modules/04_user.sh"

# 6. Power Management & Optimization
run_install_module power "$INSTALL_DIR/src/modules/06_power.sh"

# 7. Bootloader (GRUB Encrypted)
run_install_module boot "$INSTALL_DIR/src/modules/05_bootloader.sh"

# 8. Post-Install Prep (Deployment Scripts)
run_install_module final "$INSTALL_DIR/src/modules/99_final.sh"


print_step 'INSTALACIÓN BASE COMPLETADA'
log_success "Sistema listo para reiniciar."
log_info "Después del reinicio, inicia sesión con $USER_NAME."
log_info 'Continúa con: cd ~/BLACK-ICE_ARCH && bash deploy_hyprland.sh'
log_success "Distribución de teclado '${KEYMAP:-us}' configurada para consola, initramfs (LUKS) y SDDM."
echo -e "\nEscribe ${BOLD}reboot${NC} para reiniciar."

# --- Guardar configuración para uso futuro con escapado seguro ---
log_info "Respaldando configuración de sesión (install.conf.auto)..."
CONFIG_FILE="$INSTALL_DIR/install.conf.auto"
{
    echo "# BLACK-ICE ARCH - Configuración Auto-Generada"
    printf "KEYBOARD_LAYOUT=%q\n" "${KEYMAP:-us}"
    printf "TARGET_DISK=%q\n" "${DISK#/dev/}"
    printf "ENABLE_LUKS=%q\n" "$( [ "$ENCRYPT" == "true" ] && echo "yes" || echo "no" )"
    printf "FILESYSTEM=%q\n" "${FILESYSTEM:-ext4}"
    printf "KERNEL=%q\n" "${SELECTED_KERNEL:-linux}"
    printf "TIMEZONE=%q\n" "${TIMEZONE:-America/Santiago}"
    printf "SYSTEM_LANG=%q\n" "${SYSTEM_LANG:-es_CL}"
    printf "SYSTEM_LOCALE=%q\n" "${SYSTEM_LOCALE:-es_CL}"
    printf "SELECTED_COUNTRY=%q\n" "${SELECTED_COUNTRY:-Chile}"
    printf "HOSTNAME=%q\n" "${HOSTNAME:-black-ice}"
    printf "NVME_STABILITY=%q\n" "${NVME_STABILITY:-no}"
    printf "USERNAME=%q\n" "${USER_NAME:-admin}"
    echo "#Nota: Las contraseñas de root y usuario no se guardan por seguridad en este archivo auto-generado"
} > "$CONFIG_FILE"
chmod 600 "$CONFIG_FILE"

exit 0
