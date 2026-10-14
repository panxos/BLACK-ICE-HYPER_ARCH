# Demora del primer clic en escritorios

En Waybar-git `4e207a0`, el primer clic detecta el proveedor de configuración de Hyprland mediante `systeminfo`. Ese informe ejecuta consultas de diagnóstico y bloquea la acción. El resultado se guarda por proceso: recrear Waybar vuelve a pagar el coste. El comportamiento está en [el backend de esa revisión](https://github.com/Alexays/Waybar/blob/4e207a0cb51a9eb89b4245d90245721f5e39bf06/src/modules/hyprland/backend.cpp#L320).

## Evidencia

Prueba con eventos reales de puntero Wayland en Hyprland aislado, sobre dos botones de escritorios persistentes:

| Caso | Original | Backport |
|---|---:|---:|
| Primer clic del proceso | 1924,81 ms | 1,94 ms |
| Clic repetido | 0,69 ms | 1,33 ms |
| Después de 30 s | 1,05 ms | 1,45 ms |

Esto comprueba el bloqueo inicial, no cualquier demora después de inactividad prolongada del equipo físico. La consulta independiente `systeminfo` tardó aproximadamente 1,8 s; `status`, 4,5 ms. No se cambió la política de energía para ocultar el síntoma.

Una segunda prueba mantuvo el puntero sobre el botón sin actividad durante **120 segundos**: el backport respondió en **1,25 ms**. Es evidencia del compositor aislado; falta confirmar el síntoma físico descrito durante uso habitual.

## Corrección local

`scripts/build-waybar-fast-ipc.py` descarga la revisión exacta de Waybar, comprueba SHA-256 y compila una modificación pequeña: usar `status` y recurrir a `systeminfo` solo cuando un compositor anterior no ofrece `configProvider`.

```bash
python3 scripts/build-waybar-fast-ipc.py          # revisar el plan
python3 scripts/build-waybar-fast-ipc.py --apply  # compilar sin root
~/.local/bin/waybar_start.sh                     # activar al reiniciar las barras
```

Requiere las dependencias de Waybar y herramientas de compilación, incluyendo Meson, Ninja, G++, pkg-config y gdbus-codegen (`glib2-devel`). No compila al abrir Control ni una galería.

El binario está en `~/.local/libexec/black-ice/waybar-fast-ipc/`, junto con procedencia y hash. `black-ice-waybar-binary` lo selecciona únicamente si coincide el paquete base, la integridad y la prueba de ejecución. Si cambia el paquete o falla la carga, utiliza Waybar del sistema. No reemplaza `/usr/bin/waybar` ni modifica firmas de paquetes.

El backport está limitado a la revisión indicada; no instala una versión antigua sobre paquetes futuros. La matriz completa de gráficos, suspensión e inactividad física permanece en [validación](AUDIT_REPORT.md).
