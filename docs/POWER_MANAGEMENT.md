# Gestión de energía

La política vigente está en [Energía automática](AUTOMATIC_POWER.md). Sustituye la guía antigua que describía rendimiento fijo con corriente.

En portátiles con TLP compatible, Automático utiliza Equilibrado con corriente y Ahorro con batería. El menú detecta el backend activo y permite perfiles manuales. Los gobernadores disponibles dependen del controlador; no se debe asumir que `powersave` equivale a una frecuencia fija.

Con corriente, las acciones automáticas conservan bloqueo y evitan suspensión. Con batería confirmada, se aplican los tiempos de brillo, bloqueo, pantalla y suspensión del guard. Las VM y estados desconocidos no suspenden automáticamente.

**Super+Shift+P** abre perfiles. Consulta el estado con `sudo tlp-stat -s` y `~/.config/hypr/scripts/ac_guard.sh status`. Los ajustes de portátil no se aplican indiscriminadamente a equipos de escritorio.

La política con corriente fue revisada localmente; desconexión física, suspensión en batería y comparación térmica sostenida permanecen pendientes. [Compatibilidad](COMPATIBILITY_MATRIX.md).
