#!/bin/bash
# deploy-modules/02_security_tools.sh
# Cybersecurity Tools Installer — whiptail checklist UI
# Author: Francisco Aravena (P4nX0Z) | v3.3.0

banner "MÓDULO 3" "Herramientas de Seguridad"

# Installation counters
INSTALL_LOG="/tmp/cybersec_install_$(date +%Y%m%d_%H%M%S).log"
INSTALLED_COUNT=0
FAILED_COUNT=0

cd "$USER_HOME" || { log_error "No se pudo acceder a $USER_HOME"; exit 1; }

# ═══════════════════════════════════════════════════════════════════════════
# PAQUETES PESADOS — deshabilitados por defecto (compilación lenta)
# bloodhound: neo4j-community = 165 módulos Maven/Scala (~60 min)
# ghidra:     NSA RE tool, large Java download (~10-20 min)
# autopsy:    Digital forensics suite, large Java (~10-20 min)
# sliver:     Go C2 framework, compila desde fuente (~15 min)
# ═══════════════════════════════════════════════════════════════════════════
HEAVY_PKGS=("bloodhound" "ghidra" "autopsy" "sliver")

is_heavy() {
    local pkg="$1"
    for h in "${HEAVY_PKGS[@]}"; do
        [[ "$h" == "$pkg" ]] && return 0
    done
    return 1
}

