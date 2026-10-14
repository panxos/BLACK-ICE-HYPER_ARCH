# Escritorio: varias pantallas y estabilidad

## Escritorios locales

Cada monitor conserva cinco posiciones de escritorio. **Super+1…5** selecciona una posición en la pantalla enfocada; **Super+Alt+1…5** envía allí la ventana. La barra muestra números locales o los símbolos del tema.

El registro privado `~/.config/black-ice/workspaces.json` conserva identificadores por salida. La primera reconciliación adopta escritorios existentes para no trasladar ventanas. Desconectar un monitor no elimina su asignación; reconectarlo reutiliza el grupo.

`black-ice-workspaces.service` escucha eventos de monitores y recarga, con debounce; no sondea cada cambio de escritorio. El bloqueo distingue instancias de Hyprland. Las reglas persistentes preparan los escritorios y evitan creación tardía al primer uso.

Se probaron Hyprlang y Lua con tres salidas aisladas, primera/repetida selección, reconexión y bindings sin duplicados. El tiempo IPC medido no equivale a latencia gráfica. Falta confirmar fluidez física bajo carga habitual.

## Conky

En **Super+Alt+T → Estudio → Fondo y Conky**, elige automática, todas o varias casillas. La galería ofrece el mismo control. Las preferencias conservan salidas desconectadas.

Un supervisor comparte métricas entre instancias por monitor. El backend necesita enfocar brevemente cada salida al crear su superficie, y restaura el foco cuando corresponde. No cambia el foco durante actualizaciones normales. **Aplicar** mantiene la galería abierta; **Cerrar** la termina.

## Fondos

Una pantalla utiliza la imagen individual. Las salidas alineadas comparten un panorama declarado; el portátil en otra fila mantiene el fondo individual. Las selecciones manuales tienen prioridad.

Anubis-Sethek vuelve al maestro local centrado de 3840×1848 y al modo **Escena única**. En la disposición de dos pantallas 1920×1080 arriba y portátil 1366×768 abajo, utiliza un lienzo de 3840×1848 y recortes sin reescalado. El portátil muestra la continuación inferior, sin repetir la cara. La extensión lateral rechazada se retiró de las fuentes. Comparar o sustituir este maestro por el aprobado de otro equipo requiere recuperar ese archivo; no se afirma identidad sin comparar hashes.

## Galerías y barras

Las galerías muestran controles antes de decodificar fondos y generan miniaturas persistentes en un trabajador de baja prioridad. No cambian todos los temas al abrirse. Se retiró el generador antiguo que rotaba el escritorio para capturarlo.

Las barras se validan antes de reemplazarse. Se eliminó la animación infinita del borde y se redujo la transición predeterminada de escritorios; las preferencias personales se conservan. Docker/VM comprueban disponibilidad periódicamente y muestran N/D si el servicio no responde.

Se reprodujo una pausa de 1925 ms en el primer clic del proceso Waybar: su detección de proveedor consultaba `systeminfo`. El [backport local](WAYBAR_FIRST_CLICK.md) utiliza `status` y redujo ese caso a 1,94 ms en prueba aislada. Treinta segundos de reposo no reprodujeron el bloqueo original; la inactividad física prolongada requiere comprobación independiente.

## Notificaciones y USB

SwayNC sigue la paleta, conserva historial y acciones. Clic derecho en el engranaje abre notificaciones; clic derecho en una IP confirma su copia.

`black-ice-removable.service` supervisa udiskie. Los avisos de montaje ofrecen abrir archivos o terminal y el icono permite desmontar/expulsar. La migración corrige únicamente el patrón generado con tiempos 8000/4000 a 8/4 segundos.

El evento simulado con el manejador real mostró y retiró el aviso, conservando historial. La reconexión física y sus acciones todavía requieren revisión. [Validación](AUDIT_REPORT.md).

## Diagnóstico de Conky y fondos de acceso: 2026-10-13

La revisión detectó una regresión posterior a las comprobaciones anteriores. No se aplicó una corrección durante este diagnóstico.

