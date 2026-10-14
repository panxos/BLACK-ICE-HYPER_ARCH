# Resolver problemas

## Diagnóstico inicial

Ejecuta `black-ice-doctor --json` y conserva el informe saneado. Revisa `hyprctl configerrors`, `journalctl --user -u black-ice-workspaces.service` y los registros del componente que falla. No publiques credenciales ni objetivos reales.

## Barra o perfil

Prueba un tema original desde Control. El Estudio valida CSS antes de reemplazar la barra; elimina o restaura perfiles desde su papelera. [Guía](../../THEME_STUDIO.md).

## Fondos o varias pantallas

Consulta `black-ice-wallpaper status` y `black-ice-conky status`. Comprueba la geometría conectada y la selección de salidas. [Estabilidad](../../DESKTOP_STABILITY.md).

## F1 no aparece

Comprueba `~/.local/bin/cheatsheet --check` y el binding activo. Las configuraciones personales no se sobrescriben automáticamente. [Atajos](../../KEYBOARD_SHORTCUTS.md).

## Instalación interrumpida

Utiliza el registro y `--resume`; no vuelvas a iniciar particionado sin revisar el disco. [Instalador](../../INSTALLER_V4.md), [recuperación](../../SYSTEM_MANAGER.md).

Para informar un error, incluye versión, reproducción y salida saneada. [Compatibilidad pendiente](../../COMPATIBILITY_MATRIX.md).
