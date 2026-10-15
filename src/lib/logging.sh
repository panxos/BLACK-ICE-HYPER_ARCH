#!/bin/bash
# ==============================================================================
#  LOGGING LIBRARY - P4nx0z Edition (Precision UI Fix)
# ==============================================================================

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NEON_BLUE='\033[1;34m'
NEON_CYAN='\033[1;36m'
NEON_PURPLE='\033[1;35m'
GREY='\033[0;90m'
NC='\033[0m'
BOLD='\033[1m'
export RED GREEN YELLOW BLUE CYAN WHITE NEON_BLUE NEON_CYAN NEON_PURPLE GREY NC BOLD

# shellcheck source=src/lib/terminal-ui.sh
source "$(dirname "${BASH_SOURCE[0]}")/terminal-ui.sh"

BLACK_ICE_VERSION="${BLACK_ICE_VERSION:-$(cat "$(dirname "${BASH_SOURCE[0]}")/../../VERSION")}"
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/black-ice/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/install-$(date +%Y%m%d-%H%M%S)-$$.log"
if touch "$LOG_FILE" 2>/dev/null; then
    chmod 600 "$LOG_FILE" 2>/dev/null
else
    echo 'No se pudo crear un registro privado del instalador.' >&2
    exit 1
fi

timestamp() { date "+%Y-%m-%d %H:%M:%S"; }

log_raw() {
    local level="$1"
    local message
    message=$(black_ice_ui_clean "$2")
    printf '%s [%s] %s\n' "$(timestamp)" "$level" "$message" >> "$LOG_FILE"
}

installer_ui() {
    local renderer="$1"
    shift
    if [[ -t 3 && ! -t 1 ]]; then
        "$renderer" "$@" >&3
        NO_COLOR=1 "$renderer" "$@" >> "$LOG_FILE"
    else
        "$renderer" "$@"
    fi
}

log_status() {
    local level="$1" message="$2"
    if [[ -t 3 && ! -t 1 ]]; then
        black_ice_status "$level" "$message" >&3
    else
        black_ice_status "$level" "$message"
    fi
    [[ "$level" != OK ]] || level=SUCCESS
    log_raw "$level" "$message"
}

log_info() { log_status INFO "$1"; }
log_success() { log_status OK "$1"; }
success() { log_success "$1"; }
log_warn() { log_status WARN "$1"; }
log_error() { log_status ERROR "$1" >&2; }

print_step() {
    installer_ui black_ice_section "$1" "${3:-}"
}

install_stage() {
    BLACK_ICE_CURRENT_STAGE="$1"
    BLACK_ICE_STAGE_TITLE="$2"
    installer_ui black_ice_stage "$1" "$2"
}

banner() {
    # shellcheck source=src/lib/banner.sh
    source "$(dirname "${BASH_SOURCE[0]}")/banner.sh"
    if [[ ${BLACK_ICE_BANNER_SHOWN:-false} == true ]]; then
        installer_ui black_ice_section "${1:-}" "${2:-}"
    else
        installer_ui black_ice_banner "${1:-}" "${2:-}" "$BLACK_ICE_VERSION"
        BLACK_ICE_BANNER_SHOWN=true
    fi
}
