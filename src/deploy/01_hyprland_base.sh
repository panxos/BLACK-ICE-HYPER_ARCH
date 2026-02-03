#!/bin/bash
# deploy-modules/01_hyprland_base.sh
# Instala Hyprland y componentes de desktop

banner "MÓDULO 2" "BLACK-ICE Hyprland & Base"

# --- Lista de paquetes ---
HYPRLAND_PKGS=(
    # Compositor y session
    "hyprland"
    "hyprpaper"
    "hyprlock"
    "xdg-desktop-portal-hyprland"
    "xdg-desktop-portal-gtk"
    "qt5-wayland"
    "qt6-wayland"
    
    # Barra de estado y launcher
    "waybar"
    "wofi"
    "wlogout"
    
    # Waybar Dependencies (CRITICAL)
    "jq"                    # JSON parsing for custom modules
    "ttf-font-awesome"      # Icon font for Waybar
    "otf-font-awesome"      # OpenType variant
    "pango"                 # Text rendering
    "cairo"                 # Graphics rendering
    "libinput"              # Input handling
    "socat"                 # IPC communication
    
    # Notificaciones
    "dunst"
    "libnotify"
    
    # Terminal y Navegadores
    "kitty"
    "firefox"
    "brave-bin"
    "kate"
    "neovim"
    
    # File manager y utilidades
    "dolphin"
    "ark"
    "p7zip"
    "unzip"
    "unrar"
    "xdg-user-dirs"
    "xdg-utils"
    
    # Wallpaper daemon
    "hyprpaper"
    
    # Screenshot tools
    "grim"
    "slurp"
    "wl-clipboard"
    "hyprshot"
    "hyprpicker-git"
    "swappy"                # Screenshot editor (Spectacle-like)
    
    # Fuentes e iconos (Extended)
    "ttf-hack-nerd"
    "ttf-jetbrains-mono-nerd"
    "ttf-roboto-mono-nerd"
    "ttf-nerd-fonts-symbols"
    "otf-commit-mono-nerd"   # Mandatory Mecha font
    "ttf-roboto"
    "papirus-icon-theme"
    
    # Temas y Estética
    "sweet-gtk-theme-dark"
    "candy-icons-git"
    "qt5ct"
    "qt6ct"
    "kvantum"
    "kvantum-qt5"
    "kvantum-qt5"
    "nwg-look"
    "python-pywal"
    "sddm"
    
    # Utilidades adicionales
    "polkit-kde-agent"
    "brightnessctl"
    "playerctl"
    "bc"
    "curl"                  # For public IP module
    "iproute2"              # For network modules
    "bluez"                 # Bluetooth modules
    "bluez-utils"           # Bluetooth tools
    "blueman"               # Bluetooth manager (GUI + Applet)
    # Virtualization & Updates (Scripts Dependencies)
    "libvirt"               # For KVM status script (virsh)
    "pacman-contrib"        # For updates status script (checkupdates)
    "network-manager-applet"
    "pavucontrol"
    "pamixer"               # Audio control for multimedia keys
    "brightnessctl"
    "playerctl"
    "swww"                  # Wallpaper daemon
    "hypridle"              # Idle daemon
    "grimblast-git"         # Screenshot helper
    "cliphist"              # Clipboard manager
    "wev"                   # Wayland event viewer
    "pipewire"
    "pipewire-pulse"
    "pipewire-alsa"
    "pipewire-jack"
    "wireplumber"
    "libnewt"               # For whiptail (interactive menus)
    "chafa"                 # For terminal image display (Fastfetch fallback)
)

# --- Detección de Hardware y Virtualización (SOTA Smart-Detect) ---
log_info "Analizando hardware para optimización de drivers..."

# 1. CPU Microcode
CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}')
if [ "$CPU_VENDOR" == "GenuineIntel" ]; then
    log_info "CPU Intel detectada: Agregando intel-ucode..."
    HYPRLAND_PKGS+=("intel-ucode")
elif [ "$CPU_VENDOR" == "AuthenticAMD" ]; then
    log_info "CPU AMD detectada: Agregando amd-ucode..."
    HYPRLAND_PKGS+=("amd-ucode")
fi

