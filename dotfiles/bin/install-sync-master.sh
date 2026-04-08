#!/bin/bash
#
# ══════════════════════════════════════════════════════════════════════════════
# install-sync-master.sh - Instalación del Sistema de Sincronización MAESTRO
# ══════════════════════════════════════════════════════════════════════════════
# Autor: Francisco Aravena (P4nx0z)
# Fecha: 2026-03-17
# ══════════════════════════════════════════════════════════════════════════════

set -euo pipefail
IFS=$'\n\t'

# Colores
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[✓]${NC} $*"; }
log_error() { echo -e "${RED}[✗]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[⚠]${NC} $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_URL="https://raw.githubusercontent.com/P4nx0z/dotfiles/main/bin/sync-all-configs.sh"

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║  Instalación de Sincronización MAESTRA - h0rus ↔ s3th                        ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""

# 1. Verificar ~/bin/
log_info "Verificando directorio ~/bin/..."
mkdir -p "$HOME/bin"
log_success "Directorio ~/bin/ listo"

# 2. Copiar o descargar script
if [[ -f "$SCRIPT_DIR/bin/sync-all-configs.sh" ]]; then
    log_info "Copiando script desde $SCRIPT_DIR..."
    cp "$SCRIPT_DIR/bin/sync-all-configs.sh" "$HOME/bin/"
    chmod +x "$HOME/bin/sync-all-configs.sh"
    log_success "Script copiado a ~/bin/sync-all-configs.sh"
else
    log_warning "Script no encontrado localmente, creando desde plantilla..."
    # El script debe ser copiado manualmente o vía sync desde el otro host
    log_info "Ejecuta sync-all-configs.sh pull para traer el script del otro host"
fi

# 3. Crear directorio de backups
log_info "Creando directorio de backups..."
mkdir -p "$HOME/.sync-backups"
log_success "Directorio de backups creado"

# 4. Crear archivo de log
log_info "Creando archivo de log..."
sudo touch /var/log/sync-all-configs.log 2>/dev/null || touch "$HOME/sync-all-configs.log"
sudo chown "$USER:$USER" /var/log/sync-all-configs.log 2>/dev/null || true
chmod 644 /var/log/sync-all-configs.log 2>/dev/null || true
log_success "Log creado"

# 5. Instalar dependencias
log_info "Verificando dependencias..."

# rsync
if ! command -v rsync &> /dev/null; then
    log_warning "rsync no está instalado"
    if command -v pacman &> /dev/null; then
        log_info "Instalando rsync con pacman..."
        sudo pacman -S rsync --noconfirm
    elif command -v apt &> /dev/null; then
        log_info "Instalando rsync con apt..."
        sudo apt install rsync -y
    fi
fi
log_success "rsync instalado"

# tailscale
if ! command -v tailscale &> /dev/null; then
    log_error "Tailscale no está instalado - INSTÁLALO PRIMERO"
    log_info "https://tailscale.com/download"
    exit 1
else
    log_success "Tailscale disponible"
fi

# 6. Configurar cron (cada 2 horas)
log_info "Configurando cron job (cada 2 horas)..."

# Eliminar entradas viejas
crontab -l 2>/dev/null | grep -v "sync_gemini.sh" | grep -v "p2p_sync.sh" | grep -v "sync-all-configs-master" | crontab - 2>/dev/null || true

# Agregar nueva entrada
(crontab -l 2>/dev/null || echo ""; echo "0 */2 * * * /home/faravena/bin/sync-all-configs.sh push >> /var/log/sync-all-configs.log 2>&1 # sync-all-configs-master") | crontab -

log_success "Cron job instalado (cada 2 horas)"

# 7. Mostrar instrucciones
echo ""
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║  Instalación Completada                                                      ║"
echo "╠══════════════════════════════════════════════════════════════════════════════╣"
echo "║  Comandos disponibles:                                                       ║"
echo "║                                                                              ║"
echo "║    ~/bin/sync-all-configs.sh push    - Enviar configs al otro host           ║"
echo "║    ~/bin/sync-all-configs.sh pull    - Traer configs del otro host           ║"
echo "║    ~/bin/sync-all-configs.sh status  - Ver estado                            ║"
echo "║                                                                              ║"
echo "║  La sincronización automática se ejecuta cada 2 horas                        ║"
echo "╠══════════════════════════════════════════════════════════════════════════════╣"
echo "║  Para sincronizar manualmente AHORA:                                         ║"
echo "║    ~/bin/sync-all-configs.sh push                                            ║"
echo "╠══════════════════════════════════════════════════════════════════════════════╣"
echo "║  Ver cron: crontab -l                                                        ║"
echo "║  Ver logs: tail -f /var/log/sync-all-configs.log                             ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"

# 8. Verificar crontab
echo ""
log_info "Crontab actual:"
crontab -l | grep sync || echo "Sin entradas de sync"
