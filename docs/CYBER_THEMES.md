# Catálogo del escritorio

El catálogo contiene **54 temas**. Anubis-Sethek es el predeterminado para instalaciones nuevas; las actualizaciones conservan una selección válida, incluidos perfiles personales.

Consulta la [galería completa](THEMES.md): cada entrada muestra fondo, barras, fuente, geometría y estilo Conky predeterminado.

## Fuentes de configuración

| Archivo | Define |
|---|---|
| `dotfiles/waybar/cyber-catalog.json` | Colores, fondo, panorama, forma y Conky |
| `dotfiles/waybar/layout-map.json` | Distribución de barras |
| `dotfiles/waybar/typography.json` | Fuente y métricas tipográficas |
| `dotfiles/waybar/theme-aliases.json` | Nombres antiguos y migración |
| `dotfiles/conky/black-ice/theme-defaults.json` | Preferencias Conky por tema |

Regenera un diseño con `python3 scripts/build-waybar-themes.py --theme NOMBRE`. Revisa `python3 scripts/install-cyber-themes.py --dry-run` antes de aplicar. El instalador conserva perfiles personales y no selecciona automáticamente un acceso SDDM.

Los módulos de seguridad conservan IP, VPN y objetivo. Docker/VM se ocultan cuando no están disponibles y vuelven a consultarse. La bandeja queda a la derecha; los escritorios usan grupos locales por monitor.

## Recursos

Los fondos individuales y panorámicos tienen nombres explícitos; no se reemplaza el original de un tema para crear una variante diferente. Los recursos externos están registrados en `assets/wallpapers/cyber/sources.json`. Los temas usan los originales y no duplican archivos reescalados. Los registros de diseño quedan fuera de la publicación.

[Estudio](THEME_STUDIO.md) · [Pantallas](DESKTOP_STABILITY.md) · [Fuentes y créditos](../CREDITS.md).
