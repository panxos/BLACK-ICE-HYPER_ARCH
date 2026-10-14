#!/usr/bin/env bash

audit_installed_system() {
    local root=${1:?Directorio raíz requerido}
    local kernel=${2:-linux}
    local encrypted=${3:-false}
    local failures=0

    if [[ -s "$root/boot/vmlinuz-$kernel" && -s "$root/boot/initramfs-$kernel.img" ]]; then
        printf '[PASS] Kernel e initramfs presentes: %s\n' "$kernel"
    else
        printf '[FAIL] Faltan kernel o initramfs.\n' >&2
        ((++failures))
    fi
    if [[ ! -s "$root/boot/grub/grub.cfg" ]]; then
        printf '[FAIL] Falta configuración de GRUB.\n' >&2
        ((++failures))
    elif [[ "$encrypted" == true || "$encrypted" == yes ]]; then
        if grep -q 'cryptdevice=UUID=' "$root/boot/grub/grub.cfg"; then
            printf '[PASS] GRUB incluye el desbloqueo de LUKS.\n'
        else
            printf '[FAIL] Falta desbloqueo de LUKS en GRUB.\n' >&2
            ((++failures))
        fi
    else
        printf '[PASS] GRUB presente; instalación sin cifrado.\n'
    fi
    if [[ -s "$root/etc/fstab" ]]; then
        printf '[PASS] fstab presente.\n'
    else
        printf '[FAIL] fstab vacío o ausente.\n' >&2
        ((++failures))
    fi
    printf 'Auditoría del sistema: %s fallos.\n' "$failures"
    [[ "$failures" == 0 ]]
}
