#!/bin/bash
# src/deploy/09_grub_theme.sh
# Instala tema DedSec GRUB2 con selector de variante
# Repo: https://github.com/VandalByte/dedsec-grub2-theme (GPL-3.0)

banner "MÓDULO 9" "GRUB2 Theme — DedSec"
cd "$USER_HOME" || exit 1

GRUB_THEMES_DIR="/boot/grub/themes"
THEME_DEST="$GRUB_THEMES_DIR/dedsec"
REPO_URL="https://github.com/VandalByte/dedsec-grub2-theme"
TMP_REPO="/tmp/dedsec-grub2-theme"
GRUB_DEFAULT="/etc/default/grub"

# --- Prerequisitos ---
log_info "Verificando dependencias para GRUB theme..."
if ! command -v grub-mkconfig &>/dev/null; then
    log_error "grub-mkconfig no encontrado. ¿GRUB está instalado?"
    log_warn "Saltando instalación de tema GRUB."
    return 0
fi

# --- Clonar / Actualizar Repositorio ---
if [ -d "$TMP_REPO/.git" ]; then
    log_info "Repositorio DedSec ya descargado — actualizando..."
    git -C "$TMP_REPO" pull --depth=1 2>/dev/null || true
else
    log_info "Clonando DedSec GRUB2 Theme..."
    rm -rf "$TMP_REPO"
    if ! retry_command git clone --depth=1 "$REPO_URL" "$TMP_REPO"; then
        log_error "No se pudo clonar el repositorio DedSec. Verificar conexión."
        return 0
    fi
fi

# --- Detectar variantes disponibles ---
# Las variantes son subdirectorios que contienen theme.txt
mapfile -t VARIANT_DIRS < <(find "$TMP_REPO" -maxdepth 4 -name "theme.txt" \
    -exec dirname {} \; | sort)

if [ ${#VARIANT_DIRS[@]} -eq 0 ]; then
    log_error "No se encontraron variantes de tema en el repositorio clonado."
    return 0
fi

log_info "Variantes disponibles: ${#VARIANT_DIRS[@]}"

# --- Selector de Variante ---
SELECTED_VARIANT=""

if [ "${NON_INTERACTIVE:-false}" == "true" ]; then
    # Modo automático: usar la primera variante disponible
    SELECTED_VARIANT="${VARIANT_DIRS[0]}"
    log_info "Modo no-interactivo: usando variante '$(basename "$SELECTED_VARIANT")'"

elif command -v whiptail &>/dev/null; then
    # Construir lista para whiptail (radiolist)
    RADIO_ARGS=()
    FIRST=true
    for dir in "${VARIANT_DIRS[@]}"; do
        name=$(basename "$dir")
        if $FIRST; then
            RADIO_ARGS+=("$name" "DedSec - $name" "ON")
            FIRST=false
        else
            RADIO_ARGS+=("$name" "DedSec - $name" "OFF")
        fi
    done

    CHOICE=$(whiptail --title "BLACK-ICE — GRUB THEME" \
        --radiolist "Selecciona la variante del tema DedSec para GRUB:" \
        20 60 10 \
        "${RADIO_ARGS[@]}" \
        3>&1 1>&2 2>&3 < /dev/tty) || true

    # Mapear nombre elegido a path completo
    if [ -n "$CHOICE" ]; then
        CHOICE_CLEAN="${CHOICE//\"/}"
        for dir in "${VARIANT_DIRS[@]}"; do
            if [ "$(basename "$dir")" == "$CHOICE_CLEAN" ]; then
                SELECTED_VARIANT="$dir"
                break
            fi
        done
    fi

    if [ -z "$SELECTED_VARIANT" ]; then
        log_warn "No se seleccionó ninguna variante. Usando la primera disponible."
        SELECTED_VARIANT="${VARIANT_DIRS[0]}"
    fi
else
    log_warn "whiptail no disponible. Usando primera variante: $(basename "${VARIANT_DIRS[0]}")"
    SELECTED_VARIANT="${VARIANT_DIRS[0]}"
fi

VARIANT_NAME=$(basename "$SELECTED_VARIANT")
log_info "Variante seleccionada: $VARIANT_NAME"

# --- Instalar Tema ---
log_info "Instalando tema en $THEME_DEST..."
sudo mkdir -p "$GRUB_THEMES_DIR"

# Limpiar instalación previa si existe
if [ -d "$THEME_DEST" ]; then
    log_info "Eliminando tema DedSec previo..."
    sudo rm -rf "$THEME_DEST"
fi

sudo cp -r "$SELECTED_VARIANT" "$THEME_DEST"
sudo chmod -R 755 "$THEME_DEST"
sudo find "$THEME_DEST" -type f -exec chmod 644 {} \;

# Verificar que theme.txt quedó
if [ ! -f "$THEME_DEST/theme.txt" ]; then
    log_error "theme.txt no encontrado en $THEME_DEST — instalación fallida."
    return 0
fi

log_success "Tema DedSec ($VARIANT_NAME) copiado a $THEME_DEST"

# --- Configurar /etc/default/grub ---
log_info "Configurando GRUB_THEME en $GRUB_DEFAULT..."

if grep -q "^GRUB_THEME=" "$GRUB_DEFAULT" 2>/dev/null; then
    sudo sed -i "s|^GRUB_THEME=.*|GRUB_THEME=\"$THEME_DEST/theme.txt\"|" "$GRUB_DEFAULT"
elif grep -q "^#GRUB_THEME=" "$GRUB_DEFAULT" 2>/dev/null; then
    sudo sed -i "s|^#GRUB_THEME=.*|GRUB_THEME=\"$THEME_DEST/theme.txt\"|" "$GRUB_DEFAULT"
else
    echo "GRUB_THEME=\"$THEME_DEST/theme.txt\"" | sudo tee -a "$GRUB_DEFAULT" > /dev/null
fi

# Resolución: si no está configurada, poner auto para máxima compatibilidad
if ! grep -q "^GRUB_GFXMODE=" "$GRUB_DEFAULT" 2>/dev/null; then
    echo 'GRUB_GFXMODE=1920x1080,auto' | sudo tee -a "$GRUB_DEFAULT" > /dev/null
    log_info "GRUB_GFXMODE=1920x1080,auto configurado"
fi

# El tema requiere gfxterm para renderizar correctamente
if ! grep -q "^GRUB_TERMINAL_OUTPUT=" "$GRUB_DEFAULT" 2>/dev/null; then
    echo 'GRUB_TERMINAL_OUTPUT="gfxterm"' | sudo tee -a "$GRUB_DEFAULT" > /dev/null
fi

# --- Regenerar grub.cfg ---
log_info "Regenerando grub.cfg con el nuevo tema..."
if sudo grub-mkconfig -o /boot/grub/grub.cfg; then
    log_success "grub.cfg regenerado correctamente con tema DedSec ($VARIANT_NAME)"
else
    log_error "grub-mkconfig falló. Verificar /boot/grub/ y /etc/default/grub."
    log_warn "El sistema arrancará normalmente pero sin el tema visual."
fi

# Limpiar repo temporal
rm -rf "$TMP_REPO"

success "Tema GRUB DedSec ($VARIANT_NAME) instalado correctamente"
