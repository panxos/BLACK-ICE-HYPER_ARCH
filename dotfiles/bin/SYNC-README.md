# 🔄 Sincronización MAESTRA - h0rus ↔ s3th

**Autor:** Francisco Aravena (P4nx0z)  
**Fecha:** 2026-03-17  
**Script:** `~/bin/sync-all-configs.sh`

---

## 📋 Resumen Ejecutivo

### ✅ Limpieza Realizada

| Script Eliminado | Ubicación | Razón |
|-----------------|-----------|-------|
| `sync_gemini.sh` | `~/.config/bin/` | Obsoleto (solo GEMINI.md) |
| `p2p_sync.sh` | `~/.gemini/antigravity/scripts/` | Reemplazado |
| `sync_configs.sh` | `MEGA/Scripts/experimentos/` | Obsoleto |

### ✅ Script Maestro Único

| Característica | Valor |
|---------------|-------|
| **Ubicación** | `~/bin/sync-all-configs.sh` |
| **Cron** | `0 */2 * * *` (cada 2 horas) |
| **Log** | `/var/log/sync-all-configs.log` |
| **Backup** | `~/.sync-backups/` (30 días) |

---

## 🎯 Directorios Sincronizados

```
✅ ~/.qwen                           (Qwen Code - skills, instrucciones)
✅ ~/.gemini/GEMINI.md               (Gemini - configuración principal)
✅ ~/.gemini/antigravity/            (TODO excepto estado temporal)
   ├── skills/                      ✅
   ├── rules/                       ✅
   ├── global_workflows/            ✅
   ├── knowledge/                   ✅
   ├── scripts/                     ✅
   ├── mcp_config.json              ✅
   ├── user_settings.pb             ✅
   ├── .gitignore                   ✅
   ├── gitops_sync.sh               ✅
   └── brain/                       ❌ (excluido - session data)
   └── code_tracker/                ❌ (excluido - session data)
   └── context_state/               ❌ (excluido - session data)
   └── conversations/               ❌ (excluido - session data)
   └── browser_recordings/          ❌ (excluido)
   └── html_artifacts/              ❌ (excluido)
   └── playground/                  ❌ (excluido)
   └── logs/                        ❌ (excluido)
   └── implicit/                    ❌ (excluido)
   └── annotations/                 ❌ (excluido)
   └── installation_id              ❌ (excluido)
✅ ~/.claude                         (Claude - configuración)
```

---

## 📀 Instalación

### En h0rus (este equipo):
```bash
# Ya está instalado y configurado!
~/bin/sync-all-configs.sh status
```

### En s3th (ejecutar):
```bash
# 1. Copiar script de instalación
scp faravena@<tailscale-ip-h0rus>:~/bin/install-sync-master.sh ~/bin/

# 2. Ejecutar instalador
~/bin/install-sync-master.sh

# 3. Sincronizar manualmente (traer configs de h0rus)
~/bin/sync-all-configs.sh pull
```

---

## 🎯 Comandos Disponibles

```bash
# Sincronizar
~/bin/sync-all-configs.sh push      # Enviar al otro host
~/bin/sync-all-configs.sh pull      # Traer del otro host
~/bin/sync-all-configs.sh status    # Ver estado

# Cron
~/bin/sync-all-configs.sh install-cron  # Instalar cron (cada 2h)
~/bin/sync-all-configs.sh remove-cron   # Eliminar cron

# Ayuda
~/bin/sync-all-configs.sh help
```

---

## ⏰ Cron Job

```bash
# Ver cron actual
crontab -l

# Salida esperada:
0 */2 * * * /home/faravena/bin/sync-all-configs.sh push >> /var/log/sync-all-configs.log 2>&1 # sync-all-configs-master
```

---

## 📊 Monitoreo

```bash
# Ver logs en tiempo real
tail -f /var/log/sync-all-configs.log

# Ver últimas 20 sincronizaciones
tail -20 /var/log/sync-all-configs.log

# Ver backups
ls -la ~/.sync-backups/

# Ver estado
~/bin/sync-all-configs.sh status
```

---

## 🇪🇬 Nombres de Agentes

**Recordatorio:** Todos los agentes creados deben usar nombres de dioses egipcios:

- **ANUBIS** - Security & Forensics
- **HORUS** - Monitoring & Observability
- **THOTH** - Documentation & Code Analysis
- **RA** - Orchestrator
- **OSIRIS** - Backup & Recovery
- **SETH** - Offensive Security
- **BASTET** - Home Protection
- **MA'AT** - Compliance & Auditing

---

## 🔧 Solución de Problemas

### Tailscale no conecta
```bash
# Verificar estado
tailscale status

# Reconectar
sudo systemctl restart tailscaled
```

### SSH sin password
```bash
# Copiar key al otro host
ssh-copy-id faravena@<tailscale-ip-remote>
```

### Verificar sincronización
```bash
# Dry-run (sin cambios)
rsync -avzn --delete ~/.qwen/ faravena@<remote>:~/.qwen/
```

---

**¡Configuración lista po', P4nx0z!** 🚀
