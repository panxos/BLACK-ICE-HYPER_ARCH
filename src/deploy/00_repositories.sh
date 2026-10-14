#!/bin/bash
# deploy-modules/00_repositories.sh
# Configura Chaotic-AUR y comprueba que paru pueda ejecutarse.

banner "MÓDULO 1" "BLACK-ICE Repositorios"
cd "$USER_HOME" || exit 1

# --- Optimización Geográfica (Mirrors) ---
SELECTED_COUNTRY="${SELECTED_COUNTRY:-Chile}"

log_info "Optimizando mirrors para $SELECTED_COUNTRY..."
REFLECTOR_COUNTRIES=""
case "$SELECTED_COUNTRY" in
    "Chile")   REFLECTOR_COUNTRIES="Chile,Brazil,United States" ;;
    "Brazil")  REFLECTOR_COUNTRIES="Brazil,Chile,United States" ;;
    "Spain")   REFLECTOR_COUNTRIES="Spain,France,Germany" ;;
    "Germany") REFLECTOR_COUNTRIES="Germany,France,Netherlands" ;;
    *)         REFLECTOR_COUNTRIES="$SELECTED_COUNTRY" ;;
esac

if ! command -v reflector &>/dev/null; then
    log_info "Instalando reflector..."
    retry_repository_command pacman -Syu --needed --noconfirm reflector
fi

if command -v reflector &>/dev/null; then
    OPT_MIRRORS=n
    valid_mirrorlist /etc/pacman.d/mirrorlist || OPT_MIRRORS=y
    if [[ ${ASSUME_YES:-false} != true && ${NON_INTERACTIVE:-false} != true && ${AUTO_MODE:-false} != true ]] && [[ -t 0 || -t 3 || -t 4 ]]; then
        printf '¿Optimizar mirrors HTTPS? (máximo 120 segundos) [y/N]: '
        read -r -t 10 OPT_MIRRORS < /dev/tty || OPT_MIRRORS=n
        printf '\n'
    fi

    if [[ "$OPT_MIRRORS" =~ ^[Yy]$ ]]; then
        optimize_arch_mirrors "$REFLECTOR_COUNTRIES"
    else
        log_info 'Se conserva la lista de mirrors existente.'
    fi
fi

# --- Chaotic-AUR PRIMERO (paru vive aquí, compilado contra pacman actual) ---
log_info "Verificando siguiente fase: chaotic-aur"
if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
    log_info "Añadiendo repositorio chaotic-aur..."

    retry_repository_command timeout --signal=TERM --kill-after=5s 45s \
        pacman-key --recv-key 3056513887B78AEB --keyserver hkps://keyserver.ubuntu.com

    retry_repository_command pacman-key --lsign-key 3056513887B78AEB

    retry_repository_command pacman -U --noconfirm \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

    retry_repository_command pacman-key --populate archlinux chaotic

    printf '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n' | run_as_root tee -a /etc/pacman.conf


    success "chaotic-aur añadido correctamente"
else
    log_info "chaotic-aur ya está configurado"
    retry_repository_command pacman-key --populate archlinux chaotic
fi

# --- Actualizar sistema ANTES de instalar paru (ABI correcta garantizada) ---
log_info "Actualizando sistema completo..."
retry_repository_command pacman -Syu --noconfirm

# --- Instalar paru desde chaotic-aur (compilado contra el pacman actual del sistema) ---
# paru-bin de AUR es un binario pre-compilado: queda roto si pacman sube de versión mayor.
# La ejecución de paru se verifica después de instalarlo.
_PARU_OK=false
if command -v paru &>/dev/null && paru --version &>/dev/null 2>&1; then
    _PARU_OK=true
fi

if [ "$_PARU_OK" = false ]; then
    log_info "Instalando paru desde chaotic-aur..."
    # Instalar desde chaotic-aur (compilado contra libalpm del sistema)
    if run_as_root pacman -S --noconfirm --needed paru; then
        paru --version >/dev/null || { log_error 'paru no puede ejecutarse; se detuvo el despliegue.'; exit 1; }
        log_success "paru instalado desde chaotic-aur ($(paru --version | head -1))"
    else
        paru_status=$?
        (( paru_status != 77 )) || exit 77
        # Fallback: compilar desde AUR (requiere Rust, más lento pero siempre funciona)
        log_warn "paru no disponible en chaotic-aur. Compilando desde AUR (puede tardar)..."
        retry_repository_command pacman -S --needed --noconfirm base-devel git rust
        aur_work="${XDG_CACHE_HOME:-$HOME/.cache}/tmp/work/black-ice-paru-$$"
        mkdir -p "$aur_work"
        cd "$aur_work" || return 1
        retry_command git clone https://aur.archlinux.org/paru.git || { log_error "No se pudo clonar paru"; exit 1; }
        cd paru || { log_error "No se pudo entrar al directorio paru"; exit 1; }
        makepkg --noconfirm --needed || { log_error "makepkg falló para paru"; exit 1; }
        mapfile -t paru_packages < <(makepkg --packagelist)
        retry_repository_command pacman -U --noconfirm --needed "${paru_packages[@]}"
        paru --version >/dev/null || { log_error 'paru compilado no puede ejecutarse.'; exit 1; }
        cd "$SCRIPT_DIR" || { log_error "No se pudo volver a SCRIPT_DIR"; exit 1; }
        log_success "paru compilado e instalado ($(paru --version | head -1))"
    fi
else
    log_info "paru operativo ($(paru --version | head -1))"
fi

# BlackArch eliminado (v3.2+): Issues GPG/SHA1 persistentes. Tools vía AUR + Chaotic-AUR.
success "Repositorios configurados y sistema actualizado"
