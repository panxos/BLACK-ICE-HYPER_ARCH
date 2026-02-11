#!/bin/bash
# deploy-modules/04_theme_setup.sh
# Aplica tema cyberpunk y wallpaper inicial

banner "MÓDULO 5" "Tema y Personalización"

log_info "Configurando tema cyberpunk..."

# --- Inicializar swww (wallpaper daemon) ---
log_info "Iniciando swww daemon..."
swww-daemon &
sleep 2

# --- Establecer wallpaper inicial ---
PICTURES_DIR=$(sudo -u $CURRENT_USER xdg-user-dir PICTURES 2>/dev/null || echo "$USER_HOME/Pictures")
FIRST_WALLPAPER="$PICTURES_DIR/wallpapers/black_ice_wallpaper_01.png"

if [ -f "$FIRST_WALLPAPER" ]; then
    swww img "$FIRST_WALLPAPER" --transition-type grow
    echo "0" > "$USER_HOME/.config/hypr/.current_wallpaper"
    log_info "Wallpaper inicial establecido en: $FIRST_WALLPAPER"
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

