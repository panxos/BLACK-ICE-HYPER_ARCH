#!/bin/bash
# ==============================================================================
# SOTA LOGGING LIBRARY
# Robust logging with levels, colors, timestamps, and file persistence.
# ==============================================================================

# Colors (Imported or Defined)
if [ -z "${NEON_CYAN:-}" ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    CYAN='\033[0;36m'
    WHITE='\033[1;37m'
    NC='\033[0m' # No Color
    BOLD='\033[1m'
fi

# LOG_FILE is derived from INSTALL_DIR or SCRIPT_DIR if available
PROJECT_ROOT="${INSTALL_DIR:-${SCRIPT_DIR:-$(pwd)}}"
LOG_DIR="$PROJECT_ROOT/logs"
mkdir -p "$LOG_DIR" 2>/dev/null || LOG_DIR="/tmp"
LOG_FILE="${LOG_FILE:-$LOG_DIR/black_ice_$(date +%Y%m%d_%H%M%S).log}"

# Timestamp function
timestamp() {
    date "+%Y-%m-%d %H:%M:%S"
}

# --- Logging Functions ---

log_raw() {
    local level="$1"
    local message="$2"
    echo -e "$(timestamp) [$level] $message" >> "$LOG_FILE"
}

log_info() {
    local message="$1"
    echo -e "${BLUE}[INFO]${NC} $message"
    log_raw "INFO" "$message"
}

log_success() {
    local message="$1"
    echo -e "${GREEN}[OK]${NC}   $message"
    log_raw "SUCCESS" "$message"
}

success() {
    log_success "$1"
}

log_warn() {
    local message="$1"
    echo -e "${YELLOW}[WARN]${NC} $message"
    log_raw "WARN" "$message"
}

log_error() {
    local message="$1"
    echo -e "${RED}[ERR]${NC}  $message" >&2
    log_raw "ERROR" "$message"
}

log_debug() {
    if [[ "$DEBUG" == "true" ]]; then
        echo -e "${MAGENTA}[DEBUG]${NC} $message"
        log_raw "DEBUG" "$message"
    fi
}

banner() {
    local title="$1"
    local subtitle="$2"
    
    # Evitar fallos de 'clear' en entornos sin TTY
    if [ -t 1 ] && [ -n "${TERM:-}" ]; then
        clear
    fi
    
    # Ancho fijo 100 caracteres para asegurar que todo calce
    # No usamos cálculo dinámico para evitar errores de renderizado en distintas terminales
    
    echo -e "${NEON_PURPLE}██████╗ ██╗      █████╗  ██████╗██╗  ██╗    ██╗ ██████╗███████╗"
    echo -e "${NEON_BLUE}██╔══██╗██║     ██╔══██╗██╔════╝██║ ██╔╝    ██║██╔════╝██╔════╝"
    echo -e "${NEON_CYAN}██████╔╝██║     ███████║██║     █████╔╝     ██║██║     █████╗  "
    echo -e "${NEON_BLUE}██╔══██╗██║     ██╔══██║██║     ██╔═██╗     ██║██║     ██╔══╝  "
    echo -e "${NEON_PURPLE}██████╔╝███████╗██║  ██║╚██████╗██║  ██╗    ██║╚██████╗███████╗"
    echo -e "${NEON_BLUE}╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝    ╚═╝ ╚═════╝╚══════╝"
    echo -e "    ${NEON_PURPLE}BLACK-ICE EDITION  ${NC}${GREY}|${NC}${NEON_CYAN}  .0 (SOTA)${NC}"
    
    # Marco manualmente alineado (98 guiones)
    local BORDER="──────────────────────────────────────────────────────────────────────────────────────────────────"
    
    echo -e "${NEON_BLUE}┌${BORDER}┐${NC}"
    
    # Línea 1: DEV y REPO (Adjusted for visual alignment)
    # Total width inside borders = 98 chars
    # Current content calculation: 89 chars. Need +9 spaces.
    echo -e "${NEON_BLUE}│${NC}  ${BOLD}DEV:${NC} ${WHITE}Francisco Aravena${NC}             ${GREY}|${NC} ${BOLD}REPO:${NC} ${CYAN}github.com/panxos/BLACK-ICE-HYPER_ARCH${NC}               ${NEON_BLUE}│${NC}"
    
    # Línea 2: WEB y LNKD
    # Need +2 spaces (Total 29 padding spaces)
    echo -e "${NEON_BLUE}│${NC}  ${BOLD}WEB:${NC} ${WHITE}soporteinfo.net${NC}               ${GREY}|${NC} ${BOLD}LNKD:${NC} ${CYAN}linkedin.com/in/youruser${NC}                             ${NEON_BLUE}│${NC}"
    
    # Línea 3: YTB y DATE
    local TODAY=$(date +%Y-%m-%d)
    # Need +9 spaces.
    echo -e "${NEON_BLUE}│${NC}  ${BOLD}YTB:${NC} ${RED}@Soporteinfo${NC}                  ${GREY}|${NC} ${BOLD}DATE:${NC} ${WHITE}${TODAY}${NC}                                           ${NEON_BLUE}│${NC}"
    
    echo -e "${NEON_BLUE}└${BORDER}┘${NC}"
    echo ""
    echo -e "${NEON_CYAN}>> $title${NC}"
    echo -e "${GREY}   $subtitle${NC}"
    echo ""
}
