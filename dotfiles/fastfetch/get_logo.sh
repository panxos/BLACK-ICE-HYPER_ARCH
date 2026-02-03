#!/bin/bash
# get_logo.sh - Black-Ice Arch v1.0
LOGOS_DIR="$HOME/.config/fastfetch/logos"
# Solo devuelve la ruta del archivo, Fastfetch se encarga del resto
find "$LOGOS_DIR" -maxdepth 1 -name "*.png" 2>/dev/null | shuf -n 1
