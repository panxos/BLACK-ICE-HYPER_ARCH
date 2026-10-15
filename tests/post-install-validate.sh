#!/bin/bash
# Tests: Post-Install Validation
# Verifies that key components are installed and configured

SCRIPT_DIR=$(dirname "$(dirname "$(readlink -f "$0")")")
source "$SCRIPT_DIR/src/lib/logging.sh"
source "$SCRIPT_DIR/src/lib/colors.sh"

banner "TEST SUITE" "Post-Install Verification"

check_bin() {
    if command -v "$1" &>/dev/null || [[ -x "$HOME/.local/bin/$1" ]]; then
        echo -e "${GREEN}[OK]${NC} Binary found: $1"
    else
        echo -e "${RED}[FAIL]${NC} Binary missing: $1"
        FAIL=1
    fi
}

check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}[OK]${NC} Config found: $(basename "$1")"
    else
        echo -e "${RED}[FAIL]${NC} Config missing: $1"
        FAIL=1
    fi
}

check_service() {
    if systemctl is-enabled "$1" &>/dev/null; then
        echo -e "${GREEN}[OK]${NC} Service enabled: $1"
    else
        echo -e "${RED}[FAIL]${NC} Service not enabled: $1"
        FAIL=1
    fi
}

FAIL=0

log_info "Checking Core WM Binaries..."
check_bin Hyprland
check_bin waybar
check_bin wofi
check_bin kitty
check_bin awww
check_bin hyprlock
check_bin swaync

log_info "Checking AUR Helpers..."
check_bin paru

log_info "Checking Shell & Terminal..."
check_bin zsh
check_bin fastfetch
check_bin btop

log_info "Checking Dev Tools..."
if pacman -Q neovim &>/dev/null; then check_bin nvim; fi

log_info "Checking Security Tools..."
if pacman -Q nmap &>/dev/null; then check_bin nmap; fi

log_info "Checking Audio Stack..."
check_bin pipewire
check_bin wireplumber

log_info "Checking Display Manager..."
check_bin sddm

log_info "Checking Hyprland Configurations..."
check_file "$HOME/.config/hypr/hyprland.conf"
if [[ -f "$HOME/.config/hypr/hyprland.lua" ]]; then
    Hyprland --verify-config -c "$HOME/.config/hypr/hyprland.lua" >/dev/null 2>&1 || FAIL=1
fi
check_file "$HOME/.config/hypr/hyprlock.conf"

log_info "Checking Waybar Configuration..."
check_file "$HOME/.config/waybar/config"
check_file "$HOME/.config/waybar/style.css"

log_info "Checking Terminal Configuration..."
check_file "$HOME/.config/kitty/kitty.conf"

log_info "Checking Launcher Configuration..."
check_file "$HOME/.config/wofi/config"

log_info "Checking Notification Daemon..."
check_file "$HOME/.config/swaync/config.json"

log_info "Checking Shell Configuration..."
check_file "$HOME/.zshrc"
check_file "$HOME/.config/black-ice/prompt.zsh"
check_file "$HOME/.local/share/black-ice/software/config/apps.json"
check_bin black-ice-control
check_bin black-ice-theme-studio
check_bin black-ice-apps
check_bin black-ice-system
check_bin black-ice-hypr
check_file "$HOME/.local/share/black-ice/system/manager.py"
check_file /usr/share/black-ice/apps.json
if [[ ! -x /usr/lib/black-ice/system-transaction ]] || [[ $(stat -c '%U:%a' /usr/lib/black-ice/system-transaction 2>/dev/null) != root:755 ]]; then
    log_error "Helper de sistema ausente o con permisos incorrectos"
    FAIL=1
fi

log_info "Checking Systemd Services..."
check_service sddm.service
check_service NetworkManager.service
check_service bluetooth.service
if ! systemctl --user is-enabled black-ice-conky.service >/dev/null 2>&1; then
    log_error "Servicio de Conky no habilitado"
    FAIL=1
fi
check_file "$HOME/.config/systemd/user/hyprland-session.target"

log_info "Checking XDG Menu..."
check_file /etc/xdg/menus/applications.menu

if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
    if ! pgrep -u "$(id -u)" -x waybar >/dev/null; then
        log_error "Waybar no está ejecutándose en la sesión"
        FAIL=1
    fi
    if ! "$HOME/.local/bin/black-ice-conky" status | python3 -c 'import json,sys; status=json.load(sys.stdin); sys.exit(0 if not status.get("enabled", True) or status.get("running") and not status.get("errors") else 1)'; then
        log_error "Conky no tiene procesos y capas visibles; revisa su estado y el journal"
        FAIL=1
    fi
fi

if [[ $FAIL -eq 0 ]]; then
    success ">> DEPLOYMENT VERIFIED <<"
    exit 0
else
    log_error ">> DEPLOYMENT INCOMPLETE <<"
    exit 1
fi
