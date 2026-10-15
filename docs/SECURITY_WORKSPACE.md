# Puesto de seguridad

[English](SECURITY_WORKSPACE.en.md) · [Guía](GUIDE.md) · [Pendientes](PENDING.md)

El candidato reúne privacidad de red, perfiles forenses opcionales, laboratorios locales y gestión de casos. Cada indicador tiene un alcance concreto; ninguno acredita por sí solo que el equipo sea invulnerable.

## Tor del sistema

El flujo principal utiliza **tus aplicaciones instaladas y cualquier terminal habitual**. El botón Tor no abre un Bash especial. Un clic solicita activar/apagar y el clic derecho abre controles. Su tipografía y colores siguen la paleta del tema, con texto corto `○ Tor`, `◌ Tor`, `● Tor` o `! Tor`. La explicación completa vive en el tooltip.

En **Control → Sistema → Seguridad** puedes apagarlo y elegir **Mostrar Tor en la barra**. Ocultar el indicador conserva el estado de Tor. La preferencia de visibilidad es global para todos los temas, incluidos diseños compactos.

| Estado | Significado |
|---|---|
| Apagado | No hay modo Tor activo del sistema |
| Conectando | Preparación del filtro/cliente |
| Activo | Reglas efectivas, servicio y salida Tor comprobados |
| Sin verificar | Fallo o comprobación con más de 45 segundos |

El cliente tiene un usuario exclusivo `black-ice-tor`, configuración independiente y límites de 512 MiB, una CPU y 128 tareas. La tabla `inet black_ice_tor` se añade sin sustituir el firewall existente. Su filtro persiste antes de la red cuando el modo está habilitado.

Activarlo afecta al tráfico de todas las cuentas del equipo. Idioma y visibilidad son preferencias de cada usuario; no crean conexiones Tor independientes.

| Tráfico | Política activa |
|---|---|
| TCP IPv4 de procesos locales | Redirección a `127.0.0.1:19040` (TransPort) |
| DNS IPv4 UDP | Redirección a `127.0.0.1:19053` (DNSPort) |
| TCP del UID dedicado | Salida necesaria para construir circuitos Tor |
| Loopback | Permitido |
| DHCP IPv4 broadcast, 68→67 | Excepción local explícita |
| IPv6 y otros UDP/ICMP | Bloqueados |
| Reenvío de puentes de invitados | Bloqueado |

Un contenedor rootless que utiliza sockets del usuario sigue el tratamiento de los procesos locales; no equivale al reenvío de un puente. No se anuncian VMs como conectadas por Tor: el tráfico reenviado se corta.

Las conexiones existentes pueden interrumpirse al activar. VPN, QUIC, videollamadas, descubrimiento de red y herramientas UDP/raw pueden fallar. TCP hacia direcciones privadas tampoco se excluye silenciosamente: Tor no sustituye acceso al laboratorio local. Planifica el uso de VPN y Tor como modos diferentes.

