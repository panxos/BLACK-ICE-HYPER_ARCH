#!/bin/bash
# deploy-modules/04_theme_setup.sh
# Aplica tema cyberpunk y wallpaper inicial

banner "MÓDULO 5" "Tema y Personalización"
cd "$USER_HOME" || exit 1

log_info "Configurando tema cyberpunk..."

# --- Wallpapers: crear directorio, generar default, descargar pack opcional ---
PICTURES_DIR=$(sudo -u "$CURRENT_USER" xdg-user-dir PICTURES 2>/dev/null || echo "$USER_HOME/Pictures")
WALL_DIR="$PICTURES_DIR/wallpapers"
WALL_DEFAULT="$WALL_DIR/black-ice-default.png"

log_info "Preparando directorio de wallpapers..."
mkdir -p "$WALL_DIR/gh0stzk"
chown -R "$CURRENT_USER:$CURRENT_USER" "$WALL_DIR"

# 1. Generar wallpaper BLACK-ICE con imagemagick (siempre disponible, no depende de red)
if command -v convert &>/dev/null && [ ! -f "$WALL_DEFAULT" ]; then
    log_info "Generando wallpaper BLACK-ICE default con imagemagick..."
    convert -size 1920x1080 \
        gradient:"#010810-#040f20" \
        -fill "#00f3ff" -stroke "#00f3ff" -strokewidth 1 \
        -draw "line 0,2 1920,2" \
        -draw "line 0,1077 1920,1077" \
        -fill "#051525" \
        -draw "rectangle 580,380 1340,700" \
        -fill "#00f3ff" \
        -font "DejaVu-Sans-Bold" -pointsize 110 \
        -gravity Center -annotate +0-40 "BLACK-ICE" \
        -font "DejaVu-Sans" -pointsize 28 \
        -fill "#bc00ff" \
        -gravity Center -annotate +0+65 "ARCH LINUX  //  HYPRLAND  //  PENTESTING" \
        -fill "#00f3ff" -pointsize 14 \
        -gravity South -annotate +0+18 "[ ENCRYPTION ACTIVE ]  [ ALL SESSIONS MONITORED ]  [ UNAUTHORIZED ACCESS PROHIBITED ]" \
        "$WALL_DEFAULT" 2>/dev/null && \
        chown "$CURRENT_USER:$CURRENT_USER" "$WALL_DEFAULT" && \
        log_success "Wallpaper default generado: $WALL_DEFAULT" || \
        log_warn "imagemagick: no se pudo generar wallpaper default"
fi

