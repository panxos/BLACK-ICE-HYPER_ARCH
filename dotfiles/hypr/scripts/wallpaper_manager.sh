#!/bin/bash
# ~/.config/hypr/scripts/wallpaper_manager.sh
# SWWW Wallpaper Manager with Transitions
# Author: P4nx0s

WALLPAPER_DIR="$HOME/.config/hypr/wallpapers"
TRANSITION_TYPE="random" # simple, fade, left, right, top, bottom, wipe, wave, grow, center, any, outer, random
TRANSITION_DURATION="2"
TRANSITION_FPS="60"

# Check SWWW daemon
if ! pgrep -x "swww-daemon" > /dev/null; then
    swww init &
    sleep 1
fi

# Get list of wallpapers
files=($WALLPAPER_DIR/*)
num_files=${#files[@]}

if [ $num_files -eq 0 ]; then
    notify-send "Wallpaper Manager" "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

# Current index logic (simple state file)
STATE_FILE="$HOME/.config/hypr/scripts/.current_wall"
if [ ! -f "$STATE_FILE" ]; then
    echo "0" > "$STATE_FILE"
fi
current_index=$(cat "$STATE_FILE")

case $1 in
    "next")
        next_index=$(( (current_index + 1) % num_files ))
        echo $next_index > "$STATE_FILE"
        target_file=${files[$next_index]}
        ;;
    "prev")
        prev_index=$(( (current_index - 1 + num_files) % num_files ))
        echo $prev_index > "$STATE_FILE"
        target_file=${files[$prev_index]}
        ;;
    "random")
        rand_index=$(( RANDOM % num_files ))
        echo $rand_index > "$STATE_FILE"
        target_file=${files[$rand_index]}
        ;;
    "init")
        # Load last used or random
        target_file=${files[$current_index]}
        ;;
    *)
        echo "Usage: $0 {next|prev|random|init}"
        exit 1
        ;;
esac

# Apply Wallpaper
swww img "$target_file" \
    --transition-type $TRANSITION_TYPE \
    --transition-duration $TRANSITION_DURATION \
    --transition-fps $TRANSITION_FPS \
    --transition-step 90

# Optional: Generate Pywal Colors (Future implementation)
# wal -i "$target_file"

notify-send -t 2000 "Wallpaper Changed" "$(basename "$target_file")"
