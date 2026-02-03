#!/bin/bash
# deploy-modules/02_security_tools.sh
# Interactive Cybersecurity Tools Installer with Categories
# Author: Francisco Aravena (P4nX0Z)
# Version: 2.0 - Interactive Edition

banner "MÓDULO 3" "Herramientas de Seguridad"

# Colors for menu
readonly CYAN='\033[0;36m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly NC='\033[0m'

# Installation log
INSTALL_LOG="/tmp/cybersec_install_$(date +%Y%m%d_%H%M%S).log"
INSTALLED_COUNT=0
FAILED_COUNT=0

# Function to install a tool
install_tool() {
    local tool="$1"
    local display_name="${2:-$tool}"
    
    if pacman -Q "$tool" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $display_name (ya instalado)"
        return 0
    fi
    
    echo -e "  ${CYAN}→${NC} Instalando $display_name..."
    
    if sudo -n pacman -S --needed --noconfirm "$tool" &>>"$INSTALL_LOG"; then
        echo -e "  ${GREEN}✓${NC} $display_name instalado"
        ((INSTALLED_COUNT++))
        return 0
    elif yay -S --needed --noconfirm "$tool" &>>"$INSTALL_LOG"; then
        echo -e "  ${GREEN}✓${NC} $display_name instalado (AUR)"
        ((INSTALLED_COUNT++))
        return 0
    else
        echo -e "  ${RED}✗${NC} $display_name no disponible"
        echo "FAILED: $tool" >> "$INSTALL_LOG"
        ((FAILED_COUNT++))
        return 1
    fi
}

# Function to show category menu
show_category_menu() {
    local category="$1"
    shift
    local tools=("$@")
    
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${MAGENTA}BLACK-ICE ARCH${NC} - Instalador de Herramientas        ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  Categoría: ${YELLOW}$category${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}[1]${NC} Instalar todas las herramientas de esta categoría"
    echo -e "${GREEN}[2]${NC} Seleccionar herramientas individuales"
    echo -e "${RED}[0]${NC} Volver al menú principal"
    echo ""
    read -p "Selecciona una opción: " choice < /dev/tty
    
    case $choice in
        1)
            log_info "Instalando todas las herramientas de: $category"
            for tool_entry in "${tools[@]}"; do
                IFS='|' read -r package display_name <<< "$tool_entry"
                install_tool "$package" "$display_name"
            done
            ;;
        2)
            select_individual_tools "$category" "${tools[@]}"
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Opción inválida${NC}"
            sleep 1
            ;;
    esac
}

