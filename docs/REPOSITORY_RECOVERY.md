# Repositorios y autorización sudo

El fallo observado en la VM el 2026-10-13 fue `sudo: a password is required`. El escaneo de cien mirrors consumió más de cinco minutos y venció la autorización antes de importar la clave de Chaotic-AUR. Los reintentos repetían la operación sin autenticar. La política seguía exigiendo contraseña; no era un fallo comprobado de la clave ni del repositorio.

## Corrección

- `src/lib/privileges.sh` comprueba sudo antes de operaciones privilegiadas y al iniciar cada módulo. Si venció, solicita autenticación en el terminal. En modo desatendido se detiene con una indicación concreta. No modifica sudoers ni almacena contraseñas.
- `src/lib/repositories.sh` limita Reflector a veinte candidatos y 120 segundos. Escribe una lista temporal, valida URLs HTTPS y publica por rename. Si falla o recibe una lista inválida, conserva la anterior; si tampoco hay una lista válida, se detiene. No anuncia una optimización inexistente.
- Las operaciones críticas tienen tres intentos; los fallos de autorización no se reintentan como errores de red ni permiten saltar el paso. La recepción de la clave usa HKPS y un límite de tiempo. Las firmas permanecen habilitadas.
- La fase live ya no borra el llavero ante un error de descarga y muestra los errores de pacman. Optimiza o conserva mirrors antes de actualizar el llavero.
- Las dependencias del escritorio usan los nombres actuales `libayatana-appindicator` y `libappindicator`, evitando búsquedas AUR por nombres antiguos.

## Cómo continuar

Las confirmaciones rutinarias del despliegue son automáticas por defecto. Se conserva la lista de mirrors cuando es válida y no aparece un menú de reintento después de agotar los intentos. `--interactive` recupera ese comportamiento manual; `--yes` expresa la automatización al invocar el script. El plan de aplicaciones se elige una vez y `--resume` reutiliza el guardado.

La autorización sudo se solicita al iniciar y se renueva cada 45 segundos mientras dura el despliegue. El helper termina al salir, fallar o recibir una señal y no mantiene abierto el lock de despliegue. No se modifica sudoers ni se guarda la contraseña. Una revocación de credenciales o una política personalizada puede exigir autenticación adicional.

El despliegue del escritorio se ejecuta como usuario normal. Desde el mismo terminal:

```bash
cd ~/BLACK-ICE_ARCH
bash deploy_hyprland.sh --resume --yes
```

Para automatizar también la revisión de las recetas AUR de los paquetes seleccionados, la autorización se expresa en la misma ejecución:

```bash
bash deploy_hyprland.sh --resume --yes --allow-unreviewed-aur
```

