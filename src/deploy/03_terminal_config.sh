#!/bin/bash
# deploy-modules/03_terminal_config.sh
# Configura Zsh con powerlevel10k y enlaces simbólicos

banner "MÓDULO 4" "Configuración de Terminal (Zsh)"

# --- Instalar Zsh y plugins ---
log_info "Instalando Zsh, powerlevel10k, plugins, fastfetch y chafa..."
sudo -n pacman -S --needed --noconfirm zsh zsh-syntax-highlighting zsh-autosuggestions fastfetch chafa
yay -S --needed --noconfirm zsh-theme-powerlevel10k-git

# Instalar zsh-sudo manualmente (no oficial en arch repos aveces)
sudo -n mkdir -p /usr/share/zsh/plugins/zsh-sudo
sudo -n curl -L https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/sudo/sudo.plugin.zsh -o /usr/share/zsh/plugins/zsh-sudo/sudo.plugin.zsh

# --- Copiar archivos de configuración ---
log_info "Copiando configuración de Zsh..."

if [ -f "$DOTFILES_DIR/zsh/.zshrc" ]; then
    cp "$DOTFILES_DIR/zsh/.zshrc" "$USER_HOME/.zshrc"
    log_info ".zshrc copiado"
fi

if [ -f "$DOTFILES_DIR/zsh/.p10k.zsh" ]; then
    cp "$DOTFILES_DIR/zsh/.p10k.zsh" "$USER_HOME/.p10k.zsh"
    log_info ".p10k.zsh copiado"
fi

if [ -d "$DOTFILES_DIR/fastfetch" ]; then
    mkdir -p "$USER_HOME/.config/fastfetch"
    cp -r "$DOTFILES_DIR/fastfetch/"* "$USER_HOME/.config/fastfetch/"
    chmod +x "$USER_HOME/.config/fastfetch/random_logo.sh"
    log_info "Configuración de Fastfetch copiada"
fi

# Ajustar permisos
chown $CURRENT_USER:$CURRENT_USER "$USER_HOME/.zshrc"
chown $CURRENT_USER:$CURRENT_USER "$USER_HOME/.p10k.zsh"

# --- Configurar Zsh para root (con symlinks y configs) ---
log_info "Configurando Zsh para root..."

# Symlink de .zshrc
if [ ! -L "/root/.zshrc" ]; then
    sudo -n ln -sf "$USER_HOME/.zshrc" "/root/.zshrc"
    log_info "Symlink /root/.zshrc → $USER_HOME/.zshrc"
fi

# Copiar Fastfetch a root (Source of Truth: DOTFILES_DIR)
# Esto corrige el error "no such file or directory: /root/.config/fastfetch/random_logo.sh"
if [ -d "$DOTFILES_DIR/fastfetch" ]; then
    sudo -n mkdir -p /root/.config
    # Eliminar versión anterior si existe para evitar conflictos
    sudo -n rm -rf /root/.config/fastfetch
    sudo -n cp -r "$DOTFILES_DIR/fastfetch" /root/.config/
    sudo -n chmod +x /root/.config/fastfetch/random_logo.sh
    log_info "Fastfetch configurado para root (Copiado desde $DOTFILES_DIR)"
else
    log_warn "No se encontró $DOTFILES_DIR/fastfetch. El prompt de root podría fallar."
fi

# Copiar .p10k.zsh a root y modificar para prompt FIRE (Yellow)
# Copiar .p10k.zsh a root y modificar para prompt FIRE (Yellow)
if [ -f "$DOTFILES_DIR/zsh/.p10k.zsh" ]; then
    sudo -n cp "$DOTFILES_DIR/zsh/.p10k.zsh" "/root/.p10k.zsh"
    
    # Customize Root Prompt: Yellow Fire Icon
    # Appending to the end of the file is safer as it overrides previous definitions
    # and avoids complex sed regex matching issues with brace expansion.
    
    cat >> "/root/.p10k.zsh" << 'EOF'
    
# --- BLACK-ICE ROOT CUSTOMIZATION (FIRE) ---
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_CONTENT_EXPANSION=''
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_CONTENT_EXPANSION=''
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=220
# Ensure directory anchor logic uses the same icon if demanded context
typeset -g POWERLEVEL9K_HOME_ICON=''
typeset -g POWERLEVEL9K_HOME_SUB_ICON=''
EOF
    
    log_info "Root .p10k.zsh configurado con Fire Icon (Yellow - Appended Override)"
fi

# Customize User Prompt: Tux Icon (\uf17c) for Home
# Customize User Prompt: Tux Icon (\uf17c) for user anchor
if [ -f "$USER_HOME/.p10k.zsh" ]; then
    # Append overrides for User
    cat >> "$USER_HOME/.p10k.zsh" << 'EOF'
    
# --- BLACK-ICE USER CUSTOMIZATION (TUX) ---
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_CONTENT_EXPANSION=''
typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=true
typeset -g POWERLEVEL9K_HOME_ICON=''
EOF
    
    log_info "User .p10k.zsh configurado con Linux Tux Icon (Appended Override)"
fi

# --- Cambiar shell por defecto ---
log_info "Cambiando shell a zsh..."

# Usuario normal
if [ "$SHELL" != "/usr/bin/zsh" ]; then
    sudo -n chsh -s /usr/bin/zsh $CURRENT_USER
fi

# Root
sudo -n chsh -s /usr/bin/zsh root

success "Zsh configurado para $CURRENT_USER y root"
