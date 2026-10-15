# Gestores de sistema — 4.0.0-dev.2

Candidato local, sin publicar. Control incorpora accesos a Software, Actualizaciones, Proyectos/VPN, Laboratorios y Seguridad. La implementación está en validación; las pruebas unitarias no sustituyen una restauración o instalación real.

## Instalación y reanudación

Desde la ISO, `bash install.sh --resume` requiere la configuración automática original. Monta las particiones existentes, comprueba UUID y huella de configuración y conserva el disco. Si no existe registro, aborta: nunca repite el particionado automáticamente. Una interrupción durante el formateo requiere inspección manual.

`bash deploy_hyprland.sh --resume` conserva el plan de aplicaciones. Cada módulo se omite solo si su hash y comprobaciones coinciden; al repetir un módulo se invalidan sus dependientes. El software opcional vuelve a reconciliarse con pacman. Los registros privados están en `/var/lib/black-ice/install/` y `$XDG_STATE_HOME/black-ice/`.

## Software y recuperación

`black-ice-system software` abre el catálogo con búsqueda, grupos, perfiles, dependencias y cola persistente. Cancelar evita iniciar trabajos pendientes; una transacción de pacman en curso termina antes de continuar. Reintentar consulta los paquetes realmente instalados. Las aplicaciones AUR no disponibles en repositorios requieren revisión e instalación manual con paru; no se compilan como root.

El helper `/usr/lib/black-ice/system-transaction` solo acepta acciones y paquetes del catálogo instalado por root. Las instalaciones realizan una actualización completa. No elimina bloqueos de pacman ni fuerza dependencias. En Btrfs crea un snapshot y copia `/boot`/ESP; en otros sistemas no promete recuperación completa.

Desde una ISO de rescate, con el destino desmontado y el helper disponible:

```bash
python3 system-transaction.py restore-offline --snapshot NUMERO --uuid UUID --confirm NUMERO
```

Conserva la raíz anterior como `@before-recovery-*`. Tras arrancar, `sudo /usr/lib/black-ice/system-transaction verify-recovery --snapshot NUMERO` comprueba UUID, paquetes, kernel, archivos de arranque y configuración GRUB. Solo entonces registra el punto como verificado. Se probó el ciclo completo con eliminación/restauración de un paquete en la VM; consulta [la validación](AUDIT_REPORT.md).

## Proyectos y laboratorios

`black-ice-system projects` separa objetivos y perfiles VPN por proyecto. Los perfiles se referencian por UUID de NetworkManager; las credenciales permanecen en su almacén. Conectar y desconectar son acciones explícitas. Se comprueba la identidad de la activación, el servicio y el arranque para no desconectar una VPN reactivada externamente. El estado HTB requiere `tun0` activa y con IPv4; una interfaz baja no cuenta como conectada.

`black-ice-system labs` usa KVM de sesión o contenedores rootless. Presupuesto inicial agregado: 4 vCPU, 4096 MiB RAM y 60 GiB de disco. Red aislada por defecto, imágenes verificadas por SHA256/digest y operaciones limitadas al registro propio. Los contenedores tienen raíz de solo lectura, memoria/PIDs limitados y sin capacidades adicionales. El almacén nuevo cuenta con control de caché durante preparación y limpieza revisable; no constituye una cuota física del sistema de archivos.

El [asistente guiado](LABORATORIES.md) prepara Linux ligero, Linux completo, VM live, Juice Shop y WebGoat; muestra requisitos, instala solo tras confirmar y calcula/verifica integridad automáticamente. **Crear y abrir** inicia la consola o abre la aplicación web local después de comprobar HTTP. La importación de imágenes propias queda en Avanzado. Antes de iniciar/abrir, el motor vuelve a comprobar red, capacidades, privilegios, montajes y usuario.

`black-ice-system security` reúne perfiles forenses, casos, evidencias, controles de caché y vencimientos. `black-ice-privacy` controla Tor transparente del sistema, sin abrir una consola especial. La página Seguridad permite apagarlo y ocultar el indicador independientemente. Alcance, instalación y comprobaciones en [Puesto de seguridad](SECURITY_WORKSPACE.md).

Control → Sistema → Idioma selecciona español/inglés para los paneles y el Estudio. La preferencia es independiente de los temas y no traduce datos escritos por el usuario. [Idioma](LANGUAGE.md) y [guía en inglés](GUIDE.en.md).

La CLI permite exportar proyectos sin VPN/notas y plantillas de laboratorio, usando `projects export NOMBRE --output ARCHIVO` o `labs export NOMBRE --output ARCHIVO`.

El inicio de un laboratorio vuelve a comprobar sus límites. El apagado forzado requiere confirmar el nombre; eliminar una VM en ejecución se rechaza. Solo se gestionan UUID, discos y etiquetas pertenecientes al registro propio.

## Cobertura pendiente

Faltan retención de copias de arranque por cuota, actualización completa entre versiones BLACK-ICE (sistema, dotfiles y migraciones), archivado de trabajos, cuotas físicas y snapshots de laboratorios, VPN contra un servidor real y la matriz completa de fallos/instalación. Los vencimientos y controles de preparación ya tienen implementación, con distribución final/revisión nativa pendientes. Los hooks Snapper usan retención numérica; eso no sustituye una cuota para las copias privadas de `/boot` ni demuestra toda la aceptación del plan.

## Evidencia

`scripts/check-project.sh` incluye pruebas GTK bajo Xvfb. `scripts/qa-system.py --output INFORME --desktop --performance` registra entorno, resultados y tres mediciones de diez minutos. No suspende el equipo físico. La matriz BIOS/ext4/LUKS y las pruebas físicas permanecen pendientes hasta disponer de evidencia propia.
