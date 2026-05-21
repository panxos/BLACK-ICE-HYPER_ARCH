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

log_info "Configurando alias de actualización en ZSH..."

# Detectar archivo de alias (idempotente: no duplica si ya existe)
ZSH_ALIASES="$USER_HOME/.config/zsh/aliases.zsh"
[ ! -f "$ZSH_ALIASES" ] && ZSH_ALIASES="$USER_HOME/.zshrc"

if ! grep -q "claudeupdate" "$ZSH_ALIASES" 2>/dev/null; then
    cat >> "$ZSH_ALIASES" << 'EOF'

# --- IA Update Aliases (BLACK-ICE) ---
alias claudeupdate='tmp=$(mktemp /tmp/claude-install-XXXXXX.sh) && curl -fsSL https://claude.ai/install.sh -o "$tmp" && bash "$tmp"; rm -f "$tmp"'
alias geminiupdate='sudo npm install -g @google/gemini-cli'
EOF
    log_info "Aliases de IA agregados a $ZSH_ALIASES"
else
    log_info "Aliases de IA ya presentes en $ZSH_ALIASES"
fi

# --- Configurar browser por defecto para auth OAuth (Claude/Gemini abren URLs) ---
# En Wayland/Hyprland sin browser default configurado los CLIs no pueden autenticar.
log_info "Configurando browser por defecto para autenticación de CLIs..."

# Detectar browser disponible (brave > firefox > chromium)
BROWSER_BIN=""
for b in brave firefox chromium; do
    if command -v "$b" &>/dev/null; then
        BROWSER_BIN="$b"
        break
    fi
done

if [ -n "$BROWSER_BIN" ]; then
    # Configurar xdg-settings (afecta a xdg-open que usan los CLIs)
    xdg-settings set default-web-browser "${BROWSER_BIN}.desktop" 2>/dev/null || true

    # Asegurar variable BROWSER en .zshrc del usuario
    if ! grep -q "^export BROWSER=" "$USER_HOME/.zshrc" 2>/dev/null; then
        echo "export BROWSER=$BROWSER_BIN" >> "$USER_HOME/.zshrc"
    fi
    log_success "Browser por defecto: $BROWSER_BIN (OAuth de CLIs habilitado)"
else
    log_warn "No se detectó browser. Instala brave o firefox para autenticar los CLIs de IA."
fi

log_success "Módulo de IA completado"
