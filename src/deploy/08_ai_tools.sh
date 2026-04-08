#!/bin/bash
# src/deploy/08_ai_tools.sh
# Instalación de Inteligencias Artificiales (CLIs)

banner "MÓDULO 8" "Inteligencia Artificial - CLIs"

log_info "Instalando dependencias de Node.js..."
safe_install nodejs
safe_install npm

log_info "Instalando CLIs de IA globalmente..."

# Instala un paquete npm global si no está ya instalado
install_npm_cli() {
    local pkg="$1"
    local name="$2"
    if npm list -g --depth=0 "$pkg" &>/dev/null; then
        log_info "$name ya está instalado"
        return 0
    fi
    log_info "Instalando $name..."
    if sudo npm install -g "$pkg"; then
        log_success "$name instalado correctamente"
    else
        log_error "Error al instalar $name (continúa)"
    fi
}

# --- Claude Code ---
install_npm_cli "@anthropic-ai/claude-code" "Claude Code CLI"

# --- Gemini CLI ---
install_npm_cli "@google/gemini-cli" "Gemini CLI"

# --- Qwen Code ---
if ! npm list -g --depth=0 "@qwen-code/qwen-code" &>/dev/null; then
    log_info "Instalando Qwen Code CLI..."
    if sudo npm install -g @qwen-code/qwen-code@latest >> "$LOG_FILE" 2>&1; then
        log_success "Qwen Code instalado correctamente"
    else
        log_warn "Qwen Code: instalación falló (continúa)"
    fi
else
    log_info "Qwen Code ya instalado"
fi

log_info "Configurando alias de actualización en ZSH..."

# Detectar archivo de alias (idempotente: no duplica si ya existe)
ZSH_ALIASES="$USER_HOME/.config/zsh/aliases.zsh"
[ ! -f "$ZSH_ALIASES" ] && ZSH_ALIASES="$USER_HOME/.zshrc"

if ! grep -q "claudeupdate" "$ZSH_ALIASES" 2>/dev/null; then
    cat >> "$ZSH_ALIASES" << 'EOF'

# --- IA Update Aliases (BLACK-ICE) ---
alias claudeupdate='curl -fsSL https://claude.ai/install.sh | bash'
alias geminiupdate='sudo npm install -g @google/gemini-cli'
alias qwenupdate='sudo npm install -g @qwen-code/qwen-code@latest'
EOF
    log_info "Aliases de IA agregados a $ZSH_ALIASES"
else
    log_info "Aliases de IA ya presentes en $ZSH_ALIASES"
fi

log_success "Módulo de IA completado"
