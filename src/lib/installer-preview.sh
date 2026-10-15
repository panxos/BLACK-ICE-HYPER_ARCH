#!/usr/bin/env bash

black_ice_installer_preview() (
    set -euo pipefail
    local preview_root choice
    preview_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
    # shellcheck source=src/lib/banner.sh
    source "$preview_root/src/lib/banner.sh"
    # shellcheck source=src/lib/terminal-ui.sh
    source "$preview_root/src/lib/terminal-ui.sh"
    # shellcheck source=src/lib/utils.sh
    source "$preview_root/src/lib/utils.sh"
    installer_ui() { "$@"; }
    log_warn() { black_ice_status WARN "$1"; }
    BLACK_ICE_CURRENT_STAGE=1
    BLACK_ICE_STAGE_TITLE='Entorno y conectividad / VISTA PREVIA'
    BLACK_ICE_UI_TITLE='VISTA PREVIA DEL INSTALADOR'
    BLACK_ICE_UI_SUBTITLE='Demostración interactiva / no modifica el sistema'
    black_ice_banner 'VISTA PREVIA DEL INSTALADOR' 'Demostración interactiva / no modifica el sistema' "$BLACK_ICE_VERSION"
    black_ice_stage 1 "$BLACK_ICE_STAGE_TITLE"
    choice=$(ask_option 'Servidores de descarga / elige tu región' 'Chile' 'United States' 'Spain' 'Brazil' 'Germany' 'Worldwide')
    black_ice_status OK "Región de demostración: $choice"
    BLACK_ICE_CURRENT_STAGE=2
    BLACK_ICE_STAGE_TITLE='Disco y cifrado / VISTA PREVIA'
    choice=$(ask_option 'Sistema de archivos / configuración de demostración' 'btrfs' 'ext4')
    black_ice_status OK "Sistema de archivos de demostración: $choice"
    black_ice_notice '/dev/vda (ejemplo; no se ejecutará el borrado)'
    black_ice_section 'FIN DE LA VISTA PREVIA' 'No se ejecutaron operaciones de instalación ni cambios de configuración.'
)
