#!/usr/bin/env bash

retry_repository_command() {
    local attempt status
    for attempt in 1 2 3; do
        if run_as_root "$@"; then
            return 0
        else
            status=$?
        fi
        if (( status == 77 )); then
            log_error 'La operación de repositorios requiere autorización sudo; se detuvo sin saltarla.'
            return 77
        fi
        log_warn "Operación de repositorios fallida (intento $attempt/3, código $status): $*"
        (( attempt == 3 )) || sleep 2
    done
    log_error 'No se completó la configuración de repositorios. Se conservaron las firmas; corrige el error y reanuda el despliegue.'
    return 1
}

valid_mirrorlist() {
    [[ -s "$1" ]] || return 1
    awk '
        /^[[:space:]]*(#|$)/ { next }
        $1 == "Server" && $2 == "=" && $3 ~ /^https:\/\// && index($3, "$repo") && index($3, "$arch") { count++; next }
        { bad = 1 }
        END { exit !(count > 0 && !bad) }
    ' "$1"
}

optimize_arch_mirrors() (
    local countries="${1:-Worldwide}" destination="${2:-/etc/pacman.d/mirrorlist}"
    local work candidate pending status=0
    local args=(--protocol https --latest 20 --number 8 --sort rate --connection-timeout 5 --download-timeout 5)
    [[ "$countries" == Worldwide ]] || args+=(--country "$countries")
    if ! command -v reflector >/dev/null; then
        log_warn 'Reflector no está disponible; se conserva la lista de mirrors existente.'
        valid_mirrorlist "$destination"
        return $?
    fi
    mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/tmp/work"
    work=$(mktemp -d "${XDG_CACHE_HOME:-$HOME/.cache}/tmp/work/black-ice-mirrors.XXXXXX")
    trap 'rm -rf -- "$work"' EXIT
    candidate="$work/mirrorlist"
    log_info 'Evaluando hasta veinte mirrors HTTPS (máximo 120 segundos)...'
    timeout --signal=TERM --kill-after=5s 120s reflector "${args[@]}" --save "$candidate" || status=$?
    if (( status != 0 )) || ! valid_mirrorlist "$candidate"; then
        log_warn "No se obtuvo una lista válida (código $status); se conserva la anterior."
        if ! valid_mirrorlist "$destination"; then
            log_error 'No hay una lista HTTPS válida de mirrors. Revisa conectividad y /etc/pacman.d/mirrorlist antes de continuar.'
            return 1
        fi
        return 0
    fi
    pending="${destination}.black-ice-$$"
    run_as_root install -m 644 -- "$candidate" "$pending" || return 1
    if ! run_as_root mv -f -- "$pending" "$destination"; then
        run_as_root rm -f -- "$pending" || true
        return 1
    fi
    log_success 'Lista de mirrors HTTPS validada y publicada.'
)
