# Monitor del escritorio

Veinte estilos muestran telemetría real mediante Conky y Cairo sobre Wayland. Las ventanas normales cubren los widgets. Los fondos son translúcidos; las composiciones amplias dejan el centro libre y solo dibujan módulos en parte del escritorio.

| Estilo | Composición |
| --- | --- |
| Fsociety | Franja roja compacta |
| Obsidiana | Cinta angular fina |
| Fracture | Chasis angular inferior con temperatura o uso CPU destacado |
| Signal | Reloj centrado y franja inferior |
| Orbit | Tres instrumentos radiales |
| Ribbon | Cinta compacta con fondo más ligero |
| Terminal | Consola de datos en columnas |
| Pulse | Historial real de carga CPU |
| Atlas | Pantalla completa, instrumentos en las esquinas |
| Horizon | Pantalla completa, reloj superior y dos alas inferiores |
| Observatory | Pantalla completa, instrumentos laterales y actividad inferior |
| Circuit | Pantalla completa, trazos perimetrales y centro libre |
| Polar | Calendario y reloj en anillos concéntricos |
| Chronos | Cronógrafo analógico y subesferas CPU/RAM |
| Nexus | Cuatro brazos curvos conectados a un centro pequeño |
| Gotham | Reloj y fecha con tipografía grande |
| Prism | Instrumentos en rombos flotantes |
| Scope | Tres escalas verticales de carga, RAM y temperatura |
| Stack | Cuatro módulos escalonados en una columna |
| Focus | Reloj circular y datos térmicos agrupados |

## Instalar en Hyprland

Desde el repositorio y dentro de la sesión gráfica:

```bash
sudo pacman -S --needed conky python python-gobject gtk3 ttf-jetbrains-mono
bash scripts/install-desktop-monitor.sh
```

Requiere Conky con Wayland, Cairo y `conky_surface()`; verificado con el paquete Arch 1.24.2. El instalador copia solo los archivos del monitor y habilita `black-ice-conky.service` para la sesión Hyprland. En configuraciones `.conf`, agrega una inclusión con los atajos; no reemplaza la configuración principal. En Lua, usa el selector de aplicaciones o agrega tus propios atajos.

## Usar

```bash
black-ice-conky fracture
black-ice-conky signal
black-ice-conky atlas
black-ice-conky menu
black-ice-conky color ice
black-ice-conky opacity 0.72
black-ice-conky auto on
black-ice-conky reset-theme
black-ice-conky off
black-ice-conky toggle
black-ice-conky output DP-1
black-ice-conky output auto
black-ice-conky output all
black-ice-conky status
```

También puedes abrir **BLACK-ICE — Monitor del escritorio** desde el lanzador. `Super+F8` muestra u oculta y `Super+Shift+F8` abre la galería GTK. Filtra por composiciones compactas o de pantalla completa, elige colores y opacidad, y pulsa **Aplicar**: la ventana permanece abierta para comparar. Usa **Cerrar** o Escape para salir. Las miniaturas proceden del mismo renderizador de Conky; sus datos son una captura, no telemetría en vivo. Cambiar colores u opacidad actualiza las miniaturas antes de guardar.

Abre **Pantallas, posición y tamaño** para elegir una pantalla automática, todas o una selección mediante casillas. Puedes seleccionar solo una casilla. También admite nueve anclajes, desplazamiento X/Y y escala entre 65% y 135%. El supervisor limita el dibujo al espacio disponible por pantalla. Los perfiles del Estudio guardan la selección de salidas.

Los nuevos diseños son implementaciones propias; las [créditos y procedencia](../CREDITS.md) distinguen las fuentes consultadas de los archivos incorporados. Ningún estilo depende de una imagen de fondo específica: todos funcionan con tu wallpaper actual y no descargan fondos ni ejecutables al abrirse.

**Recordar por tema** recupera el diseño predeterminado y guarda tus cambios para ese tema. Desmárcalo para mantener el mismo diseño entre temas. **Predeterminado del tema** elimina solo su personalización. Los 54 temas tienen una asignación explícita en `dotfiles/conky/black-ice/theme-defaults.json`. Cambiar solo una imagen conserva el diseño elegido.

