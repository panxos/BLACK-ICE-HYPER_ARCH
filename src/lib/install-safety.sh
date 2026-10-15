#!/usr/bin/env bash

validate_target_disk() {
    local disk="$1" disk_type mounts
    [[ -b "$disk" ]] || { log_error "No existe el dispositivo: $disk"; return 1; }
    disk_type=$(lsblk -dnro TYPE "$disk") || return 1
    [[ "$disk_type" == disk ]] || { log_error "Selecciona un disco completo, no una partición: $disk"; return 1; }
    mounts=$(lsblk -nrpo MOUNTPOINTS "$disk") || return 1
    [[ ! "$mounts" =~ [^[:space:]] ]] || {
        log_error "El disco tiene sistemas montados, swap o volúmenes activos: $disk"; return 1;
    }
    [[ $(lsblk -dnro RO "$disk") == 0 ]] || { log_error "Disco de solo lectura: $disk"; return 1; }
    if lsblk -nro TYPE "$disk" | grep -Eq '^(crypt|lvm|raid|md)'; then
        log_error "El disco tiene volúmenes activos. Desactívalos antes de instalar: $disk"
        return 1
    fi
}

require_live_environment() {
    [[ -e /run/archiso/bootmnt ]] || {
        log_error "El instalador base solo se ejecuta desde una ISO live de Arch; no actualiza un sistema instalado."; return 1;
    }
}
