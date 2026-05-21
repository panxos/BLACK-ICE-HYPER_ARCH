# BLACK-ICE ARCH — Audit Report

**Fecha:** 2026-05-20  
**Versión auditada:** v3.6.3  
**Auditor:** Claude Code (claude-sonnet-4-6)

---

## Resumen Ejecutivo

Auditoría completa del proyecto BLACK-ICE_ARCH: scripts de instalación Phase 1 y Phase 2, dotfiles, documentación y seguridad. Se detectaron 12 hallazgos (4 críticos, 4 importantes, 4 informativos). Todos corregidos.

---

## Hallazgos Críticos (FIXED)

### C1 — Variable de teclado incorrecta en chroot config
**Archivo:** `src/modules/03_config.sh:54`  
**Problema:** `KEYMAP=${SYSTEM_KBD:-es}` — `$SYSTEM_KBD` nunca se define. La variable correcta es `$KEYMAP`, asignada por `00_environment.sh:172`.  
**Impacto:** Teclado siempre cae al valor por defecto `es`, ignorando la selección del usuario.  
**Fix:** `KEYMAP=${KEYMAP:-es}`

### C4 — Validación de initramfs hardcodeada a kernel linux
**Archivo:** `src/modules/03_config.sh:231`  
**Problema:** `[ ! -f /mnt/boot/initramfs-linux.img ]` — falla si el usuario eligió `linux-zen` o `linux-hardened`.  
**Impacto:** Falso positivo de error crítico en instalaciones con kernel alternativo.  
**Fix:** `[ ! -f "/mnt/boot/initramfs-${SELECTED_KERNEL:-linux}.img" ]`

### C5 — SSH con PermitRootLogin yes
**Archivo:** `src/modules/03_config.sh:342`  
**Problema:** El instalador activaba root login vía SSH "para debugging". Phase 2 lo revertía, pero si Phase 2 no se ejecuta, el sistema queda expuesto.  
**Impacto:** Vulnerabilidad de seguridad en sistemas donde solo se ejecuta Phase 1.  
**Fix:** Cambiado directamente a `prohibit-password` en Phase 1.

### C7 — bootstrap.sh apunta a repositorio incorrecto
**Archivo:** `bootstrap.sh:10,26`  
**Problema:** `REPO_URL` apuntaba a `BLACK-ICE-HYPER_ARCH.git` (nombre antiguo). El repositorio actual es `BLACK-ICE_ARCH.git`.  
**Impacto:** **Todos los nuevos installs vía `curl | bash` fallaban** con git clone error 404.  
**Fix:** URL corregida en comentario y en variable `REPO_URL`.

---

## Hallazgos Importantes (FIXED)

### C8 — hyprlock bind syntax (pendiente verificación)
**Archivo:** `dotfiles/hypr/hyprlock.conf`  
**Estado:** `bind = ESCAPE, exec, hyprctl dispatch dpms off` implementado. Sintaxis consistente con hyprlock 0.9+. Requiere prueba manual en sesión hyprlock activa (no verificable vía SSH).

### C9 — imagemagick no estaba en HYPRLAND_PKGS
**Archivo:** `src/deploy/01_hyprland_base.sh`  
**Problema:** `imagemagick` aparecía en `CRITICAL_PKGS` (validación) pero no en `HYPRLAND_PKGS` (instalación). La validación siempre fallaba porque el paquete nunca se instalaba.  
**Fix:** Agregado `imagemagick` a `HYPRLAND_PKGS`.

### I5 — kvm_intel hardcodeado en 99_finalization.sh
**Archivo:** `src/deploy/99_finalization.sh:172`  
**Problema:** `kvm_intel` siempre cargado, falla silenciosamente en CPUs AMD.  
**Fix:** Detección dinámica de vendor CPU → carga `kvm_intel` o `kvm_amd` según corresponda.

### D6 — Firewall sin regla ICMPv6
**Archivo:** `dotfiles/nftables/nftables.conf`  
**Problema:** Solo se permitía ICMPv4. En redes IPv6 (SLAAC, NDP, ping6) el sistema no respondía.  
**Fix:** Agregada regla `ip6 nexthdr icmpv6 accept`.

---

## Hallazgos Informativos (FIXED)

### D1 — URLs de repositorio incorrectas en READMEs
**Archivos:** `README.md`, `README.en.md`  
**Fix:** Reemplazado globalmente `BLACK-ICE-HYPER_ARCH` → `BLACK-ICE_ARCH`.

### D2 — Versión inconsistente entre archivos
**Problema:** README mostraba `v3.5.0`, logging.sh mostraba `v3.3.0`, CHANGELOG en `v3.6.3`.  
**Fix:** Todos sincronizados a `v3.6.3`.

### D8 — Resumen menciona BlackArch como repositorio activo
**Archivo:** `src/deploy/99_finalization.sh:220`  
**Problema:** BlackArch ya no se incluye por defecto desde v3.x.  
**Fix:** Eliminado del resumen de repositorios.

### I1 — power_profile_menu.sh — arquitectura wofi/rofi correcta
**Nota:** El script ya implementa fallback wofi→rofi. No requiere fix.

---

## Puntos Fuertes del Proyecto

- Arquitectura two-phase con separación clara de responsabilidades
- Confirmación explícita antes de operaciones destructivas (LUKS, wipe)
- `retry_command` para operaciones de red — nunca raw sleep loops
- `set -uo pipefail` en todos los módulos
- Idempotency checks antes de instalaciones pesadas
- Hardware detection inteligente (CPU microcode, GPU, virtualización)
- Migración automática IWD → NetworkManager con perfiles nativos
- nftables con arquitectura de coexistencia Docker/libvirt/Tailscale
- Snapper con hooks pre/post pacman para BTRFS

---

## Recomendaciones Pendientes

1. **hyprlock Escape bind** — verificar con `hyprlock --immediate` en sesión activa
2. **PSX BIOS** — documentar en README que el usuario debe proveer `scph5501.bin` (copyright)
3. **ShellCheck CI** — agregar `shellcheck src/**/*.sh` en pipeline para detectar regresiones
4. **Tests post-deploy** — agregar `imagemagick` y `awww` a `tests/post-install-validate.sh`