Tor no borra hostname, usuario, contenido ni identificadores enviados por las aplicaciones. Un navegador normal conserva sus características de identificación; para navegar con sus defensas específicas utiliza Tor Browser. El modo no protege contra una cuenta root comprometida, kernel manipulado o malware. [Manual Tor](https://man.archlinux.org/man/tor.1.en), [seguridad de Tor Browser](https://support.torproject.org/tor-browser/security/using-tb-safely/).

## Activar, comprobar y apagar

```bash
black-ice-privacy enable
black-ice-privacy status
black-ice-privacy verify
curl --noproxy '*' https://check.torproject.org/api/ip
black-ice-privacy disable
```

`enable`, `disable` y la comprobación solicitada utilizan la autorización normal con `pkexec`. Si faltan Tor/nftables, se solicita instalar únicamente esos requisitos mediante el helper existente. El daemon y el filtro necesitan los controles privilegiados instalados; copiar solo el botón no es suficiente.

El verificador usa `curl` normal, sin proxy explícito, para comprobar el camino del sistema. Un resultado `IsTor: true` y una IP global son necesarios para el estado activo. El guard comprueba también la huella de su tabla; si cambió o desapareció, intenta restaurarla y publica fallo. No se afirma resistencia frente a root que manipule el guard.

Si Tor cae, **el filtro se conserva**. No existe recuperación automática a conexión directa. Si quieres volver a la red habitual, apágalo desde Control o la CLI. Desde una terminal local, la recuperación administrativa es:

```bash
sudo /usr/lib/black-ice/system-tor disable
```

Este comando elimina solamente la tabla de este modo y detiene/deshabilita sus servicios. No vacía el ruleset ni detiene Tor ajeno. La conexión directa vuelve por una acción explícita.

## Actualizar BLACK-ICE

El comando unificado aplica mejoras del proyecto sobre una instalación existente, sin reinstalar Arch ni actualizar sus paquetes. Primero revisa el plan:

```bash
black-ice-update --dry-run
```

Luego aplica la actualización:

```bash
black-ice-update
```

El comando usa el checkout registrado durante la instalación. Actualiza Git con `--ff-only`, migra dotfiles sin reemplazar en bloque la configuración personal, instala BLACK-ICE Control y componentes de usuario, y finalmente solicita `sudo` para actualizar una lista acotada de archivos y unidades de sistema. Si Git detecta cambios locales, se detiene para protegerlos. Revisa esos cambios y, si ya tienes una copia revisada, puedes usar `black-ice-update --no-pull`. También puedes indicar el checkout con `black-ice-update --repo /ruta/BLACK-ICE_ARCH`.

`--dry-run` no descarga ni escribe archivos. Cada instalador protege sus propias operaciones; si falla un paso, los siguientes no corren y puedes repetir el comando después de resolverlo. No existe una reversión global atómica entre los archivos de usuario, root y systemd. Este flujo no instala paquetes, no ejecuta `pacman -Syu`, no vuelve a desplegar el escritorio, no reinicia la sesión ni activa Tor. Si Waybar no refleja una mejora, reiníciala manualmente con `~/.local/bin/waybar_start.sh`.

El entorno Tor antiguo de Podman protegía únicamente su propia terminal y fue retirado del candidato y del instalador. Al actualizar una instalación anterior, los archivos locales y recursos de ese entorno no se convierten automáticamente en estado del nuevo daemon; revisa el almacén privado antes de limpiar datos antiguos.

## Laboratorios y recursos

Alpine, Debian y Alpine live permiten practicar comandos/sistemas. Juice Shop y WebGoat usan imágenes oficiales fijadas por digest, redes internas y puertos de localhost. WebGoat utiliza UID/GID 1001; cambiarlo indiscriminadamente impedía leer su JAR.

Los recursos administrados tienen identidad, límites, comprobación del motor y almacenamiento propio. Caché e ISOs se inventarían antes de una limpieza seleccionada; no se ejecuta un prune global. La preparación se detiene si excede el presupuesto, pero **no hay cuota física continua** para todo dato posterior.

Los laboratorios nuevos vencen por defecto a los 120 minutos; el rango configurable es 15–1440. El servicio apaga recursos registrados vencidos y conserva datos/definición. Sin servicio, se debe aplicar el vencimiento desde Control o la CLI.

```bash
black-ice-system resources status
black-ice-system resources configure --cache-mib 8192 --ttl-minutes 120
black-ice-system resources cleanup-plan
black-ice-system resources expire
```

## Forense opcional

Los perfiles de disco/recuperación, memoria, metadatos, firmware y Autopsy reutilizan el catálogo. **Fuente / tamaño** consulta origen; **Comprobar** distingue instalación, ejecutable y respuesta inicial. No se instalan por defecto ni se da por validado un análisis real porque `--help` respondió.

```bash
black-ice-system forensics profiles
black-ice-system forensics status memory
black-ice-system forensics install memory
black-ice-system jobs run
```

El último comando procesa trabajos pendientes: revisa la cola antes de ejecutarlo. La aceptación de todos los perfiles y las ampliaciones E01, YARA/TestDisk y sandbox de malware permanecen en [pendientes](PENDING.md).

## Casos y evidencias

Un caso tiene objetivos autorizados por hostname exacto o IP/CIDR, VPN opcional por UUID y notas privadas. La comprobación previa consulta alcance y conexión activa; no limita automáticamente herramientas externas.

Las evidencias son archivos regulares copiados, con SHA-256, límites y registro encadenado. La verificación detecta alteraciones. El resumen saneado omite notas, alcance, VPN, nombres originales y otros identificadores; conserva datos técnicos de integridad. Los hashes encadenados no sustituyen una firma digital.

## Qué se comprobó

En VM: conexión TCP ordinaria de Benjie confirmó Tor; DNS externo fue redirigido; UDP e IPv6 fueron rechazados; el reenvío de una red de prueba incrementó el contador de descarte. La caída de Tor mantuvo el filtro y bloqueó conexión normal; reactivación y apagado recuperaron los modos correspondientes. Tras reinicio, el filtro quedó activo antes de NetworkManager y una conexión normal volvió a confirmar Tor.

La aceptación general de instalación, hardware, cuotas, perfiles forenses y publicación sigue abierta. Consulta [la lista completa](PENDING.md); el resultado de una VM no se presenta como validación de todo hardware.
