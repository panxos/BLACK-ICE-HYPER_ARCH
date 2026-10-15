#!/usr/bin/env bash

black_ice_banner() {
    local title="${1:-INSTALACIÓN}" subtitle="${2:-}" version="${3:-${BLACK_ICE_VERSION:-}}"
    local columns="${COLUMNS:-}" locale_name="${LC_ALL:-${LC_CTYPE:-${LANG:-C}}}"
    local accent='' violet='' bold='' reset='' left='|' right='|' top='+' bottom='+' stroke='-'
    local outer inner rule brand="BLACK-ICE / ARCH" line chunk spaces line_color
    if [[ ! "$columns" =~ ^[0-9]{1,4}$ ]] || (( 10#$columns < 1 )); then
        columns=$(tput cols 2>/dev/null) || columns=80
    fi
    [[ "$columns" =~ ^[0-9]{1,4}$ ]] || columns=80
    columns=$((10#$columns))
    (( columns > 92 )) && columns=92
    local LC_ALL=C.UTF-8
    if [[ -t 1 && ${TERM:-dumb} != dumb && ! ${NO_COLOR+x} ]]; then
        accent=$'\033[36m'; violet=$'\033[1;35m'; bold=$'\033[1m'; reset=$'\033[0m'
    fi
    if [[ ${locale_name^^} == *UTF-8* || ${locale_name^^} == *UTF8* ]]; then
        left='│'; right='│'; top='┌'; bottom='└'; stroke='─'
    fi
    title=$(printf '%s' "$title" | LC_ALL=C tr '\000-\037\177' ' ')
    subtitle=$(printf '%s' "$subtitle" | LC_ALL=C tr '\000-\037\177' ' ')
    version=$(printf '%s' "$version" | LC_ALL=C tr '\000-\037\177' ' ')
    if (( columns < 20 )); then
        for line in "$brand" "$version" "$title" "$subtitle"; do
            while [[ -n "$line" ]]; do
                printf '%s\n' "${line:0:columns}"
                line="${line:columns}"
            done
        done
        return 0
    fi
    outer=$((columns - 4)); inner=$((outer - 4))
    printf -v rule '%*s' "$((outer - 2))" ''
    rule=${rule// /$stroke}
    if [[ "$top" == '+' ]]; then
        printf '  %b+%s+%b\n' "$accent" "$rule" "$reset"
    else
        printf '  %b%s%s┐%b\n' "$accent" "$top" "$rule" "$reset"
    fi
    if [[ -n "$version" ]]; then
        version="v${version#v}"
        if (( ${#brand} + ${#version} + 2 <= inner )); then
            printf -v spaces '%*s' "$((inner - ${#brand} - ${#version}))" ''
            brand+="$spaces$version"
            version=''
        fi
    fi
    local -a lines=("$brand")
    [[ -z "$version" ]] || lines+=("$version")
    local -a logo=(
        ' ____  _        _    ____ _  __     ___ ____ _____ '
        '| __ )| |      / \  / ___| |/ /    |_ _/ ___| ____|'
        '|  _ \| |     / _ \| |   | '\'' /      | | |   |  _|  '
        '| |_) | |___ / ___ \ |___| . \      | | |___| |___ '
        '|____/|_____/_/   \_\____|_|\_\    |___\____|_____|'
    )
    if (( inner >= 56 )); then
        lines+=('' "${logo[@]}" '' 'ARCH LINUX  /  HYPRLAND')
    fi
    lines+=('' "$title" "$subtitle" '' 'Francisco Aravena / soporteinfo.net')
    for line in "${lines[@]}"; do
        line_color=''
        [[ "$line" == "$brand" ]] && line_color="$bold$accent"
        [[ "$line" == "$title" ]] && line_color="$bold"
        [[ "$line" != 'ARCH LINUX  /  HYPRLAND' ]] || line_color="$violet"
        for chunk in "${logo[@]}"; do
            [[ "$line" != "$chunk" ]] || line_color="$bold$accent"
        done
        while :; do
            chunk="${line:0:inner}"
            if (( ${#line} > inner )) && [[ "$chunk" == *' '* && -n ${chunk% *} ]]; then
                chunk="${chunk% *}"
            fi
            line="${line:${#chunk}}"
            line="${line# }"
            printf -v spaces '%*s' "$((inner - ${#chunk}))" ''
            printf '  %b%s%b %b%s%b%s %b%s%b\n' "$accent" "$left" "$reset" "$line_color" "$chunk" "$reset" "$spaces" "$accent" "$right" "$reset"
            [[ -z "$line" ]] && break
        done
    done
    if [[ "$bottom" == '+' ]]; then
        printf '  %b+%s+%b\n\n' "$accent" "$rule" "$reset"
    else
        printf '  %b%s%s┘%b\n\n' "$accent" "$bottom" "$rule" "$reset"
    fi
}
