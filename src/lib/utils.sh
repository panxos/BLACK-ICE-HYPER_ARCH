#!/bin/bash
# lib/utils.sh

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Este script debe ejecutarse como root."
        exit 1
    fi
}

console_to_xkb_layout() {
    case "${1:-us}" in
        la-latin1|la-latin1-nodeadkeys) printf 'latam\n' ;;
        br-abnt2) printf 'br\n' ;;
        de-latin1|de-latin1-nodeadkeys) printf 'de\n' ;;
        fr-latin1|fr-latin9) printf 'fr\n' ;;
        uk) printf 'gb\n' ;;
        es-winkeys) printf 'es\n' ;;
        *) printf '%s\n' "${1:-us}" ;;
    esac
}

check_boot_mode() {
    if [ -d "/sys/firmware/efi/efivars" ]; then
        BOOT_MODE="UEFI"
        log_info "Modo de arranque: UEFI"
    else
        BOOT_MODE="BIOS"
        log_warn "Modo de arranque: Legacy BIOS detectado."
        log_info "Se habilitará el soporte para particionado GPT + BIOS Boot."
    fi
    export BOOT_MODE
}

ask_option() {
    local prompt="$1"
    shift
    local options=("$@")
    
    local choice count="${#options[@]}"
    (( count > 0 )) || return 1
    installer_ui black_ice_menu "$prompt" "${options[@]}" >&2
    while true; do
        printf '  Opción [1-%s] > ' "$count" >&2
        IFS= read -r choice < /dev/tty || return 1
        if [[ "$choice" =~ ^[0-9]{1,6}$ ]] && (( 10#$choice >= 1 && 10#$choice <= count )); then
            printf '%s\n' "${options[10#$choice - 1]}"
            return 0
        fi
        log_warn "Elige un número entre 1 y $count." >&2
    done
}

# --- Resilience: Retry Logic ---
retry_command() {
    local n=1
    local max=3
    local delay=5
    while true; do
        if "$@"; then
            return 0
        else
            if [[ $n -lt $max ]]; then
                ((n++))
                log_warn "Fallo en comando: $*. Reintentando ($n/$max) en ${delay}s..."
                sleep $delay
            else
                log_error "Comando falló tras $max intentos: $*"
                # Si estamos en modo no interactivo, fallamos pero permitimos continuar al script si el caller lo maneja
                if [[ ${ASSUME_YES:-false} == true || ${AUTO_MODE:-false} == true || ${NON_INTERACTIVE:-false} == true ]]; then
                    return 1
                fi
                # Si existe ask_option, preguntamos al usuario
                if command -v ask_option >/dev/null; then
                    local ACTION
                    ACTION=$(ask_option "¿Qué deseas hacer con este fallo?" "Reintentar" "Saltar" "Abortar")
                    case "$ACTION" in
                        "Reintentar") n=1 ;;
                        "Saltar") return 1 ;;
                        "Abortar") exit 1 ;;
                    esac
                else
                    return 1
                fi
            fi
        fi
    done
}
# --- Password entry with asterisk masking ---
read_password() {
    local prompt="$1"
    local password=""
    local char
    
    echo -ne "$prompt" >&2
    
    while IFS= read -r -s -n 1 char < /dev/tty; do
        # Enter key
        if [[ $char == $'\0' || $char == $'\n' || $char == "" ]]; then
            break
        fi
        # Backspace
        if [[ $char == $'\177' || $char == $'\010' ]]; then
            if [ -n "$password" ]; then
                password="${password%?}"
                echo -ne "\b \b" >&2
            fi
        else
            password+="$char"
            echo -ne "*" >&2
        fi
    done
    echo >&2
    echo "$password"
}

# --- Hostname Validation (RFC 1123) ---
# Validates a hostname: alphanumeric + hyphens, 1-63 chars,
# cannot start or end with a hyphen, no spaces.
# Usage: validate_hostname "my-hostname" && echo "Valid"
validate_hostname() {
    local hostname="$1"

    # Check empty
    if [ -z "$hostname" ]; then
        return 1
    fi

    # Check length (1-63 characters)
    if [ ${#hostname} -gt 63 ] || [ ${#hostname} -lt 1 ]; then
        return 1
    fi

    # Check valid characters: only alphanumeric and hyphens
    if ! [[ "$hostname" =~ ^[a-zA-Z0-9-]+$ ]]; then
        return 1
    fi

    # Cannot start or end with hyphen
    if [[ "$hostname" == -* ]] || [[ "$hostname" == *- ]]; then
        return 1
    fi

    return 0
}

# --- Rebuild Keyring (Nuclear Reset) ---
# Reconstructs the entire pacman keyring from scratch.
# Use when PGP keyring is corrupted or keys are untrusted.
# Usage: rebuild_keyring
rebuild_keyring() {
    sudo pacman -Syu --needed archlinux-keyring || return 1
    sudo pacman-key --init || return 1
    sudo pacman-key --populate archlinux || return 1
    log_success "Llaveros oficiales actualizados conservando verificación de firmas."
}

safe_install() {
    local pkg="$1"
    [[ "$pkg" =~ ^[a-zA-Z0-9@+_.:-]+$ ]] || { log_error "Nombre de paquete inválido"; return 1; }
    if pacman -Q "$pkg" &>/dev/null; then
        log_info "$pkg ya está instalado"
        return 0
    fi
    local -a command
    if pacman -Si "$pkg" &>/dev/null; then
        command=(sudo pacman -S --needed --noconfirm "$pkg")
    elif command -v paru &>/dev/null && paru --version &>/dev/null; then
        command=(paru -S --needed --batchinstall --noremovemake --nouseask "$pkg")
        if [[ "${ALLOW_UNREVIEWED_AUR:-false}" == true ]]; then
            command+=(--noconfirm --skipreview)
        elif [[ "${NON_INTERACTIVE:-false}" == true || "${AUTO_MODE:-false}" == true ]]; then
            log_warn "$pkg requiere revisión AUR; omitido en modo desatendido."
            return 1
        else
            command+=(--confirm --review)
        fi
    else
        log_error "$pkg no está en repositorios configurados y no hay helper AUR funcional."
        return 1
    fi
    if "${command[@]}"; then
        pacman -Q "$pkg" &>/dev/null || { log_error "El gestor no confirmó la instalación de $pkg"; return 1; }
        log_success "$pkg instalado correctamente"
        return 0
    fi
    log_error "No se instaló $pkg. Se conservan firmas, dependencias y paquetes existentes."
    return 1
}
