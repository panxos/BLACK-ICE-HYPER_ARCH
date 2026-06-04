#!/bin/bash
# ==============================================================================
#  LOGGING LIBRARY - P4nx0z Edition (Precision UI Fix)
# ==============================================================================

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NEON_BLUE='\033[1;34m'
NEON_CYAN='\033[1;36m'
NEON_PURPLE='\033[1;35m'
GREY='\033[0;90m'
NC='\033[0m'
BOLD='\033[1m'

LOG_FILE="${HOME}/black_ice_install.log"
if touch "$LOG_FILE" 2>/dev/null; then
    chmod 600 "$LOG_FILE" 2>/dev/null
else
    LOG_FILE="/tmp/black_ice_install_$$.log"
    touch "$LOG_FILE" && chmod 600 "$LOG_FILE"
fi

timestamp() { date "+%Y-%m-%d %H:%M:%S"; }

log_raw() {
    local level="$1"
    local message="$2"
    echo -e "$(timestamp) [$level] $(echo "$message" | sed 's/\x1B\[[0-9;]*[JKmsu]//g')" >> "$LOG_FILE"
}

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; log_raw "INFO" "$1"; }
log_success() { echo -e "${GREEN}[OK]${NC}   $1"; log_raw "SUCCESS" "$1"; }
success() { log_success "$1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; log_raw "WARN" "$1"; }
log_error() { echo -e "${RED}[ERR]${NC}  $1" >&2; log_raw "ERROR" "$1"; }

# --- PRECISIÓN MATEMÁTICA PARA EL CUADRO ---
# Borde superior tiene 98 '─'. Total ancho visual = 100.
# Espacio interno = 98 espacios.

print_line() {
    local l1="$1" v1="$2" l2="$3" v2="$4"
    local total_internal=98
    
    # Columna 1 (Ancho 46)
    local col1_label="${l1}: "
    local col1_content="${v1}"
    local col1_raw="${col1_label}${col1_content}"
    
    # Columna 2 (Ancho 46)
    local col2_label="${l2}: "
    local col2_content="${v2}"
    local col2_raw="${col2_label}${col2_content}"
    
    # Nueva Estrategia: 98 espacios internos exactos.
    # │ (1) + espacio (1) + Col1 (45) + espacio (1) + │ (1) + espacio (1) + Col2 (48) + espacio (1) + │ (1) = 100
    
    local c1_fix=$(printf '%-45s' "${col1_raw}")
    local c2_fix=$(printf '%-48s' "${col2_raw}")
    
    echo -e "${NEON_BLUE}│${NC} ${WHITE}${c1_fix}${NC} ${GREY}│${NC} ${CYAN}${c2_fix}${NC} ${NEON_BLUE}│${NC}"
}

print_step() {
    local text="$1"
    local color="${2:-$NEON_PURPLE}"
    local internal_width=60 
    
    local border=$(printf '─%.0s' $(seq 1 $internal_width))
    echo -e "${color}┌${border}┐${NC}"
    
    # Texto centrado o con padding fijo
    local text_clean=$(echo "$text" | sed 's/\x1B\[[0-9;]*[JKmsu]//g')
    # Reemplazar tildes y caracteres especiales con sus equivalentes ASCII para contar la longitud de visualización correctamente incluso en LC_ALL=C
    local text_len_str=$(echo "$text_clean" | sed 's/Á/A/g; s/É/E/g; s/Í/I/g; s/Ó/O/g; s/Ú/U/g; s/á/a/g; s/é/e/g; s/í/i/g; s/ó/o/g; s/ú/u/g; s/Ñ/N/g; s/ñ/n/g')
    
    local pad=$((internal_width - ${#text_len_str} - 2))
    [ $pad -lt 0 ] && pad=0
    local spaces=$(printf '%*s' "$pad" "")
    
    echo -e "${color}│${NC}  ${BOLD}${text}${NC}${spaces}${color}│${NC}"
    echo -e "${color}└${border}┘${NC}"
}

banner() {
    local title="$1"
    local subtitle="$2"
    if [ -t 1 ] && [ -n "${TERM:-}" ]; then clear; fi
    
    echo -e "${NEON_PURPLE}██████╗ ██╗      █████╗  ██████╗██╗  ██╗    ██╗ ██████╗███████╗"
    echo -e "${NEON_BLUE}██╔══██╗██║     ██╔══██╗██╔════╝██║ ██╔╝    ██║██╔════╝██╔════╝"
    echo -e "${NEON_CYAN}██████╔╝██║     ███████║██║     █████╔╝     ██║██║     █████╗  "
    echo -e "${NEON_BLUE}██╔══██╗██║     ██╔══██║██║     ██╔═██╗     ██║██║     ██╔══╝  "
    echo -e "${NEON_PURPLE}██████╔╝███████╗██║  ██║╚██████╗██║  ██╗    ██║╚██████╗███████╗"
    echo -e "${NEON_BLUE}╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝    ╚═╝ ╚═════╝╚══════╝"
    echo -e "    ${NEON_PURPLE}BLACK-ICE EDITION  ${NC}${GREY}|${NC}${NEON_CYAN}  v3.11.0${NC}"
    
    local BORDER=$(printf '─%.0s' $(seq 1 98))
    echo -e "${NEON_BLUE}┌${BORDER}┐${NC}"
    print_line "DEV" "Francisco Aravena" "REPO" "github.com/panxos/BLACK-ICE-ARCH"
    print_line "WEB" "soporteinfo.net" "LNKD" "linkedin.com/in/faravena/"
    print_line "YTB" "@Soporteinfo" "DATE" "$(date +%Y-%m-%d)"
    echo -e "${NEON_BLUE}└${BORDER}┘${NC}"
    echo ""
    [ -n "$title" ] && echo -e "${NEON_CYAN}>> $title${NC}"
    [ -n "$subtitle" ] && echo -e "${GREY}   $subtitle${NC}"
    echo ""
}