# ═══════════════════════════════════════════════════════════════════════════
# MASTER TOOLS LIST — formato: "pkg|display|categoria"
# ═══════════════════════════════════════════════════════════════════════════
ALL_TOOLS=(
    # Reconocimiento
    "nmap|Nmap - Network Scanner|Recon"
    "masscan|Masscan - Fast Port Scanner|Recon"
    "rustscan|RustScan - Modern Port Scanner|Recon"
    "netdiscover|Netdiscover - ARP Scanner|Recon"
    "arp-scan|ARP-Scan - Network Discovery|Recon"
    "recon-ng|Recon-ng - Recon Framework|Recon"
    "theharvester-git|TheHarvester - OSINT Tool|Recon"
    "spiderfoot|SpiderFoot - OSINT Automation|Recon"
    "amass|Amass - Subdomain Enumeration|Recon"
    "sherlock|Sherlock - Username Hunter|Recon"
    "dnsenum2|DNSenum - DNS Enumeration|Recon"
    "python-dnsrecon|DNSrecon - DNS Recon|Recon"
    "enum4linux|Enum4Linux - SMB Enumeration|Recon"
    # Web
    "burpsuite|Burp Suite - Web Proxy|Web"
    "zaproxy|OWASP ZAP - Web Scanner|Web"
    "sqlmap|SQLMap - SQL Injection|Web"
    "nikto|Nikto - Web Server Scanner|Web"
    "wpscan|WPScan - WordPress Scanner|Web"
    "whatweb|WhatWeb - Web Fingerprinting|Web"
    "gobuster|Gobuster - Directory Fuzzer|Web"
    "ffuf|FFUF - Fast Web Fuzzer|Web"
    "feroxbuster|Feroxbuster - Content Discovery|Web"
    "nuclei|Nuclei - Vulnerability Scanner|Web"
    "httpx|HTTPx - HTTP Toolkit|Web"
    "commix|Commix - Command Injection|Web"
    "xsser|XSSer - XSS Scanner|Web"
    # Wireless
    "aircrack-ng|Aircrack-ng - WiFi Security|Wireless"
    "kismet|Kismet - Wireless Detector|Wireless"
    "wifite|Wifite - Automated WiFi Attack|Wireless"
    "reaver|Reaver - WPS Attack|Wireless"
    "bully|Bully - WPS Bruteforce|Wireless"
    "pixiewps|PixieWPS - WPS Pixie Dust|Wireless"
    # Windows/AD
    "impacket|Impacket - Python SMB/MSRPC|AD"
    "netexec|NetExec - Modern CME (nxc)|AD"
    "ruby-evil-winrm|Evil-WinRM - WinRM Shell|AD"
    "bloodhound|BloodHound - AD Mapper [~60min]|AD"
    "python-certipy-ad-git|Certipy - AD CS Attack|AD"
    "coercer|Coercer - Forced Auth|AD"
    "kerbrute-bin|Kerbrute - Kerberos Bruteforce|AD"
    "responder|Responder - LLMNR Poisoner|AD"
    "responder|Responder - LLMNR Poisoner|AD"
    "smbmap|SMBMap - SMB Enumeration|AD"
    "chntpw|Chntpw - Windows Password Reset|AD"
    # Cracking
    "john|John the Ripper - Password Cracker|Crack"
    "hashcat|Hashcat - GPU Cracker|Crack"
    "hydra|Hydra - Network Bruteforcer|Crack"
    "medusa|Medusa - Parallel Bruteforcer|Crack"
    "trufflehog|TruffleHog - Secret Scanner|Crack"
    "gitleaks|Gitleaks - Git Secret Scanner|Crack"
    "cewl|CeWL - Wordlist Generator|Crack"
    "crunch|Crunch - Wordlist Creator|Crack"
    "hashid|HashID - Hash Identifier|Crack"
    "seclists|SecLists - Security Wordlists|Crack"
    "wordlists|Wordlists - RockYou & More|Crack"
    # Explotación
    "metasploit|Metasploit Framework|Exploit"
    "sliver|Sliver - C2 Framework (Go) [~15min]|Exploit"
    "villain-c2-git|Villain - Reverse Shell Manager|Exploit"
    "exploitdb|ExploitDB - Exploit Archive|Exploit"
    "social-engineer-toolkit|Social Engineer Toolkit|Exploit"
    "routersploit|RouterSploit - Router Exploit|Exploit"
    # Sniffing
    "wireshark-qt|Wireshark - Network Analyzer|Sniff"
    "tcpdump|TCPDump - Packet Sniffer|Sniff"
    "ettercap|Ettercap - MITM Framework|Sniff"
    "bettercap|Bettercap - Network Attack|Sniff"
    "mitmproxy|MITMProxy - HTTP(S) Proxy|Sniff"
    "macchanger|MACchanger - MAC Spoofer|Sniff"
    "scapy|Scapy - Packet Manipulation|Sniff"
    # Reversing
    "gdb|GDB - GNU Debugger|RE"
    "radare2|Radare2 - Reverse Framework|RE"
    "ghidra|Ghidra - NSA RE Tool [~20min]|RE"
    "nasm|NASM - Assembler|RE"
    "android-apktool|APKTool - Android Decompiler|RE"
    "jadx|JADX - Android Decompiler|RE"
    "edb-debugger|EDB - Qt Debugger|RE"
    # Forense
    "autopsy|Autopsy - Digital Forensics [~20min]|Forense"
    "sleuthkit|SleuthKit - Forensic Toolkit|Forense"
    "volatility3|Volatility3 - Memory Forensics|Forense"
    "binwalk|Binwalk - Firmware Analysis|Forense"
    "foremost|Foremost - File Recovery|Forense"
    "exiftool|ExifTool - Metadata Reader|Forense"
    "steghide|Steghide - Steganography Tool|Forense"
    "stegseek|Stegseek - Steg Cracker|Forense"
    "hexedit|HexEdit - Hex Editor|Forense"
    # Networking
    "openbsd-netcat|Netcat - Network Swiss Army|Net"
    "socat|Socat - Data Relay|Net"
    "proxychains-ng|Proxychains - Proxy Forcer|Net"
    "sshuttle|SSHuttle - VPN over SSH|Net"
    "chisel|Chisel - TCP/UDP Tunnel|Net"
    "traceroute|Traceroute - Path Trace|Net"
    "wireshark-qt|Wireshark CLI|Net"
    "bind|Bind-tools - dig/nslookup|Net"
    "whois|Whois - Domain Lookup|Net"
    "mtr|MTR - Ping+Traceroute|Net"
    "iperf3|IPerf3 - Bandwidth Test|Net"
    "nethogs|Nethogs - Bandwidth/Process|Net"
    "iftop|Iftop - Bandwidth/Host|Net"
    "iptraf-ng|IPTraf-ng - Net Monitor|Net"
    "minicom|Minicom - Serial Terminal|Net"
    "onesixtyone|Onesixtyone - SNMP Scanner|Net"
)

