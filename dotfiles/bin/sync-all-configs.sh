#!/bin/bash
#
# ══════════════════════════════════════════════════════════════════════════════
# sync-all-configs.sh - Sincronización MAESTRA de Configuraciones
# ══════════════════════════════════════════════════════════════════════════════
# Autor: Francisco Aravena (P4nx0z)
# Fecha: 2026-03-17
# Uso: ~/bin/sync-all-configs.sh [push|pull|status]
#
# Sincroniza:
#   - ~/.qwen        (Qwen Code - skills, instrucciones)
#   - ~/.gemini      (Gemini - GEMINI.md + antigravity skills/rules)
#   - ~/.claude      (Claude - configuración)
#
# Cron: Cada 2 horas (0 */2 * * *)
# ══════════════════════════════════════════════════════════════════════════════

set -euo pipefail
IFS=$'\n\t'

# ══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ══════════════════════════════════════════════════════════════════════════════

# Colores
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Logs
readonly LOG_FILE="/var/log/sync-all-configs.log"
readonly TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Directorios a sincronizar (SOLO configs que importan)
declare -a DIRECTORIOS=(
    ".qwen"
    ".gemini/GEMINI.md"
    ".gemini/antigravity"
    ".claude"
)

# Exclusiones para antigravity (estado temporal, session data)
declare -a EXCLUSIONES=(
    "brain/"
    "code_tracker/"
    "context_state/"
    "conversations/"
    "browser_recordings/"
    "html_artifacts/"
    "playground/"
    "logs/"
    "implicit/"
    "annotations/"
    "installation_id"
    "*.bak"
    "*.log"
    ".git/"
)

# Hosts
readonly HOSTNAME=$(hostname)
readonly HORUS_NAME="h0rus"
readonly SETH_NAME="s3th"

# Determinar host local y remoto
if [[ "$HOSTNAME" == "$HORUS_NAME" ]]; then
    readonly LOCAL_HOST="$HORUS_NAME"
    readonly REMOTE_HOST="$SETH_NAME"
    readonly REMOTE_USER="${SETH_USER:-faravena}"
elif [[ "$HOSTNAME" == "$SETH_NAME" ]]; then
    readonly LOCAL_HOST="$SETH_NAME"
    readonly REMOTE_HOST="$HORUS_NAME"
    readonly REMOTE_USER="${HORUS_USER:-faravena}"
else
    echo -e "${RED}[ERROR]${NC} Host no reconocido: $HOSTNAME"
    echo "Este script debe ejecutarse en h0rus o s3th"
    exit 1
fi

# ══════════════════════════════════════════════════════════════════════════════
# FUNCIONES DE LOGGING
# ══════════════════════════════════════════════════════════════════════════════

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[✗]${NC} $*" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $*" | tee -a "$LOG_FILE"
}

log_sync() {
    echo -e "${CYAN}[SYNC]${NC} $*" | tee -a "$LOG_FILE"
}

# ══════════════════════════════════════════════════════════════════════════════
# VALIDACIONES
# ══════════════════════════════════════════════════════════════════════════════

verificar_tailscale() {
    log_info "Verificando conexión Tailscale..."
    
    if ! command -v tailscale &> /dev/null; then
        log_error "Tailscale no está instalado"
        return 1
    fi
    
    if ! tailscale status &> /dev/null; then
        log_error "Tailscale no está conectado"
        return 1
    fi
    
    # Verificar conectividad con host remoto
    if ! tailscale ping "$REMOTE_HOST" &> /dev/null; then
        log_error "No se puede conectar con $REMOTE_HOST vía Tailscale"
        return 1
    fi
    
    log_success "Conexión Tailscale verificada con $REMOTE_HOST"
    return 0
}

verificar_directorios() {
    log_info "Verificando directorios locales..."
    
    for dir in "${DIRECTORIOS[@]}"; do
        if [[ ! -e "$HOME/$dir" ]]; then
            log_warning "No existe: $HOME/$dir"
        fi
    done
}

# ══════════════════════════════════════════════════════════════════════════════
# SINCRONIZACIÓN
# ══════════════════════════════════════════════════════════════════════════════

construir_exclusiones() {
    local flags=""
    for exc in "${EXCLUSIONES[@]}"; do
        flags="$flags --exclude=$exc"
    done
    echo "$flags"
}