Combinaciones: `theme`, `swap`, `ice`, `acid`, `ember`, `orchid`, `mono`. Solo sustituyen los acentos; conservan el fondo y texto del tema. La opacidad admite `0.55` a `0.95`. **Ocultar monitor** y `off` conservan la selección y mantienen los widgets ocultos al cambiar de tema. Las preferencias persisten en `~/.local/state/black-ice/conky.json`; se aplican en hasta cinco segundos.

La salida automática prefiere la integrada. **Todas** sigue las pantallas activas al conectar o desconectar. **Elegir pantallas** conserva los nombres desconectados y no traslada el dibujo a una salida no elegida. Las preferencias antiguas con un único nombre mantienen su comportamiento de reserva. Un recolector comparte las métricas entre instancias; colores y transparencia se actualizan sin reiniciarlas. Los diseños respetan escala, orientación y reservas de las barras.

El backend Wayland instalado no permite nombrar directamente la salida. Al crear cada superficie se enfoca brevemente su pantalla y se comprueba la capa real. Se restaura el foco si no lo cambiaste durante ese inicio. Se verificaron tres instancias en eDP-1, DP-3 y DP-5 de s3th, sin errores; también la selección y conservación de procesos en un compositor aislado.

![Galería Conky](images/features/conky.webp)

## Colores y datos

Incluye paletas para los 54 temas del catálogo. Sigue el enlace `waybar/style.css` y sus metadatos explícitos `Palette`; un archivo `palette.json` permite extender temas. Campos: `bg`, `fg`, `acc1`, `acc2`, `dim`, con colores `#RRGGBB`. Los temas desconocidos usan una reserva legible.

CPU, RAM y red vienen de `/proc`; temperaturas y ventilador, de dispositivos y etiquetas en `hwmon`. No consulta Internet ni la GPU dedicada. El espacio libre corresponde al sistema de archivos de `$HOME`; la temperatura NVMe corresponde al primer dispositivo NVMe detectado. Sin sensores, los veinte estilos muestran uso CPU, ocupación de disco y CPU disponibles, con etiquetas y unidades propias. `CPU / TEMP.` indica grados; `CPU / CARGA`, porcentaje. Cero RPM puede ser una lectura real del ventilador detenido. Consulta [datos en máquinas virtuales](CONKY_VM_METRICS.md).

Actualiza cada 2 segundos con corriente y 5 con batería. La CPU muestra uso agregado; la medición de consumo del proceso se expresa respecto de **un núcleo**. No se anuncia una mejora térmica sin comparación controlada.

La [validación en s3th](AUDIT_REPORT.md) diferencia el prototipo inicial del diseño actual. Fracture translúcido registró 0,73% de un núcleo y 62,6 MiB RSS conjuntos en una muestra breve de 30 segundos con corriente. No garantiza el consumo de los demás estilos. El selector solo genera miniaturas cuando se abre o cambias sus opciones y termina al cerrarlo; no agrega un monitor residente.

## Cortes Angular de Waybar

`bash scripts/fix-angular-waybar.sh` instala el lanzador compartido y corrige las llamadas de arranque y selección conservando el resto de los scripts personales. Usa las rutas reales del CSS y JSON del tema para resolver sus imágenes relativas. Conserva originales modificados en `~/.local/state/black-ice/waybar-changes/angular-assets/`. Los cuatro Angular se comprobaron tras reiniciar Waybar; el reinicio completo del equipo sigue pendiente.

## Diagnóstico y desactivación

```bash
journalctl --user -u black-ice-conky.service -n 30
black-ice-conky off
systemctl --user disable --now black-ice-conky.service
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -p test_desktop_monitor.py
```

`off` conserva el supervisor ligero y la preferencia oculta. Deshabilitar el servicio detiene también el supervisor; abrir el selector lo inicia de nuevo. Para eliminar los atajos, quita la línea que incluye `hypr/conky.conf` de tu configuración principal.
