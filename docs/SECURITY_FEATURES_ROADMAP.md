# Seguridad, pentesting y forense: estado y siguientes pasos

Estado: implementación local y aceptación parcial, 2026-10-14. Uso, arquitectura y límites en [Puesto de seguridad](SECURITY_WORKSPACE.md). Una feature implementada no equivale a despliegue final verificado.

## Accesos actuales de Control

| Acceso | Utilidad y cobertura |
| --- | --- |
| Centro de software | Catálogo opcional, selección por grupos/perfiles, instalación/desinstalación y trabajos persistentes con reintento. Instalación real y conciliación con pacman comprobadas; no se instalaron todas las aplicaciones del catálogo. AUR no disponible requiere revisión manual. |
| Actualizaciones y recuperación | Actualización completa con punto de recuperación Btrfs y copia de arranque. Restauración desde ISO y arranque posterior comprobados en un caso; no es una copia externa de los datos personales. |
| Laboratorios | VMs KVM de sesión y contenedores rootless propios. Cinco plantillas, requisitos, integridad automática, consola y OWASP web local; ver [guía](LABORATORIES.md). No equivale a un laboratorio AD ni una sandbox de malware. |
| Diagnóstico del escritorio | Comprueba ejecutables, archivos/enlaces, configuración Hyprland y dibujo real de Conky. No es un escáner de vulnerabilidades ni una auditoría de red. |

## Privacidad desde Waybar — implementación local

El flujo vigente usa Tor transparente del sistema: TCP/DNS IPv4 redirigidos, IPv6/UDP restante/reenvío bloqueados y apagado explícito. Utiliza herramientas instaladas desde cualquier terminal; el alcance anterior de consola aislada fue rechazado como experiencia principal. No se instala Tor Browser automáticamente ni se garantiza anonimato perfecto. [Tor Project](https://support.torproject.org/tor-browser/security/using-tb-safely/).

El indicador compacto adapta su paleta a todos los temas y muestra detalles al pasar el cursor. Control permite apagar Tor y ocultar el módulo por separado. En VM se comprobó salida de una conexión normal, DNS, caída, bloqueo UDP/IPv6/reenvío y reinicio antes de NetworkManager. Queda aceptación sostenida en hardware y escenarios adicionales.

Tor Browser sigue como integración opcional. El modo de sistema no se presenta como equivalente a una estación/puerta separadas como [Whonix](https://www.whonix.org/wiki/Technical_Introduction). Cambiar solo hostname, User-Agent o una variable no demuestra anonimato. El contenido y la identificación del navegador permanecen fuera del control del proxy.

Los perfiles VPN de HTB/THM y redes internas permanecen separados. Tor SOCKS admite TCP y resolución de nombres; no soporta UDP ASSOCIATE. No prometer compatibilidad con escaneo SYN, UDP o cualquier herramienta por instalar proxychains. [Especificación oficial](https://spec.torproject.org/socks-extensions.html).

## Forense opcional

El grupo Sec-Forense ofrece Autopsy, Sleuth Kit, Volatility 3, Binwalk, Foremost, ExifTool, Steghide, Stegseek y HexEdit. Seguridad incorpora perfiles voluntarios, consulta de fuente/tamaño y comprobaciones de paquete/ejecutable/inicio. Su instalación completa todavía no está acreditada.

Los casos implementan alcance/VPN, notas, copias de evidencias y verificación encadenada. Evaluar PhotoRec/TestDisk, YARA, adquisición E01/RAW y registro de versiones de cada análisis. El montaje de solo lectura por software no sustituye un bloqueador físico cuando el procedimiento lo exige.

Fuentes: [Autopsy](https://www.sleuthkit.org/autopsy/), [Volatility](https://volatilityfoundation.org/the-volatility-framework/), [PhotoRec](https://www.cgsecurity.org/wiki/PhotoRec), [YARA](https://virustotal.github.io/yara/).

## Orden recomendado

1. Completar copia final y revisión visual de Tor/Seguridad en VM y equipo físico cuando el entorno permita sockets gráficos/libvirt.
2. Verificar servicio, vencimientos, limpieza y reinicio reales; el control de preparación implementado no sustituye una cuota física.
3. Validar instalación/uso de todos los perfiles forenses sobre evidencias de prueba.
4. Ampliar recorridos de [Juice Shop](https://owasp.org/www-project-juice-shop/) y [WebGoat](https://owasp.org/www-project-webgoat/) y comprobar alcance de lecciones sin Internet.
5. Integrar el preflight de casos en lanzadores de herramientas; actualmente es una comprobación explícita y no controla comandos arbitrarios.
6. Ampliar el resumen saneado de casos a diagnósticos e informes narrativos, con redacción configurable y vista previa completa.
7. Ejecutar CI, unificar actualización de sistema/dotfiles y programar ensayos de restauración antes de publicar una versión estable.
