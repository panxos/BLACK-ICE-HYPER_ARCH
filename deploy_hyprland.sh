#!/bin/bash
# ==============================================================================
# DEPLOY HYPRLAND - BLACK-ICE ARCH
# Deployment script for Hyprland with security tools
# ==============================================================================
# Author: Francisco Aravena (P4nx0s)
# GitHub: https://github.com/panxos
# ==============================================================================

# --- Variables Globales ---
set -euo pipefail
# : SCRIPT_DIR es la raíz del proyecto
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
export DOTFILES_DIR="$SCRIPT_DIR/dotfiles"
BLACK_ICE_VERSION=$(<"$SCRIPT_DIR/VERSION")
APP_ARGS=()
APP_PLAN=""
PREVIEW=false
RESUME_MODULES=false
AUTO_CONFIRM_OVERRIDE=''
AUR_CONFIRM_OVERRIDE=''
while (( $# )); do
    case "$1" in
        --banner)
            # shellcheck source=src/lib/banner.sh
            source "$SCRIPT_DIR/src/lib/banner.sh"
            black_ice_banner "DESPLIEGUE DEL ESCRITORIO" "Hyprland / temas y aplicaciones" "$BLACK_ICE_VERSION"
            exit 0 ;;
        --dry-run) PREVIEW=true; shift ;;
        --resume) RESUME_MODULES=true; shift ;;
        -y|--yes) AUTO_CONFIRM_OVERRIDE=true; shift ;;
        --interactive) AUTO_CONFIRM_OVERRIDE=false; shift ;;
        --allow-unreviewed-aur) AUR_CONFIRM_OVERRIDE=true; shift ;;
        --profile) [[ $# -ge 2 ]] || exit 2; APP_ARGS+=(--profile "$2"); shift 2 ;;
        --apps-ui) APP_ARGS+=(--ui auto); shift ;;
        --plan) [[ $# -ge 2 ]] || exit 2; APP_PLAN="$2"; shift 2 ;;
        --version) printf '%s\n' "$BLACK_ICE_VERSION"; exit 0 ;;
        --help)
            echo 'Uso: deploy_hyprland.sh [--dry-run] [--resume] [--yes | --interactive] [--allow-unreviewed-aur]'
            echo 'Aplicaciones: --apps-ui | --profile minimal|desktop|pentest|full | --plan ARCHIVO'
            echo 'Las confirmaciones rutinarias son automáticas. La revisión AUR se conserva salvo autorización explícita.'
            exit 0 ;;
        *) echo "Opción desconocida: $1" >&2; exit 2 ;;
    esac
done
if [[ "$PREVIEW" == true ]]; then
    [[ -n "$APP_PLAN" ]] && APP_ARGS=(--load "$APP_PLAN")
    python3 "$SCRIPT_DIR/scripts/select-apps.py" "${APP_ARGS[@]}"
    printf 'Confirmaciones automáticas: %s; AUR sin revisión: %s\n' "${AUTO_CONFIRM_OVERRIDE:-${ASSUME_YES:-true}}" "${AUR_CONFIRM_OVERRIDE:-${ALLOW_UNREVIEWED_AUR:-false}}"
    echo 'Vista previa: módulos base + aplicaciones indicadas. No se modificó el sistema.'
    exit 0
fi
if (( EUID == 0 )); then
    echo 'Ejecuta el despliegue como usuario normal.' >&2
    exit 1
fi
DEPLOY_CONFIG="$SCRIPT_DIR/install.conf.auto"
if [[ -f "$DEPLOY_CONFIG" ]]; then
    # shellcheck source=/dev/null
    source "$DEPLOY_CONFIG"
fi
export ASSUME_YES="${AUTO_CONFIRM_OVERRIDE:-${ASSUME_YES:-true}}"
export ALLOW_UNREVIEWED_AUR="${AUR_CONFIRM_OVERRIDE:-${ALLOW_UNREVIEWED_AUR:-false}}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/black-ice"
mkdir -p "$STATE_DIR"
exec 8>"$STATE_DIR/deploy.lock"
flock -n 8 || { echo 'Ya existe un despliegue en ejecución.' >&2; exit 1; }
if [[ -n "$APP_PLAN" ]]; then
    APP_PLAN=$(realpath "$APP_PLAN")
    python3 "$SCRIPT_DIR/scripts/select-apps.py" --load "$APP_PLAN" >/dev/null
