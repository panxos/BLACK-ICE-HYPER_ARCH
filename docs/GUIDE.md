# Guía de BLACK-ICE ARCH

[English](GUIDE.en.md) · [Documentación](README.md) · [Pendientes](PENDING.md)

Esta guía recorre el candidato 4.0.0-dev.2. La rama remota puede contener una revisión anterior. Para evaluar el flujo completo utiliza una VM desechable antes de un equipo con datos.

## Instalar y reanudar

La fase base se ejecuta desde una ISO oficial de Arch como root. Elige disco, sistema de archivos, cifrado opcional, usuario y arranque. La confirmación de borrado es específica del disco. La configuración local deriva de `config/install.conf.example`; contraseñas y planes privados no se incluyen en Git.

Después del reinicio, entra como el usuario creado y ejecuta `bash deploy_hyprland.sh`. El despliegue prepara repositorios, Hyprland, terminal, temas, software, SDDM y servicios. La selección de aplicaciones admite perfiles, grupos y paquetes individuales. Cancelar omite lo opcional. Revisa AUR y evita automatizar código sin examinarlo.

```bash
bash deploy_hyprland.sh --dry-run --profile minimal
bash deploy_hyprland.sh --profile minimal
bash deploy_hyprland.sh --resume
```

`--resume` comprueba huellas, destino y resultados antes de omitir módulos. No repite el particionado automáticamente. Si pacman está ocupado, espera o revisa el proceso; no borres su bloqueo. Si sudo vence, el módulo pide autorización normal. [Instalador](INSTALLER_V4.md) y [recuperación de repositorios](REPOSITORY_RECOVERY.md).

## Primer acceso

Abre Control con el engranaje o **Super+Alt+T**. En Sistema puedes ajustar audio/brillo y escoger [idioma](LANGUAGE.md). Apariencia reúne temas, lanzador, fondos y Conky. Red y Bluetooth utilizan los servicios reales disponibles; hardware ausente no se presenta como conectado.

**Super+Enter** abre Kitty; **Super** o **Super+D**, el lanzador. **F1** consulta los atajos cargados. Las teclas personales pueden variar; esa ventana es la referencia de la sesión.

## Temas y perfiles

La [galería](THEMES.md) contiene 54 temas. Aplicar coordina barras, terminal, menús, notificaciones y fondos. Los originales permanecen disponibles cuando creas un perfil.

En Estudio, comienza con un tema base, cambia su nombre y ajusta:

| Pestaña | Uso |
|---|---|
| Perfiles | Cargar, exportar/importar y recuperar perfiles |
| Posiciones | Ordenar módulos por zonas y mover Conky |
| Barras | Elegir distribución, geometría, altura y opacidad |
| Fuentes y colores | Tipografía de escritorio/datos y paleta |
| Módulos | Mostrar, ocultar y recuperar módulos |
| Fondo y Conky | Imagen, geometría de pantallas y telemetría |
| Inicio de sesión | Revisar y preparar SDDM para el próximo acceso |

**Guardar perfil** conserva el archivo. **Guardar y aplicar** también cambia el escritorio. Las cifras del preview son ilustrativas. Eliminar un perfil personalizado lo envía a la papelera; su fondo se conserva y el perfil puede restaurarse. El tema activo requiere cambiar primero a otro.

En Conky, **Aplicar** no cierra la galería. Puedes elegir una pantalla automática, todas o una lista. Los sensores ausentes no se inventan: en VM se muestran datos de uso o N/D según el componente. [Estudio](THEME_STUDIO.md) y [monitor](DESKTOP_MONITOR.md).

## Pantallas, fondos y escritorios

Una pantalla utiliza una imagen individual. Los panoramas automáticos se reparten por filas; Escena única utiliza la unión geométrica de las pantallas. Un portátil ubicado debajo puede tener fondo independiente en modo por filas. Escala mixta y reconexión física requieren la aceptación documentada en [pendientes](PENDING.md).

Hay cinco escritorios locales por monitor. **Super+1…5** cambia en el monitor enfocado; **Super+Alt+1…5** mueve la ventana. Identificadores persistentes mantienen los grupos al reconectar. [Estabilidad](DESKTOP_STABILITY.md).

