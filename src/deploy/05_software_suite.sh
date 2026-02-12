#!/bin/bash
# deploy-modules/05_software_suite.sh
# Suite de aplicaciones profesionales y configuración de servicios

banner "MÓDULO 6" "Premium Software Suite"
cd "$USER_HOME" || exit 1

# Función para instalar paquetes (delega a safe_install para resiliencia PGP)
pkg_install() {
    local pkg=$1
    safe_install "$pkg"
}

# --- Selección Interactiva de Software ---
# Usamos whiptail para una experiencia profesional, a menos que estemos en NON_INTERACTIVE
if [ "$NON_INTERACTIVE" == "true" ]; then
    log_info "Modo No-Interactivo detectado. Instalando suite completa por defecto."
    CHOICES="Browsers DevTools Security AI_Tools Productivity Multimedia Remote Cloud Office System"
elif command -v whiptail &>/dev/null; then
    # Use a temporary file for results as whiptail redirection with many FDs is tricky in nested scripts
    TMP_CHOICES=$(mktemp)
    
    whiptail --title "BLACK-ICE SOFTWARE SUITE" --checklist \
    "Selecciona el software que deseas instalar (Espacio para seleccionar):" 20 75 12 \
    "Browsers" "Firefox y Brave Browser" ON \
    "DevTools" "Docker, KVM/QEMU, Kate, VS Code" ON \
    "Security" "Caido, Wireshark, Burp, IPScan" ON \
    "AI_Tools" "Claude, Gemini, Antigravity" ON \
    "Productivity" "Obsidian, Betterbird, KeePassXC" ON \
    "Multimedia" "VLC, OBS (Minimal), GIMP" ON \
    "Remote" "AnyDesk, RustDesk, Remmina" ON \
    "Cloud" "MegaSync, FileZilla" ON \
    "Office" "OnlyOffice, Okular (PDF), Fonts" ON \
    "System" "GParted, BleachBit, 7Zip" ON 2>"$TMP_CHOICES" < /dev/tty || true
    
    CHOICES=$(cat "$TMP_CHOICES")
    rm -f "$TMP_CHOICES"
else
    log_warn "Whiptail no detectado. Instalando suite completa por defecto."
    CHOICES="Browsers DevTools Security AI_Tools Productivity Multimedia Remote Cloud Office System"
fi

# --- Procesar Instalación ---
for choice in $CHOICES; do
    case $choice in
        "\"Browsers\""|"Browsers")
            log_info "Instalando Navegadores..."
            pkg_install "firefox"
            pkg_install "brave-bin"
            ;;
        "\"DevTools\""|"DevTools")
            log_info "Configurando Entorno de Desarrollo..."
            pkg_install "docker"
            pkg_install "docker-compose"
            
            # --- Configuración KVM Condicional (Evitar Nested Virt Error si ya estamos en VM) ---
            if systemd-detect-virt >/dev/null; then
                log_warn "Sistema ejecutándose en Virtual Machine ($(systemd-detect-virt))."
                log_warn "Saltando instalación de KVM/QEMU Host Tools para evitar conflictos."
            else
                log_info "Instalando KVM/QEMU Host Tools..."
                pkg_install "qemu-full"
                pkg_install "libvirt"
                pkg_install "virt-manager"
                pkg_install "dnsmasq"
                pkg_install "bridge-utils"
                
                log_info "Tuning KVM/Libvirt..."
                sudo -n systemctl enable --now libvirtd.service
                sudo -n usermod -aG libvirt "$USER"
                # Habilitar red por defecto de libvirt
                sudo -n virsh net-autostart default 2>/dev/null || true
                sudo -n virsh net-start default 2>/dev/null || true
            fi

            pkg_install "kate"
            pkg_install "antigravity"
            
            # Configuración Docker
            log_info "Tuning Docker..."
            sudo -n systemctl enable --now docker.service
            sudo -n usermod -aG docker "$USER"
            ;;
        "\"Security\""|"Security")
            log_info "Instalando Herramientas de Pentesting PRO..."
            pkg_install "caido"
            pkg_install "wireshark-qt"
            pkg_install "ipscan"
            sudo -n usermod -aG wireshark "$USER"
            ;;
        "\"AI_Tools\""|"AI_Tools")
            log_info "Instalando Ecosistema IA..."
            pkg_install "claude-desktop-bin"
            pkg_install "geminidesk-bin"
            ;;
        "\"Productivity\""|"Productivity")
            log_info "Instalando Herramientas de Productividad..."
            pkg_install "obsidian"
            pkg_install "betterbird-bin"
            pkg_install "keepassxc"
            ;;
        "\"Multimedia\""|"Multimedia")
            log_info "Instalando Multimedia & Diseño..."
            pkg_install "vlc"
            pkg_install "gimp"
            pkg_install "spectacle"
            ;;
        "\"Remote\""|"Remote")
            log_info "Instalando Conectividad Remota..."
            pkg_install "anydesk-bin"
            pkg_install "rustdesk-bin"
            pkg_install "remmina"
            pkg_install "freerdp"
            ;;
        "\"Cloud\""|"Cloud")
            log_info "Instalando Servicios Cloud..."
            pkg_install "megasync-bin"
            pkg_install "filezilla"
            ;;
        "\"Office\""|"Office")
            log_info "Instalando Suite de Oficina y PDF..."
            pkg_install "onlyoffice-bin"
            pkg_install "okular"
            pkg_install "ttf-liberation" # Fuentes compatibles MS
            
            # Soporte Multilenguaje (Español)
            # Detectar si el sistema está en español
            CURRENT_LANG=$(echo $LANG | cut -d_ -f1)
            if [ "$CURRENT_LANG" == "es" ]; then
                log_info "Idioma español detectado: Instalando diccionarios..."
                pkg_install "hunspell-es_CL" 2>/dev/null || pkg_install "hunspell-es_ES" 2>/dev/null || pkg_install "hunspell-es_any"
                
                # Intentar instalar fuentes adicionales si es necesario
                log_success "Soporte de idioma español agregado a OnlyOffice/Hunspell"
            fi
            ;;
        "\"System\""|"System")
            log_info "Instalando Utilidades de Sistema..."
            pkg_install "gparted"
            pkg_install "bleachbit"
            pkg_install "p7zip"
            pkg_install "ktorrent"
            ;;
    esac
done

success "Suite de software procesada correctamente."