# ═══════════════════════════════════════════════════════════════════════════
# INSTALL FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════
install_tool() {
    local tool="$1"
    local display_name="${2:-$tool}"

    if pacman -Q "$tool" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $display_name (ya instalado)"
        return 0
    fi

    # Aviso especial para paquetes pesados
    if is_heavy "$tool"; then
        echo -e ""
        echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║  ⚠️  COMPILACIÓN LENTA: $tool${NC}"
        echo -e "${YELLOW}║  Este paquete puede tardar 15-60 min. NO canceles.          ║${NC}"
        echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo -e ""
    fi

    echo -e "  ${CYAN}→${NC} Instalando $display_name..."
    if safe_install "$tool"; then
        echo -e "  ${GREEN}✓${NC} $display_name instalado"
        ((INSTALLED_COUNT++))
        return 0
    else
        echo -e "  ${RED}✗${NC} $display_name no disponible"
        echo "FAILED: $tool" >> "$INSTALL_LOG"
        ((FAILED_COUNT++))
        return 1
    fi
}

# Instala lista de paquetes evitando duplicados
install_pkg_list() {
    local -a pkgs=("$@")
    local -A seen=()
    for pkg in "${pkgs[@]}"; do
        [[ -z "$pkg" ]] && continue
        [[ -n "${seen[$pkg]:-}" ]] && continue
        seen[$pkg]=1
        install_tool "$pkg"
    done
}

# Suite estándar: todo excepto HEAVY_PKGS
install_standard() {
    log_info "Instalando Suite Estándar (sin paquetes pesados)..."
    local -a pkgs=()
    for entry in "${ALL_TOOLS[@]}"; do
        IFS='|' read -r pkg _ _ <<< "$entry"
        is_heavy "$pkg" || pkgs+=("$pkg")
    done
    install_pkg_list "${pkgs[@]}"
}

# Suite completa incluyendo pesados
install_full() {
    log_info "Instalando Suite COMPLETA (incluyendo paquetes de compilación larga)..."
    echo -e "${YELLOW}⚠️  bloodhound/ghidra/autopsy pueden tardar 20-60 min cada uno.${NC}"
    sleep 2
    local -a pkgs=()
    for entry in "${ALL_TOOLS[@]}"; do
        IFS='|' read -r pkg _ _ <<< "$entry"
        pkgs+=("$pkg")
    done
    install_pkg_list "${pkgs[@]}"
}

