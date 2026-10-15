# Compatibilidad y validación

Versión evaluada: **4.0.0-dev.2**. “Implementado” indica una ruta de código; “comprobado” exige una ejecución registrada. No se declara compatibilidad universal por detectar un hipervisor.

| Entorno o función | Estado | Alcance |
|---|---|---|
| Arch + Hyprland en portátil Intel | Comprobado localmente | Tres salidas, Waybar, Conky y controles |
| Hyprland 0.56.2, Hyprlang | Comprobado | Configuración activa y verificaciones |
| Proveedor Lua | Comprobado en compositor aislado y QA | Migración preparada; activar al volver a iniciar sesión |
| KVM, UEFI, Btrfs, LUKS, perfil `minimal` | Comprobado en QA 2026-10-15 | Instalación limpia desde ISO + repo oficial, arranque SDDM/Hyprland y persistencia del tema |
| BIOS/ext4 y combinaciones alternativas | Implementadas parcialmente; matriz pendiente | No atribuirles el resultado UEFI/Btrfs/LUKS |
| Actualización unificada de BLACK-ICE | Implementada localmente | `black-ice-update --dry-run` revisa; `black-ice-update` coordina checkout, dotfiles, controles de usuario y componentes de sistema; no actualiza Arch ni activa Tor |
| Salto desde una versión anterior | Pendiente de aceptación | Aplicar en una VM anterior reproducible y probar preferencias, servicios y recuperación por etapa |
| VMware, Xen, VirtualBox, Hyper-V | Detección en código; no verificado en este candidato | Faltan instalaciones propias |
| Dos o tres monitores alineados | Distribución comprobada con fixtures | Revisión de encuadre y hotplug físico pendientes |
| Tres salidas Hyprland aisladas | Comprobado | Escritorios persistentes, selección y reconexión |
| SDDM de agencias | Comprobado en QA | Autenticación y retorno al escritorio |
| Suspensión S3/S4 de VM | Fallo gráfico reproducible | Desactivada en QA; pausa del hipervisor comprobada |
| Suspensión física con batería | Pendiente | No se induce durante una sesión de trabajo |
| NVIDIA/AMD físicos, HiDPI mixto, VRR | No verificado | Requieren equipos y pruebas propias |

## Dependencias específicas

Conky necesita Wayland, Cairo y `conky_surface()`; se comprobó Conky 1.24.2. Rofi necesita una compilación compatible con Wayland; Wofi permanece como alternativa. Waybar requiere IPC compatible con el proveedor de configuración usado; el despliegue contempla `waybar-git` para Lua y no fuerza silenciosamente conflictos de paquetes.

## Recuperación

La restauración completa se ha probado en una VM Btrfs con copia de kernel, initramfs y ESP. No cubre automáticamente particiones externas, datos excluidos del snapshot ni ext4. Consulta [SYSTEM_MANAGER.md](SYSTEM_MANAGER.md).

Las mediciones IPC de escritorios no representan latencia visible completa. Una ejecución correcta de pruebas tampoco prueba ausencia de errores. Los criterios abiertos están en [ROADMAP_SYSTEM_V4.md](ROADMAP_SYSTEM_V4.md).
