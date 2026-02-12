#!/bin/bash
# deploy-modules/03_terminal_config.sh
# Configura Zsh con powerlevel10k (git clone oficial) y dotfiles personalizados
# Author: Francisco Aravena (P4nX0Z)
# Modified: 2026-02-11 — Fix: Instalar p10k vía git clone oficial

banner "MÓDULO 4" "Configuración de Terminal (Zsh)"

# --- Instalar Zsh y plugins base ---
log_info "Instalando Zsh, plugins, fastfetch y chafa..."
safe_install zsh
safe_install zsh-syntax-highlighting
safe_install zsh-autosuggestions
safe_install fastfetch
safe_install chafa
safe_install ttf-jetbrains-mono-nerd

# Instalar zsh-sudo manualmente (no siempre disponible en repos oficiales)
cd "$USER_HOME" || cd /tmp
sudo -n mkdir -p /usr/share/zsh/plugins/zsh-sudo
sudo -n curl -L https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/sudo/sudo.plugin.zsh \
    -o /usr/share/zsh/plugins/zsh-sudo/sudo.plugin.zsh

# --- Instalar Powerlevel10k vía git clone oficial ---
# Ref: https://github.com/romkatv/powerlevel10k
log_info "Instalando Powerlevel10k (método git clone oficial)..."

# 1. Instalar para el usuario actual
cd "$USER_HOME" || { log_error "No se pudo acceder a $USER_HOME"; exit 1; }
if [ -d "$USER_HOME/powerlevel10k" ]; then
    log_info "Powerlevel10k ya existe en $USER_HOME/powerlevel10k, actualizando..."
    git -C "$USER_HOME/powerlevel10k" pull --depth=1 2>/dev/null || true
else
    log_info "Clonando Powerlevel10k para $CURRENT_USER..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$USER_HOME/powerlevel10k"
fi
chown -R "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/powerlevel10k"

# Agregar source a .zshrc del usuario (si no existe ya)
if ! grep -q "powerlevel10k.zsh-theme" "$USER_HOME/.zshrc" 2>/dev/null; then
    echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >> "$USER_HOME/.zshrc"
    log_info "Source de p10k agregado a $USER_HOME/.zshrc"
fi

# 2. Instalar para root
if [ -d "/root/powerlevel10k" ]; then
    log_info "Powerlevel10k ya existe en /root/powerlevel10k, actualizando..."
    sudo git -C /root/powerlevel10k pull --depth=1 2>/dev/null || true
else
    log_info "Clonando Powerlevel10k para root..."
    sudo git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /root/powerlevel10k
fi

# Agregar source a .zshrc de root (si no existe ya)
if ! sudo grep -q "powerlevel10k.zsh-theme" /root/.zshrc 2>/dev/null; then
    echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' | sudo tee -a /root/.zshrc > /dev/null
    log_info "Source de p10k agregado a /root/.zshrc"
fi

success "Powerlevel10k instalado para $CURRENT_USER y root"

# --- Copiar archivos de configuración de Zsh ---
# IMPORTANTE: Copiar dotfiles DESPUÉS de instalar p10k para sobreescribir config por defecto
log_info "Copiando dotfiles de Zsh (sobreescriben config por defecto de p10k)..."

if [ -f "$DOTFILES_DIR/zsh/.zshrc" ]; then
    cp "$DOTFILES_DIR/zsh/.zshrc" "$USER_HOME/.zshrc"
    # Re-agregar source de p10k si el dotfile no lo incluye
    if ! grep -q "powerlevel10k.zsh-theme" "$USER_HOME/.zshrc" 2>/dev/null; then
        echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >> "$USER_HOME/.zshrc"
    fi
    chown "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.zshrc"
    log_info ".zshrc del proyecto copiado"
fi

if [ -f "$DOTFILES_DIR/zsh/.p10k.zsh" ]; then
    # Copiar para usuario
    cp "$DOTFILES_DIR/zsh/.p10k.zsh" "$USER_HOME/.p10k.zsh"
    chown "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.p10k.zsh"
    log_info ".p10k.zsh copiado para $CURRENT_USER (sobreescribe default)"

    # Copiar para root
    sudo cp "$DOTFILES_DIR/zsh/.p10k.zsh" "/root/.p10k.zsh"
    log_info ".p10k.zsh copiado para root (sobreescribe default)"
