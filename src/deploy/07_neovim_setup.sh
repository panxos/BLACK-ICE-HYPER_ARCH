#!/bin/bash
# deploy-modules/07_neovim_setup.sh
# Configura Neovim con NvChad v2.5 + LSPs para Python, C/C++, Docker, Java
# Author: Francisco Aravena (P4nX0Z)

banner "MÓDULO 7" "Setup Neovim Pro (NvChad)"

# --- Pre-requisitos ---
log_info "Instalando pre-requisitos para Neovim/NvChad..."
safe_install neovim
safe_install tree-sitter-cli
safe_install ripgrep
safe_install gcc
safe_install make
safe_install nodejs
safe_install npm
safe_install python-pip
safe_install unzip

# --- Limpieza de configuraciones antiguas ---
log_info "Limpiando instalaciones previas de Neovim..."
rm -rf "$USER_HOME/.config/nvim"
rm -rf "$USER_HOME/.local/state/nvim"
rm -rf "$USER_HOME/.local/share/nvim"

# --- Instalación de NvChad Starter ---
log_info "Clonando NvChad Starter..."
git clone https://github.com/NvChad/starter "$USER_HOME/.config/nvim"

# --- Desplegar Custom Configuration ---
# Si existe configuración personalizada en dotfiles, la usamos.
# Si no, creamos la estructura base para los LSPs solicitados.
NVIM_DOTFILES="$SCRIPT_DIR/dotfiles/nvim"

if [ -d "$NVIM_DOTFILES" ]; then
    log_info "Copiando configuración personalizada de NvChad (v2.5 structure)..."
    cp -r "$NVIM_DOTFILES/lua/"* "$USER_HOME/.config/nvim/lua/" 2>/dev/null || true
else
    log_info "Instalación base de NvChad terminada. Se recomienda personalización posterior."
fi

# Ajustar permisos
chown -R "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.config/nvim"

# --- Post-instalación (Mason e Instalación de LSPs) ---
# Nota: Mason requiere que Neovim se abra para instalar. 
# Intentaremos una instalación silenciosa de los plugins y LSPs críticos.
log_info "Iniciando instalación silenciosa de complementos (Mason/TS)..."

# Lista de LSPs para instalar vía Mason
# pyright, black, isort, debugpy (Python)
# clangd, codelldb (C/C++)
# dockerls (Docker)
# jdtls (Java)

sudo -u "$CURRENT_USER" nvim --headless "+Lazy! sync" +qa 2>/dev/null
sudo -u "$CURRENT_USER" nvim --headless "+MasonInstall pyright black isort debugpy clangd codelldb dockerls jdtls" +qa 2>/dev/null

success "Neovim con NvChad v2.5 configurado correctamente"