# 2. Intentar descargar pack gh0stzk (Emilia-TokyoNight) si hay internet
EMILIA_DIR="$WALL_DIR/gh0stzk/Emilia-TokyoNight"
if ping -c 1 -W 3 raw.githubusercontent.com &>/dev/null; then
    log_info "Internet disponible — descargando wallpapers gh0stzk (Emilia-TokyoNight)..."
    mkdir -p "$EMILIA_DIR"
    EMILIA_API="https://api.github.com/repos/gh0stzk/dotfiles/contents/config/bspwm/rices/emilia/walls"
    EMILIA_URLS=$(curl -sf "$EMILIA_API" 2>/dev/null | \
        grep '"download_url"' | \
        grep -E '\.jpg|\.png|\.webp' | \
        sed 's/.*"download_url": "\([^"]*\)".*/\1/' | \
        head -6)

    if [ -n "$EMILIA_URLS" ]; then
        DOWNLOADED=0
        while IFS= read -r url; do
            fname=$(basename "$url")
            if [ ! -f "$EMILIA_DIR/$fname" ]; then
                curl -sf --retry 2 -o "$EMILIA_DIR/$fname" "$url" 2>/dev/null && \
                    DOWNLOADED=$((DOWNLOADED + 1)) || true
            fi
        done <<< "$EMILIA_URLS"
        chown -R "$CURRENT_USER:$CURRENT_USER" "$EMILIA_DIR"
        log_success "Wallpapers gh0stzk descargados: $DOWNLOADED archivos en $EMILIA_DIR"

        # Usar primer wallpaper descargado como activo
        FIRST_ONLINE=$(ls "$EMILIA_DIR"/*.{jpg,png,webp} 2>/dev/null | head -1)
        [ -n "$FIRST_ONLINE" ] && WALL_DEFAULT="$FIRST_ONLINE"
    else
        log_warn "No se pudo obtener listado de wallpapers — usando default generado"
    fi
else
    log_warn "Sin internet — usando wallpaper generado localmente"
fi

# 3. Actualizar waypaper config con el wallpaper activo real
WAYPAPER_CONF="$USER_HOME/.config/waypaper/config.ini"
if [ -f "$WAYPAPER_CONF" ] && [ -f "$WALL_DEFAULT" ]; then
    WALL_DEFAULT_TILDE="${WALL_DEFAULT/$USER_HOME/\~}"
    sed -i "s|^wallpaper\s*=.*|wallpaper = $WALL_DEFAULT_TILDE|" "$WAYPAPER_CONF"
    sed -i "s|^folder\s*=.*|folder = ~/Pictures/wallpapers|" "$WAYPAPER_CONF"
    chown "$CURRENT_USER:$CURRENT_USER" "$WAYPAPER_CONF"
    log_success "waypaper config actualizada → $WALL_DEFAULT_TILDE"
fi

# 4. Activar wallpaper con awww
log_info "Iniciando awww daemon y aplicando wallpaper..."
if command -v awww &>/dev/null && [ -f "$WALL_DEFAULT" ]; then
    pkill awww-daemon 2>/dev/null || true
    sleep 1
    sudo -u "$CURRENT_USER" WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}" \
        awww-daemon &>/dev/null &
    sleep 2
    sudo -u "$CURRENT_USER" WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}" \
        awww img "$WALL_DEFAULT" --transition-type grow 2>/dev/null && \
        log_success "Wallpaper aplicado: $(basename "$WALL_DEFAULT")" || \
        log_warn "awww img falló — wallpaper se aplicará al primer login en Hyprland"
else
    log_warn "awww no disponible o wallpaper no generado — se aplica en primer login"
fi

# --- Crear archivo settarget vacío ---
touch "$USER_HOME/.settarget"
echo "No target set" > "$USER_HOME/.settarget"

# --- Verificar Temas GTK ---
log_info "Verificando instalación de temas GTK e Iconos..."
REQUIRED_THEME="Sweet-Dark"
REQUIRED_ICON="candy-icons"

if [ ! -d "/usr/share/themes/$REQUIRED_THEME" ] && [ ! -d "$USER_HOME/.themes/$REQUIRED_THEME" ]; then
    log_warn "Tema $REQUIRED_THEME no encontrado. Instalando..."
    safe_install sweet-theme-git || log_warn "No se pudo instalar el tema Sweet. Se usará un tema alternativo."
fi

if [ -n "$REQUIRED_ICON" ] && ! pacman -Q "$REQUIRED_ICON" &>/dev/null; then
    log_info "Instalando librería de iconos: $REQUIRED_ICON..."
    safe_install candy-icons-git || \
    safe_install candy-icons || \
    log_warn "No se pudo instalar los iconos. El sistema usará Papirus como respaldo."
fi

# NOTE: Kvantum linking is already handled in Module 01 (Advanced Detection)


# --- Configurar Qt5ct y Qt6ct ---
log_info "Configurando Qt themes (qt5ct y qt6ct)..."

# Copiar configuraciones Qt
mkdir -p "$USER_HOME/.config/qt5ct"
mkdir -p "$USER_HOME/.config/qt6ct"

if [ -f "$DOTFILES_DIR/qt5ct/qt5ct.conf" ]; then
    cp "$DOTFILES_DIR/qt5ct/qt5ct.conf" "$USER_HOME/.config/qt5ct/"
    log_success "Configuración qt5ct copiada"
else
    log_warn "No se encontró qt5ct.conf en dotfiles"
fi

if [ -f "$DOTFILES_DIR/qt6ct/qt6ct.conf" ]; then
    cp "$DOTFILES_DIR/qt6ct/qt6ct.conf" "$USER_HOME/.config/qt6ct/"
    log_success "Configuración qt6ct copiada"
else
    log_warn "No se encontró qt6ct.conf en dotfiles"
fi

success "Tema configurado"