sync_push() {
    log_sync "Iniciando PUSH de configuraciones a $REMOTE_HOST..."
    
    local errores=0
    local exitosos=0
    local exclusiones=$(construir_exclusiones)
    
    for item in "${DIRECTORIOS[@]}"; do
        local src="$HOME/$item"
        local dst="${REMOTE_USER}@${REMOTE_HOST}:$HOME/$item"
        
        if [[ -e "$src" ]]; then
            log_info "Sincronizando $item..."
            
            if [[ -d "$src" ]]; then
                # Directorio
                if rsync -avz --delete \
                    -e "ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10" \
                    "$src/" "$dst/" 2>&1 | tee -a "$LOG_FILE"; then
                    log_success "$item sincronizado"
                    ((exitosos++))
                else
                    log_error "Error sincronizando $item"
                    ((errores++))
                fi
            else
                # Archivo individual
                if rsync -avz \
                    -e "ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10" \
                    "$src" "$dst" 2>&1 | tee -a "$LOG_FILE"; then
                    log_success "$item sincronizado"
                    ((exitosos++))
                else
                    log_error "Error sincronizando $item"
                    ((errores++))
                fi
            fi
        else
            log_warning "No existe: $item (saltando)"
        fi
    done
    
    log_info "Resumen: $exitosos exitosos, $errores errores"
    
    if [[ $errores -eq 0 ]]; then
        log_success "PUSH completado exitosamente"
        return 0
    else
        log_error "PUSH completado con $errores errores"
        return 1
    fi
}

sync_pull() {
    log_sync "Iniciando PULL de configuraciones desde $REMOTE_HOST..."
    
    local errores=0
    local exitosos=0
    local exclusiones=$(construir_exclusiones)
    
    for item in "${DIRECTORIOS[@]}"; do
        local src="${REMOTE_USER}@${REMOTE_HOST}:$HOME/$item"
        local dst="$HOME/$item"
        
        log_info "Descargando $item..."
        
        # Verificar si existe en remoto
        if ! ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 \
            "${REMOTE_USER}@${REMOTE_HOST}" "test -e '$HOME/$item'" 2>/dev/null; then
            log_warning "No existe en remoto: $item (saltando)"
            continue
        fi
        
        if [[ -d "$dst" ]] || ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 \
            "${REMOTE_USER}@${REMOTE_HOST}" "test -d '$HOME/$item'" 2>/dev/null; then
            # Directorio
            if rsync -avz --delete \
                -e "ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10" \
                "$src/" "$dst/" 2>&1 | tee -a "$LOG_FILE"; then
                log_success "$item descargado"
                ((exitosos++))
            else
                log_error "Error descargando $item"
                ((errores++))
            fi
        else
            # Archivo individual
            if rsync -avz \
                -e "ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10" \
                "$src" "$dst" 2>&1 | tee -a "$LOG_FILE"; then
                log_success "$item descargado"
                ((exitosos++))
            else
                log_error "Error descargando $item"
                ((errores++))
            fi
        fi
    done
    
    log_info "Resumen: $exitosos exitosos, $errores errores"
    
    if [[ $errores -eq 0 ]]; then
        log_success "PULL completado exitosamente"
        return 0
    else
        log_error "PULL completado con $errores errores"
        return 1
    fi
}

sync_status() {
    log_info "Estado de configuraciones en $LOCAL_HOST..."
    echo ""
    
    for item in "${DIRECTORIOS[@]}"; do
        echo -e "${CYAN}════════════════════════════════════════${NC}"
        echo -e "${CYAN} $item${NC}"
        echo -e "${CYAN}════════════════════════════════════════${NC}"
        
        if [[ -e "$HOME/$item" ]]; then
            if [[ -d "$HOME/$item" ]]; then
                local count=$(find "$HOME/$item" -type f 2>/dev/null | wc -l)
                local size=$(du -sh "$HOME/$item" 2>/dev/null | cut -f1)
                local modified=$(find "$HOME/$item" -type f -mtime -7 2>/dev/null | wc -l)
                
                log_success "Archivos: $count | Tamaño: $size | Modificados (7 días): $modified"
            else
                local size=$(du -h "$HOME/$item" 2>/dev/null | cut -f1)
                log_success "Archivo: $size"
            fi
        else
            log_warning "No existe"
        fi
        
        echo ""
    done
    
    # Estado de Tailscale
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    echo -e "${CYAN} Estado Tailscale${NC}"
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    tailscale status | head -10
    echo ""
    
    # Últimas sincronizaciones
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    echo -e "${CYAN} Últimas sincronizaciones${NC}"
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    if [[ -f "$LOG_FILE" ]]; then
        tail -20 "$LOG_FILE"
    else
        log_info "Sin logs de sincronización"
    fi
    echo ""
}