# 2. Virtualización
VIRT_SYSTEM=$(systemd-detect-virt)
IS_VM=false
case "$VIRT_SYSTEM" in
    vmware)
        log_info "Hypervisor VMware detectado: Instalando open-vm-tools..."
        HYPRLAND_PKGS+=("open-vm-tools" "xf86-video-vmware")
        # Habilitar servicio más tarde
        SHOULD_ENABLE_VMWARE="true"
        IS_VM=true
        ;;
    oracle)
        log_info "Hypervisor VirtualBox detectado: Instalando guest-utils..."
        HYPRLAND_PKGS+=("virtualbox-guest-utils")
        SHOULD_ENABLE_VBOX="true"
        IS_VM=true
        ;;
    kvm|qemu)
        log_info "Hypervisor KVM/QEMU detectado: Instalando agente..."
        HYPRLAND_PKGS+=("qemu-guest-agent")
        SHOULD_ENABLE_QEMU="true"
        IS_VM=true
        ;;
    xen)
        log_info "Hypervisor Xen detectado: Instalando guest-utils..."
        HYPRLAND_PKGS+=("xe-guest-utilities")
        IS_VM=true
        ;;
    microsoft)
        log_info "Hypervisor Hyper-V detectado: Instalando guest-utils..."
        HYPRLAND_PKGS+=("hyperv")
        IS_VM=true
        ;;
    none)
        log_info "Bare-metal (Hardware Real) detectado. Omitiendo tools de VM."
        IS_VM=false
        ;;
    *)
        log_warn "Virtualización desconocida ($VIRT_SYSTEM). Omitiendo tools específicas."
        IS_VM=false
        ;;
esac

# VM Graphics Fix: Inject WLR_NO_HARDWARE_CURSORS=1 for Hyprland
if [ "$IS_VM" = true ]; then
    log_info "Entorno virtualizado detectado: Configurando WLR_NO_HARDWARE_CURSORS=1..."
    
    # Create/update .zprofile with VM graphics fix
    if ! grep -q "WLR_NO_HARDWARE_CURSORS" "$USER_HOME/.zprofile" 2>/dev/null; then
        cat >> "$USER_HOME/.zprofile" << 'EOF'

# VM Graphics Fix for Hyprland (prevents black screen/flickering)
export WLR_NO_HARDWARE_CURSORS=1
EOF
        chown $CURRENT_USER:$CURRENT_USER "$USER_HOME/.zprofile"
        log_success "WLR_NO_HARDWARE_CURSORS=1 configurado en .zprofile"
    fi
    
    # Also inject into Hyprland env config if it exists
    HYPR_ENV_CONF="$USER_HOME/.config/hypr/hyprland.conf"
    if [ -f "$HYPR_ENV_CONF" ] && ! grep -q "WLR_NO_HARDWARE_CURSORS" "$HYPR_ENV_CONF"; then
        sed -i '/^# Environment variables/a env = WLR_NO_HARDWARE_CURSORS,1' "$HYPR_ENV_CONF" 2>/dev/null || true
    fi
fi

# FIX KEYRING (BlackArch/Arch) - FORCE REPAIR due to persistent GPG errors
log_info "Forzando reparación de Keyring (GPG)..."
sudo rm -rf /etc/pacman.d/gnupg
sudo pacman-key --init
sudo pacman-key --populate archlinux blackarch
sudo pacman -Sy --noconfirm --overwrite '*' archlinux-keyring blackarch-keyring
log_success "Keyring reinicializado."

log_info "Instalando Hyprland y componentes base..."

# RESOLVE CONFLICTS (Hyprpicker & Jack2)
if pacman -Q hyprpicker &>/dev/null || pacman -Q hyprpicker-git &>/dev/null; then
    log_warn "Conflicto detectado: Eliminando hyprpicker para prevenir errores de versión..."
    sudo -n pacman -Rns --noconfirm hyprpicker hyprpicker-git 2>/dev/null || true
fi
if pacman -Q jack2 &>/dev/null; then
    log_warn "Conflicto detectado: Eliminando jack2 con -Rdd (allow pipewire-jack replacement)..."
    sudo -n pacman -Rdd --noconfirm jack2 || true
fi

for pkg in "${HYPRLAND_PKGS[@]}"; do
    if ! pacman -Q "$pkg" &> /dev/null; then
        echo -e "  ${CYAN}→${NC} Instalando $pkg..."
        sudo -n pacman -S --needed --noconfirm "$pkg" || yay -S --needed --noconfirm "$pkg"
    fi
done

# --- Validación Post-Instalación ---
log_info "Validando instalación de componentes críticos..."
CRITICAL_PKGS=("waybar" "jq" "ttf-font-awesome" "python-pywal" "swww" "imagemagick")
VALIDATION_FAILED=false

for pkg in "${CRITICAL_PKGS[@]}"; do
    if ! pacman -Q "$pkg" &> /dev/null; then
        log_error "CRÍTICO: $pkg no se instaló correctamente"
        VALIDATION_FAILED=true
    else
        echo -e "  ${GREEN}✓${NC} $pkg instalado"
    fi
done

if [ "$VALIDATION_FAILED" = true ]; then
    log_error "Falló la validación de paquetes críticos. Abortando."
    exit 1
fi

success "Todos los paquetes críticos instalados correctamente"


# --- Configuración de Teclado (Sistema) ---
log_info "Configurando teclado en español (ES)..."
sudo -n localectl set-x11-keymap es
sudo -n localectl set-locale LANG=es_ES.UTF-8
echo "KEYMAP=es" | sudo -n tee /etc/vconsole.conf

