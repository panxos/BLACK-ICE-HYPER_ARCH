#!/bin/bash
#
# Screenshot Capture Script for BLACK-ICE ARCH Documentation
# Run this script LOCALLY on the Hyprland machine (207)
#
# Usage: ./capture_screenshots.sh

set -euo pipefail

# Configuration
SCREENSHOT_DIR="$HOME/Pictures/screenshots/readme"
TEMP_DIR="/tmp/blackice_screenshots"
THEMES=("Ra-Solar" "Horus-Cyber" "Anubis-Death" "Isis-Magic")
DELAY=3  # Seconds between theme change and screenshot

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${GREEN}BLACK-ICE ARCH - Screenshot Capture for README${NC}        ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running in Hyprland
if [ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    echo -e "${RED}ERROR: This script must be run from within a Hyprland session${NC}"
    echo -e "${YELLOW}Please run this script in your Hyprland terminal${NC}"
    exit 1
fi

# Check dependencies
for cmd in grim hyprctl magick; do
    if ! command -v "$cmd" &>/dev/null; then
        echo -e "${RED}ERROR: Required command '$cmd' not found${NC}"
        echo -e "${YELLOW}Install with: sudo pacman -S grim hyprland imagemagick${NC}"
        exit 1
    fi
done

# Create directories
mkdir -p "$SCREENSHOT_DIR" "$TEMP_DIR"
echo -e "${GREEN}✓${NC} Created directories"

# Function to pixelate region (bottom-center for IP)
pixelate_ip() {
    local input="$1"
    local output="$2"
    
    # Get image dimensions
    local width=$(identify -format "%w" "$input")
    local height=$(identify -format "%h" "$input")
    
    # Calculate region to pixelate (bottom-center module for IP)
    # Target: Center of bottom bar (1366x768 res)
    local region_width=600  # Wide enough to cover both IPs
    local region_height=40
    local region_x=$(( (width - region_width) / 2 ))
    local region_y=$(( height - region_height - 0 )) # Bottom 40px
    
    echo -e "${CYAN}  Pixelating IP region (X:$region_x Y:$region_y W:$region_width H:$region_height)...${NC}"
    
    # Create pixelated version
    magick "$input" \
        \( +clone -crop ${region_width}x${region_height}+${region_x}+${region_y} \
           -scale 10% -scale 1000% \) \
        -geometry +${region_x}+${region_y} \
        -composite "$output"
}

# Function to capture screenshot for a theme
capture_theme() {
    local theme="$1"
    local index="$2"
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}[$index/4]${NC} Capturing theme: ${YELLOW}$theme${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Change theme using theme selector
    echo -e "${CYAN}  Switching to $theme...${NC}"
    "$HOME/.config/bin/theme_selector" "$theme" 2>/dev/null || {
        echo -e "${YELLOW}  Warning: theme_selector not found, trying manual switch${NC}"
        # Manual theme switch
        ln -sf "$HOME/.config/waybar/themes/$theme/config.jsonc" "$HOME/.config/waybar/config.jsonc"
        ln -sf "$HOME/.config/waybar/themes/$theme/style.css" "$HOME/.config/waybar/style.css"
        pkill waybar && waybar &>/dev/null &
    }
    
    # Wait for theme to load
    echo -e "${CYAN}  Waiting ${DELAY}s for theme to load...${NC}"
    sleep $DELAY
    
    # Take screenshot
    local raw_file="$TEMP_DIR/${theme}_raw.png"
    local final_file="$SCREENSHOT_DIR/${theme}.png"
    
    echo -e "${CYAN}  Capturing screenshot...${NC}"
    grim "$raw_file"
    
    # Pixelate IP address
    pixelate_ip "$raw_file" "$final_file"
    
    # Get file size
    local size=$(du -h "$final_file" | cut -f1)
    
    echo -e "${GREEN}  ✓ Screenshot saved: $final_file ($size)${NC}"
}

# Main execution
echo -e "${YELLOW}IMPORTANT:${NC}"
echo -e "  1. Make sure you have some applications open (browser, terminal, etc.)"
echo -e "  2. Position windows to show off the desktop"
echo -e "  3. This script will change themes automatically"
echo -e "  4. IP addresses in Waybar will be pixelated"
echo ""
echo -e "${CYAN}Press ENTER to start capturing screenshots...${NC}"
read

# Capture each theme
for i in "${!THEMES[@]}"; do
    capture_theme "${THEMES[$i]}" $((i+1))
done

# Summary
echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${GREEN}CAPTURE COMPLETE!${NC}                                       ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Screenshots saved to:${NC} $SCREENSHOT_DIR"
echo ""
echo -e "${YELLOW}Files created:${NC}"
ls -lh "$SCREENSHOT_DIR"/*.png | awk '{print "  " $9 " (" $5 ")"}'
echo ""
echo -e "${CYAN}Next steps:${NC}"
echo -e "  1. Review screenshots to ensure IP is pixelated"
echo -e "  2. Copy to your local machine:"
echo -e "     ${YELLOW}scp faravena@172.18.200.207:$SCREENSHOT_DIR/*.png /local/path/${NC}"
echo -e "  3. Add to README.md"
echo ""

# Cleanup temp files
rm -rf "$TEMP_DIR"
echo -e "${GREEN}✓${NC} Cleaned up temporary files"
