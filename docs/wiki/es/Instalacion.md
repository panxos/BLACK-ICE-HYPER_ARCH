# Instalación

Consulta [Instalador 4.0](../../INSTALLER_V4.md) antes de comenzar. El candidato está publicado en `main`, sin release.

La fase base usa `sudo bash install.sh` desde la ISO Arch y particiona el disco elegido. Después de reiniciar e iniciar sesión como usuario normal, `bash deploy_hyprland.sh` configura el escritorio.

Inspecciona primero `bash deploy_hyprland.sh --dry-run --profile pentest`. Elige aplicaciones individualmente, por grupos o perfiles; Cancelar omite software opcional. Las opciones `--resume` validan el registro y no repiten automáticamente el particionado.

[Compatibilidad](../../COMPATIBILITY_MATRIX.md) · [Configuración de temas](../../THEME_STUDIO.md).
