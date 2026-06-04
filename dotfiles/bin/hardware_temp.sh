#!/bin/bash
# CPU (and GPU if available) temperature for Waybar custom module
# Supports: Intel (coretemp/thinkpad), AMD (k10temp Tctl/Tdie), NVIDIA, AMD GPU
# Classes: normal (<60) | warm (60-74) | high (75-89) | critical (>=90)

cpu_temp=""

# Intel coretemp
if [[ -z "$cpu_temp" ]]; then
    cpu_temp=$(sensors coretemp-isa-0000 2>/dev/null | awk '/Package id 0/ {gsub(/[^0-9.]/, "", $4); print int($4)}')
fi
# Intel ThinkPad fallback
if [[ -z "$cpu_temp" || "$cpu_temp" -eq 0 ]] 2>/dev/null; then
    cpu_temp=$(sensors thinkpad-isa-0000 2>/dev/null | awk '/^CPU/ {gsub(/[^0-9.]/, "", $2); print int($2)}')
fi
# AMD k10temp
if [[ -z "$cpu_temp" || "$cpu_temp" -eq 0 ]] 2>/dev/null; then
    cpu_temp=$(sensors 2>/dev/null | awk '/Tctl:|Tdie:/ {gsub(/[^0-9.]/, "", $2); print int($2); exit}')
fi
# Generic fallback
if [[ -z "$cpu_temp" || "$cpu_temp" -eq 0 ]] 2>/dev/null; then
    cpu_temp=$(sensors 2>/dev/null | awk '/Package id 0:/ {gsub(/[^0-9.]/, "", $4); print int($4); exit}')
fi

if [[ -z "$cpu_temp" ]]; then
    echo '{"text": " N/A", "class": "unknown", "tooltip": "Sin sensor de temperatura"}'
    exit 0
fi

# GPU (optional)
gpu_text=""
gpu_tooltip=""

if command -v nvidia-smi &>/dev/null; then
    gpu_t=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader 2>/dev/null | head -1)
    [[ "$gpu_t" =~ ^[0-9]+$ ]] && gpu_text="  󰢮 ${gpu_t}°C" && gpu_tooltip="\nGPU(NVIDIA): ${gpu_t}°C"
fi

if [[ -z "$gpu_text" ]]; then
    amd_t=$(sensors 2>/dev/null | awk '/^amdgpu/{found=1} found && /edge:/{gsub(/[^0-9.]/, "", $2); print int($2); exit}')
    [[ -n "$amd_t" ]] && gpu_text="  󰢮 ${amd_t}°C" && gpu_tooltip="\nGPU(AMD): ${amd_t}°C"
fi

# Color class
if [[ "$cpu_temp" -ge 90 ]]; then
    CLASS="critical"
elif [[ "$cpu_temp" -ge 75 ]]; then
    CLASS="high"
elif [[ "$cpu_temp" -ge 60 ]]; then
    CLASS="warm"
else
    CLASS="normal"
fi

echo "{\"text\": \" ${cpu_temp}°C${gpu_text}\", \"class\": \"${CLASS}\", \"tooltip\": \"CPU: ${cpu_temp}°C${gpu_tooltip}\"}"
