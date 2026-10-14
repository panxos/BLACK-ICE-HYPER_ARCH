# Pendientes y criterios de cierre

[English](PENDING.en.md) · [Guía](GUIDE.md) · [Roadmap](ROADMAP_SYSTEM_V4.md)

Estado del candidato local 4.0.0-dev.2, actualizado 2026-10-14. Esta lista reúne aceptación pendiente y propuestas futuras. No convierte una propuesta en función implementada ni una comprobación de VM en aceptación física.

## Bloqueos antes de release

| Área | Pendiente | Se cierra con |
|---|---|---|
| Instalación | Repetir el ciclo completo desde disco vacío después de agregar `uwsm` como dependencia crítica | Disco vacío, acceso, red, software y segunda ejecución preservando datos; el ciclo limpio anterior detectó la falta de `uwsm` al iniciar SDDM y el código ya está corregido |
| Matriz | BIOS, ext4 y LUKS; combinaciones soportadas | Registros reproducibles de instalación, reinicio y recuperación |
| Transacciones | Falta de espacio, hooks fallidos e interrupciones dentro de actualización/instalación | Abortos controlados y recuperación comprobada sin éxito falso |
| Recuperación | Retención de archivos de arranque, cuotas y fallos adicionales | Restauraciones reales con kernel, paquetes, ESP y datos consistentes |
| Software | Aplicaciones opcionales y fuentes AUR seleccionadas | Instalación/inicio de cada selección; errores y reintentos verificables |
| Hardware | Batería/corriente, tapa, suspensión y recuperación | Pruebas físicas; la pausa del hipervisor no reemplaza suspensión |
| Monitores | Hotplug, escala mixta y HiDPI | Reconexión física con sesiones, fondos y barras correctos |
| USB | Reconexión y acciones de avisos | Montaje real, abrir archivos/terminal y conservar historial |
| Fluidez | Cambios de escritorios con carga e inactividad prolongada | Revisión física sin fallo intermitente y datos comparables |
| Rendimiento | Baseline equivalente y consumo con/sin Conky | Tres muestras sostenidas de diez minutos en condiciones iguales |
| Licencia | Licencia general del proyecto | Decisión expresa y archivo correspondiente |
| Recursos | Redistribución de fondos, logos y otros recursos externos | Procedencia, permisos y exclusión de lo no redistribuible |
| Distribución | Pack final y componentes nuevos desde una instalación vacía | Manifiesto íntegro, hashes, binarios y servicios contrastados |
| CI | Primera ejecución remota de la definición local | Comprobaciones aprobadas; un cambio inválido debe bloquearlas |
| Publicación | Revisión del diff, commit/tag/release | Autorización posterior y cierre de los bloqueos anteriores |

## Aceptación adicional de seguridad

| Área | Pendiente | Se cierra con |
|---|---|---|
| Tor | Prueba sostenida en hardware y escenarios de VPN/red real | Sin salida directa, estados correctos y reversión comprobada |
| Acceso y wallpaper | Confirmar visualmente SDDM y el escritorio en el próximo login de la VM QA | El tema Mr-Robot y el wallpaper ya están configurados; no se reinició la sesión tras corregirlos |
| Perfiles forenses | Instalar y usar todos los perfiles opcionales | Paquete, ejecutable, sonda y ejercicio real por herramienta |
| Laboratorios web | Aceptación final después de actualizar controles | Localhost, aislamiento, datos, vencimiento y limpieza de recursos QA |
| Caché/vencimiento | Reconexión, reinicio y límites adicionales | Servicio activo, expiración real y limpieza exclusiva de recursos propios |
| KVM anidado | Ampliar el invitado live ya comprobado | Sistema invitado completo, límites internos y snapshot/restauración |
| VPN | Endpoint propio y perfil ajeno | Conexión/reconexión real sin reutilizar conexión u objetivo de otro caso |
| Casos | Ampliar escenarios y ejercicio operacional | Alcance, VPN, evidencias alteradas y exportación revisados con casos reales de prueba |

Tor del sistema ya comprobó en VM TCP normal, DNS redirigido, caída del daemon, UDP/IPv6/reenvío bloqueados, apagado y reinicio con filtro previo a NetworkManager. Se retiró la consola Podman/Kitty anterior; el control no abre terminal y Tor aplica a las aplicaciones del sistema dentro del alcance descrito. Esto no acredita anonimato absoluto ni sustituye Tor Browser.

El 2026-10-14 se probó instalación limpia UEFI/Btrfs sin LUKS, reanudación conservando el sistema y despliegue del perfil mínimo hasta el corte de aceptación configurado. El primer inicio detectó que faltaba `uwsm` para la sesión Hyprland de SDDM; se añadió a los paquetes y a la lista crítica, y la VM QA quedó iniciada con esa dependencia. Falta repetir el ciclo completo de instalación y despliegue usando desde el comienzo este candidato corregido.

## Revisión visual y contenido

- Aprobación humana del parecido del elenco Mr-Robot y los homenajes Condor/Condor Noir.
- Referencia exacta y similitud final de s4vitar, incluida la procedencia del fondo.
- Recuperar y comparar el maestro Anubis aprobado desde el segundo equipo cuando esté disponible, sin enviar archivos hacia él.
- Revisión de perfiles Yael/Varinka y acceso/bloqueo con pantallas físicas múltiples.
- Recursos con detalle 4K nativo: los derivados existentes son reescalados y deben seguir rotulados como tales.
- Mantener revisión visual de ambos idiomas al ampliar controles; traducciones externas y greeters de terceros dependen de sus propios catálogos.
- Control y los veinte diseños de Conky ya usan el idioma seleccionado. La traducción por pruebas de los textos dibujados está cubierta; la apariencia final debe revisarse en una sesión gráfica nueva tras desplegar los archivos actualizados.

## Propuestas futuras

| Propuesta | Falta implementar o ampliar |
|---|---|
| Actualizador unificado | Paquetes, dotfiles y migraciones con una transacción coordinada |
| Centro de software | Desinstalación revisable completa, historial, progreso y archivado de cola |
| Cuotas reales | Límites físicos continuos de imágenes, ISO y datos, por proyecto |
| Diagnóstico exportable | Saneamiento general de IP, rutas personales, tokens y vista previa |
| Packs descargables | Instalar solo recursos elegidos, con integridad y reintento |
| Restauración periódica | Ensayo automático en clon e informe de arranque |
| Proyectos | Abrir notas/terminales/herramientas y confirmar VPN del objetivo |
| Tor Browser | Integración opcional con sus defensas de navegador; no sustituirlo por un navegador común |
| Forense ampliado | Adquisición E01, YARA/TestDisk y ejercicios adicionales |
| Laboratorios | Plantillas AD y sandbox de malware con aceptación específica |
| Editor universal | Proyecto independiente de Hyprland; nombre/stack/prototipo aún sin decidir |

## Continuidad

La copia del segundo equipo continúa aplazada por instrucción expresa. No asumir sincronización ni publicación por estar el proyecto dentro de una carpeta sincronizada.

Algunos cambios históricos conservan casillas desactualizadas: recuperación Git, Lua y previews antiguos tienen evidencia posterior o fueron sustituidos por otro mecanismo. Deben reconciliarse y archivarse con esa evidencia; no corresponde volver a ejecutar el generador retirado ni regresar a versiones 3.x.

La validación técnica está resumida en [AUDIT_REPORT.md](AUDIT_REPORT.md). Los contratos de las seis mejoras siguen en [el plan](SYSTEM_V4_IMPLEMENTATION_PLAN.md). Los detalles de una sesión y sus evidencias privadas no se publican en este listado.