# --- Configuración de SDDM (CyberSec Theme) ---
# Limpiar configuración antigua para evitar conflictos
# (sddm.conf suele tener prioridad sobre sddm.conf.d, así que lo eliminamos si fue creado por versiones anteriores)
if [ -f "/etc/sddm.conf" ]; then
    log_warn "Eliminando /etc/sddm.conf antiguo para priorizar configuración modular (.d)..."
    sudo rm "/etc/sddm.conf"
fi

# La configuración del tema se maneja en 06_sddm_setup.sh
# Solo habilitamos el servicio aquí
sudo systemctl enable sddm


# --- Configuración de Audio y Bluetooth ---
log_info "Configurando servicios de Audio (Pipewire) y Bluetooth..."
sudo systemctl enable --now bluetooth
systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service

success "Hyprland, SDDM, Audio y Bluetooth configurados"

# --- Copiar Dotfiles ---
log_info "Copiando archivos de configuración..."
mkdir -p "$USER_HOME/.config/hypr"
cp -r "$DOTFILES_DIR/hypr/"* "$USER_HOME/.config/hypr/"

# Inject final hyprland.conf (Hardware & 0.53.3 Logic)
if [ -f "$DOTFILES_DIR/hypr/hyprland.conf" ]; then
    cp "$DOTFILES_DIR/hypr/hyprland.conf" "$USER_HOME/.config/hypr/hyprland.conf"
fi
mkdir -p "$USER_HOME/.config/kitty"
mkdir -p "$USER_HOME/.config/wofi"

# Copiar dotfiles
if [ -d "$DOTFILES_DIR/hypr" ]; then
    cp -r "$DOTFILES_DIR/hypr/"* "$USER_HOME/.config/hypr/"
    chmod +x "$USER_HOME/.config/hypr/scripts/"*.sh 2>/dev/null
    log_info "Configuración de Hyprland copiada y permisos ajustados"
fi

# Copy ZSH configuration (includes Fastfetch, Powerlevel10k, etc.)
if [ -f "$DOTFILES_DIR/zsh/.zshrc" ]; then
    cp "$DOTFILES_DIR/zsh/.zshrc" "$USER_HOME/.zshrc"
    cp "$DOTFILES_DIR/zsh/.p10k.zsh" "$USER_HOME/.p10k.zsh" 2>/dev/null || true
    chown $CURRENT_USER:$CURRENT_USER "$USER_HOME/.zshrc" "$USER_HOME/.p10k.zsh"
    log_info "Configuración ZSH copiada (.zshrc + .p10k.zsh)"
fi

# --- Instalar Scripts de Utilidad (EARLY for Waybar) ---
log_info "Instalando scripts de utilidad (EARLY)..."
mkdir -p "$USER_HOME/.config/bin"
if [ -d "$DOTFILES_DIR/bin" ]; then
    cp -r "$DOTFILES_DIR/bin/"* "$USER_HOME/.config/bin/"
    chmod +x "$USER_HOME/.config/bin/"*
    log_info "Scripts de utilidad instalados en ~/.config/bin"
fi

# INTEGRACIÓN: Crear scripts helper para Waybar (Robustez)
log_info "Creando scripts helper para Waybar..."
cat > "$USER_HOME/.config/bin/check_target_status.sh" << 'EOF'
#!/bin/bash
TARGET_FILE="$HOME/.config/target_ip"
if [ -f "$TARGET_FILE" ] && [ -s "$TARGET_FILE" ]; then
    TARGET=$(cat "$TARGET_FILE")
    echo "{\"text\":\"$TARGET\",\"class\":\"active\"}"
else
    echo "{\"text\":\"No Target\",\"class\":\"inactive\"}"
fi
EOF

cat > "$USER_HOME/.config/bin/check_vpn_status.sh" << 'EOF'
#!/bin/bash
if ip link show | grep -q "tun0\|wg0\|vpn"; then
    echo "{\"text\":\"VPN ON\",\"class\":\"connected\"}"
else
    echo "{\"text\":\"VPN OFF\",\"class\":\"disconnected\"}"
fi
EOF

cat > "$USER_HOME/.config/bin/power_menu.sh" << 'EOF'
#!/bin/bash
OPTIONS="🔒 Lock\n⏾ Sleep\n🔄 Reboot\n⏻ Shutdown\n🚪 Logout"
CHOICE=$(echo -e "$OPTIONS" | wofi --dmenu --prompt "Power Menu" -i)
case "$CHOICE" in
    "🔒 Lock") hyprlock || swaylock ;;
    "⏾ Sleep") systemctl suspend ;;
    "🔄 Reboot") systemctl reboot ;;
    "⏻ Shutdown") systemctl poweroff ;;
    "🚪 Logout") hyprctl dispatch exit ;;
