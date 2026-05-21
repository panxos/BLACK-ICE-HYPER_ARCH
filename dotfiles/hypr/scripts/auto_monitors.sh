#!/bin/bash
# auto_monitors.sh — Detecta monitores y configura monitors.conf
#
# Comportamiento:
#   - Primera vez (sin state file): genera config + abre nwg-displays si hay 2+ monitores
#   - Boots siguientes: aplica monitors.conf existente en silencio, no abre nada
#   - Para reconfigurar manualmente: auto_monitors.sh --force-gui
#
# Uso: auto_monitors.sh [--force-gui]

MONITORS_CONF="$HOME/.config/hypr/monitors.conf"
STATE_FILE="$HOME/.cache/black-ice/monitors_configured"
FORCE_GUI=false

[[ "${1:-}" == "--force-gui" ]] && FORCE_GUI=true

mkdir -p "$HOME/.cache/black-ice"

# --- Detectar entorno y escribir overrides de performance + GPU ---
VM_CONF="$HOME/.config/hypr/vm-performance.conf"
VIRT=$(systemd-detect-virt 2>/dev/null || echo "none")

if [[ "$VIRT" != "none" && "$VIRT" != "" ]]; then
    # VM: deshabilitar efectos pesados y forzar renderer GLES2 (compatible VirGL)
    cat > "$VM_CONF" << 'EOF'
# AUTO-GENERADO — VM detectada (KVM/QEMU/VBox): efectos desactivados + renderer VirGL
env = WLR_RENDERER,gles2
env = LIBVA_DRIVER_NAME,virpipe
env = MESA_LOADER_DRIVER_OVERRIDE,virpipe
decoration {
    blur { enabled = false }
    shadow { enabled = false }
}
animations { enabled = false }
misc {
    vfr = true
    render_ahead_of_time = false
}
EOF
else
    # Bare-metal: detectar GPU y activar aceleración óptima
    GPU_VENDOR=""
    if command -v lspci &>/dev/null; then
        GPU_VENDOR=$(lspci 2>/dev/null | grep -iE "VGA|3D|Display" | head -1)
    fi

    if echo "$GPU_VENDOR" | grep -qi "Intel"; then
        cat > "$VM_CONF" << 'EOF'
# AUTO-GENERADO — bare-metal Intel: aceleración GPU activada
env = LIBVA_DRIVER_NAME,iHD
env = VDPAU_DRIVER,va_gl
env = WLR_DRM_NO_ATOMIC,0
EOF
    elif echo "$GPU_VENDOR" | grep -qi "AMD\|Radeon\|AMDGPU"; then
        cat > "$VM_CONF" << 'EOF'
# AUTO-GENERADO — bare-metal AMD: aceleración GPU activada
env = LIBVA_DRIVER_NAME,radeonsi
env = VDPAU_DRIVER,radeonsi
env = WLR_DRM_NO_ATOMIC,0
EOF
    elif echo "$GPU_VENDOR" | grep -qi "NVIDIA\|GeForce"; then
        cat > "$VM_CONF" << 'EOF'
# AUTO-GENERADO — bare-metal NVIDIA: modo offload activado
env = WLR_DRM_NO_ATOMIC,1
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = GBM_BACKEND,nvidia-drm
EOF
    else
        echo "# bare-metal — GPU no identificada, sin overrides" > "$VM_CONF"
    fi
fi

# Boots normales: si ya fue configurado antes, salir silenciosamente
if [[ -f "$STATE_FILE" && "$FORCE_GUI" == false ]]; then
    exit 0
fi

# Necesita Hyprland corriendo para usar hyprctl
command -v hyprctl &>/dev/null || exit 0

MONITOR_COUNT=$(hyprctl monitors -j 2>/dev/null \
    | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "1")

# Monitor único: config mínima, marcar como configurado
if [[ "$MONITOR_COUNT" -eq 1 ]]; then
    if [[ ! -f "$MONITORS_CONF" ]]; then
        echo "monitor=,preferred,auto,1" > "$MONITORS_CONF"
    fi
    touch "$STATE_FILE"
    exit 0
fi

# Múltiples monitores: primera vez o --force-gui
# Generar config base con todos los monitores en fila
python3 - << 'PYEOF'
import subprocess, json, os

try:
    monitors = json.loads(subprocess.check_output(["hyprctl", "monitors", "-j"]).decode())
except Exception:
    raise SystemExit(0)

lines = ["# monitors.conf — BLACK-ICE ARCH (auto-generado)"]
offset_x = 0
for i, m in enumerate(monitors):
    name = m.get("name", f"monitor{i}")
    w    = m.get("width", 1920)
    h    = m.get("height", 1080)
    hz   = m.get("refreshRate", 60)
    scale = m.get("scale", 1.0)
    lines.append(f"monitor={name},{w}x{h}@{hz:.0f},{offset_x}x0,{scale:.1f}")
    offset_x += w

conf = os.path.expanduser("~/.config/hypr/monitors.conf")
with open(conf, "w") as f:
    f.write("\n".join(lines) + "\n")
PYEOF

touch "$STATE_FILE"

# Abrir nwg-displays para ajuste fino (solo en primera vez / --force-gui)
if command -v nwg-displays &>/dev/null; then
    sleep 2
    notify-send "BLACK-ICE ARCH" \
        "Se detectaron $MONITOR_COUNT monitores. Abre nwg-displays para ajustar disposición." \
        --icon=display 2>/dev/null || true
    nwg-displays &
else
    notify-send "BLACK-ICE ARCH" \
        "$MONITOR_COUNT monitores detectados. Config base generada en monitors.conf" \
        --icon=display 2>/dev/null || true
fi
