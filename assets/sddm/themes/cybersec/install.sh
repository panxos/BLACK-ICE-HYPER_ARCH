#!/bin/bash

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}[*] Installing CyberSec SDDM Theme...${NC}"

# Check for Root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}[!] Please run as root (sudo ./install.sh)${NC}"
    exit 1
fi

# 1. Install Dependencies (Arch Linux)
echo -e "${CYAN}[*] Checking dependencies...${NC}"
if command -v pacman &> /dev/null; then
    pacman -S --needed --noconfirm qt5-graphicaleffects qt5-quickcontrols2 ttf-jetbrains-mono sddm
else
    echo -e "${RED}[!] This script supports Arch Linux (pacman). Please install 'qt5-graphicaleffects', 'qt5-quickcontrols2', and 'ttf-jetbrains-mono' manually.${NC}"
fi

# 2. Install Theme Files
THEME_DIR="/usr/share/sddm/themes/cybersec"
echo -e "${CYAN}[*] Deploying theme to $THEME_DIR...${NC}"

mkdir -p "$THEME_DIR"
cp -r ./* "$THEME_DIR/"
# Remove the install script itself from the destination to keep it clean
rm "$THEME_DIR/install.sh"
rm "$THEME_DIR/README.md" 2>/dev/null

# 3. Configure SDDM
echo -e "${CYAN}[*] Configuring SDDM to use 'cybersec' theme...${NC}"

SDDM_CONF_DIR="/etc/sddm.conf.d"
mkdir -p "$SDDM_CONF_DIR"

# Create a specialized config snippet
cat > "$SDDM_CONF_DIR/theme.conf" <<EOF
[Theme]
Current=cybersec
EOF

# 4. Test Mode Hint
echo -e "${GREEN}[+] Installation Complete!${NC}"
echo -e "${CYAN}[*] To test without rebooting, run:${NC}"
echo -e "sddm-greeter --test-mode --theme $THEME_DIR"
