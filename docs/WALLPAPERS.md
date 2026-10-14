# Fondos de escritorio

El catálogo de temas usa las imágenes fuente almacenadas en `assets/wallpapers/cyber/` y `dotfiles/wallpapers/`. No incluye copias reescaladas para simular resolución 4K: aumentar las dimensiones de un archivo no crea detalle adicional y duplicaba cientos de MiB en el repositorio.

Hyprland, Waypaper, Waybar y SDDM escalan la imagen al espacio disponible cuando la muestran. Los fondos panorámicos mantienen su proporción y se distribuyen según la geometría de las pantallas; los perfiles de escena conservan su composición original. La nitidez final depende de la resolución del archivo fuente y de la pantalla.

Para cambiar los fondos de un tema, edita `dotfiles/waybar/cyber-catalog.json` y regenera los perfiles:

```bash
python3 scripts/build-waybar-themes.py
python3 scripts/check-distribution.py
```

El generador valida que cada archivo del catálogo exista antes de escribir los perfiles. `assets/wallpapers/cyber/sources.json` registra la procedencia de los recursos externos. Los archivos no documentados allí son recursos creados o mantenidos dentro del proyecto.

En la instalación de SDDM se conserva el formato y los bytes de la fuente elegida. El tema dibuja el fondo a la resolución de la pantalla; no necesita una segunda copia UHD.
