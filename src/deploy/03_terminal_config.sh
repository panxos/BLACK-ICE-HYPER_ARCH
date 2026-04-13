#!/bin/bash
# deploy-modules/03_terminal_config.sh
# Configura Zsh con powerlevel10k (git clone oficial) y dotfiles personalizados
# Author: Francisco Aravena (P4nX0Z)
# Modified: 2026-02-11 — Fix: Instalar p10k vía git clone oficial

banner "MÓDULO 4" "Configuración de Terminal (Zsh)"
# --- Configurar bin/ del usuario (Scripts Tácticos) ---
log_info "Configurando scripts tácticos (~/bin/ y ~/.config/bin/)..."
mkdir -p "$USER_HOME/bin"
cp -rf "$SCRIPT_DIR/dotfiles/bin/"* "$USER_HOME/bin/"
chmod +x "$USER_HOME/bin/"* 2>/dev/null || true
chown -R "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/bin"

# Waybar referencia ~/.config/bin/ → symlink a ~/bin para que ambas rutas funcionen
mkdir -p "$USER_HOME/.config"
if [ ! -e "$USER_HOME/.config/bin" ]; then
    ln -sf "$USER_HOME/bin" "$USER_HOME/.config/bin"
    log_success "~/.config/bin → symlink a ~/bin (Waybar scripts OK)"
elif [ -d "$USER_HOME/.config/bin" ] && [ ! -L "$USER_HOME/.config/bin" ]; then
    # Directorio real: copiar contenido y reemplazar con symlink
    cp -n "$USER_HOME/.config/bin/"* "$USER_HOME/bin/" 2>/dev/null || true
    rm -rf "$USER_HOME/.config/bin"
    ln -sf "$USER_HOME/bin" "$USER_HOME/.config/bin"
    log_success "~/.config/bin convertido a symlink → ~/bin"
fi

# --- Instalar Zsh y plugins base ---
log_info "Instalando Zsh, plugins, fastfetch y chafa..."
safe_install zsh
safe_install zsh-syntax-highlighting
safe_install zsh-autosuggestions
safe_install fastfetch
safe_install chafa
safe_install ttf-jetbrains-mono-nerd
safe_install fzf
safe_install bat        # Previews en fzf-tab

# --- fzf-tab (tab completion con preview visual) ---
log_info "Instalando fzf-tab..."
FZF_TAB_DIR="$USER_HOME/.local/share/fzf-tab"
if [ -d "$FZF_TAB_DIR" ]; then
    git -C "$FZF_TAB_DIR" pull --depth=1 2>/dev/null || true
    log_info "fzf-tab actualizado"
else
    git clone --depth=1 https://github.com/Aloxaf/fzf-tab.git "$FZF_TAB_DIR"
    log_success "fzf-tab instalado en $FZF_TAB_DIR"
fi
chown -R "$CURRENT_USER:$CURRENT_USER" "$FZF_TAB_DIR"

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
# El .zshrc usa ~/.powerlevel10k (con punto) — clonar con ese nombre
if [ -d "$USER_HOME/.powerlevel10k" ]; then
    log_info "Powerlevel10k ya existe, actualizando..."
    git -C "$USER_HOME/.powerlevel10k" pull --depth=1 2>/dev/null || true
else
    log_info "Clonando Powerlevel10k para $CURRENT_USER..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$USER_HOME/.powerlevel10k"
fi
chown -R "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.powerlevel10k"

# 2. Instalar para root
if [ -d "/root/.powerlevel10k" ]; then
    log_info "Powerlevel10k ya existe para root, actualizando..."
    sudo git -C /root/.powerlevel10k pull --depth=1 2>/dev/null || true
else
    log_info "Clonando Powerlevel10k para root..."
    sudo git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /root/.powerlevel10k
fi

success "Powerlevel10k instalado para $CURRENT_USER y root"

# --- Copiar archivos de configuración de Zsh ---
# Desplegar .zshrc del usuario desde dotfiles
log_info "Desplegando .zshrc personalizado..."

if [ -f "$DOTFILES_DIR/zsh/.zshrc" ]; then
    cp "$DOTFILES_DIR/zsh/.zshrc" "$USER_HOME/.zshrc"
    chown "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.zshrc"
    log_success ".zshrc desplegado correctamente"
else
    log_warn "No se encontró dotfiles/zsh/.zshrc — .zshrc no modificado"
fi

if [ -f "$DOTFILES_DIR/zsh/.p10k.zsh" ]; then
    cp "$DOTFILES_DIR/zsh/.p10k.zsh" "$USER_HOME/.p10k.zsh"
    chown "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.p10k.zsh"
    log_success ".p10k.zsh desplegado para $CURRENT_USER"
fi

# Root usa su propio .p10k.root.zsh si existe, sino el del usuario
if [ -f "$DOTFILES_DIR/zsh/.p10k.root.zsh" ]; then
    sudo cp "$DOTFILES_DIR/zsh/.p10k.root.zsh" "/root/.p10k.zsh"
    log_success ".p10k.zsh de root desplegado (config propia)"
elif [ -f "$DOTFILES_DIR/zsh/.p10k.zsh" ]; then
    sudo cp "$DOTFILES_DIR/zsh/.p10k.zsh" "/root/.p10k.zsh"
    log_info ".p10k.zsh de root = copia del usuario (fallback)"
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

# .zshrc de root = symlink al del usuario (se mantienen sincronizados)
if [ -f "$USER_HOME/.zshrc" ]; then
    sudo ln -sf "$USER_HOME/.zshrc" /root/.zshrc
    log_success ".zshrc de root → symlink a $USER_HOME/.zshrc"
fi

# Copiar Fastfetch a root
if [ -d "$DOTFILES_DIR/fastfetch" ]; then
    sudo -n mkdir -p /root/.config
    sudo -n rm -rf /root/.config/fastfetch
    sudo -n cp -r "$DOTFILES_DIR/fastfetch" /root/.config/
    sudo -n chmod +x /root/.config/fastfetch/random_logo.sh 2>/dev/null || true
    log_info "Fastfetch configurado para root"
fi


# --- Configurar Nano Pro (Highlighter + RC) ---
log_info "Configurando Nano Pro..."
safe_install nano-syntax-highlighting
if [ -f "$DOTFILES_DIR/nano/.nanorc" ]; then
    cp "$DOTFILES_DIR/nano/.nanorc" "$USER_HOME/.nanorc"
    sudo cp "$DOTFILES_DIR/nano/.nanorc" "/root/.nanorc"
    chown "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.nanorc"
    log_info "Nano Pro configurado para usuario y root"
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