Sin esa opción, Paru usa `--confirm --review` para conservar la revisión y sus confirmaciones. Con autorización explícita usa `--skipreview`; en ambos casos conserva firmas y falla ante conflictos que requieren cambios de paquetes. Las dependencias de compilación se conservan y las instalaciones AUR se agrupan cuando pueden hacerlo. Las opciones se contrastaron con el [manual oficial de Paru](https://github.com/Morganamilo/paru/blob/master/man/paru.8).

No hace falta volver a particionar para repetir esta fase. `install.sh` corresponde a la instalación base como root desde ArchISO. Una ejecución que ya estaba abierta conserva las funciones que cargó; las correcciones se cargan al volver a ejecutar el despliegue.

## Verificación

Automatización posterior: 283 pruebas, cinco omitidas por pantalla, siete GTK y controles aprobados. Ocho regresiones adicionales comprueban renovación, limpieza al fallar/terminar, liberación del lock, protección frente a limpieza desde subshells, argumentos de revisión AUR y vistas previas sin estado. Esta validación no garantiza una sola petición de contraseña ante políticas sudo personalizadas.

275 pruebas, cinco omitidas por pantalla, siete GTK y controles del proyecto aprobados. Ocho regresiones específicas cubren autenticación vencida, rechazada y desatendida, reintentos acotados, mirrors inválidos/HTTP/timeout y conservación de la lista anterior. Pruebas adicionales de instalador y ShellCheck completo de scripts modificados aprobados tras los últimos ajustes.

En la VM instalada se comprobaron Chaotic-AUR, su keyring/mirrorlist y `paru v2.1.0` con libalpm 16.0.1. La política sudo conserva `%wheel ALL=(ALL:ALL) ALL`, modo 440. Una prueba de Reflector real generó una lista HTTPS válida en 86 segundos sobre un destino aislado y conservó el hash de la lista del sistema. La reinstalación supervisada posterior completó el escritorio mínimo y sus comprobaciones; alcance y evidencia en VM_VALIDATION_V4.md.

## Fuentes

El comportamiento de autorización está documentado en [ArchWiki: sudo](https://wiki.archlinux.org/title/Sudo); selección y actualización de mirrors en [ArchWiki: Reflector](https://wiki.archlinux.org/title/Reflector). El bootstrap mantiene el flujo de [Chaotic-AUR](https://github.com/chaotic-aur). Los nombres de las bibliotecas se verificaron en [libayatana-appindicator](https://archlinux.org/packages/extra/x86_64/libayatana-appindicator/) y [libappindicator](https://archlinux.org/packages/extra/x86_64/libappindicator/).

## Conflictos detectados durante la instalación real

La ejecución manual del 2026-10-13 también registró dos conflictos de paquetes: `hyprpicker-git` requería `hyprutils-git`, incompatible con la biblioteca estable de Hyprland; `pipewire-jack` encontraba `jack2`, elegido antes como proveedor de JACK. El candidato usa `hyprpicker` de extra y establece primero PipeWire, incluidos sus proveedores PulseAudio/ALSA/JACK. La validación crítica comprueba estos componentes y no permite anunciarlos como instalados si faltan. Comprobado en la reinstalación supervisada desde disco vacío.

El cierre `deploy_hyprland.sh: line 150: q: command not found` ocurrió después de sobrescribir el script mientras Bash lo ejecutaba. El archivo vigente no contiene ese comando en esa línea; el mecanismo de lectura parcial se reprodujo de forma aislada. No actualizar archivos de una ejecución activa: preparar una copia en otra ruta, detener el instalador fuera de una transacción de paquetes y ejecutar el candidato fijo con `--resume`.

La prueba por etapas descubrió que la reanudación comparaba `findmnt MAJ:MIN` de Btrfs (por ejemplo, 0:74) con el dispositivo físico (254:2), rechazando el mismo disco. Ahora compara el dispositivo canónico obtenido con `findmnt --nofsroot`, además del UUID. Se conserva el rechazo a otra unidad con UUID duplicado; dos regresiones cubren ambos casos.

En Paru 2.1.0, `--noconfirm` también omite la revisión aunque se combine con `--review`. Se observó en la compilación real de ttf-dseg y se contrastó con el [historial oficial de Paru](https://github.com/Morganamilo/paru/blob/master/CHANGELOG.md). La política sin autorización explícita usa ahora `--confirm --review`; repositorios firmados siguen con confirmaciones automáticas. La combinación `--noconfirm --skipreview` queda limitada a `--allow-unreviewed-aur`. La prueba anterior de flags aceptaba una combinación ineficaz y fue corregida.

## Teclado al iniciar SDDM

En la VM, Xorg presentaba inicialmente `pc+us` y después cargaba `pc+latam` desde la configuración del sistema. SDDM conservaba el mapa leído al inicializar y mostraba US, aunque más tarde el mapa efectivo fuera latinoamericano. Cambiar únicamente el texto del selector no corregía esa secuencia y se descartó.

`scripts/configure-sddm-keyboard.py` genera un DisplayCommand que ejecuta Xsetup del proveedor y fija el mapa XKB antes del greeter. El módulo SDDM instala explícitamente xorg-setxkbmap y aplica la conversión desde la configuración de consola. Conserva DisplayCommand personalizados y permite una vista previa sin escritura. Cuatro pruebas cubren instalación vacía, configuración personalizada, precedencia/idempotencia y entrada inválida. En el greeter real se verificó `pc+latam`, nombre Spanish (Latin American) y selector latam.