# Function to select individual tools
select_individual_tools() {
    local category="$1"
    shift
    local tools=("$@")
    local selected=()
    
    while true; do
        clear
        echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║${NC}  Selección Individual - ${YELLOW}$category${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        local idx=1
        for tool_entry in "${tools[@]}"; do
            IFS='|' read -r package display_name <<< "$tool_entry"
            local status=""
            if pacman -Q "$package" &>/dev/null; then
                status="${GREEN}(ya instalado)${NC}"
            elif [[ " ${selected[@]} " =~ " ${idx} " ]]; then
                status="${YELLOW}[SELECCIONADO]${NC}"
            fi
            echo -e "[$idx] $display_name $status"
            ((idx++))
        done
        
        echo ""
        echo -e "${GREEN}[A]${NC} Instalar herramientas seleccionadas"
        echo -e "${RED}[0]${NC} Volver"
        echo ""
        read -p "Selecciona herramientas (ej: 1 3 5) o [A] para instalar: " input < /dev/tty
        
        if [[ "$input" == "0" ]]; then
            return
        elif [[ "$input" =~ ^[Aa]$ ]]; then
            if [ ${#selected[@]} -gt 0 ]; then
                log_info "Instalando herramientas seleccionadas..."
                for idx in "${selected[@]}"; do
                    tool_entry="${tools[$((idx-1))]}"
                    IFS='|' read -r package display_name <<< "$tool_entry"
                    install_tool "$package" "$display_name"
                done
                selected=()
                read -p "Presiona Enter para continuar..." < /dev/tty
            else
                echo -e "${YELLOW}No hay herramientas seleccionadas${NC}"
                sleep 1
            fi
        else
            for num in $input; do
                if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#tools[@]}" ]; then
                    if [[ ! " ${selected[@]} " =~ " ${num} " ]]; then
                        selected+=("$num")
                    fi
                fi
            done
        fi
    done
}

# ═══════════════════════════════════════════════════════════════════════════
# CATEGORÍAS DE HERRAMIENTAS
# ═══════════════════════════════════════════════════════════════════════════

# Categoría 1: Reconocimiento y Escaneo
install_recon() {
    local tools=(
        "nmap|Nmap - Network Scanner"
        "masscan|Masscan - Fast Port Scanner"
        "rustscan|RustScan - Modern Port Scanner"
        "netdiscover|Netdiscover - ARP Scanner"
        "arp-scan|ARP-Scan - Network Discovery"
        "recon-ng|Recon-ng - Reconnaissance Framework"
        "theharvester|TheHarvester - OSINT Tool"
        "spiderfoot|SpiderFoot - OSINT Automation"
        "amass|Amass - Subdomain Enumeration"
        "sherlock|Sherlock - Username Hunter"
        "dnsenum|DNSenum - DNS Enumeration"
        "dnsrecon|DNSrecon - DNS Reconnaissance"
        "fierce|Fierce - DNS Scanner"
        "enum4linux|Enum4Linux - SMB Enumeration"
    )
    show_category_menu "Reconocimiento y Escaneo" "${tools[@]}"
}

# Categoría 2: Hacking Web
install_web() {
    local tools=(
        "burpsuite|Burp Suite - Web Proxy"
        "zaproxy|OWASP ZAP - Web Scanner"
        "sqlmap|SQLMap - SQL Injection"
        "nikto|Nikto - Web Server Scanner"
        "wpscan|WPScan - WordPress Scanner"
        "joomscan|JoomScan - Joomla Scanner"
        "whatweb|WhatWeb - Web Fingerprinting"
        "gobuster|Gobuster - Directory Fuzzer"
        "ffuf|FFUF - Fast Web Fuzzer"
        "wfuzz|WFuzz - Web Fuzzer"
        "feroxbuster|Feroxbuster - Content Discovery"
        "dirb|DIRB - URL Bruteforcer"
        "commix|Commix - Command Injection"
        "xsser|XSSer - XSS Scanner"
        "nuclei|Nuclei - Vulnerability Scanner"
        "httpx|HTTPx - HTTP Toolkit"
    )
    show_category_menu "Hacking Web" "${tools[@]}"
}

# Categoría 3: Wireless y Bluetooth
install_wireless() {
    local tools=(
        "aircrack-ng|Aircrack-ng - WiFi Security"
        "kismet|Kismet - Wireless Detector"
        "wifite|Wifite - Automated WiFi Attack"
        "reaver|Reaver - WPS Attack"
        "bully|Bully - WPS Bruteforce"
        "pixiewps|PixieWPS - WPS Pixie Dust"
        "bluez-tools|Bluez Tools - Bluetooth Utils"
        "bluez-utils|Bluez Utils - Bluetooth Stack"
    )
    show_category_menu "Wireless y Bluetooth" "${tools[@]}"
}

# Categoría 4: Windows y Active Directory
install_windows_ad() {
    local tools=(
        "impacket|Impacket - Python SMB/MSRPC"
        "crackmapexec|CrackMapExec - AD Swiss Army"
        "evil-winrm|Evil-WinRM - WinRM Shell"
        "bloodhound|BloodHound - AD Mapper"
        "neo4j|Neo4j - Graph Database"
        "smbmap|SMBMap - SMB Enumeration"
        "responder|Responder - LLMNR Poisoner"
        "rdesktop|RDesktop - RDP Client"
        "freerdp|FreeRDP - Modern RDP Client"
        "chntpw|Chntpw - Windows Password Reset"
    )
    show_category_menu "Windows y Active Directory" "${tools[@]}"
}

# Categoría 5: Cracking y Wordlists
install_cracking() {
    local tools=(
        "john|John the Ripper - Password Cracker"
        "hashcat|Hashcat - Advanced Cracker"
        "ophcrack|Ophcrack - Rainbow Tables"
        "hydra|Hydra - Network Logon Cracker"
        "medusa|Medusa - Parallel Bruteforcer"
        "cewl|CeWL - Wordlist Generator"
        "crunch|Crunch - Wordlist Creator"
        "hashid|HashID - Hash Identifier"
        "seclists|SecLists - Security Wordlists"
        "wordlists|Wordlists - RockyYou & More"
    )
    show_category_menu "Cracking y Wordlists" "${tools[@]}"
}

# Categoría 6: Explotación y Frameworks
install_exploitation() {
    local tools=(
        "metasploit|Metasploit Framework"
        "armitage|Armitage - MSF GUI"
        "exploitdb|ExploitDB - Exploit Archive"
        "searchsploit|SearchSploit - Exploit Search"
        "set|Social Engineer Toolkit"
        "routersploit|RouterSploit - Router Exploitation"
    )
    show_category_menu "Explotación y Frameworks" "${tools[@]}"
}

# Categoría 7: Sniffing y Spoofing
install_sniffing() {
    local tools=(
        "wireshark-qt|Wireshark - Network Analyzer"
        "tcpdump|TCPDump - Packet Sniffer"
        "netsniff-ng|Netsniff-ng - Network Toolkit"
        "ettercap|Ettercap - MITM Framework"
        "bettercap|Bettercap - Network Attack"
        "mitmproxy|MITMProxy - HTTP(S) Proxy"
        "dsniff|DSniff - Network Auditing"
        "macchanger|MACchanger - MAC Spoofer"
        "scapy|Scapy - Packet Manipulation"
    )
    show_category_menu "Sniffing y Spoofing" "${tools[@]}"
}

# Categoría 8: Reverse Engineering
install_reversing() {
    local tools=(
        "gdb|GDB - GNU Debugger"
        "edb-debugger|EDB - Qt Debugger"
        "radare2|Radare2 - Reverse Framework"
        "ghidra|Ghidra - NSA RE Tool"
        "nasm|NASM - Assembler"
        "clang|Clang - C/C++ Compiler"
        "apktool|APKTool - Android Decompiler"
        "dex2jar|Dex2Jar - DEX to JAR"
        "jadx|JADX - Android Decompiler"
    )
    show_category_menu "Reverse Engineering" "${tools[@]}"
}

# Categoría 9: Forense
install_forensics() {
    local tools=(
        "autopsy|Autopsy - Digital Forensics"
        "sleuthkit|SleuthKit - Forensic Toolkit"
        "volatility3|Volatility - Memory Forensics"
        "binwalk|Binwalk - Firmware Analysis"
        "foremost|Foremost - File Recovery"
        "scalpel|Scalpel - File Carver"
        "exiftool|ExifTool - Metadata Reader"
        "pdf-parser|PDF-Parser - PDF Analysis"
        "stegseek|Stegseek - Steganography Cracker"
        "steghide|Steghide - Steganography Tool"
        "hexedit|HexEdit - Hex Editor"
        "ghex|GHex - GNOME Hex Editor"
    )
    show_category_menu "Forense" "${tools[@]}"
}

# Categoría 10: Utilidades de Red y Tunneling
install_networking() {
    local tools=(
        "openbsd-netcat|Netcat - Network Swiss Army"
        "socat|Socat - Data Relay"
        "curl|cURL - Transfer Tool"
        "wget|Wget - File Downloader"
        "git|Git - Version Control"
        "proxychains-ng|Proxychains - Proxy Forcer"
        "sshuttle|SSHuttle - VPN over SSH"
        "chisel|Chisel - Fast TCP/UDP Tunnel"
        "ptunnel|PTunnel - ICMP Tunnel"
        "httptunnel|HTTPTunnel - HTTP Tunnel"
    )
    show_category_menu "Utilidades de Red y Tunneling" "${tools[@]}"
}

# Install all categories
install_all() {
    log_info "Instalando TODAS las herramientas de ciberseguridad..."
    echo -e "${YELLOW}Esto puede tomar varios minutos...${NC}"
    sleep 2
    
    # Install CLI tools first
    log_info "Instalando utilidades CLI base..."
    CLI_TOOLS=("lsd" "bat" "xclip" "fzf" "ripgrep" "fd" "htop" "btop" "reflector" "snapper" "yt-dlp" "mpv" "speedtest-cli" "jq" "curl" "wget" "net-tools")
    for tool in "${CLI_TOOLS[@]}"; do
        install_tool "$tool"
    done
    
    # Install all categories (non-interactive)
    local all_tools=(
        # Recon
        "nmap" "masscan" "rustscan" "netdiscover" "arp-scan" "recon-ng" "theharvester" 
        "spiderfoot" "amass" "sherlock" "dnsenum" "dnsrecon" "fierce" "enum4linux"
        # Web
        "burpsuite" "zaproxy" "sqlmap" "nikto" "wpscan" "joomscan" "whatweb" 
        "gobuster" "ffuf" "wfuzz" "feroxbuster" "dirb" "commix" "xsser" "nuclei" "httpx"
        # Wireless
        "aircrack-ng" "kismet" "wifite" "reaver" "bully" "pixiewps" "bluez-tools" "bluez-utils"
        # Windows/AD
        "impacket" "crackmapexec" "evil-winrm" "bloodhound" "neo4j" "smbmap" "responder" 
        "rdesktop" "freerdp" "chntpw"
        # Cracking
        "john" "hashcat" "ophcrack" "hydra" "medusa" "cewl" "crunch" "hashid" "seclists" "wordlists"
        # Exploitation
        "metasploit" "armitage" "exploitdb" "searchsploit" "set" "routersploit"
        # Sniffing
        "wireshark-qt" "tcpdump" "netsniff-ng" "ettercap" "bettercap" "mitmproxy" 
        "dsniff" "macchanger" "scapy"
        # Reversing
        "gdb" "edb-debugger" "radare2" "ghidra" "nasm" "clang" "apktool" "dex2jar" "jadx"
        # Forensics
        "autopsy" "sleuthkit" "volatility3" "binwalk" "foremost" "scalpel" "exiftool" 
        "pdf-parser" "stegseek" "steghide" "hexedit" "ghex"
        # Networking
        "openbsd-netcat" "socat" "curl" "wget" "git" "proxychains-ng" "sshuttle" 
        "chisel" "ptunnel" "httptunnel"
    )
    
    for tool in "${all_tools[@]}"; do
        install_tool "$tool"
    done
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN MENU
# ═══════════════════════════════════════════════════════════════════════════

main_menu() {
    while true; do
        clear
        echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║${NC}                                                            ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}     ${MAGENTA}██████╗ ██╗      █████╗  ██████╗██╗  ██╗${NC}           ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}     ${MAGENTA}██╔══██╗██║     ██╔══██╗██╔════╝██║ ██╔╝${NC}           ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}     ${MAGENTA}██████╔╝██║     ███████║██║     █████╔╝${NC}            ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}     ${MAGENTA}██╔══██╗██║     ██╔══██║██║     ██╔═██╗${NC}            ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}     ${MAGENTA}██████╔╝███████╗██║  ██║╚██████╗██║  ██╗${NC}           ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}     ${MAGENTA}╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝${NC}           ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}                                                            ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}          ${BLUE}ICE ARCH - Cybersecurity Tools${NC}              ${CYAN}║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${GREEN}[1]${NC}  Reconocimiento y Escaneo"
        echo -e "${GREEN}[2]${NC}  Hacking Web"
        echo -e "${GREEN}[3]${NC}  Wireless y Bluetooth"
        echo -e "${GREEN}[4]${NC}  Windows y Active Directory"
        echo -e "${GREEN}[5]${NC}  Cracking y Wordlists"
        echo -e "${GREEN}[6]${NC}  Explotación y Frameworks"
        echo -e "${GREEN}[7]${NC}  Sniffing y Spoofing"
        echo -e "${GREEN}[8]${NC}  Reverse Engineering"
        echo -e "${GREEN}[9]${NC}  Forense"
        echo -e "${GREEN}[10]${NC} Utilidades de Red y Tunneling"
        echo ""
        echo -e "${YELLOW}[A]${NC}  Instalar TODO (todas las categorías)"
        echo -e "${RED}[0]${NC}  Salir"
        echo ""
        echo -e "${CYAN}Instaladas: ${GREEN}$INSTALLED_COUNT${NC} | Fallidas: ${RED}$FAILED_COUNT${NC}"
        echo ""
        read -p "Selecciona una opción: " choice < /dev/tty
        
        case $choice in
            1) install_recon ;;
            2) install_web ;;
            3) install_wireless ;;
            4) install_windows_ad ;;
            5) install_cracking ;;
            6) install_exploitation ;;
            7) install_sniffing ;;
            8) install_reversing ;;
            9) install_forensics ;;
            10) install_networking ;;
            [Aa]) install_all; read -p "Presiona Enter para continuar..." < /dev/tty ;;
            0) 
                log_success "Saliendo del menú de herramientas de seguridad..."
                return 0
                ;;
            *)
                echo -e "${RED}Opción inválida${NC}"
                sleep 1
                ;;
        esac
    done
}

