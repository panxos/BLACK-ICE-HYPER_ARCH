#!/usr/bin/env bash

ensure_sudo() {
    (( EUID != 0 )) || return 0
    if command sudo -n -v 2>/dev/null; then
        return 0
    fi
    if [[ ${NON_INTERACTIVE:-false} == true || ${AUTO_MODE:-false} == true ]] || [[ ! -t 0 && ! -t 3 && ! -t 4 ]]; then
        log_error 'La autorización sudo no está disponible. Autentica con sudo -v en este terminal y vuelve a ejecutar el despliegue.' >&2
        return 1
    fi
    log_warn 'sudo necesita autenticación. Introduce tu contraseña en el terminal para continuar.' >&2
    if ! command sudo -v < /dev/tty; then
        log_error 'Autenticación sudo cancelada o rechazada; no se ejecutó la operación privilegiada.' >&2
        return 1
    fi
}

run_as_root() {
    ensure_sudo || return 77
    if (( EUID == 0 )); then
        "$@"
    elif [[ ${NON_INTERACTIVE:-false} == true || ${AUTO_MODE:-false} == true ]]; then
        command sudo -n -- "$@"
    else
        command sudo -- "$@"
    fi
}

start_sudo_session() {
    local interval="${1:-45}" owner="$BASHPID"
    [[ "$interval" =~ ^[0-9]+([.][0-9]+)?$ && "$interval" == *[1-9]* ]] || return 1
    ensure_sudo || return 1
    (( EUID != 0 )) || return 0
    [[ -z ${SUDO_SESSION_PID:-} ]] || return 0
    SUDO_SESSION_OWNER="$owner"
    (
        exec </dev/null >/dev/null 2>&1 3>&- 4>&- 8>&-
        local sleeper=''
        trap '[[ -z "$sleeper" ]] || kill "$sleeper" 2>/dev/null || true; exit 0' TERM INT
        while kill -0 "$owner" 2>/dev/null; do
            sleep "$interval" &
            sleeper=$!
            wait "$sleeper" || exit 0
            sleeper=''
            kill -0 "$owner" 2>/dev/null || exit 0
            command sudo -n -v || exit 0
        done
    ) &
    SUDO_SESSION_PID=$!
}

stop_sudo_session() {
    [[ ${SUDO_SESSION_OWNER:-} == "$BASHPID" && -n ${SUDO_SESSION_PID:-} ]] || return 0
    kill "$SUDO_SESSION_PID" 2>/dev/null || true
    wait "$SUDO_SESSION_PID" 2>/dev/null || true
    unset SUDO_SESSION_PID SUDO_SESSION_OWNER
}
