<div align="center">

<img src="docs/images/showcase/blackice-cover.jpg" alt="BLACK-ICE ARCH: Arch Linux, Hyprland, 54 temas, módulos propios y herramientas de seguridad" width="100%">

# BLACK-ICE ARCH

### Arch Linux · Hyprland · Puesto de trabajo para seguridad

**54 temas coordinados · controles propios · 143 aplicaciones seleccionables · Tor del sistema**

![Versión](https://img.shields.io/badge/versi%C3%B3n-4.0.0--dev.2-8A2BE2?style=for-the-badge)
![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=archlinux&logoColor=white)
![Hyprland](https://img.shields.io/badge/Hyprland-00B9AE?style=for-the-badge)
![Estado](https://img.shields.io/badge/estado-candidato_sin_release-orange?style=for-the-badge)

[English](README.en.md) · [Instalación](docs/INSTALLER_V4.md) · [Galería](docs/THEMES.md) · [Guía](docs/GUIDE.md) · [Pendientes](docs/PENDING.md)

</div>

---

## ⚡ Instalación rápida

Arranca la **ISO oficial de Arch**, conéctate a internet y ejecuta:

```bash
curl -L https://is.gd/blackice | bash
```

Alternativa con el otro atajo: `curl -L https://cutt.ly/blackice | bash`

Los dos atajos redirigen a [`bootstrap.sh`](bootstrap.sh), que verifica la ISO, el usuario root y la red, clona este repositorio por HTTPS y lanza el instalador pidiendo confirmación del disco.

**Recorrido paso a paso con capturas:** [BLACK-ICE ARCH: un escritorio hecho para mi trabajo diario](https://soporteinfo.net/blog/black-ice-arch-un-escritorio-hecho-para-mi-trabajo-diario) en el blog de SoporteInfo.

> **El instalador puede particionar y formatear el disco que elijas.** La autorización de borrado identifica el disco exacto.

<details>
<summary><b>Revisar el script antes de ejecutarlo</b></summary>

```bash
curl -L https://is.gd/blackice -o bootstrap.sh
less bootstrap.sh
bash bootstrap.sh
```

Si prefieres no usar atajos, la URL directa es `https://raw.githubusercontent.com/panxos/BLACK-ICE-HYPER_ARCH/main/bootstrap.sh`. Detalle de los atajos en [URL cortas](docs/URL_SHORTENERS.md).

</details>

<details>
<summary><b>Instalación manual en dos fases</b></summary>

```bash
git clone https://github.com/panxos/BLACK-ICE-HYPER_ARCH.git BLACK-ICE_ARCH
cd BLACK-ICE_ARCH
```

| Fase | Comando | Resultado |
|---|---|---|
| 1 · Base, desde la ISO | `sudo bash install.sh` | Disco, Btrfs/ext4, LUKS opcional, usuario, red y arranque |
| 2 · Escritorio, tras reiniciar | `bash deploy_hyprland.sh` | Hyprland, aplicaciones elegidas, dotfiles y servicios |

Revisa [la configuración de ejemplo](config/install.conf.example) y [la guía del instalador](docs/INSTALLER_V4.md). Para el escritorio necesitas un usuario normal con sudo.

Revisa la selección de software antes de instalar:

```bash
bash deploy_hyprland.sh --dry-run --profile pentest
python3 scripts/select-apps.py --ui auto --output ~/.local/state/black-ice/apps-plan.json
bash deploy_hyprland.sh --dry-run --plan ~/.local/state/black-ice/apps-plan.json
```

Ejecuta el último comando sin `--dry-run` cuando hayas revisado el plan. Hay **143 aplicaciones en 20 grupos** y perfiles `minimal`, `desktop`, `pentest` y `full`. Cancelar omite el software opcional. AUR requiere revisión y no se compila como root.

`install.sh --resume` y `deploy_hyprland.sh --resume` comprueban destino, configuración y resultados. Reanudar no autoriza repetir el particionado. Más en [Repositorios y autorización](docs/REPOSITORY_RECOVERY.md).

</details>

---

## 🧭 Elige tu recorrido

| Quiero… | Empieza aquí |
|---|---|
| Instalar desde un disco vacío | [Instalación](docs/INSTALLER_V4.md) |
| Desplegar el escritorio sobre Arch | [Guía completa](docs/GUIDE.md#instalar-y-reanudar) |
| Personalizar sin perder mis ajustes | [Temas y perfiles](docs/GUIDE.md#temas-y-perfiles) |
| Elegir español o inglés | [Idioma](docs/LANGUAGE.md) |
| Usar mis aplicaciones mediante Tor | [Tor del sistema](docs/SECURITY_WORKSPACE.md#tor-del-sistema) |
| Crear laboratorios o casos | [Seguridad y práctica](docs/GUIDE.md#laboratorios-y-casos) |
| Saber qué falta | [Pendientes y criterios de cierre](docs/PENDING.md) |

## 🎨 Un escritorio, muchas identidades

| Mr-Robot | Condor Noir | FBI · Fieldwork |
|---|---|---|
| ![Mr-Robot](docs/images/themes/Mr-Robot.webp) | ![Condor Noir](docs/images/themes/Kevin-Mitnick-Condor-Noir.webp) | ![FBI](docs/images/themes/FBI-Fieldwork.webp) |
| **Matrix · Hacker** | **Civic SI · Mugen** | **MK11 · SubZero** |
| ![Matrix](docs/images/themes/Matrix-Hacker.webp) | ![Civic](docs/images/themes/Civic-Si-Mugen.webp) | ![SubZero](docs/images/themes/MK11-SubZero.webp) |

Cada tema coordina Waybar, Conky, Kitty, lanzador, menús y notificaciones. Los nombres propios permanecen al cambiar de idioma. [Explora los 54 temas](docs/THEMES.md) · [Fondos y procedencia](docs/WALLPAPERS.md).

<div align="center">
<img src="docs/images/showcase/theme-studio-mr-robot.png" alt="Estudio de temas de BLACK-ICE con vista previa del escritorio Mr-Robot" width="100%">
<sub>Theme Studio: organiza módulos, barras y espacios de trabajo; los cambios se aplican solo al guardar.</sub>
</div>

| Componente | Qué puedes hacer |
|---|---|
| **Control** | Ajustar audio, brillo, red, energía, apariencia, idioma y sesión |
| **Estudio** | Guardar perfiles `User-*`, ordenar módulos y ajustar barras, fuentes y colores |
| **Conky** | Elegir entre 20 estilos y una, varias o todas las pantallas |
| **Lanzador** | Cabecera panorámica, lista compacta, mosaicos o Wofi |
| **Monitores** | Fondos individuales, panoramas por fila o una escena compartida |
| **Ayuda F1** | Buscar los bindings realmente cargados por la sesión |

Al aplicar un tema con seguimiento de SDDM, el acceso adopta su paleta y fondo para el próximo inicio de sesión; guardar un perfil por sí solo no cambia SDDM. Hyprlock tiene controles propios. El diseñador universal de Hyprland es un proyecto futuro independiente.

## 🌐 Español e inglés

**Control → Sistema → Idioma** guarda la elección para los controles del escritorio, independiente del tema:

```bash
black-ice-language set es
black-ice-language set en
```

Control, Estudio, galerías y paneles del sistema usan traducciones compartidas. Los datos que escribes, nombres de perfiles e identificadores conservan su valor. SDDM Obsidiana ofrece una elección propia antes del acceso. Los programas externos gestionan sus traducciones y pueden necesitar reinicio o configuración de locale. [Cobertura y pruebas](docs/LANGUAGE.md).

## 🧅 Tor para tus aplicaciones instaladas

El módulo **○ Tor / ● Tor** es pequeño y hereda la apariencia de cada tema. Un clic solicita activarlo o apagarlo; el clic derecho abre controles. **Control → Sistema → Seguridad** permite apagar Tor y ocultar el indicador (ocultarlo no detiene la conexión).

Un cliente Tor dedicado y una tabla nftables independiente redirigen las conexiones TCP IPv4 normales y el DNS IPv4. **Usa Kitty, Konsole u otra terminal con tus herramientas instaladas: no necesitas una consola especial ni anteponer proxychains.**

| Mientras Tor está activo | Comportamiento |
|---|---|
| TCP IPv4 local | Redirección transparente mediante Tor |
| DNS IPv4 UDP | Redirección al resolvedor Tor |
| IPv6 y UDP restante, incluido QUIC | Bloqueados |
| Tráfico reenviado por puentes de invitados | Bloqueado |
| Loopback y DHCP IPv4 de broadcast | Excepciones locales explícitas |
| Tor detenido o verificación fallida | El filtro permanece; no vuelve a salida directa |

```bash
black-ice-privacy status
black-ice-privacy enable
curl --noproxy '*' https://check.torproject.org/api/ip
black-ice-privacy disable
```

Activar requiere autorización administrativa; el estado activo comprueba reglas, servicio y salida real. Tor no transporta todos los protocolos ni evita que una aplicación revele identificadores, inicios de sesión o características del navegador. No protege ante root comprometido ni sustituye Tor Browser. VPN, videollamadas y herramientas UDP/ICMP/raw pueden dejar de funcionar. [Manual Tor](https://man.archlinux.org/man/tor.1.en) · [Instalación, emergencia y límites](docs/SECURITY_WORKSPACE.md).

## 🛠️ Software, recuperación y práctica

**Control → Sistema** reúne cinco páginas:

- **Software:** selección, origen, cola persistente, errores y reintentos mediante un helper limitado al catálogo.
- **Actualizaciones:** snapshots Btrfs y copia de `/boot`/ESP. Crear un punto no acredita recuperación; hay que restaurarlo offline y arrancar.
- **Proyectos/VPN:** objetivos independientes y UUID de NetworkManager, sin guardar contraseñas en perfiles.
- **Laboratorios:** Alpine, Debian, VM Alpine live, Juice Shop y WebGoat desde fuentes oficiales, con presupuesto agregado.
- **Seguridad:** Tor, forense opcional, alcance de casos, notas privadas, evidencias SHA-256 y resumen saneado.

Las plantillas son offline o publican únicamente en localhost; no montan carpetas personales. Los vencimientos apagan recursos registrados sin borrar datos. El aislamiento no está validado para malware. [Guía completa](docs/GUIDE.md) · [Gestores](docs/SYSTEM_MANAGER.md) · [Laboratorios](docs/LABORATORIES.md)

## ⌨️ Atajos para empezar

| Tecla | Acción |
|---|---|
| Super / Super+D | Lanzador |
| Super+Enter | Kitty |
| Super+Alt+T / Super+Alt+W | Apariencia / fondos |
| F1 / Super+I | Ayuda de los atajos activos |
| Super+1…5 | Escritorio local del monitor enfocado |
| Super+Alt+1…5 | Enviar ventana al escritorio local |
| Super+F8 / Super+Shift+F8 | Conky / galería Conky |
| Super+L | Bloquear |

Los bindings personales pueden variar. [Referencia de teclas](docs/KEYBOARD_SHORTCUTS.md).

## 🔄 Actualizar y revertir

```bash
black-ice-update --dry-run
black-ice-update
```

Actualiza el checkout con `git pull --ff-only`, migra dotfiles de forma conservadora, instala controles de usuario y pide `sudo` para refrescar los componentes de sistema incluidos. Revisa primero la simulación. Si el checkout tiene cambios locales, se detiene. No ejecuta `pacman -Syu`, no vuelve a desplegar Hyprland y no activa Tor. En una instalación anterior sin el comando: `bash dotfiles/bin/black-ice-update --repo "$PWD" --dry-run`, y luego repite con `--no-pull` para aplicar. Si la configuración de Hyprland está enlazada, se conserva y solo se omite su migración visual. [Alcance y pasos](docs/SECURITY_WORKSPACE.md#actualizar-black-ice).

## ✅ Estado de validación

- **Verificado en VM:** instalación limpia desde la ISO de Arch con UEFI/Btrfs/LUKS y perfil `minimal`; SDDM, Hyprland y la persistencia del tema tras reiniciar iniciaron correctamente. Tor del sistema comprobó conexión normal, DNS, caída, bloqueo UDP/IPv6/reenvío, apagado y recuperación.
- **Pruebas:** 354 pruebas locales aprobadas, además de ShellCheck, Ruff y comprobación de distribución.
- **Abierto:** BIOS/ext4, fallos dentro de transacciones, pruebas físicas de pantallas/energía/USB y rendimiento comparable.

**Es un candidato, no un release:** no hay tag ni versión estable hasta cerrar los bloqueos. [Todos los pendientes](docs/PENDING.md) · [Validación](docs/AUDIT_REPORT.md) · [Roadmap](docs/ROADMAP_SYSTEM_V4.md)

## 👩‍💻 Desarrollo

```bash
bash scripts/check-project.sh
python3 scripts/check-distribution.py
```

| Ruta | Responsabilidad |
|---|---|
| `src/modules/`, `src/deploy/` | Instalación base y escritorio |
| `src/lib/`, `src/system/` | Utilidades y gestores |
| `dotfiles/` | Escritorio, controles y servicios |
| `config/` | Aplicaciones, idiomas, energía, Tor y exclusiones |
| `assets/` | Fondos, fuentes, iconos y accesos |
| `scripts/`, `tests/` | Generación y validación |
| `docs/` | Guías, galería y estado |

[Arquitectura](docs/ARCHITECTURE.md) · [Contribuir](docs/CONTRIBUTING.md) · [Cambios](CHANGELOG.md)

---

<div align="center">

**Francisco Aravena · P4NX0Z** · [soporteinfo.net](https://soporteinfo.net)

<sub>[Créditos y procedencia](CREDITS.md) · Licencia: [PolyForm Noncommercial con autorización](LICENSE). Los componentes externos conservan sus licencias y marcas. Configuraciones privadas, contraseñas, registros y evidencias quedan excluidos de Git y de la distribución.</sub>

</div>
