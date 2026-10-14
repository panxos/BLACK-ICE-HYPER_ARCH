#!/usr/bin/env bash

module_journal() {
    local options=()
    if [[ "$1" == init && "${RESUME_MODULES:-false}" != true ]]; then
        options+=(--fresh)
    fi
    python3 "$MODULE_ROOT/scripts/module-state.py" "$1" --state "$MODULE_STATE" \
        --identity "$MODULE_IDENTITY" --fingerprint "$MODULE_FINGERPRINT" \
        --module "${2:-}" --source "${3:-$MODULE_ROOT/VERSION}" "${options[@]}"
}

run_install_module() {
    local module="$1" source_file="$2"
    if declare -F ensure_sudo >/dev/null; then
        ensure_sudo || return 1
    fi
    if [[ "${RESUME_MODULES:-false}" == true && "${MODULE_INVALIDATED:-false}" != true ]] && module_journal status "$module" "$source_file" && verify_install_module "$module"; then
        log_info "Módulo $module ya comprobado; se conserva."
        return 0
    fi
    MODULE_INVALIDATED=true
    module_journal begin "$module" "$source_file"
    # shellcheck source=/dev/null
    source "$source_file"
    verify_install_module "$module" || { log_error "Falló la comprobación del módulo $module"; exit 1; }
    module_journal 'done' "$module" "$source_file"
    if [[ "${BLACK_ICE_STOP_AFTER:-}" == "$module" ]]; then
        log_warn "Corte de QA después de $module. Se puede reanudar."
        exit 75
    fi
}
