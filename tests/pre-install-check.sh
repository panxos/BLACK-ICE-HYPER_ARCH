#!/bin/bash
# Tests: Pre-Install Check
# Validates environment readiness without modifying disk

SCRIPT_DIR=$(dirname "$(dirname "$(readlink -f "$0")")")
source "$SCRIPT_DIR/src/lib/logging.sh"
source "$SCRIPT_DIR/src/lib/utils.sh"
source "$SCRIPT_DIR/src/lib/colors.sh"

banner "TEST SUITE" "Pre-Install Environment Validation"

FAIL=0

log_info "1. Checking UEFI..."
if [ -d "/sys/firmware/efi/efivars" ]; then
    success "UEFI Detected"
else
    log_warn "Legacy BIOS detected (Supported but not recommended)"
fi

log_info "2. Checking Internet..."
if ping -c 1 8.8.8.8 &>/dev/null; then
    success "Internet Connection OK"
else
    log_error "No Internet Connection"
    FAIL=1
fi

log_info "3. Checking Root Privileges..."
if [ "$EUID" -eq 0 ]; then
    success "Running as Root"
else
    log_warn "Not running as root (Required for install.sh)"
fi

log_info "4. Checking Keyring..."
if [ -d "/etc/pacman.d/gnupg" ]; then
    success "Keyring directory exists"
else
    log_warn "Keyring directory missing (Will be created)"
fi

if [ $FAIL -eq 0 ]; then
    echo ""
    success ">> SYSTEM READY FOR INSTALLATION <<"
    exit 0
else
    echo ""
    log_error ">> SYSTEM NOT READY <<"
    exit 1
fi
