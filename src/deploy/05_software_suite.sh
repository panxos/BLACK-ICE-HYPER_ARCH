#!/usr/bin/env bash

banner "SOFTWARE OPCIONAL" "Plan de aplicaciones"
mapfile -t SELECTED_APPS < <(python3 "$SCRIPT_DIR/scripts/select-apps.py" --load "$APP_PLAN" --packages)
FAILED_APPS=()
INSTALLED_APPS=()
for app in "${SELECTED_APPS[@]}"; do
    [[ -n "$app" ]] || continue
    [[ "$app" == claude-code-cli ]] && continue
    if [[ "$app" =~ ^(qemu-full|libvirt|virt-manager|dnsmasq)$ ]] && systemd-detect-virt --quiet; then
        log_warn "Se omite $app dentro de una VM; instala herramientas de host en hardware real."
        continue
    fi
    if safe_install "$app"; then
        INSTALLED_APPS+=("$app")
    else
        FAILED_APPS+=("$app")
    fi
done

app_installed() {
    local candidate
    for candidate in "${INSTALLED_APPS[@]}"; do
        [[ "$candidate" == "$1" ]] && return 0
    done
    return 1
}

for pair in 'docker:docker' 'libvirt:libvirtd' 'mpd:mpd' 'mpd-mpris:mpd-mpris'; do
    IFS=: read -r app service <<< "$pair"
    app_installed "$app" || continue
    if [[ "$app" == mpd* ]]; then
        continue
    elif ! sudo systemctl enable --now "$service.service"; then
        FAILED_APPS+=("$app:servicio")
    fi
done
if app_installed libvirt; then
    sudo usermod -aG libvirt "$CURRENT_USER" || FAILED_APPS+=("libvirt:grupo")
fi
if app_installed docker; then
    log_warn "Docker usa sudo. No se agrega automáticamente al grupo docker, que otorga acceso equivalente a root."
fi
if app_installed wireshark-qt; then
    sudo usermod -aG wireshark "$CURRENT_USER" || FAILED_APPS+=("wireshark:grupo")
fi
if app_installed mpd; then
            # Config MPD del usuario
            MPD_CONF_DIR="$USER_HOME/.config/mpd"
            MPD_MUSIC_DIR="$USER_HOME/Music"
            mkdir -p "$MPD_CONF_DIR" "$MPD_MUSIC_DIR" "$MPD_CONF_DIR/playlists"

            if [ ! -f "$MPD_CONF_DIR/mpd.conf" ]; then
                cat > "$MPD_CONF_DIR/mpd.conf" << 'MPDEOF'
# MPD Configuration - BLACK-ICE ARCH
music_directory    "~/Music"
playlist_directory "~/.config/mpd/playlists"
db_file            "~/.config/mpd/mpd.db"
log_file           "~/.config/mpd/mpd.log"
pid_file           "~/.config/mpd/mpd.pid"
state_file         "~/.config/mpd/mpdstate"

bind_to_address    "127.0.0.1"
port               "6600"

audio_output {
    type    "pipewire"
    name    "PipeWire Output"
}

audio_output {
    type    "pulse"
    name    "PulseAudio Output"
}

replaygain          "auto"
MPDEOF
                chown "$CURRENT_USER:$CURRENT_USER" "$MPD_CONF_DIR/mpd.conf"
                log_success "MPD configurado en $MPD_CONF_DIR/mpd.conf"
            fi

    systemctl --user enable --now mpd.service || FAILED_APPS+=("mpd:servicio")
fi
if app_installed mpd-mpris; then
    systemctl --user enable --now mpd-mpris.service || FAILED_APPS+=("mpd-mpris:servicio")
fi

if app_installed megasync-bin; then
            # Wrapper para MEGAsync — fuerza systray visible en Hyprland/Wayland
            mkdir -p "$USER_HOME/.local/bin"
            cat > "$USER_HOME/.local/bin/megasync-hypr" << 'MEGAEOF'
#!/bin/bash
# megasync-hypr — wrapper Hyprland/Wayland para systray
export XDG_CURRENT_DESKTOP=Unity
export QT_QPA_PLATFORM=xcb
export GDK_BACKEND=x11
exec /usr/bin/megasync "$@"
MEGAEOF
            chmod +x "$USER_HOME/.local/bin/megasync-hypr"
            chown "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.local/bin/megasync-hypr"

            # .desktop override para abrir con wrapper
            mkdir -p "$USER_HOME/.local/share/applications"
            cat > "$USER_HOME/.local/share/applications/megasync.desktop" << MEGADEOF
[Desktop Entry]
Name=MEGAsync
Comment=Easy automated syncing with MEGA (Hyprland fix)
Exec=$USER_HOME/.local/bin/megasync-hypr %U
Icon=mega
Type=Application
Categories=Network;FileTransfer;
StartupNotify=false
MEGADEOF
            chown "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.local/share/applications/megasync.desktop"
            log_success "MEGAsync instalado con fix Hyprland (wrapper megasync-hypr)"
fi

state="${XDG_STATE_HOME:-$HOME/.local/state}/black-ice"
mkdir -p "$state"
printf '%s\n' "${FAILED_APPS[@]}" > "$state/apps-failed.txt"
if (( ${#FAILED_APPS[@]} )); then
    log_warn "Aplicaciones con fallos: ${FAILED_APPS[*]}. Revisa $state/apps-failed.txt."
else
    log_success "Plan de software opcional completado (${#INSTALLED_APPS[@]} aplicaciones)."
fi
