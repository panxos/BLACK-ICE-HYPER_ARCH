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

FAIL=0

log_info "Checking Core Binaries..."
check_bin hyprland
check_bin waybar
check_bin wofi
check_bin kitty
check_bin swww
check_bin yay

log_info "Checking Configurations..."
check_file "$HOME/.config/hypr/hyprland.conf"
check_file "$HOME/.config/waybar/config"
check_file "$HOME/.config/kitty/kitty.conf"

if [ $FAIL -eq 0 ]; then
    success ">> DEPLOYMENT VERIFIED <<"
    exit 0
else
    log_error ">> DEPLOYMENT INCOMPLETE <<"
    exit 1
fi