esac
EOF

chmod +x "$USER_HOME/.config/bin/"*.sh
log_success "Scripts helper instalados y permisos ajustados."

if [ -d "$DOTFILES_DIR/waybar" ]; then
    # Clean and Copy (Force Refresh)
    rm -rf "$USER_HOME/.config/waybar"
    mkdir -p "$USER_HOME/.config/waybar"
    cp -r "$DOTFILES_DIR/waybar/"* "$USER_HOME/.config/waybar/"
    
    # Set Horus-Cyber (formerly Mechabar) as default
    cp "$DOTFILES_DIR/waybar/themes/Horus-Cyber/config.jsonc" "$USER_HOME/.config/waybar/config" 2>/dev/null || true
    cp "$DOTFILES_DIR/waybar/themes/Horus-Cyber/config.jsonc" "$USER_HOME/.config/waybar/config.jsonc"
    cp "$DOTFILES_DIR/waybar/themes/Horus-Cyber/style.css" "$USER_HOME/.config/waybar/style.css"
    
    # Fix Permissions
    chown -R $CURRENT_USER:$CURRENT_USER "$USER_HOME/.config/waybar"
    chmod -R +rwx "$USER_HOME/.config/waybar" # Ensure readable/executable
    log_info "Configuración de Waybar copiada (Horus-Cyber set as default)"
fi

if [ -d "$DOTFILES_DIR/kitty" ]; then
    cp -r "$DOTFILES_DIR/kitty/"* "$USER_HOME/.config/kitty/"
    log_info "Configuración de Kitty copiada"
fi

if [ -d "$DOTFILES_DIR/fastfetch" ]; then
    mkdir -p "$USER_HOME/.config/fastfetch"
    cp -r "$DOTFILES_DIR/fastfetch/"* "$USER_HOME/.config/fastfetch/"
    chmod +x "$USER_HOME/.config/fastfetch/random_logo.sh" 2>/dev/null || true
    log_info "Configuración de Fastfetch copiada y script de logo habilitado"
fi

if [ -d "$DOTFILES_DIR/wofi" ]; then
    cp -r "$DOTFILES_DIR/wofi/"* "$USER_HOME/.config/wofi/"
    log_info "Configuración de Wofi copiada"
fi

if [ -d "$DOTFILES_DIR/gtk-3.0" ]; then
    mkdir -p "$USER_HOME/.config/gtk-3.0"
    cp -r "$DOTFILES_DIR/gtk-3.0/"* "$USER_HOME/.config/gtk-3.0/"
fi

if [ -d "$DOTFILES_DIR/gtk-4.0" ]; then
    mkdir -p "$USER_HOME/.config/gtk-4.0"
    cp -r "$DOTFILES_DIR/gtk-4.0/"* "$USER_HOME/.config/gtk-4.0/"
fi


# --- Copiar wallpapers ---
# --- Copiar wallpapers (Dynamic Localization) ---
log_info "Copiando wallpapers (con detección de idioma XDG)..."

# Ensure XDG dirs are created
if command -v xdg-user-dirs-update &>/dev/null; then
    xdg-user-dirs-update
fi

# Detect Pictures directory correctly (e.g. Imágenes vs Pictures)
if command -v xdg-user-dir &>/dev/null; then
    PICTURES_DIR=$(xdg-user-dir PICTURES)
    [ -z "$PICTURES_DIR" ] && PICTURES_DIR="$USER_HOME/Pictures"
else
    PICTURES_DIR="$USER_HOME/Pictures"
fi

WALLPAPER_DEST="$PICTURES_DIR/wallpapers"

if [ -d "$DOTFILES_DIR/wallpapers" ]; then
    # Ensure destination is writable by current user
    sudo -n chown -R $CURRENT_USER:$CURRENT_USER "$PICTURES_DIR" 2>/dev/null
    mkdir -p "$WALLPAPER_DEST"
    
    log_info "Copiando desde $DOTFILES_DIR/wallpapers/ a $WALLPAPER_DEST/"
    cp -r "$DOTFILES_DIR/wallpapers/"* "$WALLPAPER_DEST/" 2>/dev/null
    
    WALLPAPER_COUNT=$(ls -1 "$WALLPAPER_DEST/" 2>/dev/null | wc -l)
    success "$WALLPAPER_COUNT wallpapers copiados a: $WALLPAPER_DEST"
    
    # Update hyprland.conf and switcher logic to point to correct dir
    # First, fix switcher script in place before copying or after?
    # We'll update the switcher script source if it exists in .config/bin
    
    if [ -f "$USER_HOME/.config/bin/wallpaper_switcher" ]; then
        sed -i "s|WALL_DIR=\"\$HOME/Pictures/wallpapers\"|WALL_DIR=\"$WALLPAPER_DEST\"|g" "$USER_HOME/.config/bin/wallpaper_switcher"
        log_info "Script wallpaper_switcher actualizado con ruta: $WALLPAPER_DEST"
    fi
     
    # Update initial wallpaper in hyprland.conf
    # We do a safer replacement for the initial swww img command
    if [ -f "$USER_HOME/.config/hypr/hyprland.conf" ]; then
         sed -i "s|swww img ~/Pictures/wallpapers|swww img $WALLPAPER_DEST|g" "$USER_HOME/.config/hypr/hyprland.conf"
         log_info "Hyprland conf actualizado con ruta de wallpapers: $WALLPAPER_DEST"
    fi
