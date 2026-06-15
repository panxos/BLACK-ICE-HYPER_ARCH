#!/bin/bash
# Tests: Post-Install Validation
# Verifies that key components are installed and configured

SCRIPT_DIR=$(dirname "$(dirname "$(readlink -f "$0")")")
source "$SCRIPT_DIR/src/lib/logging.sh"
source "$SCRIPT_DIR/src/lib/colors.sh"

banner "TEST SUITE" "Post-Install Verification"

check_bin() {
    if command -v "$1" &>/dev/null; then
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

check_symlink() {
    if [[ -L "$1" ]]; then
        echo -e "${GREEN}[OK]${NC} Symlink found: $1"
    else
        echo -e "${RED}[FAIL]${NC} Symlink missing: $1"
        FAIL=1
    fi
}

FAIL=0

log_info "Checking Core WM Binaries..."
check_bin hyprland
check_bin waybar
check_bin wofi
check_bin kitty
check_bin awww
check_bin hyprlock
check_bin swaync

log_info "Checking AUR Helpers..."
check_bin yay
check_bin paru

log_info "Checking Shell & Terminal..."
check_bin zsh
check_bin fastfetch
check_bin btop

log_info "Checking Dev Tools..."
check_bin nvim

log_info "Checking Security Tools..."
check_bin nmap

log_info "Checking Audio Stack..."
check_bin pipewire
check_bin wireplumber

log_info "Checking Display Manager..."
check_bin sddm

log_info "Checking Hyprland Configurations..."
check_file "$HOME/.config/hypr/hyprland.conf"
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

log_info "Checking Systemd Services..."
check_service sddm.service
check_service NetworkManager.service
check_service bluetooth.service

log_info "Checking XDG Menu Symlink..."
check_symlink /etc/xdg/menus/applications.menu

if [[ $FAIL -eq 0 ]]; then
    success ">> DEPLOYMENT VERIFIED <<"
    exit 0
else
    log_error ">> DEPLOYMENT INCOMPLETE <<"
    exit 1
fi
