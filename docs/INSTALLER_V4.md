# Instalación 4.0.0-dev.2 — sin publicar

`VERSION` define la versión propia. Los banners, planes y metadatos de escritorio la leen; las versiones de Arch y sus paquetes siguen sus repositorios. No se modifican entradas históricas del changelog.

Esta preparación permanece en el árbol local. La descarga de la rama pública sigue entregando lo que esté publicado allí, no estos cambios pendientes.

## Elegir aplicaciones

El catálogo `config/apps.json` reúne 143 aplicaciones en 20 grupos, incluidas las herramientas de seguridad, Tor/nftables y Podman rootless opcional. Se puede elegir individualmente, por grupos, o usar los perfiles mínimo, escritorio, pentest y completo. El perfil completo incluye aplicaciones remotas y compilaciones pesadas. Cancelar omite todo el software opcional.

`install.sh --resume` y `deploy_hyprland.sh --resume` comprueban registro, destino y módulos antes de continuar. La reanudación nunca repite el particionado automáticamente. Los gestores de sistema y sus límites están en [SYSTEM_MANAGER.md](SYSTEM_MANAGER.md).

```bash
# Vista previa sin sudo, instalaciones ni cambios de configuración.
bash deploy_hyprland.sh --dry-run --profile pentest

# Abrir el selector gráfico, o terminal cuando no hay escritorio.
python3 scripts/select-apps.py --ui auto --output ~/.local/state/black-ice/apps-plan.json

# Crear una selección reproducible por grupos y aplicaciones.
python3 scripts/select-apps.py --groups Browsers Sec-Recon --apps keepassxc --output ~/.local/state/black-ice/apps-plan.json

# Revisar un plan y utilizarlo durante el despliegue completo.
bash deploy_hyprland.sh --dry-run --plan ~/.local/state/black-ice/apps-plan.json
bash deploy_hyprland.sh --plan ~/.local/state/black-ice/apps-plan.json
```

En el escritorio, **BLACK-ICE Control → Sistema → Aplicaciones** abre el selector y guarda un plan; esa pantalla no instala paquetes. El despliegue también configura el escritorio base. No se presenta como un gestor gráfico de desinstalación.

Sin interfaz interactiva se usa una selección explícita; `NON_INTERACTIVE=true` sin perfil instala únicamente la base. Neovim/NvChad y Claude Code respetan la selección. Los fallos opcionales aparecen en `~/.local/state/black-ice/apps-failed.txt`; no se informa que todo terminó correctamente cuando fallaron paquetes.

## Protecciones del instalador

La autorización sudo y los mirrors tienen [recuperación específica](REPOSITORY_RECOVERY.md): autenticación cuando vence, optimización acotada y publicación de listas válidas, conservando firmas y configuración anterior ante fallos.

El despliegue automatiza confirmaciones rutinarias y mantiene la autorización sudo durante su ejecución. `--interactive` recupera las preguntas; `--allow-unreviewed-aur` permite automatizar también la revisión AUR, únicamente para esa ejecución. `--dry-run` muestra ambas políticas sin instalar.

- El instalador base requiere ISO live de Arch y bloquea ejecuciones simultáneas. `--dry-run` muestra el flujo sin acceder a discos.
- Se rechazan particiones, discos montados, swap, volúmenes activos y dispositivos de solo lectura. En modo automático, `CONFIRM_ERASE` debe contener la ruta exacta del disco. La configuración con contraseñas debe pertenecer a root y tener modo `600`.
- Los comandos críticos detienen el flujo. Se espera a udev antes de formatear y se escribe `/etc/black-ice-release` al finalizar.
- No se desactivan firmas, no se usan eliminaciones `-Rdd` ni sobrescrituras globales para resolver paquetes. La instalación AUR requiere revisión; el modo desatendido la omite salvo `ALLOW_UNREVIEWED_AUR=true` explícito.
- Las contraseñas se transmiten a `chpasswd` por stdin. La copia al sistema instalado excluye `install.conf`, archivos `.env` y registros. Una instalación nueva exige contraseña para sudo; no cambia la política del equipo actual.
- Se conserva el directorio personal de scripts, los snapshots existentes y el firewall personalizado. Las reglas propuestas se validan antes de aplicarse. Docker no añade automáticamente al usuario al grupo con privilegios equivalentes a root.
- Los registros privados viven en el directorio de estado. El bootstrap usa HTTPS directo y una carpeta única; no elimina una descarga anterior.

## Validación y límites

Ejecuta `bash scripts/check-project.sh` para sintaxis, ShellCheck, Ruff y pruebas funcionales. `black-ice-doctor` comprueba componentes instalados y configuración; `--json` produce un informe sin direcciones de red ni credenciales.

La VM de QA comprobó instalación UEFI/Btrfs sin cifrado, reanudación, arranque desde disco, acceso SDDM → Hyprland y restauración offline. BIOS, ext4, LUKS y fallos dentro de transacciones requieren ampliar la matriz; suspensión y pantallas necesitan pruebas físicas. Consulta [la validación](AUDIT_REPORT.md). La versión permanece sin publicar.

El despliegue verifica sus componentes antes de anunciar éxito. Para Lua se utiliza `waybar-git` con IPC compatible; Waybar 0.15 estable no incluye esa adaptación. Sustituir una instalación estable existente requiere una transacción revisada (`sudo pacman -S waybar-git`); el modo automático se detiene ante ese conflicto. Las firmas siguen habilitadas. El selector nativo de fondos funciona si Waypaper queda pendiente de revisión AUR.

Plan de las seis mejoras de sistema: [SYSTEM_V4_IMPLEMENTATION_PLAN.md](SYSTEM_V4_IMPLEMENTATION_PLAN.md). Catálogo y procedencia de fondos: [WALLPAPERS.md](WALLPAPERS.md).

