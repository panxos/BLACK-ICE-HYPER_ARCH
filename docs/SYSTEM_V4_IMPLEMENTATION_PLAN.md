# Plan de sistema — BLACK-ICE 4.0

Estado: implementación y validación, sin release. Fecha: 2026-10-11. Este documento conserva los criterios de aceptación; una función escrita no se considera validada hasta registrar su prueba.

## Estado comprobado — 2026-10-12

Los seis componentes base están implementados. La VM nueva completó instalación con reanudaciones y una recuperación real desde ISO, conservando datos y restaurando paquetes/arranque. Se comprobaron instalación gráfica de paquetes con reintento, proyectos/estados locales de tun0, límites de contenedor y definición/arranque de un laboratorio KVM propio. No se declara completada la aceptación de los seis hitos.

Quedan pendientes primera pasada íntegra del candidato final, matriz BIOS/ext4/LUKS, fallos durante transacciones, retención de archivos de recuperación, VPN externa real, sistema invitado anidado, snapshots de laboratorios y mediciones comparables de diez minutos. S3 virtual bloquea el controlador gráfico y está desactivado en la definición de QA; pausa/reanudación del hipervisor sí se comprobó. Las pruebas físicas de corriente/batería y hotplug requieren una sesión acordada, sin interrumpir trabajo.

Estado público de aceptación: [validación](AUDIT_REPORT.md). Los registros detallados y tareas de sesión se conservan de forma privada. El candidato sigue sin release.

## Orden y dependencias

| Hito | Entrega | Depende de | Condición para avanzar |
|---|---|---|---|
| H0 | VM reproducible y mediciones iniciales | Candidato en `main` | Instalación, arranque y evidencia; fallos documentados |
| H1 | Reanudación segura por módulo | H0 | Cortes inducidos y segunda ejecución sin pérdida de datos |
| H2 | Actualización y recuperación por snapshots | H0, H1 | Restauración real y arranque del estado anterior |
| H3 | Centro de software con trabajos persistentes | H1, H2 | Cancelar/reintentar y conservar coherencia de paquetes |
| H4 | Objetivos y VPN por proyecto | H1 | Proyectos aislados y estado real de túnel |
| H5 | Laboratorios con límites | H2, H3 | Recursos y aislamiento comprobados |
| H6 | Matriz automatizada y pruebas físicas | Todos | Gates de estabilidad y rendimiento aprobados |

H4 puede avanzar en paralelo con H2/H3. La infraestructura de pruebas comienza en H0 y acompaña cada hito. La duración se estima después de medir la primera instalación; no se fija una fecha de release antes de validar recuperación.

## Contratos compartidos

- Mantener Bash para instalación base y Python/GTK para Control. Separar ejecución y presentación para compartir backend entre CLI e interfaz gráfica.
- Cada operación tiene `id`, versión de esquema, versión del proyecto, parámetros sin secretos, estado, fechas, intentos y resultado verificable. Estados: pendiente, ejecutando, completada, fallida, cancelada e interrumpida.
- Escrituras atómicas y bloqueo único. Estado del sistema en `/var/lib/black-ice/`, propiedad de root; preferencias y proyectos en `$XDG_STATE_HOME/black-ice/`, privados. No utilizar registros para guardar contraseñas.
- Interfaz sin privilegios. Acciones privilegiadas limitadas a operaciones y argumentos validados; nunca aceptar comandos arbitrarios, rutas escapadas o código de una configuración personal.
- Reutilizar `config/apps.json`, `black-ice-doctor`, migración Lua y scripts de actualización existentes. Migrar formatos con copia verificable y lector compatible antes de retirar el anterior.
- Las notificaciones muestran etapa, resultado y acción recuperable. Conservar un registro acotado y exportable, con datos sensibles ocultos.

## 1. Reanudar instalaciones por módulo

Registrar una huella de configuración y versión de cada módulo, UUID del destino y comprobaciones de salida. Después de un reinicio, volver a detectar disco y montajes; una ruta `/dev/vda` por sí sola no identifica el destino. Una tarea marcada como completada debe superar su verificación antes de omitirse.

Separar preparar disco, instalar paquetes, configurar sistema, usuario, arranque y escritorio. El particionado nunca se repite automáticamente: una interrupción durante ese paso exige inspección del esquema y confirmación específica antes de cualquier nuevo borrado. En los demás pasos, preferir operaciones idempotentes y reconciliación del estado real.

**Aceptación:** interrumpir después de cada módulo y durante descarga/configuración; continuar con el mismo UUID; rechazar destino diferente y configuración incompatible; no duplicar fstab, hooks, usuarios ni servicios. Conservar los datos escritos por Benjie antes de reanudar. El fallo de un módulo bloquea sus dependientes.

## 2. Actualizaciones con recuperación comprobada

Unificar la actualización de sistema, dotfiles y migraciones bajo una transacción: diagnóstico → comprobar espacio/corriente/red → snapshot → actualización completa firmada → verificación → confirmar. Respetar bloqueo de pacman y configuración personal. No permitir actualizaciones parciales de Arch.

Para Btrfs, comprobar subvolúmenes incluidos y excluidos, configuración Snapper y coherencia de `/usr`, `/etc` y base de datos de paquetes. `/boot` y ESP necesitan una estrategia explícita, porque pueden estar fuera del snapshot raíz. Mantener una entrada de arranque de recuperación funcional y registrar kernel/initramfs/EFI asociados. Un snapshot creado sin prueba de restauración no certifica recuperación.