# ══════════════════════════════════════════════════════════════════════════════
# BACKUP PRE-SINCRONIZACIÓN
# ══════════════════════════════════════════════════════════════════════════════

crear_backup() {
    local backup_dir="$HOME/.sync-backups/$TIMESTAMP"
    log_info "Creando backup en $backup_dir..."
    
    mkdir -p "$backup_dir"
    
    for item in "${DIRECTORIOS[@]}"; do
        if [[ -e "$HOME/$item" ]]; then
            local backup_name=$(echo "$item" | tr '/' '_')
            cp -r "$HOME/$item" "$backup_dir/$backup_name" 2>/dev/null || true
        fi
    done
    
    log_success "Backup creado: $backup_dir"
    
    # Limpiar backups antiguos (>30 días)
    find "$HOME/.sync-backups" -type d -mtime +30 -exec rm -rf {} \; 2>/dev/null || true
}

# ══════════════════════════════════════════════════════════════════════════════
# GESTIÓN CRON
# ══════════════════════════════════════════════════════════════════════════════

instalar_cron() {
    log_info "Instalando cron job (cada 2 horas)..."
    
    local script_path="$(realpath "$0")"
    local cron_entry="0 */2 * * * $script_path push >> $LOG_FILE 2>&1"
    local cron_tag="# sync-all-configs-master"
    
    # Eliminar entrada anterior si existe
    crontab -l 2>/dev/null | grep -v "$cron_tag" | crontab - 2>/dev/null || true
    
    # Agregar nueva entrada
    (
        crontab -l 2>/dev/null || echo ""
        echo "$cron_entry $cron_tag"
    ) | crontab -
    
    log_success "Cron job instalado (cada 2 horas)"
    log_info "Revisar con: crontab -l"
}

eliminar_cron() {
    log_info "Eliminando cron job..."
    
    local cron_tag="# sync-all-configs-master"
    crontab -l 2>/dev/null | grep -v "$cron_tag" | crontab - 2>/dev/null || true
    
    log_success "Cron job eliminado"
}

# ══════════════════════════════════════════════════════════════════════════════
# CLEANUP
# ══════════════════════════════════════════════════════════════════════════════

cleanup() {
    local exit_code=$?
    
    # Limpiar backups antiguos
    if [[ -d "$HOME/.sync-backups" ]]; then
        find "$HOME/.sync-backups" -type d -mtime +30 -exec rm -rf {} \; 2>/dev/null || true
    fi
    
    exit $exit_code
}

trap cleanup EXIT

# ══════════════════════════════════════════════════════════════════════════════
# MAIN
# ══════════════════════════════════════════════════════════════════════════════

mostrar_ayuda() {
    cat << EOF
╔══════════════════════════════════════════════════════════════════════════════╗
║  Sincronización MAESTRA - h0rus ↔ s3th                                       ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Uso: ~/bin/sync-all-configs.sh [comando]                                    ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Comandos:                                                                   ║
║    push      - Enviar configuraciones a $REMOTE_HOST                         ║
║    pull      - Descargar configuraciones desde $REMOTE_HOST                  ║
║    status    - Mostrar estado de configuraciones                             ║
║    install-cron  - Instalar cron job (cada 2 horas)                          ║
║    remove-cron   - Eliminar cron job                                         ║
║    help      - Mostrar esta ayuda                                            ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Directorios sincronizados:                                                  ║
║    - ~/.qwen        (Qwen Code)                                              ║
║    - ~/.gemini      (Gemini - GEMINI.md + antigravity)                       ║
║    - ~/.claude      (Claude)                                                 ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Host local: $LOCAL_HOST                                                     ║
║  Host remoto: $REMOTE_HOST                                                   ║
╚══════════════════════════════════════════════════════════════════════════════╝

EOF
}

main() {
    local comando="${1:-help}"
    
    log_info "Host local: $LOCAL_HOST"
    log_info "Host remoto: $REMOTE_HOST"
    echo ""
    
    case "$comando" in
        push)
            verificar_tailscale || exit 1
            verificar_directorios
            crear_backup
            sync_push
            ;;
        pull)
            verificar_tailscale || exit 1
            verificar_directorios
            crear_backup
            sync_pull
            ;;
        status)
            sync_status
            ;;
        install-cron)
            instalar_cron
            ;;
        remove-cron)
            eliminar_cron
            ;;
        help|--help|-h)
            mostrar_ayuda
            ;;
        *)
            log_error "Comando no reconocido: $comando"
            mostrar_ayuda
            exit 1
            ;;
    esac
}

# Solo ejecutar main si es script principal
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
