#!/bin/bash
# modules/00_environment.sh

banner "PASO 1" "Verificación de Entorno y Red"

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
        echo -e "${YELLOW}Posible problema local de DNS. Continuando bajo riesgo.${NC}"
    fi
else
    log_warn "Sin enlace exterior detectado (8.8.8.8 off)."
    echo -e "${NEON_PURPLE}┌──────────────────────────────────────────────┐${NC}"
    echo -e "${NEON_PURPLE}│${NC}  ${BOLD}CONFIGURACIÓN DE RED REQUERIDA            ${NC} ${NEON_PURPLE}│${NC}"
    echo -e "${NEON_PURPLE}└──────────────────────────────────────────────┘${NC}"
    echo -e "${YELLOW}¿Deseas activar la red ahora (Protocolo BLACK-ICE)?${NC}"
    local NET_CHOICE=$(ask_option "Elige herramienta:" "iwctl (WiFi)" "nmtui (General/Ethernet)" "No")
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

# 3.1 Update Keyring (Harden PGP environment)
log_info "Inicializando y sincronizando llaveros PGP (Arch Linux)..."

# Asegurar que el directorio de GPG existe y está limpio si hay problemas
mkdir -p /etc/pacman.d/gnupg
chmod 700 /etc/pacman.d/gnupg

while true; do
    # Inicializar y poblar llaves antes de descargar el keyring
    pacman-key --init >/dev/null 2>&1
    pacman-key --populate archlinux >/dev/null 2>&1
    
    if pacman -Syy --noconfirm archlinux-keyring >/dev/null 2>&1; then
        success "Llaveros PGP actualizados y validados."
        break
    else
        log_warn "Error sincronizando llaveros. Aplicando limpieza profunda de GPG..."
        rm -rf /etc/pacman.d/gnupg/*
        pacman-key --init >/dev/null 2>&1
        pacman-key --populate archlinux >/dev/null 2>&1
        
        if pacman -Syy --noconfirm archlinux-keyring >/dev/null 2>&1; then
             success "Llaveros PGP recuperados tras limpieza profunda."
             break
        fi
        
        log_error "Fallo persistente en PGP. Verificando conexión de red..."
        sleep 5
    fi
done

# 3.2 Country & Mirror Optimization
echo -e "\n${NEON_PURPLE}┌──────────────────────────────────────────────┐${NC}"
echo -e "${NEON_PURPLE}│${NC}  ${BOLD}OPTIMIZACIÓN GEOGRÁFICA (MIRRORS)         ${NC} ${NEON_PURPLE}│${NC}"
echo -e "${NEON_PURPLE}└──────────────────────────────────────────────┘${NC}"
echo -e "${CYAN}Elegir los servidores más cercanos acelerará la descarga.${NC}\n"

if [ -n "${SELECTED_COUNTRY:-}" ]; then
    success "País pre-configurado: $SELECTED_COUNTRY"
else
    SELECTED_COUNTRY=$(ask_option "Selecciona tu país de origen:" "Chile" "United States" "Spain" "Brazil" "Germany")
    export SELECTED_COUNTRY
fi

log_info "Optimizando mirrors para $SELECTED_COUNTRY (Protocolo HTTPS)..."

# Definir lista de países para reflector basados en la elección
REFLECTOR_COUNTRIES=""
case "$SELECTED_COUNTRY" in
    "Chile")   REFLECTOR_COUNTRIES="Chile,Brazil,United States" ;;
    "Brazil")  REFLECTOR_COUNTRIES="Brazil,Chile,United States" ;;
    "Spain")   REFLECTOR_COUNTRIES="Spain,France,Germany" ;;
    "Germany") REFLECTOR_COUNTRIES="Germany,France,Netherlands" ;;
    *)         REFLECTOR_COUNTRIES="$SELECTED_COUNTRY" ;;
esac

while true; do
    if ! command -v reflector &>/dev/null; then
        pacman -S --noconfirm reflector >/dev/null 2>&1 || continue
    fi
    
    # --- Check for existing mirrors to avoid re-run ---
    if [ -s /etc/pacman.d/mirrorlist ]; then
        log_info "Lista de mirrors detectada previamente."
        
        if [ "${AUTO_MODE:-}" == "true" ]; then
            log_info "Modo Desatendido: Usando mirrors existentes para ahorrar tiempo."
            break
        elif command -v ask_option >/dev/null; then
             if [[ $(ask_option "¿Deseas re-escanear mirrors? (Toma tiempo)" "No (Usar existentes)" "Si (Optimizar)") == "No (Usar existentes)" ]]; then
                log_info "Saltando optimización de mirrors."
                break
             fi
        fi
    fi

    log_info "Ejecutando reflector para: $REFLECTOR_COUNTRIES..."
    echo -e "${YELLOW}>> PROCESANDO MIRRORS... POR FAVOR ESPERE (ESTO PUEDE TARDAR UNOS MINUTOS)${NC}"
    echo -e "${GREY}   Buscando los servidores más rápidos y recientes...${NC}"
    
    if reflector --country "$REFLECTOR_COUNTRIES" --protocol https --latest 100 --number 10 --sort rate --connection-timeout 5 --download-timeout 5 --verbose --save /etc/pacman.d/mirrorlist; then
        success "Nodos de descarga optimizados para tu región."
        break
    else
        log_warn "Fallo al optimizar con países específicos. Intentando modo global..."
        if reflector --protocol https --latest 100 --number 10 --sort rate --connection-timeout 5 --download-timeout 5 --save /etc/pacman.d/mirrorlist >/dev/null 2>&1; then
            success "Nodos globales actualizados (Fallo regional)."
            break
        fi
        
        log_warn "¿Reintentar optimización de mirrors?"
        if [[ $(ask_option "Decisión:" "Si" "No") == "No" ]]; then
            log_warn "Usando lista de mirrors actual sin optimizar."
            break
        fi
    fi
done

# 4. Keyboard Layout
echo -e "\n${NEON_PURPLE}┌──────────────────────────────────────────────┐${NC}"
echo -e "${NEON_PURPLE}│${NC}  ${BOLD}CONFIGURACIÓN DE ENTRADA (TECLADO)        ${NC} ${NEON_PURPLE}│${NC}"
echo -e "${NEON_PURPLE}└──────────────────────────────────────────────┘${NC}"

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
echo -e "\n${NEON_PURPLE}┌──────────────────────────────────────────────┐${NC}"
echo -e "${NEON_PURPLE}│${NC}  ${BOLD}CONFIGURACIÓN DE IDENTIDAD (HOSTNAME)     ${NC} ${NEON_PURPLE}│${NC}"
echo -e "${NEON_PURPLE}└──────────────────────────────────────────────┘${NC}"

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