fi

# --- Copiar configuración de Fastfetch ---
if [ -d "$DOTFILES_DIR/fastfetch" ]; then
    mkdir -p "$USER_HOME/.config/fastfetch"
    cp -r "$DOTFILES_DIR/fastfetch/"* "$USER_HOME/.config/fastfetch/"
    chmod +x "$USER_HOME/.config/fastfetch/random_logo.sh" 2>/dev/null || true
    chown -R "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.config/fastfetch"
    log_info "Configuración de Fastfetch copiada"
fi

# --- Configurar Zsh para root (con configs y fastfetch) ---
log_info "Configurando Zsh para root..."

# Copiar .zshrc a root (copia independiente, no symlink, para evitar conflictos de permisos)
if [ -f "$DOTFILES_DIR/zsh/.zshrc" ]; then
    sudo cp "$DOTFILES_DIR/zsh/.zshrc" "/root/.zshrc"
    # Asegurar que source de p10k está presente
    if ! sudo grep -q "powerlevel10k.zsh-theme" /root/.zshrc 2>/dev/null; then
        echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' | sudo tee -a /root/.zshrc > /dev/null
    fi
fi

# Copiar Fastfetch a root
if [ -d "$DOTFILES_DIR/fastfetch" ]; then
    sudo -n mkdir -p /root/.config
    sudo -n rm -rf /root/.config/fastfetch
    sudo -n cp -r "$DOTFILES_DIR/fastfetch" /root/.config/
    sudo -n chmod +x /root/.config/fastfetch/random_logo.sh 2>/dev/null || true
    log_info "Fastfetch configurado para root"
fi

# --- Customizar prompt de root: Fire Icon (Yellow) ---
if [ -f "/root/.p10k.zsh" ]; then
    sudo tee -a "/root/.p10k.zsh" > /dev/null << 'EOF'

# --- BLACK-ICE ROOT CUSTOMIZATION (FIRE) ---
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_CONTENT_EXPANSION=''
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_CONTENT_EXPANSION=''
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=220
typeset -g POWERLEVEL9K_HOME_ICON=''
typeset -g POWERLEVEL9K_HOME_SUB_ICON=''
EOF
    log_info "Root .p10k.zsh configurado con Fire Icon (Yellow)"
fi

# --- Customizar prompt de usuario: Tux Icon ---
if [ -f "$USER_HOME/.p10k.zsh" ]; then
    cat >> "$USER_HOME/.p10k.zsh" << 'EOF'

# --- BLACK-ICE USER CUSTOMIZATION (TUX) ---
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_CONTENT_EXPANSION=''
typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=true
typeset -g POWERLEVEL9K_HOME_ICON=''
EOF
    chown "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.p10k.zsh"
    log_info "User .p10k.zsh configurado con Linux Tux Icon"
fi

# --- Cambiar shell por defecto a Zsh ---
log_info "Cambiando shell por defecto a Zsh..."

# Verificar que zsh está instalado
if ! command -v zsh &>/dev/null; then
    log_error "Zsh no está instalado. No se puede cambiar el shell."
else
    # Usuario normal
    CURRENT_SHELL=$(getent passwd "$CURRENT_USER" | cut -d: -f7)
    if [ "$CURRENT_SHELL" != "/usr/bin/zsh" ]; then
        sudo -n chsh -s /usr/bin/zsh "$CURRENT_USER"
        log_info "Shell cambiado a Zsh para $CURRENT_USER"
    else
        log_info "Zsh ya es el shell por defecto de $CURRENT_USER"
    fi

    # Root
    ROOT_SHELL=$(getent passwd root | cut -d: -f7)
    if [ "$ROOT_SHELL" != "/usr/bin/zsh" ]; then
        sudo -n chsh -s /usr/bin/zsh root
        log_info "Shell cambiado a Zsh para root"
    else
        log_info "Zsh ya es el shell por defecto de root"
    fi
fi

success "Zsh + Powerlevel10k configurado para $CURRENT_USER y root"
