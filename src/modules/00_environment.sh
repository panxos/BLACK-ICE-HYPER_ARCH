#!/bin/bash
# modules/00_environment.sh


# 1. Root Check
check_root

# 2. Boot Mode Check
check_boot_mode

# 3. Internet Check
log_info "Escaneando conectividad exterior..."
INTERNET_OK=false

for i in {1..3}; do
    if timeout 5 ping -c 1 8.8.8.8 &>/dev/null; then
        INTERNET_OK=true
        break
    fi
    log_warn "Intento $i: Fallo de enlace con 8.8.8.8. Reintentando..."
    sleep 1
done

if [ "$INTERNET_OK" = true ]; then
    # Double check DNS with reliable hosts
    if timeout 5 ping -c 1 google.com &>/dev/null || timeout 5 ping -c 1 cloudflare.com &>/dev/null; then
        success "Enlace DNS activo y verificado."
    else
        log_warn "Conexión IP detectada, pero falla resolución DNS."
        echo -e "${YELLOW}Posible problema de DNS. Continuando bajo riesgo.${NC}"
    fi
else
    log_warn "Sin enlace exterior detectado (8.8.8.8 off)."
    print_step 'Conexión de red'
    echo -e "${YELLOW}¿Deseas activar la red ahora (Protocolo BLACK-ICE)?${NC}"
    NET_CHOICE=$(ask_option "Elige herramienta:" "iwctl (WiFi)" "nmtui (General/Ethernet)" "No")
    if [ "$NET_CHOICE" == "iwctl (WiFi)" ]; then
        while true; do
            iwctl
            if timeout 10 ping -c 1 8.8.8.8 &> /dev/null; then
                success "Conexión establecida con éxito."
                break
            else
                log_error "Aún sin enlace. ¿Reintentar configuración?"
                if [[ $(ask_option "Decisión:" "Si" "No") == "No" ]]; then
                    exit 1
                fi
            fi
        done
    elif [ "$NET_CHOICE" == "nmtui (General/Ethernet)" ]; then
        nmtui
    elif [ "$NET_CHOICE" == "No" ]; then
        log_error "Se requiere enlace exterior para el despliegue."
        exit 1
    fi
fi

# 3.2 Country & Mirror Optimization
print_step 'Servidores de descarga / mirrors'
echo -e "${CYAN}Elegir los servidores más cercanos acelerará la descarga.${NC}\n"

if [ -n "${SELECTED_COUNTRY:-}" ]; then
    success "País pre-configurado: $SELECTED_COUNTRY"
else
    SELECTED_COUNTRY=$(ask_option "Selecciona tu país de origen:" "Chile" "United States" "Spain" "Brazil" "Germany" "Worldwide")
    export SELECTED_COUNTRY
fi

log_info "Optimizando mirrors para $SELECTED_COUNTRY (Protocolo HTTPS)..."

# Definir lista de países para reflector basados en la elección
REFLECTOR_COUNTRIES=""
case "$SELECTED_COUNTRY" in
    "Chile")     REFLECTOR_COUNTRIES="Chile,Brazil,United States" ;;
    "Brazil")    REFLECTOR_COUNTRIES="Brazil,Chile,United States" ;;
    "Spain")     REFLECTOR_COUNTRIES="Spain,France,Germany" ;;
    "Germany")   REFLECTOR_COUNTRIES="Germany,France,Netherlands" ;;
    "Worldwide") REFLECTOR_COUNTRIES="Worldwide" ;;
    *)           REFLECTOR_COUNTRIES="$SELECTED_COUNTRY" ;;
esac

OPTIMIZE_MIRRORS=true
if valid_mirrorlist /etc/pacman.d/mirrorlist; then
    if [[ ${AUTO_MODE:-false} == true ]]; then
        OPTIMIZE_MIRRORS=false
    elif [[ $(ask_option '¿Deseas revisar mirrors? (máximo 120 segundos)' 'No (Usar existentes)' 'Si (Optimizar)') == 'No (Usar existentes)' ]]; then
        OPTIMIZE_MIRRORS=false
    fi
fi
if [[ "$OPTIMIZE_MIRRORS" == true ]]; then
    optimize_arch_mirrors "$REFLECTOR_COUNTRIES"
else
    log_info 'Se conserva la lista HTTPS existente.'
fi

log_info 'Inicializando y sincronizando llaveros PGP de Arch Linux...'
mkdir -p /etc/pacman.d/gnupg
chmod 700 /etc/pacman.d/gnupg
retry_repository_command timeout --signal=TERM --kill-after=5s 60s pacman-key --init
retry_repository_command timeout --signal=TERM --kill-after=5s 60s pacman-key --populate archlinux
retry_repository_command pacman -Sy --needed --noconfirm archlinux-keyring
success 'Llavero oficial actualizado; firmas habilitadas.'

# 4. Keyboard Layout
print_step 'Distribución del teclado'

if [ -n "${KEYBOARD_LAYOUT:-}" ]; then
    loadkeys "$KEYBOARD_LAYOUT" 2>/dev/null
    KEYMAP="$KEYBOARD_LAYOUT"
    success "Mapeo de teclado: $KEYBOARD_LAYOUT (Protocolo Auto)"
else
    KEYMAP=$(ask_option "Selecciona distribución de teclado:" "la-latin1" "es" "us" "de" "fr")
    loadkeys "$KEYMAP" 2>/dev/null
    success "Mapeo de teclado fijado en: ${NEON_BLUE}$KEYMAP${NC}"
fi

# 5. Time update
log_info "Sincronizando reloj atómico (NTP)..."
timedatectl set-ntp true
success "Tiempo sincronizado con el núcleo."

# 6. Hostname Configuration
print_step 'Nombre del equipo'

if [ -n "${HOSTNAME:-}" ] && [ "${AUTO_MODE:-}" == "true" ]; then
    # Unattended mode: use hostname from config file
    if validate_hostname "$HOSTNAME"; then
        success "Hostname pre-configurado: $HOSTNAME (Protocolo Auto)"
    else
        log_warn "Hostname inválido en config ('$HOSTNAME'). Usando default."
        HOSTNAME="black-ice"
        success "Hostname establecido: $HOSTNAME (default)"
    fi
else
    # Attended mode: prompt user
    while true; do
        echo -e "${CYAN}Introduce el hostname del sistema (ej: black-ice, mi-laptop):${NC}"
        echo -e "${GREY}  Solo letras, números y guiones. Máx 63 chars. Sin espacios.${NC}"
        read -rp "> " USER_HOSTNAME < /dev/tty

        # Default fallback
        if [ -z "$USER_HOSTNAME" ]; then
            USER_HOSTNAME="black-ice"
            log_info "Sin entrada. Usando hostname por defecto: $USER_HOSTNAME"
        fi

        if validate_hostname "$USER_HOSTNAME"; then
            HOSTNAME="$USER_HOSTNAME"
            success "Hostname configurado: ${NEON_BLUE}$HOSTNAME${NC}"
            break
        else
            log_error "Hostname inválido. Solo alfanuméricos y guiones (1-63 chars, sin empezar/terminar con -)."
        fi
    done
fi

export HOSTNAME