else
    if [[ "$RESUME_MODULES" == true && -f "$STATE_DIR/apps-plan.json" && ${#APP_ARGS[@]} == 0 ]]; then
        APP_ARGS=(--load "$STATE_DIR/apps-plan.json")
    fi
    if (( ${#APP_ARGS[@]} == 0 )) && [[ "${NON_INTERACTIVE:-false}" != true ]]; then
        APP_ARGS=(--ui auto)
    fi
    APP_PLAN="$STATE_DIR/apps-plan.json"
    python3 "$SCRIPT_DIR/scripts/select-apps.py" "${APP_ARGS[@]}" --output "$APP_PLAN" >/dev/null
fi

# --- Importar utilidades y colores  ---
source "$SCRIPT_DIR/src/lib/colors.sh"
source "$SCRIPT_DIR/src/lib/logging.sh"
source "$SCRIPT_DIR/src/lib/utils.sh"
# shellcheck source=src/lib/privileges.sh
source "$SCRIPT_DIR/src/lib/privileges.sh"
# shellcheck source=src/lib/repositories.sh
source "$SCRIPT_DIR/src/lib/repositories.sh"

# --- Manejo de Interrupciones (SIGINT / Ctrl+C) ---
# Definido DESPUÉS de source para que $RED/$YELLOW/$NC estén disponibles
# shellcheck disable=SC2329
cleanup() {
    echo -e "\n\n${RED}!!! DESPLIEGUE INTERRUMPIDO (Ctrl+C) !!!${NC}"
    echo -e "${YELLOW}[WARN] El sistema puede haber quedado en un estado parcial.${NC}"
    log_error "Despliegue cancelado por el usuario (SIGINT)."
    exit 130
}

trap cleanup SIGINT

# --- Logging Setup (Global Redirection) ---
# Save original stdout/stderr for interactive menus (whiptail/read)
exec 3>&1
exec 4>&2

# Captura TODO (stdout y stderr) en un archivo de log y lo muestra en pantalla
exec > >(tee -ai "$LOG_FILE") 2>&1
echo "--- BLACK-ICE DEPLOYMENT STARTED: $(date) ---"
log_info "Log de sesión: $LOG_FILE"

# --- Verificar que NO sea root ---
if [ "$EUID" -eq 0 ]; then
    log_error "Este script NO debe ejecutarse como root."
    log_info "Ejecuta como usuario normal (usará sudo cuando sea necesario)"
    exit 1
fi

# Obtener usuario actual
CURRENT_USER=$(whoami)
USER_HOME="/home/$CURRENT_USER"
USER_HOME="$HOME"
start_sudo_session
trap stop_sudo_session EXIT
trap 'exit 143' TERM

banner "DESPLIEGUE DEL ESCRITORIO" "Hyprland / temas y aplicaciones"

log_info "Iniciando despliegue de Hyprland para $CURRENT_USER..."
echo ""

# --- Módulos de instalación ---
log_info "Ejecutando módulos de instalación..."
MODULE_ROOT="$SCRIPT_DIR"
MODULE_STATE="$STATE_DIR/deploy-modules.json"
MODULE_IDENTITY="$(id -u):$(findmnt -nro UUID -T "$HOME"):$HOME"
MODULE_FINGERPRINT=$({ cat "$SCRIPT_DIR/VERSION" "$APP_PLAN"; [[ ! -f "$DEPLOY_CONFIG" ]] || cat "$DEPLOY_CONFIG"; } | sha256sum | cut -d' ' -f1)
export MODULE_ROOT MODULE_STATE MODULE_IDENTITY MODULE_FINGERPRINT
source "$SCRIPT_DIR/src/lib/module-runner.sh"
verify_install_module() {
    case "$1" in
        repositories)
            paru --version >/dev/null && pacman -Q chaotic-keyring chaotic-mirrorlist >/dev/null &&
                pacman-conf --repo-list | grep -Fxq chaotic-aur
            ;;
        desktop)
            pacman -Q hyprland kitty >/dev/null && [[ -s "$HOME/.config/hypr/hyprland.conf" ]] || return 1
            [[ -z "${KEYBOARD_LAYOUT:-}" ]] || grep -Fxq "KEYMAP=$KEYBOARD_LAYOUT" /etc/vconsole.conf
            ;;
        terminal) [[ -s "$HOME/.zshrc" && -s "$HOME/.config/kitty/kitty.conf" ]] ;;
        theme) [[ -s "$HOME/.config/qt5ct/qt5ct.conf" && -s "$HOME/.config/qt6ct/qt6ct.conf" ]] ;;
        sddm) [[ -s /usr/share/sddm/themes/black-ice-obsidian/Main.qml ]] ;;
        neovim) [[ -d "$HOME/.config/nvim" ]] ;;
        ai) command -v claude >/dev/null ;;
        grub) [[ -s /boot/grub/grub.cfg ]] ;;
        final) PATH="$HOME/.local/bin:$HOME/bin:$PATH" bash "$SCRIPT_DIR/tests/post-install-validate.sh" ;;
        *) return 1 ;;
    esac
}
module_journal init