fi

# --- Configurar GTK Theme & Fonts (Atomic Dark Mode Force) ---
log_info "Configurando temas GTK e Iconos (Hard Copy for Discovery)..."

# Create local directories
mkdir -p "$USER_HOME/.themes" "$USER_HOME/.local/share/icons" "$USER_HOME/.icons"

# Hard Copy (Definitive Fix for discovery)
cp -r /usr/share/themes/Sweet-Dark "$USER_HOME/.themes/" 2>/dev/null
cp -r /usr/share/icons/candy-icons "$USER_HOME/.local/share/icons/" 2>/dev/null
cp -r /usr/share/icons/candy-icons "$USER_HOME/.icons/" 2>/dev/null

# Apply Gsettings with DBUS Wrapper
log_info "Aplicando configuraciones GNOME/GTK (vía dbus-launch)..."
apply_gsettings() {
    sudo -u $CURRENT_USER dbus-launch gsettings set "$1" "$2" "$3"
}

apply_gsettings org.gnome.desktop.interface gtk-theme 'Sweet-Dark'
apply_gsettings org.gnome.desktop.interface icon-theme 'candy-icons'
apply_gsettings org.gnome.desktop.interface font-name 'Roboto Medium 11'
apply_gsettings org.gnome.desktop.interface cursor-theme 'Breeze_Snow'
apply_gsettings org.gnome.desktop.interface color-scheme 'prefer-dark'

# --- Fix Theme branch and Portals (BLACK-ICE CRITICAL FIX) ---
log_info "Corrigiendo rama de tema (Sweet-Dark) y configuración de Portales..."

# 1. Asegurar rama Ambar-Blue-Dark ( DARK REAL )
if [ -d "/usr/share/themes/Sweet-Dark" ]; then
    cd /usr/share/themes/Sweet-Dark
    if [ ! -d ".git" ]; then
        sudo rm -rf /usr/share/themes/Sweet-Dark
        sudo git clone https://github.com/EliverLara/Sweet.git /usr/share/themes/Sweet-Dark
        cd /usr/share/themes/Sweet-Dark
    fi
    sudo git checkout Ambar-Blue-Dark || sudo git checkout -b Ambar-Blue-Dark origin/Ambar-Blue-Dark
    sudo sed -i 's/GtkTheme=Sweet/GtkTheme=Sweet-Dark/' /usr/share/themes/Sweet-Dark/index.theme
fi

# 2. Configuración de Portales (xdg-desktop-portal 1.20+)
mkdir -p "$USER_HOME/.config/xdg-desktop-portal"
cat > "$USER_HOME/.config/xdg-desktop-portal/portals.conf" << 'EOF'
[preferred]
default=hyprland;gtk
EOF

# 3. GTK 4.0 CSS Link (Atomic Dark Mode)
mkdir -p "$USER_HOME/.config/gtk-4.0"
ln -sf /usr/share/themes/Sweet-Dark/gtk-4.0/gtk.css "$USER_HOME/.config/gtk-4.0/gtk.css"
ln -sf /usr/share/themes/Sweet-Dark/gtk-4.0/assets "$USER_HOME/.config/gtk-4.0/assets"

# 4. Qt/KDE Styling (Dolphin & Kate Fix - Premium Sweet Mode)
log_info "Configurando estilos Qt/KDE Premium (Sweet-Dark + Kvantum)..."
mkdir -p "$USER_HOME/.config/Kvantum"

# Link official Sweet Kvantum from the theme folder
KVANTUM_SRC="/usr/share/themes/Sweet-Dark/kde/Kvantum/Sweet"
if [ -d "$KVANTUM_SRC" ]; then
    ln -snf "$KVANTUM_SRC" "$USER_HOME/.config/Kvantum/Sweet"
    echo -e '[General]\ntheme=Sweet' > "$USER_HOME/.config/Kvantum/kvantum.kvconfig"
    log_success "Tema Kvantum Sweet enlazado correctamente"