- **Conky:** la actualización de paquetes de las 10:18:14 cambió 1.24.2-1 por 1.25.2-1. El journal del servicio registró 1.769 abortos al momento de la consulta con `set_font(unsigned int): Assertion f < pango_fonts.size() failed`. El supervisor seguía activo y relanzaba el proceso; Hyprland no mostraba capas Conky en la consulta realizada. Los archivos instalados del supervisor y `draw.lua` coinciden por SHA-256 con el repositorio.
- **Causa compatible con el código oficial:** Conky 1.25.2 ejecuta `setup_fonts()` antes de `load_fonts()` en Wayland. [Conky 1.25.3](https://github.com/brndnmtthws/conky/releases/tag/v1.25.3) invierte ese orden para corregir la inicialización. La base local de paquetes todavía ofrece 1.25.2-1; no se refrescaron repositorios ni se instaló otra versión. La recuperación con el parche sigue sin verificar en este equipo.
- **Bloqueo:** `black-ice-appearance.render()` sustituye una sola ruta en `hyprlock.conf.in`; su bloque `background` tiene `monitor =` vacío. La configuración instalada apunta al maestro Anubis de 3840×1848 para todas las salidas. No reutiliza los recortes de `black-ice-wallpaper` ni los regenera al conectar pantallas.
- **SDDM:** el tema activo es `black-ice-obsidian`, con un recurso estático de 1672×941. Su QML utiliza `Image.PreserveAspectCrop` y una única ruta `config.background`. `sddm_preview()` copia un solo fondo; no calcula un panorama o recortes por salida. Adaptar la imagen al rectángulo no implementa la continuidad entre pantallas.
- **Verificación insuficiente:** `black-ice-doctor` no comprueba Conky. El supervisor publica PID/salida después de crear la capa, pero ese estado puede sobrevivir brevemente al aborto posterior del hijo. Las pruebas de reconciliación usan procesos simulados y no detectan una regresión del binario instalado.

Se ejecutaron 10 pruebas de fondos y 24 de monitor, todas aprobadas. Esto valida esa lógica, sin demostrar renderizado de Conky ni fondos multimonitor de acceso. Solo estaba conectada eDP-1 de 1366×768; no se probó reconexión física, no se bloqueó la sesión y no se reinició SDDM.

Orden de corrección pendiente: resolver la regresión de Conky y comprobar dibujo sostenido; reflejar caídas de hijos y limitar reintentos; generar fondos Hyprlock por salida; implementar la geometría de SDDM en el propio acceso, donde no existe la sesión Hyprland del usuario. Después, comprobar una, dos y tres pantallas, escalas mixtas y reconexión. Los demás controles del candidato permanecen en [el roadmap](ROADMAP_SYSTEM_V4.md).

## Corrección aplicada el 2026-10-13

El diagnóstico anterior describe el estado previo a esta corrección.

**Conky:** instalada la fuente oficial 1.25.3 en `~/.local/libexec/black-ice/conky-wayland/`, con Cairo y Lua 5.4. El paquete 1.25.2 del sistema permanece intacto. El selector comprueba versión de paquete, hashes de los recursos y ejecución; ante un paquete corregido vuelve al sistema. Si 1.25.2 no tiene corrección local válida, comunica el error antes de generar abortos. El supervisor detecta caídas posteriores a la creación de capa y espera 5, 10, 20… hasta 300 segundos entre intentos; una instancia estable durante 30 segundos limpia el contador. El servicio limita los volcados de memoria.

Doctor y `black-ice-conky status` comprueban PID, ausencia de estado zombi y capa visible en la salida correcta. El verificador de postinstalación utiliza ese estado. Conky volvió a dibujar en la pantalla física eDP-1 y generó las veinte vistas previas. Se conserva la variante Fracture y las preferencias del usuario.

**Hyprlock:** los recortes del escritorio se incluyen en bloques por conector, sobre un fondo general de reserva. `black-ice-wallpaper prepare` no cambia el escritorio. `black-ice-lock` prepara en un máximo de cinco segundos y ejecuta Hyprlock aunque la preparación falle. Se migró el comando generado de Hypridle y se relanzó su proceso para leerlo; la política de energía se conserva. Los ajustes de bloqueo personales distintos de la plantilla no se reemplazan. Una pantalla añadida cuando el bloqueo ya está activo recibe el fondo general; la siguiente activación regenera todos los recortes. El renderizado del bloqueo real y su autenticación siguen pendientes de prueba física.

**SDDM:** el fondo adaptativo usa las pantallas reales del greeter. Una pantalla conserva la imagen individual; los modos espejo, panorama por fila y escena completa calculan su región. Las agencias incluyen panoramas y el tema inicial copia el maestro Anubis de 3840×1848. Se actualizaron los cinco temas locales de la familia BLACK-ICE, conservando su selección, paletas y fuentes; SDDM no se reinició. El modo de prueba del greeter dibujó Anubis en Xvfb y se inspeccionó la captura. Tres salidas simuladas verificaron los píxeles esperados de izquierda, derecha y portátil con Qt Quick.

La instalación desde cero tiene su recorrido y pruebas en [INSTALLER_V4.md](INSTALLER_V4.md). Quedan pendientes el acceso real tras cerrar sesión, reconexión física y escala mixta; solo eDP-1 estaba conectada. El verificador global de postinstalación detectó además que s3th no tiene `paru`: el despliegue nuevo lo instala en su etapa de repositorios y la comprobación es válida. No se instaló un helper adicional para ocultar esa diferencia del equipo existente.

Recuperación local: `~/.local/state/black-ice/access-fix/20261013/restore.json` conserva los archivos anteriores; el paquete Conky y la selección de SDDM no cambiaron. Para reconstruir la corrección de Conky ejecuta `python3 scripts/build-conky-wayland.py --apply`; su segunda aplicación verifica el resultado y omite la compilación. No se publicó ni se transfirió el proyecto a h0ruz.
