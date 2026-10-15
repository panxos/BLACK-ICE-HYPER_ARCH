# Roadmap de sistema

La versión 4.0.0-dev.2 ya incorpora código para reanudación, recuperación, software, proyectos/VPN, laboratorios y QA. Sus criterios completos siguen abiertos; no corresponde anunciar esas seis capacidades como terminadas.

## Primero: cerrar la aceptación del candidato

| Prioridad | Trabajo | Evidencia necesaria |
|---|---|---|
| P0 | Instalación final de principio a fin | Disco vacío, acceso, red y segundo despliegue conservando datos |
| P0 | BIOS/ext4/LUKS y fallos dentro de transacciones | Matriz reproducible, abortos controlados y recuperación |
| P0 | Varias pantallas y energía física | Reconexión, escala mixta, fluidez visible y batería/corriente |
| P0 | Recursos y distribución | Revisión de permisos de redistribución, licencia general y pack final |
| P1 | VPN real y laboratorio anidado | Conexión contra endpoint propio y arranque de invitado completo |
| P1 | Rendimiento comparable | Baseline y tres muestras sostenidas, condiciones iguales |

Instalación UEFI/Btrfs, cortes entre módulos y una restauración offline ya tienen evidencia. Git local vuelve a pasar `fsck`; no permanece como fallo abierto.

## Mejoras nuevas propuestas

El estado de privacidad desde Waybar, forense opcional y laboratorios web está en [Seguridad y pentesting](SECURITY_FEATURES_ROADMAP.md). Ya existe implementación local de Tor, cinco plantillas, perfiles, casos, control de preparación y vencimientos; su aceptación final sigue abierta. Uso y límites en [Puesto de seguridad](SECURITY_WORKSPACE.md).

| Mejora | Qué aporta | Criterio de aceptación |
|---|---|---|
| CI por pull request | Ejecutar sintaxis, linters, pruebas, enlaces y filtros de distribución antes de integrar | Un cambio inválido bloquea la comprobación; ningún job publica una release |
| Actualizador unificado de componentes | Coordinar mejoras de BLACK-ICE en componentes de usuario/root, dotfiles, servicios y migraciones, con diagnóstico y rollback | Actualizar una versión anterior reproducible, comprobar servicios/preferencias y recuperar un fallo inducido |
| Centro de software completo | Desinstalación revisable, historial, progreso por trabajo y archivado de cola | Dependencias preservadas, cola recuperable después de reinicio y errores accionables |
| Presupuestos y vencimiento de laboratorios | Cuotas de imágenes/discos, limpieza por proyecto y tiempo máximo de ejecución | El límite agregado se cumple dentro del invitado y tras reconexión |
| Diagnóstico exportable saneado | Compartir entorno, versiones y fallos sin IP, rutas personales ni tokens | Fixtures con datos sensibles se exportan ocultos; vista previa antes de guardar |
| Paquetes de recursos separados | Descargar solo temas y panoramas elegidos, con manifiesto de integridad | Instalación mínima sin cientos de MB innecesarios; reintento y verificación de hash |
| Restauración ensayada periódicamente | Comprobar que un punto de recuperación arranca en un clon | Informe automático distingue snapshot creado de recuperación comprobada |
| Perfiles de trabajo por proyecto | Abrir terminales, notas y herramientas del objetivo con confirmación de VPN | Cambiar proyecto no reutiliza objetivos ni conexiones ajenas |

CI remota aprobada el 2026-10-15. Caché/vencimientos y resumen saneado de casos tienen implementación parcial de estos criterios: no hay cuota física continua ni diagnóstico general exportable. La actualización entre versiones, los archivos de recursos y los ensayos periódicos siguen pendientes o propuestos. Ninguna fila debe darse por aceptada solo por aparecer en este documento.

## Fuera de este release

El diseñador visual universal de Hyprland se conserva como proyecto independiente. El Estudio actual queda sencillo, con perfiles y vista previa. No se publica release hasta cerrar los bloqueos P0. El [plan de seis componentes](SYSTEM_V4_IMPLEMENTATION_PLAN.md) conserva sus contratos y criterios.