# Instala selección personalizada desde whiptail
install_whiptail_checklist() {
    if ! command -v whiptail &>/dev/null; then
        log_warn "whiptail no disponible. Usando suite estándar."
        install_standard
        return
    fi

    local -a wt_args=()
    for entry in "${ALL_TOOLS[@]}"; do
        IFS='|' read -r pkg display cat <<< "$entry"
        local label="[$cat] $display"
        local state="ON"
        is_heavy "$pkg" && state="OFF"
        # Marcar ya instalados
        pacman -Q "$pkg" &>/dev/null && label="$label ✓"
        wt_args+=("$pkg" "$label" "$state")
    done

    local CHOICES
    CHOICES=$(whiptail \
        --title "BLACK-ICE ARCH — Suite de Ciberseguridad" \
        --checklist \
        "ESPACIO = seleccionar/deseleccionar  |  ENTER = confirmar
Los marcados con ⚠️ en el nombre tardan 15-60 min (compilación desde fuente).
Recomendado: dejar bloodhound, ghidra y autopsy desmarcados en primera instalación." \
        40 80 25 \
        "${wt_args[@]}" \
        3>&1 1>&2 2>&3) || return 0  # usuario canceló

    # Instalar seleccionados
    log_info "Instalando herramientas seleccionadas..."
    local -a selected=()
    # shellcheck disable=SC2206
    IFS=' ' read -r -a selected <<< "$CHOICES"
    for pkg in "${selected[@]}"; do
        pkg="${pkg//\"/}"  # quitar comillas que whiptail añade
        install_tool "$pkg"
    done
}

# ═══════════════════════════════════════════════════════════════════════════
# MENÚ PRINCIPAL
# ═══════════════════════════════════════════════════════════════════════════
main_menu() {
    if ! command -v whiptail &>/dev/null; then
        log_warn "whiptail no disponible — instalando suite estándar automáticamente."
        install_standard
        return
    fi

    local choice
    choice=$(whiptail \
        --title "BLACK-ICE ARCH — Instalador de Ciberseguridad" \
        --menu \
"Elige el modo de instalación:

  ESTÁNDAR:   ~100 herramientas, excluye las de compilación larga.
  PERSONALIZADO: Checklist completo — ESPACIO para marcar/desmarcar.
  COMPLETO:   TODO incluyendo bloodhound (~60min), ghidra (~20min), autopsy (~20min).
" \
        20 72 4 \
        "1" "Suite Estándar  (recomendado — sin pesadas)" \
        "2" "Selección personalizada  (whiptail checklist)" \
        "3" "Suite Completa  (incluye bloodhound / ghidra / autopsy)" \
        "0" "Saltar — no instalar herramientas ahora" \
        3>&1 1>&2 2>&3) || return 0

    case "$choice" in
        1) install_standard ;;
        2) install_whiptail_checklist ;;
        3) install_full ;;
        0) log_info "Instalación de herramientas omitida por el usuario." ; return 0 ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════
# WORDLISTS
# ═══════════════════════════════════════════════════════════════════════════
fix_wordlists() {
    log_info "Verificando disponibilidad de wordlists..."
    sudo -n mkdir -p /usr/share/wordlists

    if [ -d "/usr/share/seclists" ]; then
        ln -sf "/usr/share/seclists" "$USER_HOME/wordlists"
        log_success "SecLists enlazada en ~/wordlists"
    fi

    local rockyou_path=""
    [ -f "/usr/share/wordlists/rockyou.txt" ]      && rockyou_path="/usr/share/wordlists/rockyou.txt"
    [ -f "/usr/share/seclists/Passwords/Leaked-Databases/rockyou.txt" ] && \
        rockyou_path="/usr/share/seclists/Passwords/Leaked-Databases/rockyou.txt"
    [ -f "/usr/share/wordlists/rockyou.txt.gz" ]   && rockyou_path="/usr/share/wordlists/rockyou.txt.gz"

    if [ -n "$rockyou_path" ]; then
        if [[ "$rockyou_path" == *.gz ]]; then
            sudo -n gunzip -c "$rockyou_path" | sudo tee "/usr/share/wordlists/rockyou.txt" > /dev/null
            rockyou_path="/usr/share/wordlists/rockyou.txt"
        fi
        [ -e "$rockyou_path" ] && ln -sf "$rockyou_path" "$USER_HOME/rockyou.txt"
        log_success "RockYou localizada en $rockyou_path"
    else
        log_warn "RockYou no encontrada. Descargando..."
        sudo -n curl -L -o /usr/share/wordlists/rockyou.txt \
            https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt && \
            ln -sf "/usr/share/wordlists/rockyou.txt" "$USER_HOME/rockyou.txt"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# ENTRY POINT
# ═══════════════════════════════════════════════════════════════════════════
if [ "${NON_INTERACTIVE:-false}" == "true" ] || [ "${AUTO_MODE:-false}" == "true" ]; then
    log_info "Modo desatendido: instalando Suite Estándar (sin bloodhound/ghidra/autopsy)..."
    install_standard
else
    main_menu
fi

fix_wordlists

log_success "Herramientas instaladas: $INSTALLED_COUNT | Fallidas: $FAILED_COUNT"
[ -s "$INSTALL_LOG" ] && log_warn "Ver fallos en: $INSTALL_LOG"