# --- Wordlist Verification & Fix ---
fix_wordlists() {
    log_info "Verificando disponibilidad de wordlists..."
    
    # Ensure wordlists base dir exists
    sudo -n mkdir -p /usr/share/wordlists
    
    # 1. SecLists
    if [ -d "/usr/share/seclists" ]; then
        log_success "SecLists encontrada en /usr/share/seclists"
        ln -sf "/usr/share/seclists" "$USER_HOME/wordlists"
    else
        log_warn "SecLists no encontrada. Instala con 'yay -S seclists' si la necesitas."
    fi
    
    # 2. Rockyou (BlackArch / Standard)
    local rockyou_path=""
    [ -f "/usr/share/wordlists/rockyou.txt" ] && rockyou_path="/usr/share/wordlists/rockyou.txt"
    [ -f "/usr/share/seclists/Passwords/Leaked-Databases/rockyou.txt" ] && rockyou_path="/usr/share/seclists/Passwords/Leaked-Databases/rockyou.txt"
    [ -f "/usr/share/wordlists/rockyou.txt.gz" ] && rockyou_path="/usr/share/wordlists/rockyou.txt.gz"
    
    if [ -n "$rockyou_path" ]; then
        log_success "RockYou wordlist localizada en $rockyou_path"
        # Descomprimir si está comprimido
        if [[ "$rockyou_path" == *.gz ]]; then
            log_info "Descomprimiendo rockyou.txt..."
            sudo -n gunzip -c "$rockyou_path" | sudo  tee "/usr/share/wordlists/rockyou.txt" > /dev/null
            rockyou_path="/usr/share/wordlists/rockyou.txt"
        fi
        ln -sf "$rockyou_path" "$USER_HOME/rockyou.txt"
    else
        log_warn "RockYou.txt no encontrada. Intentando descargar..."
        sudo -n curl -L -o /usr/share/wordlists/rockyou.txt https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt
        ln -sf "/usr/share/wordlists/rockyou.txt" "$USER_HOME/rockyou.txt"
    fi
}

# Start interactive menu
main_menu
fix_wordlists