else
    # Fallback search
    log_info "Buscando tema Kvantum en ubicaciones alternativas..."
    
    # Create Kvantum directories (CORRECT PATHS)
    mkdir -p "$USER_HOME/.local/share/Kvantum"
    mkdir -p "$USER_HOME/.config/Kvantum"
    
    # Check standard Kvantum folder
    if [ -d "/usr/share/Kvantum/Sweet" ]; then
        ln -snf "/usr/share/Kvantum/Sweet" "$USER_HOME/.local/share/Kvantum/Sweet"
        echo -e '[General]\ntheme=Sweet' > "$USER_HOME/.config/Kvantum/kvantum.kvconfig"
        log_success "Tema Kvantum encontrado en /usr/share/Kvantum"
    else
        # Deep search
        FOUND_KVANTUM=$(find /usr/share/themes /usr/share/Kvantum -type d -name "Sweet" 2>/dev/null | grep Kvantum | head -n 1)
        if [ -n "$FOUND_KVANTUM" ]; then
            ln -snf "$FOUND_KVANTUM" "$USER_HOME/.local/share/Kvantum/Sweet"
            echo -e '[General]\ntheme=Sweet' > "$USER_HOME/.config/Kvantum/kvantum.kvconfig"
            log_success "Tema Kvantum encontrado y enlazado: $FOUND_KVANTUM"
        else
            # USE BUNDLED THEME from dotfiles
            if [ -d "$DOTFILES_DIR/Kvantum/Sweet" ]; then
                log_info "Instalando tema Kvantum desde dotfiles bundle..."
                rm -rf "$USER_HOME/.local/share/Kvantum/Sweet"
                mkdir -p "$USER_HOME/.local/share/Kvantum/Sweet"
                cp -r "$DOTFILES_DIR/Kvantum/Sweet/"* "$USER_HOME/.local/share/Kvantum/Sweet/"
                echo -e '[General]\ntheme=Sweet' > "$USER_HOME/.config/Kvantum/kvantum.kvconfig"
                log_success "Tema Kvantum Sweet instalado en ~/.local/share/Kvantum/"
            else
                log_error "No se encontró el tema Kvantum en $DOTFILES_DIR/Kvantum/Sweet"
            fi
        fi
    fi
    chown -R $CURRENT_USER:$CURRENT_USER "$USER_HOME/.local/share/Kvantum" "$USER_HOME/.config/Kvantum"
fi

# Copy Qt5ct and Qt6ct configurations (with color schemes)
mkdir -p "$USER_HOME/.config/qt5ct/colors"
mkdir -p "$USER_HOME/.config/qt6ct/colors"
cp -r "$DOTFILES_DIR/qt5ct/"* "$USER_HOME/.config/qt5ct/" 2>/dev/null || true
cp -r "$DOTFILES_DIR/qt6ct/"* "$USER_HOME/.config/qt6ct/" 2>/dev/null || true
chown -R $CURRENT_USER:$CURRENT_USER "$USER_HOME/.config/qt5ct" "$USER_HOME/.config/qt6ct"
log_info "Configuración Qt5ct/Qt6ct copiada con color schemes"

# Force Qt Environment Globally
if ! grep -q "QT_QPA_PLATFORMTHEME" /etc/environment; then
    echo "QT_QPA_PLATFORMTHEME=qt5ct" | sudo tee -a /etc/environment
    log_info "QT_QPA_PLATFORMTHEME añadido a /etc/environment"
fi

# Link color scheme and force in kdeglobals
mkdir -p "$USER_HOME/.local/share/color-schemes"
COLOR_SCHEME_SRC="/usr/share/themes/Sweet-Dark/kde/konsole/Sweet.colorscheme"
if [ -f "$COLOR_SCHEME_SRC" ]; then
    ln -sf "$COLOR_SCHEME_SRC" "$USER_HOME/.local/share/color-schemes/Sweet.colorscheme"
fi
# Robust kdeglobals with explicit colors (Fix Black Text on Dark Background)
cat > "$USER_HOME/.config/kdeglobals" << 'EOF'
[General]
ColorScheme=Sweet
Name=Sweet
shadeSortColumn=true
font=Roboto,10,-1,5,50,0,0,0,0,0
menuFont=Roboto,10,-1,5,50,0,0,0,0,0
toolBarFont=Roboto,10,-1,5,50,0,0,0,0,0
smallestReadableFont=Roboto,9,-1,5,50,0,0,0,0,0
fixed=Hack Nerd Font Mono,10,-1,5,50,0,0,0,0,0

[KDE]
LookAndFeelPackage=Sweet
SingleClick=false
widgetStyle=Fusion

[Colors:Button]
BackgroundAlternate=64,69,82
BackgroundNormal=30,34,51
DecorationFocus=0,193,228
DecorationHover=197,14,210
ForegroundActive=255,255,255
ForegroundInactive=160,165,175
ForegroundLink=0,193,228
ForegroundNegative=237,37,78
ForegroundNeutral=255,106,0
ForegroundNormal=230,230,230
ForegroundPositive=113,247,159
ForegroundVisited=82,148,226

