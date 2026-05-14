#!/bin/bash
# hardware_temp.sh
# Script para obtener la temperatura de la CPU y GPU (si existe) para un módulo personalizado en Waybar.
# Formato de salida: JSON para el módulo custom de waybar con return-type: json.

# --- Obtener Temperatura de la CPU ---
# Busca la métrica Tctl o Tdie (que suelen ser las principales en AMD) o Core 0 / Package id 0 en Intel
cpu_temp=""
if command -v sensors &> /dev/null; then
    cpu_temp=$(sensors | awk '/Tctl:/ {print $2} /Tdie:/ {print $2} /Package id 0:/ {print $4} /^Core 0:/ {print $3}' | head -n 1 | tr -d '+°C')
fi

# Si no encuentra ninguna métrica obvia de CPU, pone un fallback de 0
if [[ -z "$cpu_temp" || ! "$cpu_temp" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    cpu_temp="--"
else
    cpu_temp=$(printf "%.0f" "$cpu_temp")
fi

# Formatear la cadena de la CPU
output_text=" ${cpu_temp}°C"

# --- Obtener Temperatura de la GPU (si existe) ---
gpu_temp=""
has_gpu=false

# 1. Comprobar si existe GPU NVIDIA usando nvidia-smi
if command -v nvidia-smi &> /dev/null; then
    # Verifica si en realidad la GPU responde y recoge la temperatura (excluyendo errores comunes)
    nv_out=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader 2>/dev/null | head -n 1)
    if [[ "$nv_out" =~ ^[0-9]+$ ]]; then
        gpu_temp="$nv_out"
        has_gpu=true
    fi
fi

# 2. Si no es NVIDIA, comprobar si existe GPU AMD a través de sensors
if [ "$has_gpu" = false ] && command -v sensors &> /dev/null; then
    # Busca la sección amdgpu y la métrica edge o junction (común en gráficas AMD modernas)
    amd_out=$(sensors amdgpu-* 2>/dev/null | awk '/edge:/ {print $2} /junction:/ {print $2}' | head -n 1 | tr -d '+°C')
    if [ -n "$amd_out" ]; then
        # Redondea a entero
        gpu_temp=$(printf "%.0f" "$amd_out")
        has_gpu=true
    fi
fi

# Si se encontró una GPU, la agregamos a la salida
if [ "$has_gpu" = true ] && [ -n "$gpu_temp" ]; then
    output_text="$output_text  󰢮 ${gpu_temp}°C"
fi

# Armar el JSON requerido por Waybar
# - text: Lo que se muestra en la barra
# - tooltip: Lo que se muestra al pasar el cursor
# - class: Podemos poner "normal", "warning" o "critical" basado en la CPU para cambiar colores si se desea (opcional)

class="normal"
# Lógica simple para alertas (puedes ajustar los límites si es necesario)
if [[ "$cpu_temp" =~ ^[0-9]+$ ]]; then
    if [ "$cpu_temp" -ge 85 ]; then
        class="critical"
    elif [ "$cpu_temp" -ge 70 ]; then
        class="warning"
    fi
fi

cat <<EOF
{"text": "$output_text", "tooltip": "CPU: ${cpu_temp}°C\nGPU: ${gpu_temp:-N/A}°C", "class": "$class"}
EOF
