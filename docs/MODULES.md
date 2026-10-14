# Módulos y puntos de entrada

## Sistema base

| Archivo en `src/modules/` | Responsabilidad |
|---|---|
| `00_environment.sh` | Entorno live, conectividad, idioma y selección |
| `01_disk.sh` | Disco, particiones y cifrado opcional |
| `02_base.sh` | Paquetes base y fstab |
| `03_config.sh` | Locale, hostname y configuración del sistema |
| `04_user.sh` | Usuario, contraseñas y sudo |
| `05_bootloader.sh` | GRUB y arranque BIOS/UEFI |
| `06_power.sh` | Política de energía según hardware |
| `99_final.sh` | Auditoría y copia filtrada del proyecto |

## Escritorio

| Archivo en `src/deploy/` | Responsabilidad |
|---|---|
| `00_repositories.sh` | Repositorios y gestor AUR |
| `01_hyprland_base.sh` | Hyprland, Waybar, Rofi/Wofi, Kitty y dependencias |
| `02_security_tools.sh` | Herramientas de seguridad seleccionadas |
| `03_terminal_config.sh` | Zsh, prompt y Fastfetch |
| `04_theme_setup.sh` | Recursos de apariencia y configuración |
| `05_software_suite.sh` | Aplicaciones opcionales del plan |
| `06_sddm_setup.sh` | Acceso SDDM |
| `07_neovim_setup.sh` | Neovim/NvChad opcional |
| `08_ai_tools.sh` | Asistentes opcionales sujetos a la selección |
| `09_grub_theme.sh` | Tema Cyberpunk Arcade de arranque |
| `99_finalization.sh` | Servicios, integración y verificación final |

`src/lib/module-runner.sh` coordina el registro de módulos; `install-safety.sh` valida destinos y entradas; `post-install-audit.sh` comprueba resultados. `logging.sh`, `utils.sh` y `colors.sh` comparten utilidades.

## Herramientas del escritorio

`black-ice-control` reúne preferencias. `black-ice-theme-studio` configura perfiles. `black-ice-appearance`, `black-ice-waybar`, `black-ice-wallpaper` y `black-ice-workspaces` aplican/adaptan la apariencia. `black-ice-conky` supervisa telemetría; `black-ice-launcher` abre aplicaciones y `cheatsheet` muestra bindings activos.

`src/system/manager.py` implementa software, recuperación, objetivos/VPN y laboratorios para `black-ice-system`. La interfaz usa el helper limitado `system-transaction` para operaciones administrativas.

[Arquitectura](ARCHITECTURE.md) · [Instalación](INSTALLER_V4.md) · [Sistema](SYSTEM_MANAGER.md).
