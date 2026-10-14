# Estudio de temas

Abre **Super+Alt+T → Estudio de temas**, o ejecuta `black-ice-theme-studio`. El Estudio es un configurador sencillo con vista previa; el diseñador universal de capas queda como proyecto independiente.

## Crear y aplicar

1. Elige uno de los 54 temas base y escribe un nombre.
2. Configura Barras, Fuentes y colores, Módulos y Fondo/Conky.
3. Usa Posiciones para organizar módulos en zonas compatibles y mover Conky.
4. Pulsa **Guardar perfil** o **Guardar y aplicar**. `Ctrl+S` guarda.

Los escritorios permanecen centrados; bandeja y controles, a la derecha. Deshacer/Rehacer conserva hasta 30 movimientos. Escape cancela un arrastre. La vista previa utiliza cifras ilustrativas y no reproduce exactamente todos los estilos Cairo.

Los perfiles se guardan en `~/.config/waybar/themes/User-*/`. Cambiar la fuente guarda CSS válido sin modificar el tema original. El arranque comprueba el CSS antes de sustituir las barras.

## Eliminar y restaurar

En la galería, los temas personales muestran **Eliminar**. En Perfiles del Estudio también puedes eliminar la selección y recuperarla desde la papelera. El tema activo y los originales están protegidos; primero aplica otro tema si quieres borrar el activo.

La papelera está en `$XDG_DATA_HOME/black-ice/deleted-themes/`. La operación mueve el directorio completo y no borra fondos compartidos. Restaurar rechaza un nombre ya existente y no sobrescribe el perfil.

## Fondos, fuentes y Conky

El catálogo combina siete familias principales con símbolos específicos y fuentes de apoyo para iconos/japonés. Un monitor utiliza el fondo individual; salidas alineadas utilizan el panorama declarado. Un fondo escogido manualmente tiene prioridad.

**Escena única para todas las pantallas** compone un solo lienzo según la geometría completa, incluyendo pantallas en otra fila. Anubis-Sethek utiliza este modo con su maestro local centrado; en su disposición nativa no se amplían píxeles. Los otros modos conservan repetición y panoramas por fila.

Conky ofrece 20 estilos, paleta, transparencia, escala, posición y casillas para una o varias pantallas. **Aplicar** mantiene abierta la galería; **Cerrar** la termina. Puedes ocultar Conky y volver al estilo predeterminado del tema.

La exportación JSON contiene ajustes; lleva también la imagen utilizada y revisa los nombres de salidas en otro equipo. El tema conserva la fuente seleccionada; consulta [WALLPAPERS.md](WALLPAPERS.md) para el catálogo y su procedencia.

## Acceso y bloqueo

Selecciona un SDDM instalado y abre su vista previa. Aplicar prepara una copia propia para el próximo acceso, conserva la selección anterior y requiere autorización administrativa. No reinicia la sesión. Otros temas pueden ignorar opciones que admite BLACK-ICE Obsidiana.

[Fondos y 54 temas](THEMES.md) · [Lanzador](LAUNCHER.md) · [Conky](DESKTOP_MONITOR.md) · [Validación](AUDIT_REPORT.md).
