# Proposal — fix-wallpaper-persistence-and-bugs
**Fecha:** 2026-06-27  
**Estado:** approved

## Qué
Corregir 4 bugs en el rice system de BLACK-ICE ARCH que hacen que los wallpapers y temas no persistan correctamente al reiniciar.

## Por qué

### Bug 1 — CRÍTICO: `set_wallpaper.sh` ignora waypaper/config.ini
- El usuario cambia el wallpaper con waypaper GUI → waypaper escribe en `config.ini`
- Al reiniciar, `set_wallpaper.sh` lee `~/.cache/current_wallpaper` (cache) que NO se actualizó
- Resultado: el wallpaper vuelve al anterior o al default (HORUS-CYBER.jpg)

### Bug 2 — MEDIO: `theme_selector` no actualiza waypaper/config.ini
- `theme_selector` cambia el wallpaper activo y escribe el cache, pero NO actualiza `waypaper/config.ini`
- Si el usuario abre waypaper GUI después, ve el wallpaper antiguo (inconsistencia)
- Si se reinicia, el cache y el ini apuntan a cosas distintas

### Bug 3 — MEDIO: `04_theme_setup.sh` no escribe el cache al instalar
- El instalador actualiza waypaper/config.ini correctamente
- Pero NO escribe `~/.cache/current_wallpaper`
- Resultado: al primer reinicio, el cache está vacío o apunta a HORUS-CYBER.jpg

### Bug 4 — MENOR: `wofi-launcher` no tiene permiso de ejecución
- El archivo `dotfiles/bin/wofi-launcher` no tiene bit +x
- Los nuevos installs no podrán ejecutar el launcher directamente

## Decisión de diseño
**Fuente de verdad única:** `~/.config/waypaper/config.ini` para el wallpaper activo.
Todo script que cambie el wallpaper debe actualizar config.ini. `set_wallpaper.sh` lee config.ini primero.
