# Arquitectura

BLACK-ICE separa la instalación del sistema, el despliegue del escritorio y las operaciones cotidianas. Bash coordina etapas; Python comparte modelos entre CLI y GTK.

## Instalación en dos fases

| Entrada | Implementación | Responsabilidad |
|---|---|---|
| `bootstrap.sh` | Descarga a un directorio propio | Obtener una copia revisable |
| `install.sh` | `src/modules/` | Disco, base Arch, usuario, energía y arranque |
| `deploy_hyprland.sh` | `src/deploy/` | Repositorios, escritorio, selección de aplicaciones y configuración |
| Registro de etapas | `scripts/module-state.py`, `src/lib/module-runner.sh` | Huellas, comprobaciones y reanudación |

La fase base requiere ISO live y privilegios administrativos. La fase de escritorio se inicia como usuario normal. El registro comprueba identidad del destino y resultados antes de omitir una etapa; no repite automáticamente el particionado.

`src/lib/banner.sh` dibuja cabeceras sin efectos secundarios; `logging.sh` conserva la función pública `banner`. Los tres accesos ofrecen `--banner` antes de validar privilegios o preparar estado. Bootstrap dispone de una alternativa autónoma para la descarga de un solo archivo. Los registros usan append para conservar escrituras del logger y las cabeceras.

`src/lib/terminal-ui.sh` reúne etapas, selecciones y estados. El logger separa terminal con color de registro plano. `install.sh --preview` carga una demo independiente antes de privilegios, estado, bloqueo o módulos de instalación; los menús reales conservan los valores y confirmaciones existentes.

`src/lib/privileges.sh` revalida sudo al iniciar módulos y antes de operaciones críticas de repositorios. `src/lib/repositories.sh` limita reintentos y duración de Reflector; valida una lista temporal antes de publicarla y conserva la anterior ante fallos. No cambia la política sudo ni elimina llaveros. Detalles en [recuperación de repositorios](REPOSITORY_RECOVERY.md).

## Escritorio

`dotfiles/waybar/cyber-catalog.json`, `layout-map.json` y `typography.json` describen los temas. `scripts/build-waybar-themes.py` produce CSS, configuración, paletas y metadatos. Los instaladores conservan ajustes personales mediante manifiestos de archivos y reversión protegida.

`black-ice-appearance` sincroniza componentes. `black-ice-waybar` adapta barras por salida; `black-ice-workspaces` mantiene grupos estables y responde a cambios de monitores. `black-ice-wallpaper` distribuye panoramas según geometría. Conky comparte telemetría entre instancias por salida y usa Cairo sobre Wayland.

`black-ice-wallpaper prepare` calcula recortes sin aplicar imágenes al escritorio. `black_ice_lock.py` incorpora esos archivos en bloques Hyprlock por conector; `black-ice-lock` prepara antes de bloquear, con un límite de tiempo y conservación del bloqueo ante errores. Los cambios de monitor actualizan la configuración para el siguiente bloqueo. Una salida conectada durante un bloqueo ya iniciado utiliza el fondo general de reserva.

SDDM calcula la geometría con `Qt.application.screens` y `Screen.name`, dentro del propio acceso. `AdaptiveBackground.qml` y `WallpaperGeometry.js` seleccionan imagen individual, panorama por fila o escena completa; no dependen de la sesión Hyprland del usuario. Los recursos quedan dentro del tema, accesibles al greeter.

Antes del greeter X11, `scripts/configure-sddm-keyboard.py` prepara un DisplayCommand que ejecuta Xsetup original y fija XKB. El módulo instala xorg-setxkbmap y convierte la distribución de consola; se conservan comandos personalizados. Esta etapa evita que el selector conserve el mapa US leído antes de cargar latam. La reanudación base identifica Btrfs mediante UUID y dispositivo canónico de `findmnt --nofsroot`, sin comparar su MAJ:MIN virtual con el del disco físico.

El selector `black_ice_conky_binary.py` verifica los archivos de una compilación local 1.25.3 únicamente ante el paquete defectuoso 1.25.2. El despliegue prepara esa compilación automáticamente cuando corresponde y propaga sus fallos. El supervisor registra caídas tardías, espera entre reintentos y publica procesos; el estado vivo exige también la capa de la salida. Doctor y postinstalación consumen ese estado.

Control y Estudio utilizan modelos en `black_ice_theme.py` y `black_ice_layout.py`. El lanzador se ejecuta bajo demanda; F1 consulta los bindings activos, sin duplicar una lista estática.

## Operaciones del sistema

`src/system/manager.py` comparte software, proyectos y laboratorios entre CLI y GTK. El helper privilegiado `scripts/system-transaction.py` limita acciones al catálogo instalado por root; no ejecuta comandos arbitrarios procedentes de perfiles personales.

`src/system/laboratories.py` prepara plantillas oficiales, verifica ISO/digest, detecta requisitos y abre consolas; `labs_ui.py` ofrece el asistente GTK y la importación avanzada. La instalación distribuye juntos los módulos de `src/system/`. KVM consulta capacidades reales para seleccionar VirtIO/SPICE o VGA/VNC. La apertura vuelve a comprobar propiedad y aislamiento, incluyendo red, montajes, capacidades, privilegios, usuario y discos registrados. Detalles en [Laboratorios guiados](LABORATORIES.md).

El estado de usuario vive en `$XDG_STATE_HOME/black-ice/`; la instalación base, en `/var/lib/black-ice/`. VPN utiliza UUID de NetworkManager y su almacén de credenciales. Laboratorios propios se identifican por registros, UUID y etiquetas.

`system_privacy.py` coordina Tor del sistema mediante el helper root `scripts/system-tor.py`. El daemon tiene UID dedicado; una tabla nftables independiente redirige TCP/DNS IPv4 y bloquea IPv6, UDP restante y reenvío. El filtro persistente arranca antes de la red y el guard publica comprobaciones en `/run/black-ice/tor.json`. Apagar retira solo su tabla; una caída conserva el bloqueo. El control usa cualquier terminal o aplicación habitual y nunca abre una consola especial.

Waybar incorpora el módulo en tiempo de ejecución, deriva colores de la paleta activa y respeta visibilidad global guardada en configuración de usuario. `web_labs.py` limita OWASP a red interna/localhost; `storage.py` controla preparación y limpieza; `cases.py` conserva alcance, evidencias y registro encadenado. Los controles de usuario se instalan con `scripts/install-security-workspace.py`; los componentes root, con `scripts/install-system-tor.sh`. Ninguno activa Tor automáticamente. Detalles en [Seguridad](SECURITY_WORKSPACE.md).

`black_ice_i18n.py` y `config/i18n/en.json` comparten idioma persistente entre controles GTK, galerías, Estudio y sistema. La traducción actúa en presentación, conservando datos de entradas e IDs. Los wrappers GObject mantienen originales para cambios en vivo y los modelos conservan referencias durante la ventana. Rofi y etiquetas dibujadas traducen explícitamente. SDDM tiene selección propia anterior a la sesión. [Idioma](LANGUAGE.md).

## Distribución y límites

`.gitignore` excluye contexto local. `config/distribution-excludes.txt` impide copiarlo al sistema instalado. Fuentes, iconos y fondos conservan procedencia y licencias separadas.

La reversión de dotfiles no sustituye la recuperación del sistema. Los snapshots Btrfs requieren copia de arranque/ESP y una restauración verificada. Consulta [gestores](SYSTEM_MANAGER.md), [compatibilidad](COMPATIBILITY_MATRIX.md) y [validación](AUDIT_REPORT.md).
