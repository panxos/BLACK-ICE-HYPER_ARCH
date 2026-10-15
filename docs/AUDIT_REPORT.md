# Validación del candidato

**4.0.0-dev.2 · 2026-10-13 · sin release.** Este documento resume comprobaciones y límites; no certifica ausencia de errores.

## Comprobaciones de desarrollo

`bash scripts/check-project.sh` reúne sintaxis Bash, ShellCheck, Ruff, pruebas unittest y GTK real bajo Xvfb. Las capturas de los 54 temas se generaron en Hyprland aislado con Waybar real y datos de demostración.

Resultado de la revisión: **243 pruebas**, cinco omitidas sin pantalla y siete comprobaciones GTK ejecutadas por separado, aprobadas. Ruff se amplió a todo el código Python. El detector no encontró secretos en los 773 archivos de texto candidatos de la revisión documental anterior; no es un análisis completo del historial Git ni de archivos binarios. No se encontraron metadatos de instrucciones en las imágenes candidatas revisadas.

El primer clic real de Waybar original tardó 1924,81 ms por la consulta de proveedor `systeminfo`. El backport local lo redujo a 1,94 ms; tras 120 s sin mover el puntero respondió en 1,25 ms, en compositor aislado. La escena Anubis provisional utiliza recortes comprobados píxel por píxel del maestro local, sin afirmar identidad con el recurso pendiente de recuperar de otro equipo.

Se verificó el filtro de distribución creando un archivo tar real: conserva scripts, catálogo y documentación pública, y excluye configuración privada, contexto de sesión y cachés.

El compositor aislado comprobó cinco escritorios persistentes en cada una de tres salidas, proveedores Hyprlang/Lua, reconexión y ausencia de bindings duplicados. La mediana de respuesta IPC estuvo entre 0,26 y 0,41 ms; ese dato no mide fluidez visible ni elimina la necesidad de prueba física.

## Evidencia de sistema disponible

| Comprobación | Resultado registrado |
|---|---|
| Instalación limpia UEFI/Btrfs/LUKS, perfil `minimal`, desde ISO + repo oficial (2026-10-15) | Arranque, SDDM, Hyprland y persistencia del tema tras reinicio en VM |
| Interrupción entre módulos | Reanudación y conservación de datos |
| Recuperación offline | Restauración de paquete/archivo y arranque con kernel/ESP |
| Software gráfico | Instalación y reintento después de corregir autorización Qt |
| Contenedor rootless | Límites comprobados dentro del contenedor |
| Laboratorio KVM propio | Definición, límites y arranque; sin invitado completo |
| SDDM de agencias | Autenticación y retorno a Hyprland |
| Suspensión S3/S4 virtual | Fallo gráfico reproducible; desactivada en QA |

Los registros completos contienen datos del entorno y se conservan fuera de la distribución. La instalación limpia confirma este escenario de VM; no prueba equipos físicos, BIOS/ext4 ni una actualización entre versiones BLACK-ICE.

## Abierto antes de publicar

- Una actualización desde una versión anterior y matriz BIOS/ext4.
- Fallos inducidos dentro de transacciones y retención por cuota.
- VPN externa real y sistema invitado KVM anidado.
- USB físico y sus acciones; energía física y hotplug/HiDPI.
- Rendimiento sostenido con baseline y revisión visual final.
- Licencia general y revisión de redistribución de recursos.

Git local pasó `git fsck --full --no-reflogs` sin objetos faltantes; los objetos colgantes no constituyen corrupción. No se publicaron commits, etiquetas ni release.

[Compatibilidad](COMPATIBILITY_MATRIX.md) · [Sistema](SYSTEM_MANAGER.md) · [Roadmap](ROADMAP_SYSTEM_V4.md).

## Verificación local posterior — 2026-10-15

Se corrigió una aserción que no consideraba el argumento `timeout=8` enviado por el control de brillo. `bash scripts/check-project.sh` volvió a ejecutarse completo: **347 pruebas aprobadas**, lint y sintaxis aprobados, distribución de 1.439 archivos y 54 temas sin problemas. La suite muestra avisos deprecados de `PyGObject`/Python 3.14, sin fallos asociados.

`gitleaks detect --no-git --redact --source .` revisó 77,66 MB y no encontró secretos en el árbol actual. La CI remota aprobó el candidato publicado y la suite local pasó. La instalación limpia descrita arriba sí se completó; sigue pendiente la actualización entre versiones y la matriz física indicada en [pendientes](PENDING.md).