[Colors:Selection]
BackgroundAlternate=29,153,243
BackgroundNormal=0,0,127
DecorationFocus=0,0,127
DecorationHover=197,14,210
ForegroundActive=252,252,252
ForegroundInactive=211,218,227
ForegroundLink=253,188,75
ForegroundNegative=237,37,78
ForegroundNeutral=255,106,0
ForegroundNormal=254,254,254
ForegroundPositive=113,247,159
ForegroundVisited=189,195,199

[Colors:Tooltip]
BackgroundAlternate=47,52,63
BackgroundNormal=53,57,69
DecorationFocus=0,193,228
DecorationHover=197,14,210
ForegroundActive=255,255,255
ForegroundInactive=160,165,175
ForegroundLink=0,193,228
ForegroundNegative=237,37,78
ForegroundNeutral=255,106,0
ForegroundNormal=230,230,230
ForegroundPositive=113,247,159
ForegroundVisited=82,148,226

[Colors:View]
BackgroundAlternate=31,35,51
BackgroundNormal=22,25,37
DecorationFocus=0,193,228
DecorationHover=197,14,210
ForegroundActive=255,255,255
ForegroundInactive=180,180,180
ForegroundLink=0,193,228
ForegroundNegative=237,37,78
ForegroundNeutral=255,106,0
ForegroundNormal=240,240,240
ForegroundPositive=113,247,159
ForegroundVisited=124,183,255

[Colors:Window]
BackgroundAlternate=47,52,63
BackgroundNormal=24,27,40
DecorationFocus=0,193,228
DecorationHover=197,14,210
ForegroundActive=255,255,255
ForegroundInactive=160,165,175
ForegroundLink=0,193,228
ForegroundNegative=237,37,78
ForegroundNeutral=255,106,0
ForegroundNormal=240,240,240
ForegroundPositive=113,247,159
ForegroundVisited=179,13,191

[Icons]
Theme=candy-icons
EOF

# Crear settings.ini limpio (No invalid keys)
mkdir -p "$USER_HOME/.config/gtk-3.0" "$USER_HOME/.config/gtk-4.0"
cat > "$USER_HOME/.config/gtk-3.0/settings.ini" << 'EOF'
[Settings]
gtk-theme-name=Sweet-Dark
gtk-icon-theme-name=candy-icons
gtk-font-name=Roboto Medium 10
gtk-cursor-theme-name=Breeze_Snow
gtk-application-prefer-dark-theme=1
gtk-color-scheme=prefer-dark
EOF
cp "$USER_HOME/.config/gtk-3.0/settings.ini" "$USER_HOME/.config/gtk-4.0/settings.ini"

# --- ZSH Integration (settarget) ---
if ! grep -q "function settarget" "$USER_HOME/.zshrc"; then
    cat >> "$USER_HOME/.zshrc" << 'EOF'

# Función settarget para HTB/Waybar (s4vitar style)
function settarget(){
    ip_address=$1
    machine_name=$2
    if [ -n "$ip_address" ] && [ -n "$machine_name" ]; then
        echo "$ip_address $machine_name" > ~/.config/bin/target
    elif [ -n "$ip_address" ]; then
        echo "$ip_address" > ~/.config/bin/target
    else
        echo "No Target" > ~/.config/bin/target
    fi
}
EOF
fi
# --- Despliegue de Configuraciones (Dotfiles) ---
log_info "Desplegando configuraciones de Hyprland, Waybar, Kitty y Wofi..."

# Asegurar arquitectura de directorios
mkdir -p "$USER_HOME/.config/hypr"
mkdir -p "$USER_HOME/.config/waybar"
mkdir -p "$USER_HOME/.config/kitty"
mkdir -p "$USER_HOME/.config/wofi"
mkdir -p "$USER_HOME/.config/wlogout"
mkdir -p "$USER_HOME/.config/dunst"
mkdir -p "$USER_HOME/.config/bin"

# Copia Recursiva de configuraciones CORE
if [ -d "$DOTFILES_DIR/hypr" ]; then
    cp -r "$DOTFILES_DIR/hypr/"* "$USER_HOME/.config/hypr/"
    log_info "Hyprland dotfiles copiados"
fi

if [ -d "$DOTFILES_DIR/waybar" ]; then
    cp -r "$DOTFILES_DIR/waybar/"* "$USER_HOME/.config/waybar/"
    log_info "Waybar dotfiles copiados"
fi

if [ -d "$DOTFILES_DIR/kitty" ]; then
    cp -r "$DOTFILES_DIR/kitty/"* "$USER_HOME/.config/kitty/"
    log_info "Kitty dotfiles copiados"
fi

