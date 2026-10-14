# Migración de Hyprland a Lua

Hyprland 0.55 incorporó Lua; el aviso de 0.56.2 anuncia la retirada de `.conf` en 0.57. BLACK-ICE conserva la configuración instalada y la convierte localmente, sin sustituirla por una plantilla del repositorio.

## Actualizar una instalación existente

La primera actualización debe ejecutarse **desde la copia nueva del repositorio**. No uses una copia antigua de `dotfiles-update`: algunas versiones reemplazaban carpetas personales por enlaces al repositorio.

```bash
cd /ruta/a/BLACK-ICE_ARCH
git pull --ff-only
bash dotfiles/bin/dotfiles-update --no-pull
```

El comando instala la nueva ruta de actualización y realiza la migración. Después puedes usar `dotfiles-update --repo /ruta/a/BLACK-ICE_ARCH`. Se conservan las configuraciones de Waybar, Kitty y las demás aplicaciones; este actualizador no las sustituye ni reinicia servicios. Revisa los cambios de esas configuraciones por separado.

El conversor es `hyprlang2lua`. Si está instalado, se usa localmente. Si falta y existe Go compatible, se compila la revisión fija `4d69a9b52ce09c9b113a1642e537cd2fa4754a09` de v0.7.2 y se guarda en `~/.local/lib/black-ice/`. La descarga contiene código del conversor, nunca archivos de configuración. Si falta Go, instala primero `paru -S hyprlang2lua`.

## Comprobar sin aplicar

```bash
python3 dotfiles/bin/hyprland-migrate --dry-run
```

La simulación requiere un conversor disponible; no lo descarga. También puedes indicar `--converter /ruta/a/hyprlang2lua` y `--config-dir /ruta/a/hypr`. No modifica configuración, respaldos ni comandos instalados.

## Qué se conserva y cuándo se activa

- Los `.conf` originales permanecen intactos. Las inclusiones locales se expanden en orden para conservar las variables compartidas, atajos, teclado, reglas y comandos personales.
- `monitors.conf` y `vm-performance.conf` se convierten en módulos independientes. El helper de monitores se adapta sin reemplazar su contenido personal; sincroniza los módulos tras regenerarlos y después de cerrar `nwg-displays`.
- Los selectores instalados reciben una adaptación del comando de bordes, compatible con la sesión antigua y con Lua. El menú de ajustes abre el archivo Lua.
- Se exige una conversión sin pendientes y `config ok` de `Hyprland --verify-config`. Una configuración Lua existente nunca se reemplaza.
- Los respaldos privados quedan en `${XDG_STATE_HOME:-$HOME/.local/state}/black-ice/hyprland-migrations/`. No se publican en Git.

Hyprland elige el formato al iniciar. Una sesión abierta con `.conf` continúa utilizándolo; guardar Lua o ejecutar `hyprctl reload` no cambia ese backend. Cierra e inicia sesión cuando corresponda para activar Lua. La migración no fuerza un cierre.

## Recuperación y límites

```bash
dotfiles-rollback --dry-run
dotfiles-rollback
```

La reversión comprueba que los archivos no hayan cambiado desde la migración y valida la configuración antigua antes de recuperarla. Si ya editaste Lua, se detiene para conservar esos cambios. En 0.57 o superior se rechaza volver a `.conf`; conserva un archivo Lua válido o recupera primero una versión compatible de Hyprland.

La migración se detiene ante plugins o directivas que el conversor marque como ambiguos, inclusiones inexistentes/cíclicas/externas, fragmentos generados con variables personales o scripts de monitores con un `trap` propio. Los archivos personales no se reemplazan. Si `~/.config/hypr` es un enlace a un repositorio, primero prepara una copia local: no se escribe Lua dentro del repositorio compartido. Un lanzador personalizado con `Hyprland -c ...conf` también debe revisarse antes del próximo inicio.

Actualizar paquetes con `paru -Syu` no ejecuta este comando: realiza primero la actualización de BLACK-ICE para migrar antes de instalar una versión sin soporte de `.conf`.

Fuentes: [cambio oficial a Lua](https://hypr.land/news/26_lua/), [configuración actual](https://wiki.hypr.land/Configuring/Start/), [conversor y límites](https://github.com/EIonTusk/hyprlang2lua).
