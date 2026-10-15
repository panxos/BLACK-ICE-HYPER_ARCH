#!/usr/bin/env bash

black_ice_ui_style() {
    local columns="${COLUMNS:-}" locale_name="${LC_ALL:-${LC_CTYPE:-${LANG:-C}}}"
    if [[ ! "$columns" =~ ^[0-9]{1,4}$ ]] || (( 10#$columns < 1 )); then
        columns=$(tput cols 2>/dev/null) || columns=80
    fi
    [[ "$columns" =~ ^[0-9]{1,4}$ ]] || columns=80
    bi_width=$((10#$columns))
    (( bi_width > 92 )) && bi_width=92
    bi_cyan='' bi_violet='' bi_white='' bi_muted='' bi_reset='' bi_red='' bi_green='' bi_yellow=''
    bi_stroke='-'
    if [[ -t 1 && ${TERM:-dumb} != dumb && ! ${NO_COLOR+x} ]]; then
        bi_cyan=$'\033[1;36m'; bi_violet=$'\033[1;35m'; bi_white=$'\033[1;37m'
        bi_muted=$'\033[0;37m'; bi_reset=$'\033[0m'; bi_red=$'\033[1;31m'
        bi_green=$'\033[1;32m'; bi_yellow=$'\033[1;33m'
    fi
    if [[ ${locale_name^^} == *UTF-8* || ${locale_name^^} == *UTF8* ]]; then
        bi_stroke='─'
    fi
    return 0
}

black_ice_ui_clean() {
    printf '%s' "$1" | sed -E 's/\\033\[[0-9;]*m//g; s/\x1b\[[0-9;]*[[:alpha:]]//g' | LC_ALL=C tr '\000-\037\177' ' '
}

black_ice_ui_text() {
    local text="$1" color="${2:-}" prefix="${3:-  }" chunk space width prefix_width
    local LC_ALL=C.UTF-8
    text=$(black_ice_ui_clean "$text")
    prefix_width=$(black_ice_ui_clean "$prefix")
    prefix_width=${#prefix_width}
    if (( bi_width <= prefix_width )); then
        prefix=''; prefix_width=0
    fi
    width=$((bi_width - prefix_width))
    while :; do
        chunk="${text:0:width}"
        if (( ${#text} > width )) && [[ "$chunk" == *' '* && -n ${chunk% *} ]]; then
            chunk="${chunk% *}"
        fi
        text="${text:${#chunk}}"; text="${text# }"
        printf '%s%s%s%s\n' "$prefix" "$color" "$chunk" "$bi_reset"
        [[ -n "$text" ]] || break
        printf -v space '%*s' "$prefix_width" ''
        prefix="$space"
    done
}

black_ice_section() {
    local title="$1" description="${2:-}" rule
    black_ice_ui_style
    printf '\n'
    black_ice_ui_text "$title" "$bi_violet" '  // '
    if (( bi_width >= 20 )); then
        printf -v rule '%*s' "$((bi_width - 4))" ''
        printf '  %s%s%s\n' "$bi_violet" "${rule// /$bi_stroke}" "$bi_reset"
    fi
    [[ -z "$description" ]] || black_ice_ui_text "$description" "$bi_muted"
    printf '\n'
}

black_ice_stage() {
    local stage="$1" title="$2" name label line='' index=0 group_limit=4 in_group=0
    black_ice_ui_style
    (( bi_width >= 60 )) || group_limit=2
    (( bi_width >= 28 )) || group_limit=1
    printf '\n'
    black_ice_ui_text "BLACK-ICE / ARCH   |   FASE BASE" "$bi_cyan"
    for name in ENTORNO DISCO BASE SISTEMA ACCESO ENERGIA ARRANQUE CIERRE; do
        ((++index))
        printf -v label '%02d %s' "$index" "$name"
        [[ "$index" != "$stage" ]] || label="[$label]"
        if [[ -n "$line" ]] && (( in_group >= group_limit || ${#line} + ${#label} + 4 > bi_width - 4 )); then
            black_ice_ui_text "$line" "$bi_muted"
            line=''; in_group=0
        fi
        [[ -z "$line" ]] || line+=' / '
        line+="$label"
        ((++in_group))
    done
    [[ -z "$line" ]] || black_ice_ui_text "$line" "$bi_muted"
    black_ice_section "$(printf '%02d / 08' "$stage")   $title"
}

black_ice_menu() {
    local title="$1" option index=0
    shift
    black_ice_ui_style
    if [[ -n ${BLACK_ICE_CURRENT_STAGE:-} && -t 1 && ${TERM:-dumb} != dumb && ! ${NO_COLOR+x} ]]; then
        printf '\033[2J\033[H'
        black_ice_banner "${BLACK_ICE_UI_TITLE:-INSTALACIÓN BASE}" "${BLACK_ICE_UI_SUBTITLE:-Arch Linux / sistema, discos y arranque}" "${BLACK_ICE_VERSION:-}"
        black_ice_stage "$BLACK_ICE_CURRENT_STAGE" "${BLACK_ICE_STAGE_TITLE:-}"
    fi
    black_ice_ui_text "$title" "$bi_white"
    printf '\n'
    for option in "$@"; do
        ((++index))
        black_ice_ui_text "$option" "$bi_white" "  ${bi_cyan}$(printf '%02d' "$index")${bi_reset}  "
    done
    printf '\n'
    black_ice_ui_text "Escribe un número y pulsa Enter." "$bi_muted"
}

black_ice_status() {
    local level="$1" text="$2" color
    black_ice_ui_style
    case "$level" in
        OK) color="$bi_green" ;;
        WARN) color="$bi_yellow" ;;
        ERROR) color="$bi_red" ;;
        *) color="$bi_cyan" ;;
    esac
    black_ice_ui_text "$text" "$bi_muted" "  ${color}$(printf '%-5s' "$level")${bi_reset}  "
}

black_ice_notice() {
    black_ice_ui_style
    printf '\n'
    black_ice_ui_text 'BORRADO DEL DISCO DE DESTINO' "$bi_red" '  !! '
    black_ice_ui_text "Se eliminarán permanentemente todos los datos de $1." "$bi_white"
    black_ice_ui_text 'Escribe SI para autorizar el borrado o NO para cancelar.' "$bi_yellow"
    printf '\n'
}
