# Seguridad y configuración

BLACK-ICE instala paquetes, configura servicios y puede particionar discos. Sus protecciones reducen fallos concretos; no constituyen una certificación de seguridad.

## Instalación

- El sistema base requiere ISO live y comprueba discos, montajes, swap, volúmenes activos y modo de solo lectura.
- La automatización exige confirmar la ruta exacta del disco. Reanudar valida UUID y registro; no repite el particionado.
- Se mantienen firmas de paquetes y dependencias. Los fallos no se resuelven mediante `-Rdd` ni sobrescritura global.
- Las configuraciones con contraseñas requieren propiedad root y modo `600`. Las contraseñas se transmiten por stdin y se excluyen de la distribución.
- Las instalaciones nuevas requieren autenticación sudo. Docker no incorpora automáticamente al usuario a un grupo con privilegios equivalentes a root.

Revisa scripts, planes y paquetes AUR antes de autorizarlos. No ejecutes una copia descargada sin inspección solo porque un README la anuncia como segura.

## Operaciones

El centro de sistema se ejecuta sin privilegios; el helper administrativo valida acciones y catálogo. Las transacciones de pacman no se interrumpen a mitad por pulsar Cancelar. La restauración Btrfs se realiza offline y conserva la raíz anterior.

Los laboratorios administran únicamente recursos propios. Los contenedores rootless usan límites de memoria/PIDs y capacidades reducidas. Todavía no hay cuota global para las imágenes del motor. NetworkManager mantiene las credenciales VPN; los proyectos referencian sus UUID.

## Datos privados

Los registros y planes están en los directorios de estado del usuario o del sistema. No publiques `install.conf`, archivos `.env`, claves, perfiles VPN, objetivos reales ni capturas con datos de clientes.

`.gitignore` y `config/distribution-excludes.txt` excluyen material local. Antes de publicar revisa los archivos candidatos y ejecuta un detector de secretos; estos filtros no sustituyen esa revisión.

## Informar un problema

Incluye versión, paso que falla, salida saneada y reproducción mínima. Retira credenciales y datos privados antes de abrir un issue. Los problemas que exponen secretos deben comunicarse por un canal privado acordado con el mantenedor.

Consulta [validación](AUDIT_REPORT.md) y [límites de compatibilidad](COMPATIBILITY_MATRIX.md). La matriz de fallos dentro de transacciones, cuotas y pruebas físicas continúa abierta.