if [ -d "$DOTFILES_DIR/wofi" ]; then
    cp -r "$DOTFILES_DIR/wofi/"* "$USER_HOME/.config/wofi/"
    log_info "Wofi dotfiles copiados"
fi

if [ -d "$DOTFILES_DIR/bin" ]; then
    cp -r "$DOTFILES_DIR/bin/"* "$USER_HOME/.config/bin/"
    chmod +x "$USER_HOME/.config/bin/"*
    log_info "Scripts binarios copiados y chmod +x aplicado"
fi

if [ -d "$DOTFILES_DIR/wlogout" ]; then
    cp -r "$DOTFILES_DIR/wlogout/"* "$USER_HOME/.config/wlogout/"
    log_info "wlogout dotfiles copiados"
fi

if [ -d "$DOTFILES_DIR/fastfetch" ]; then
    cp -r "$DOTFILES_DIR/fastfetch/"* "$USER_HOME/.config/fastfetch/"
    chmod +x "$USER_HOME/.config/fastfetch/random_logo.sh" 2>/dev/null || true
    log_info "Fastfetch dotfiles y script randomizer copiados"
fi

# Replication of manual "winning" configs (KWrite, Kate, Dolphin)
log_info "Instalando configuraciones ganadoras (KWrite, Kate, Dolphin)..."
cp "$DOTFILES_DIR/kwrite/kwriterc" "$USER_HOME/.config/kwriterc" 2>/dev/null || true
cp "$DOTFILES_DIR/kwrite/katerc" "$USER_HOME/.config/katerc" 2>/dev/null || true
cp "$DOTFILES_DIR/kwrite/dolphinrc" "$USER_HOME/.config/dolphinrc" 2>/dev/null || true
chown $CURRENT_USER:$CURRENT_USER "$USER_HOME/.config/kwriterc" "$USER_HOME/.config/katerc" "$USER_HOME/.config/dolphinrc" 2>/dev/null || true

# scripts ya instalados en fase EARLY
log_info "Verificando scripts de utilidad..."
if [ -d "$USER_HOME/.config/bin" ]; then
    chmod +x "$USER_HOME/.config/bin/"*
    success "Scripts de utilidad verificados"
fi

# --- Ajustar permisos ---
chown -R $CURRENT_USER:$CURRENT_USER "$USER_HOME/.config/hypr"
chown -R $CURRENT_USER:$CURRENT_USER "$USER_HOME/.config/waybar"
chown -R $CURRENT_USER:$CURRENT_USER "$USER_HOME/.config/kitty"
chown -R $CURRENT_USER:$CURRENT_USER "$USER_HOME/.config/wofi"
chown -R $CURRENT_USER:$CURRENT_USER "$WALLPAPER_DEST" 2>/dev/null || true

# --- PLYMOUTH (Boot Splash - via AUR) ---
log_info "Instalando y configurando Plymouth (Boot Splash)..."

# Instalar plymouth y un tema desde AUR
if ! pacman -Q plymouth &>/dev/null; then
    retry_command yay -S --needed --noconfirm plymouth plymouth-theme-abstract-ring-git
fi

# Validate Abstract Ring Installation (Fix Path with better discovery)
PLYMOUTH_THEME_DIR=$(pacman -Ql plymouth-theme-abstract-ring-git 2>/dev/null | grep ".plymouth$" | head -n 1 | awk '{print $2}' | xargs dirname)
if [ -z "$PLYMOUTH_THEME_DIR" ]; then 
    PLYMOUTH_THEME_DIR=$(find /usr/share/plymouth/themes \( -name "abstract_ring" -o -name "abstract-ring" \) -type d | head -n 1)
fi

if [ -n "$PLYMOUTH_THEME_DIR" ] && [ -d "$PLYMOUTH_THEME_DIR" ]; then
    THEME_NAME=$(basename "$PLYMOUTH_THEME_DIR")
    log_info "Tema Plymouth detectado en: $PLYMOUTH_THEME_DIR (Nombre: $THEME_NAME)"
    sudo -n plymouth-set-default-theme -R "$THEME_NAME"
else
    log_warn "No se pudo detectar el volumen del tema Abstract Ring. Usando default..."
fi

# Inyectar hook en mkinitcpio.conf
if ! grep -q "plymouth" /etc/mkinitcpio.conf; then
    log_info "Inyectando hook 'plymouth' en mkinitcpio.conf..."
    sudo -n sed -i 's/base udev/base udev plymouth/' /etc/mkinitcpio.conf
    sudo -n mkinitcpio -P
fi

# Añadir quiet splash a GRUB
if ! grep -q "splash" /etc/default/grub; then
    log_info "Habilitando 'quiet splash' en GRUB..."
    sudo -n sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash /' /etc/default/grub
    sudo -n grub-mkconfig -o /boot/grub/grub.cfg
fi

success "Plymouth configurado correctamente"

success "Hyprland configurado completamente"
