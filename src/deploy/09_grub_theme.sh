#!/bin/bash
# src/deploy/09_grub_theme.sh
# Instala tema Cyberpunk Arcade para GRUB2
# Repo: https://github.com/Ricardo-Simoes/cyberpunk_arcade

banner "MÓDULO 9" "GRUB2 Theme — Cyberpunk Arcade"
cd "$USER_HOME" || exit 1

GRUB_THEMES_DIR="/boot/grub/themes"
THEME_DEST="$GRUB_THEMES_DIR/cyberpunk_arcade"
BUNDLED_THEME="$SCRIPT_DIR/assets/themes/grub/cyberpunk_arcade"
REPO_URL="https://github.com/Ricardo-Simoes/cyberpunk_arcade"
TMP_REPO="/tmp/cyberpunk_arcade"
GRUB_DEFAULT="/etc/default/grub"

# --- Prerequisitos ---
log_info "Verificando dependencias para GRUB theme..."
if ! command -v grub-mkconfig &>/dev/null; then
    log_error "grub-mkconfig no encontrado. ¿GRUB está instalado?"
    log_warn "Saltando instalación de tema GRUB."
    return 0
fi

# --- Obtener fuente del tema ---
# Primero usar assets bundleados en el repo (offline, garantizado).
# Fallback: clonar desde GitHub si no están presentes.
THEME_SOURCE=""

if [[ -f "$BUNDLED_THEME/theme.txt" ]]; then
    log_info "Usando tema bundleado en el repo (offline)..."
    THEME_SOURCE="$BUNDLED_THEME"
else
    log_info "Assets bundleados no encontrados — clonando desde GitHub..."
    if [[ -d "$TMP_REPO/.git" ]]; then
        git -C "$TMP_REPO" pull --depth=1 2>/dev/null || true
    else
        rm -rf "$TMP_REPO"
        if ! retry_command git clone --depth=1 "$REPO_URL" "$TMP_REPO"; then
            log_error "No se pudo clonar el repositorio. Verificar conexión."
            return 0
        fi
    fi
    if [[ ! -f "$TMP_REPO/theme.txt" ]]; then
        log_error "theme.txt no encontrado en el repositorio clonado."
        return 0
    fi
    THEME_SOURCE="$TMP_REPO"
fi

# --- Instalar Tema ---
log_info "Instalando tema en $THEME_DEST..."
sudo mkdir -p "$GRUB_THEMES_DIR"

if [[ -d "$THEME_DEST" ]]; then
    log_info "Eliminando tema previo..."
    sudo rm -rf "$THEME_DEST"
fi

sudo cp -r "$THEME_SOURCE" "$THEME_DEST"
sudo chmod -R 755 "$THEME_DEST"
sudo find "$THEME_DEST" -type f -exec chmod 644 {} \;
# Limpiar artefactos innecesarios si vinieron de git clone
sudo rm -rf "$THEME_DEST/.git" "$THEME_DEST/screenshots" "$THEME_DEST/media" \
            "$THEME_DEST/LICENSE" "$THEME_DEST/README.md"

if [[ ! -f "$THEME_DEST/theme.txt" ]]; then
    log_error "theme.txt no encontrado en $THEME_DEST — instalación fallida."
    return 0
fi

[[ -n "$TMP_REPO" && -d "$TMP_REPO" ]] && rm -rf "$TMP_REPO"
log_success "Tema Cyberpunk Arcade copiado a $THEME_DEST"

# --- Configurar /etc/default/grub ---
log_info "Configurando GRUB_THEME en $GRUB_DEFAULT..."

if grep -q "^GRUB_THEME=" "$GRUB_DEFAULT" 2>/dev/null; then
    sudo sed -i "s|^GRUB_THEME=.*|GRUB_THEME=\"$THEME_DEST/theme.txt\"|" "$GRUB_DEFAULT"
elif grep -q "^#GRUB_THEME=" "$GRUB_DEFAULT" 2>/dev/null; then
    sudo sed -i "s|^#GRUB_THEME=.*|GRUB_THEME=\"$THEME_DEST/theme.txt\"|" "$GRUB_DEFAULT"
else
    echo "GRUB_THEME=\"$THEME_DEST/theme.txt\"" | sudo tee -a "$GRUB_DEFAULT" > /dev/null
fi

# Resolución en cascada: 1080p → 768p → auto
# El installer no puede detectar la resolución del hardware en chroot,
# GRUB intentará cada modo en orden y usará el primero que soporte la GPU.
if grep -q "^GRUB_GFXMODE=" "$GRUB_DEFAULT" 2>/dev/null; then
    sudo sed -i 's|^GRUB_GFXMODE=.*|GRUB_GFXMODE=1920x1080x32,1366x768x32,auto|' "$GRUB_DEFAULT"
else
    echo 'GRUB_GFXMODE=1920x1080x32,1366x768x32,auto' | sudo tee -a "$GRUB_DEFAULT" > /dev/null
fi
log_info "GRUB_GFXMODE=1920x1080x32,1366x768x32,auto configurado"

# El tema requiere gfxterm — forzar siempre
if grep -q "^GRUB_TERMINAL_OUTPUT=" "$GRUB_DEFAULT" 2>/dev/null; then
    sudo sed -i 's|^GRUB_TERMINAL_OUTPUT=.*|GRUB_TERMINAL_OUTPUT="gfxterm"|' "$GRUB_DEFAULT"
elif grep -q "^#GRUB_TERMINAL_OUTPUT=" "$GRUB_DEFAULT" 2>/dev/null; then
    sudo sed -i 's|^#GRUB_TERMINAL_OUTPUT=.*|GRUB_TERMINAL_OUTPUT="gfxterm"|' "$GRUB_DEFAULT"
else
    echo 'GRUB_TERMINAL_OUTPUT="gfxterm"' | sudo tee -a "$GRUB_DEFAULT" > /dev/null
fi
log_info "GRUB_TERMINAL_OUTPUT=gfxterm configurado"

# --- Regenerar grub.cfg ---
log_info "Regenerando grub.cfg con el nuevo tema..."
if sudo grub-mkconfig -o /boot/grub/grub.cfg; then
    log_success "grub.cfg regenerado correctamente con tema Cyberpunk Arcade"
else
    log_error "grub-mkconfig falló. Verificar /boot/grub/ y /etc/default/grub."
    log_warn "El sistema arrancará normalmente pero sin el tema visual."
fi

rm -rf "$TMP_REPO"

success "Tema GRUB Cyberpunk Arcade instalado correctamente"
