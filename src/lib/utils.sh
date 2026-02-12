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
    local OLD_PS3="${PS3:-}"
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
                # Si estamos en modo no interactivo, fallamos pero permitimos continuar al script si el caller lo maneja
                if [ "${AUTO_MODE:-}" == "true" ] || [ "${NON_INTERACTIVE:-}" == "true" ]; then
                    return 1
                fi
                # Si existe ask_option, preguntamos al usuario
                if command -v ask_option >/dev/null; then
                    local ACTION=$(ask_option "¿Qué deseas hacer con este fallo?" "Reintentar" "Saltar" "Abortar")
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
# Use when PGP keyring is completely corrupted.
# Usage: rebuild_keyring
rebuild_keyring() {
    log_warn "Reconstruyendo keyring completo (operación nuclear)..."
    sudo rm -rf /etc/pacman.d/gnupg
    sudo pacman-key --init
    sudo pacman-key --populate archlinux
    # Populate chaotic-aur keys if available
    [[ -f /usr/share/pacman/keyrings/chaotic.gpg ]] && sudo pacman-key --populate chaotic
    # Populate blackarch keys if available
    [[ -f /usr/share/pacman/keyrings/blackarch.gpg ]] && sudo pacman-key --populate blackarch
    log_success "Keyring reconstruido exitosamente"
}

# --- Safe Install (PGP-Resilient Package Installer) ---
# Installs a package with automatic PGP error detection and recovery.
# Tries: 1) normal install, 2) fix PGP + retry, 3) ask user or skip.
# Usage: safe_install <package_name>
# Returns: 0 on success, 1 on failure/skip
safe_install() {
    local pkg="$1"

    # Ensure valid working directory for remote execution reliability
    cd "$HOME" || cd /tmp || { log_error "No se pudo acceder a un directorio de trabajo válido."; return 1; }

    # Skip if already installed
    if pacman -Q "$pkg" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $pkg (ya instalado)"
        return 0
    fi

    log_info "Instalando: $pkg"

    # Attempt 1: Normal installation via yay (handles both repos and AUR)
    if command -v yay &>/dev/null; then
        if yay -S --noconfirm --needed "$pkg" 2>/dev/null; then
            log_success "$pkg instalado correctamente"
            return 0
        fi
    else
        if sudo -n pacman -S --noconfirm --needed "$pkg" 2>/dev/null; then
            log_success "$pkg instalado correctamente"
            return 0
        fi
    fi

    # Capture error output for analysis
    local error_output
    if command -v yay &>/dev/null; then
        error_output=$(yay -S --noconfirm --needed "$pkg" 2>&1)
    else
        error_output=$(sudo -n pacman -S --noconfirm --needed "$pkg" 2>&1)
    fi

    # Detect PGP/signature error
    if echo "$error_output" | grep -qiE "unknown trust|invalid.*signature|corrupted|PGP|FAILED|gpg|key"; then
        log_warn "Error PGP detectado para $pkg, intentando reparar..."

        # Clean corrupted package from cache
        sudo find /var/cache/pacman/pkg/ -name "${pkg%%[-_]*}*.pkg.tar.*" -delete 2>/dev/null

        # Extract key ID and import
        local key_id
        key_id=$(echo "$error_output" | grep -oP '(?<=key ")[A-F0-9]+' | head -1)
        if [ -z "$key_id" ]; then
            key_id=$(echo "$error_output" | grep -oP '[A-F0-9]{8,}' | head -1)
        fi

        if [ -n "$key_id" ]; then
            log_info "Importando clave PGP: $key_id"
            sudo pacman-key --recv-keys "$key_id" 2>/dev/null || \
                sudo pacman-key --recv-keys "$key_id" --keyserver keyserver.ubuntu.com 2>/dev/null
            sudo pacman-key --lsign-key "$key_id" 2>/dev/null
        fi

        # Attempt 2: Retry after key repair
        if command -v yay &>/dev/null; then
            if yay -S --noconfirm --needed "$pkg" 2>/dev/null; then
                log_success "$pkg instalado tras reparar firma PGP"
                return 0
            fi
        else
            if sudo -n pacman -S --noconfirm --needed "$pkg" 2>/dev/null; then
                log_success "$pkg instalado tras reparar firma PGP"
                return 0
            fi
        fi

        # Attempt 3: Ask user or skip depending on install mode
        if [ "${AUTO_MODE:-}" != "true" ] && [ "${NON_INTERACTIVE:-}" != "true" ]; then
            log_warn "⚠️  $pkg sigue fallando por problemas de firma PGP."
            echo -e "${YELLOW}Opciones: [s] Instalar sin verificación | [r] Reconstruir keyring | [n] Saltar${NC}"
            read -rp "¿Qué deseas hacer? (s/r/N): " choice < /dev/tty
            case "$choice" in
                s|S)
                    if command -v yay &>/dev/null; then
                        yay -S --noconfirm --needed --mflags "--skippgpcheck" "$pkg" && return 0
                    else
                        sudo -n pacman -S --noconfirm --needed "$pkg" --overwrite '*' && return 0
                    fi
                    ;;
                r|R)
                    rebuild_keyring
                    # Retry one more time after full rebuild
                    if command -v yay &>/dev/null; then
                        yay -S --noconfirm --needed "$pkg" 2>/dev/null && return 0
                    else
                        sudo -n pacman -S --noconfirm --needed "$pkg" 2>/dev/null && return 0
                    fi
                    ;;
                *)
                    log_warn "Saltando $pkg por decisión del usuario"
                    return 1
                    ;;
            esac
        else
            log_warn "Saltando $pkg (modo desatendido, firma PGP inválida)"
            return 1
        fi
    fi

    log_error "Fallo al instalar $pkg"
    return 1
}