## Copia al sistema instalado

La fase base utiliza `config/distribution-excludes.txt`: conserva código y guías, y excluye configuración sensible, notas de sesión, cachés y registros de diseño. La configuración automática saneada se escribe por separado con modo `600`.

Ejecuta `python3 scripts/check-distribution.py` antes de preparar cambios. No copies perfiles privados ni apliques configuraciones de energía de portátil a otros equipos sin revisar su hardware.

## Conky y fondos de acceso en instalaciones nuevas

El módulo `99_finalization.sh` detecta Conky 1.25.2, instala las dependencias de compilación y ejecuta `scripts/build-conky-wayland.py --apply`. Descarga 1.25.3 desde una fuente oficial fijada por SHA-256, compila Cairo/Wayland y publica binario y módulos en libexec del usuario. No necesita una copia previa de ese binario. Si falla, la etapa falla; no anuncia una instalación completa. Ante otra versión conserva Conky del sistema.

Los instaladores visuales distribuyen `black-ice-lock`, los módulos compartidos y el supervisor corregido. La configuración base de Hypridle prepara los fondos antes de bloquear. La migración solo sustituye el comando de bloqueo generado; conserva comandos personales distintos.

El módulo SDDM y el instalador visual utilizan la misma función `sddm_backgrounds()` para copiar el maestro Anubis y declarar el modo escena. Los temas de agencias incluyen sus panoramas. El greeter calcula recortes con sus pantallas Qt; Estudio exporta también el modo y el panorama cuando el perfil sigue al tema base.

La regresión `test_access_backgrounds.py` aplica los instaladores a un destino vacío, ejecuta los helpers instalados sin importar módulos desde el repositorio y comprueba recursos, servicio y comando de bloqueo. También comprueba la rama de despliegue para 1.25.2, la omisión de versiones corregidas y la propagación de un fallo de compilación. Esto no sustituye instalar Arch desde ISO ni la matriz física de pantallas.

## Cabeceras de instalación

Bootstrap, sistema base y escritorio comparten marca, versión, etapa y descripción. La portada muestra un logotipo ASCII grande cuando hay espacio; en terminales estrechas conserva la marca compacta. Cian identifica la marca, violeta las etapas y blanco el contenido. Respeta `NO_COLOR` y `TERM=dumb`; en locales sin UTF-8 utiliza bordes ASCII. La cabecera no borra los mensajes anteriores.

La vista previa es de solo lectura y funciona sin root, red ni una ISO:

```bash
bash bootstrap.sh --banner
bash install.sh --banner
bash deploy_hyprland.sh --banner
```

`src/lib/banner.sh` contiene el renderer; `logging.sh` mantiene la función pública `banner`. Los registros se abren en modo append para conservar las cabeceras y mensajes escritos por el logger. Con tee y descriptor 3 interactivo, la terminal recibe el banner de color y el archivo una copia sin ANSI. El bootstrap descargado por curl conserva una alternativa compacta autónoma antes de clonar.

La [captura de las tres cabeceras](images/features/installer-banners.png) procede de xterm en Xvfb ejecutando esas vistas previas. Las pruebas cubren anchos de 1 a 120 columnas, alineación, colores, ASCII, caracteres de control, logs y ausencia de efectos de instalación.

## Flujo visual de la fase base

Ocho etapas siguen el orden real: entorno, disco, base, sistema, acceso, energía, arranque y cierre. Los corchetes indican la etapa actual; la navegación no representa un porcentaje ni acredita etapas omitidas. Los menús comparten números de dos dígitos, espaciado y recuperación de errores. Se conservan las opciones originales y la autorización escrita `SI`/`NO` antes del borrado.

`src/lib/terminal-ui.sh` reúne secciones, etapas, opciones, estados y aviso de borrado. Un menú interactivo reconstruye su página en el terminal original, conservando el scrollback y el registro privado. La salida redirigida, `NO_COLOR` y `TERM=dumb` permanece lineal. No añade dependencias a ArchISO ni cambia la fuente de consola.

Para recorrer dos pantallas con datos de demostración, sin root, discos, red ni creación de estado:

```bash
bash install.sh --preview
```

La [pantalla de selección](images/features/installer-mirrors.png) y la [versión compacta](images/features/installer-compact.png) son capturas del programa real en xterm. La demo no ejecuta particionado, instalación, cambios de teclado ni contraseñas. Fin de entrada cancela la selección; una opción inválida permite reintentar.

Verificación del 2026-10-13: 267 pruebas, cinco omitidas por pantalla, siete GTK explícitas y controles del proyecto aprobados. Después del último ajuste visual pasaron las 35 pruebas de instalador y ShellCheck completo de los scripts modificados. La aceptación visual y una instalación completa con esta interfaz siguen pendientes.

## Instalación supervisada en s3th

El caso UEFI/Btrfs sin cifrado y perfil minimal pasó desde disco vacío hasta SDDM/Hyprland, Conky y bloqueo. La reanudación reconoce Btrfs ya montado y mantiene la protección frente a otra unidad con UUID duplicado. El módulo SDDM fija XKB antes del greeter mediante scripts/configure-sddm-keyboard.py, conservando DisplayCommand personalizados.

289 pruebas y siete GTK aprobadas; siete controles reales de QA y doctor sin fallos. Resultados, errores, evidencias y alcance en el registro privado `docs/VM_VALIDATION_V4.md` y [REPOSITORY_RECOVERY.md](REPOSITORY_RECOVERY.md). Aplicaciones opcionales y matriz física/BIOS/LUKS siguen pendientes.