## Tor del sistema

El botón Tor aplica un proxy transparente a TCP IPv4 y DNS. Utiliza tus terminales y herramientas instaladas; la consola Tor aislada fue retirada. IPv6, UDP restante y reenvío de invitados se bloquean. El filtro sigue activo si Tor cae y solo el apagado explícito recupera la conexión normal.

**Control → Sistema → Seguridad** ofrece apagado y visibilidad. Ocultar el módulo no apaga Tor. Lee [alcance, instalación y emergencia](SECURITY_WORKSPACE.md) antes de activarlo. No equivale a proteger contra malware, root comprometido o identificación por contenido.

## Software y recuperación

El centro de software presenta catálogo, origen, selección y trabajos. La cola conserva errores y reintentos; una comprobación de ejecutable no demuestra todas las funciones de la aplicación. La eliminación y actualización deben revisarse por sus dependencias.

La recuperación completa requiere Btrfs con la disposición soportada. El punto incluye snapshot de raíz y archivos de arranque/ESP. Se restaura desde una ISO, con el sistema de destino offline y el identificador confirmado. Solo después de arrancar se marca como verificado. Revertir dotfiles no recupera paquetes, kernel ni ESP. [Gestores](SYSTEM_MANAGER.md).

## Laboratorios y casos

En Laboratorios elige plantilla y nombre, comprueba requisitos y confirma **Crear y abrir**. Alpine sirve para comandos ligeros; Debian incluye Bash; Alpine live prueba una VM; Juice Shop y WebGoat ofrecen ejercicios web solo en localhost. Importar una imagen propia calcula su hash, pero ese hash no acredita su procedencia.

El presupuesto predeterminado es 4 vCPU, 4096 MiB y 60 GiB de discos reservados. La preparación comparte caché propia y verifica límites; no impone una cuota física continua. Los recursos nuevos tienen vencimiento configurable; el servicio los apaga y conserva su definición/datos. Borrar es una acción separada. [Laboratorios](LABORATORIES.md).

En Seguridad crea un caso con objetivos autorizados y VPN opcional por UUID. Antes de trabajar, comprueba alcance/VPN. Importa evidencias regulares: se copian con SHA-256 y registro encadenado. El resumen saneado omite identificadores y notas; no equivale a firma digital ni controla herramientas externas. Los perfiles forenses son opcionales y tienen comprobaciones propias. [Puesto de seguridad](SECURITY_WORKSPACE.md).

## Energía, avisos y diagnóstico

El perfil automático distingue corriente y batería. La política existente restringe suspensión a batería; no se cambia autenticación para resolver un fallo visual. Comprueba suspensión y reconexión en hardware real. [Energía](AUTOMATIC_POWER.md).

El centro de notificaciones conserva historial. Los avisos USB ofrecen acciones de archivos/terminal; su reconexión física permanece en aceptación. Docker y VM aparecen al existir sus herramientas, con revisión periódica.

```bash
black-ice-doctor
black-ice-doctor --json
bash tests/post-install-validate.sh
```

Doctor comprueba componentes concretos; el verificador de instalación requiere ejecutarse como el usuario del escritorio. Un resultado favorable no reemplaza pruebas físicas ni la matriz completa.

## Actualizar con revisión

```bash
bash dotfiles/bin/dotfiles-update --no-pull --dry-run
bash dotfiles/bin/dotfiles-update --no-pull
```

Inspecciona el plan y conserva los manifiestos de reversión. La [migración Lua](HYPRLAND_LUA_MIGRATION.md) prepara el próximo acceso sin obligar a cerrar la sesión actual. Para los controles nuevos, utiliza [la actualización selectiva](SECURITY_WORKSPACE.md#actualizar-los-controles).

## Antes de publicar

Ejecuta `bash scripts/check-project.sh`; todas las pruebas GTK corren en Xvfb para no abrir ventanas de test en el escritorio. Revisa la distribución y consulta [todos los pendientes](PENDING.md). Quedan pruebas de matriz, fallos transaccionales, hardware, rendimiento y licencias. El candidato no se anuncia como libre de errores ni como release publicado.