En ext4/XFS sin mecanismo equivalente, mostrar claramente la cobertura disponible; no ofrecer reversión de sistema completa basándose solo en dotfiles. No reemplazar el sistema raíz mientras está ejecutándose: restaurar mediante arranque de recuperación y comprobaciones posteriores.

**Aceptación:** en clon de QA inducir fallo de hook, espacio insuficiente, actualización interrumpida y configuración de escritorio inválida. Restaurar, reiniciar y comprobar versión de paquetes, kernel, acceso, red y datos de usuario. Limitar retención por espacio y conservar siempre el último punto comprobado.

## 3. Centro de software

Extender el selector existente con detalle de aplicación, origen, paquetes/dependencias, tamaño cuando el backend lo pueda estimar y cola persistente. Conservar selección por perfil, grupos, búsqueda y elementos individuales. Distinguir instalado, pendiente y fallido consultando pacman, no solo el catálogo.

El backend publica eventos de progreso; la UI no analiza mensajes traducidos de una terminal para decidir éxito. Si no hay porcentaje fiable, mostrar etapa y contador. Ejecutar una transacción pacman a la vez. Revisar cambios AUR de forma explícita; compilar como usuario normal y elevar solo la instalación necesaria. Cancelar de forma segura entre transacciones; una operación ya comprometida debe reconciliarse antes de reintentar.

**Aceptación:** cerrar y reabrir Control durante descarga; recuperar la cola; reintentar solo fallos; manejar dependencia conflictiva, falta de red y bloqueo externo; desinstalar mostrando dependientes afectados; conservar aplicaciones instaladas fuera de BLACK-ICE. El perfil mínimo no instala herramientas opcionales por defecto.

## 4. Laboratorios KVM y contenedores

Plantillas declarativas con motor, imagen y hash/origen, CPU, RAM, almacenamiento, red y vencimiento opcional. Detectar capacidades antes de mostrar controles. Reutilizar libvirt y el motor instalado; evaluar Podman rootless como alternativa sin sustituir Docker ni añadir al usuario automáticamente a grupos privilegiados.

Red aislada o NAT por defecto, sin puertos expuestos al host/LAN salvo selección explícita. Límites efectivos por VM y cgroups en contenedores. Mostrar consumo y presupuesto agregado antes de iniciar. Iniciar bajo demanda y detener al cerrar proyecto cuando esa política esté seleccionada. No tocar máquinas ajenas al registro de BLACK-ICE.

**Aceptación:** comprobar límites dentro del invitado/contenedor y en el host; rechazar reservas superiores al presupuesto; verificar aislamiento con pruebas de conectividad; importar y exportar plantilla sin secretos; limpiar solo recursos propios tras mostrar lo que se retirará. Ensayar snapshot/restauración de un laboratorio desechable.

## 5. Objetivos y VPN por proyecto

Crear proyectos con nombre, objetivos validados, notas locales, interfaz de túnel y referencia a perfil VPN. Conservar compatibilidad con Set Target y el módulo Waybar. Sin objetivo activo: `No target`. VPN de laboratorio activa únicamente cuando existe `tun0` con dirección válida; mostrar icono HTB verde o `No conectado` rojo según estado real. No deducir conexión de un proceso OpenVPN existente.

Cambiar proyecto actualiza objetivo y preferencias de VPN de forma atómica; iniciar/desconectar túnel requiere acción visible y no afecta VPN ajenas. Guardar perfiles privados fuera del repo y credenciales en el almacén del sistema; no exportarlas con el proyecto. Validar IP/hostname sin ejecutar texto como shell.

**Aceptación:** dos proyectos con objetivos diferentes, cambio sin filtraciones; túnel caído, interfaz sin IP, reconexión y VPN externa; importación de perfil inválido; reinicio de Control conservando proyecto activo. Eliminar proyecto no elimina laboratorios o credenciales sin selección explícita.

## 6. Pruebas automáticas y rendimiento

Separar verificaciones estáticas/unitarias, integración en VM y pruebas físicas. Cada informe incluye versión del candidato, hashes, entorno, duración, evidencias y estados aprobado/fallido/no verificado. Una nueva versión no se publica automáticamente al pasar QA.

**Matriz mínima:** UEFI y BIOS; Btrfs y ext4; LUKS activado/desactivado; perfil mínimo y escritorio; instalación interrumpida; segundo despliegue; actualización y recuperación; red ausente; usuario sin privilegios. Añadir XFS/F2FS solo si continúan ofreciéndose y pasan una matriz propia.

**Escritorio:** SDDM → Hyprland, Lua, Waybar y Conky; todos los temas con recursos presentes; editor personal sin alterar originales; font/iconos; 1/2/3 monitores y hotplug; menú, atajos, Kitty y módulos condicionales.

**Rendimiento:** medir arranque y apertura de Control/menú, CPU/RAM en reposo durante 10 minutos y con carga definida, sin descargas de fondo. Comparar medianas de tres ejecuciones en el mismo equipo. Proponer inicialmente una regresión máxima del 15% frente al baseline, revisable según ruido observado. No comparar cifras de VM con las de s3th como si fueran equivalentes.

**Energía:** en VM comprobar suspensión/reanudación cuando el hipervisor lo permita. En s3th probar físicamente corriente/batería, tapa, inactividad y recuperación de pantallas: con corriente no debe suspender por inactividad; en batería debe respetar política configurada. Nunca programar suspensión física silenciosa durante trabajo del usuario.

## Gates de publicación

Integridad Git recuperada o migración explícitamente acordada a checkout sano; pruebas críticas aprobadas; recuperación demostrada; originales/procedencia y límites del reescalado documentados; revisión del diff sin secretos; checklist de conversación actualizado. Publicar requiere una instrucción posterior: esta etapa permanece local.