# Asegurar directorio de trabajo válido al inicio del despliegue
cd "$USER_HOME" || cd "$SCRIPT_DIR" || exit 1

# 1. Repositorios (yay, chaotic-aur, BlackArch)
run_install_module repositories "$SCRIPT_DIR/src/deploy/00_repositories.sh"

# 2. Hyprland y componentes base
run_install_module desktop "$SCRIPT_DIR/src/deploy/01_hyprland_base.sh"

# 3. Configuración de terminal (Zsh + p10k)
run_install_module terminal "$SCRIPT_DIR/src/deploy/03_terminal_config.sh"

# 4. Tema y personalización (GTK, Qt, Waybar temas)
run_install_module theme "$SCRIPT_DIR/src/deploy/04_theme_setup.sh"

# 5. Software Suite Premium (Checklist Interactivo)
source "$SCRIPT_DIR/src/deploy/05_software_suite.sh"

# 6. Configuración SDDM (CyberSec Theme)
run_install_module sddm "$SCRIPT_DIR/src/deploy/06_sddm_setup.sh"

# 7. Setup Neovim Pro (NvChad)
if app_installed neovim; then
    run_install_module neovim "$SCRIPT_DIR/src/deploy/07_neovim_setup.sh"
fi

# 8. AI CLIs (Claude Code, Gemini)
if printf '%s\n' "${SELECTED_APPS[@]}" | grep -Fxq claude-code-cli; then
    run_install_module ai "$SCRIPT_DIR/src/deploy/08_ai_tools.sh"
fi

# 9. GRUB Theme (DedSec)
run_install_module grub "$SCRIPT_DIR/src/deploy/09_grub_theme.sh"

# 99. Finalización (dotfiles, symlinks, permisos)
run_install_module final "$SCRIPT_DIR/src/deploy/99_finalization.sh"

# 10. Herramientas de Seguridad — AL FINAL (opcional, no bloquea el entorno)
source "$SCRIPT_DIR/src/deploy/02_security_tools.sh"

log_info "Verificando el escritorio instalado..."
PATH="$USER_HOME/.local/bin:$USER_HOME/bin:$PATH" bash "$SCRIPT_DIR/tests/post-install-validate.sh"

echo ""
if (( ${#FAILED_APPS[@]} )); then
    log_warn "Escritorio desplegado con aplicaciones opcionales pendientes: ${FAILED_APPS[*]}"
else
    success "Despliegue de Hyprland $BLACK_ICE_VERSION completado."
fi
echo ""
echo -e "${NEON_CYAN}Próximos pasos:${NC}"
echo -e "  1. ${YELLOW}Cierra sesión${NC}"
echo -e "  2. En el login manager, selecciona ${GREEN}Hyprland${NC}"
echo -e "  3. Inicia sesión"
echo -e "  4. ${CYAN}Win+Return${NC} abre Kitty"
echo -e "  5. ${CYAN}Win+D${NC} abre launcher (wofi)"
echo -e "  6. ${CYAN}Win+Alt+W${NC}  cambia wallpaper (selector visual)"
echo -e "  7. ${CYAN}Win+Alt+T${NC}  abre BLACK-ICE Control en Apariencia"
echo -e "  8. ${CYAN}Win+Alt+R${NC}  cambia estilo Wofi"
echo -e "  9. ${CYAN}Win+Alt+F${NC}  toggle WiFi"
echo -e " 10. ${CYAN}Win+Shift+M${NC} abre music player (ncmpcpp)"
echo -e " 11. ${CYAN}Win+L${NC}      bloquea sesión (Cyberpunk Lock)"
echo -e ""
echo -e "  ${YELLOW}Teclas multimedia:${NC} Vol/Mute/Mic/Brillo funcionan directo"
echo ""

exit 0
