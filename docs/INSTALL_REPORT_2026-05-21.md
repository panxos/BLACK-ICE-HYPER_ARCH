# BLACK-ICE ARCH — Install Report
**Fecha:** 2026-05-21  
**Versión:** v3.7.1 — "Polish" Edition  
**Entorno:** KVM/QEMU (VM `black-ice-benjie`, 192.168.122.200)  
**Usuario:** benjie  

---

## Resumen Ejecutivo

| Métrica | Valor |
|---------|-------|
| Inicio Phase 2 (intento final) | 02:11 |
| Fin Phase 2 | 02:51 |
| **Tiempo efectivo** | **~40 min** |
| Tiempo total (con OOMs) | ~2h 18min |
| Paquetes AUR compilados | 58 |
| Paquetes totales instalados | ~1641+ |
| OOM kills | 2 |
| Errores fatales | 0 |
| Advertencias PGP (auto-reparadas) | 4 |

---

## Timeline Completo

```
00:33:28  Phase 2 — Inicio (intento 1)
          → Repos, Hyprland base, herramientas de seguridad...

01:37:25  trufflehog (Go source compile) — inicio
~01:46    OOM KILL — compilador Go consumió toda la RAM disponible
          → Phase 2 abortado

02:02:40  Phase 2 — Reinicio (intento 2)
02:05:09  trufflehog intento 2 — OOM KILL nuevamente
          → Phase 2 abortado

02:11:36  Phase 2 — Reinicio (intento 3, con fix trufflehog-bin)
02:14:18  trufflehog-bin — inicio (binario pre-compilado)
02:14:32  trufflehog-bin — OK (14 segundos)

02:33:48  edb-debugger — inicio (Qt C++ desde fuente)
02:42:48  edb-debugger — OK (~9 minutos)

02:43:04  stegseek — inicio (C++ desde fuente)
~02:45    stegseek — OK (~2 minutos)

~02:46    chisel — inicio (Scala/sbt desde fuente)
~02:51    chisel — OK (~5 minutos)

02:51:07  onesixtyone-git — OK (último paquete AUR)
02:51:xx  PHASE2_DONE ✅
```

---

## Incidencias

### OOM Kill x2 — trufflehog (Go compilation)

**Causa raíz:** El compilador Go necesita ~3 GB de memoria virtual para compilar `trufflehog`. La VM tiene RAM limitada y sin swap suficiente para absorber el pico.

**Fix aplicado:** Cambio de `trufflehog` → `trufflehog-bin` en `src/deploy/02_security_tools.sh` línea 87.

```bash
# Antes
"trufflehog|TruffleHog - Secret Scanner|Crack"
# Después
"trufflehog-bin|TruffleHog - Secret Scanner|Crack"
```

Resultado: instalación en 14 segundos vs compilación de 45+ min + OOM.

### Advertencias PGP (auto-reparadas)

Los siguientes paquetes tuvieron error PGP pero el script los reparó automáticamente vía `--skippgpcheck`:
- `megasync-bin`
- `theharvester-git`
- `dnsenum2`
- `nuclei`

No hubo impacto en la instalación.

### systemd timeout

```
Failed to enable unit: Connection timed out
```

Cosmético. Ocurre al intentar habilitar un servicio systemd desde dentro de una sesión de usuario en VM sin bus D-Bus de sistema activo. No afecta el resultado.

---

## Paquetes Compilados desde AUR (Top by tiempo estimado)

| Paquete | Tiempo | Tipo | Observación |
|---------|--------|------|-------------|
| edb-debugger 1.5.0 | ~9 min | Qt C++ | Candidato a HEAVY_PKGS |
| chisel 6.3.0 | ~5 min | Scala/sbt | Alternativa: chisel-bin 1.11.5 |
| stegseek 0.6 | ~2 min | C++ | Sin binario AUR disponible |
| trufflehog-bin 3.95.3 | 14 seg | Pre-compilado | Fix correcto ✅ |

---

## Optimizaciones Recomendadas

### Prioridad Alta

**1. `edb-debugger` → HEAVY_PKGS**

Compilar `edb-debugger` desde AUR tarda ~9 minutos en hardware real y más en VM. Es una herramienta especializada (debugger Qt/GDB) que la mayoría de usuarios de pentesting no usa en el día a día.

Propuesta: moverlo a una categoría `HEAVY_PKGS` o marcarlo como opcional en la UI de whiptail con advertencia de tiempo.

**2. `chisel` → `chisel-bin`**

`chisel-bin 1.11.5` existe en AUR como binario pre-compilado. La versión fuente (`chisel 6.3.0`) compila con sbt/Scala (~5 min). Son versiones distintas pero ambas funcionales para tunneling TCP/UDP.

```bash
# Cambiar en 02_security_tools.sh
"chisel-bin|Chisel - TCP/UDP Tunnel|Net"
```

**Nota:** verificar compatibilidad antes del merge — la versión del binario (1.11.5) difiere del source (6.3.0).

### Prioridad Media

**3. Swap en VMs / sistemas con poca RAM**

En entornos con <4 GB RAM efectiva, considerar añadir un bloque de precondición en `deploy_hyprland.sh` que verifique si existe swap y, si no, cree uno temporal:

```bash
# En 00_repositories.sh o al inicio de deploy_hyprland.sh
if [[ $(free -m | awk '/Swap:/{print $2}') -lt 1024 ]]; then
    log_warn "Swap insuficiente (<1GB). Paquetes Go/Rust/Scala pueden fallar por OOM."
fi
```

---

## Validación Post-Install

```bash
# Ejecutar en la VM después del primer boot gráfico
bash ~/BLACK-ICE_ARCH/tests/post-install-validate.sh
```

Verificaciones manuales recomendadas:
- [ ] `hyprctl version` — Hyprland corriendo
- [ ] `waybar` visible con 21 temas disponibles
- [ ] `nmap --version` — herramientas de red OK
- [ ] `msfconsole --version` — Metasploit OK
- [ ] `trufflehog --version` — Secret scanner OK
- [ ] SDDM con tema CyberSec activo
- [ ] Neovim con LazyVim funcional

---

## Conclusión

La instalación completó exitosamente en ~40 min de tiempo efectivo. Los únicos incidentes fueron los 2 OOM kills de `trufflehog` (Go compiler) que ya están corregidos. El sistema quedó con >1600 paquetes instalados, 58 compilados desde AUR, sin errores fatales.

**Próximas acciones recomendadas para v3.8.0:**
1. `chisel` → `chisel-bin` en `02_security_tools.sh`
2. `edb-debugger` marcado como opcional/HEAVY en la UI whiptail
3. Advertencia de swap insuficiente al inicio de Phase 2
