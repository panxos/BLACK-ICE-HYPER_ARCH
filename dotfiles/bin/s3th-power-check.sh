#!/bin/bash
# Capturamos el modo real de TLP
MODE=$(tlp-stat -p | grep "Mode" | sed 's/.*= //' | tr '[:lower:]' '[:upper:]')
[ -z "$MODE" ] && MODE="DESCONOCIDO"

# Notificación Cyber-Slim
notify-send -u normal -i battery-good "⚡ s3th: PERFIL ENERGÍA" "Estado del Sistema: <b>$MODE</b>\nOptimizando s3th para el máximo rendimiento." -t 5000
