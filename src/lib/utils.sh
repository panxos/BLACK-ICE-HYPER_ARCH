#!/bin/bash
# lib/utils.sh

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Este script debe ejecutarse como root."
        exit 1
    fi
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
}

ask_option() {
    local prompt="$1"
    shift
    local options=("$@")
    
    echo -e "${CYAN}$prompt${NC}" >&2
    local choice=""
    
    # Save old PS3
    local OLD_PS3="$PS3"
    PS3="Selecciona una opción: "
    
    select opt in "${options[@]}"; do
        if [ -n "$opt" ]; then
            choice="$opt"
            break
        else
            echo -e "${RED}Opción inválida.${NC}" >&2
        fi
    done < /dev/tty
    
    # Restore PS3
    PS3="$OLD_PS3"
    
    echo "$choice"
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
                # Si estamos en modo no interactivo, abortamos
                if [ "$AUTO_MODE" == "true" ] || [ "$NON_INTERACTIVE" == "true" ]; then
                    return 1
                fi
                # Si existe ask_option, preguntamos al usuario
                if command -v ask_option >/dev/null; then
                    if [[ $(ask_option "¿Deseas reintentar manualmente o abortar?" "Reintentar" "Abortar") == "Abortar" ]]; then
                        return 1
                    else
                        n=1 # Reset counter for manual retry
                    fi
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
