# Atajos de teclado

**F1** o **Super+I** abre la ayuda buscable con la paleta del tema. Lee los bindings de la sesión activa, agrupa acciones y señala ejecutables ausentes. Las funciones Lua opacas sin descripción no se presentan como verificadas.

| Atajo predeterminado | Acción |
|---|---|
| Super / Super+D | Abrir o cerrar el lanzador |
| Super+Enter | Kitty |
| Super+Q | Cerrar ventana |
| Super+V | Flotante |
| Super+F | Pantalla completa |
| Super+Tab | Selector de ventanas |
| Super+1…5 | Escritorio local del monitor enfocado |
| Super+Alt+1…5 | Enviar ventana al escritorio local |
| Super+flechas | Foco entre ventanas |
| Super+Alt+T | BLACK-ICE Control → Apariencia |
| Super+Alt+W | Galería de fondos |
| Super+Shift+F9 | Panel general |
| Super+F8 | Mostrar u ocultar Conky |
| Super+Shift+F8 | Galería de estilos Conky |
| Super+L | Bloquear pantalla |
| Super+Shift+P | Perfil de energía |
| Super+H | Portapapeles |
| Super+Shift+X | Menú KeePassXC |
| Super+Ctrl+Enter | Sesiones de terminal |

La configuración personal puede añadir o modificar atajos. **La ventana F1 es la referencia efectiva**; esta tabla resume los predeterminados. Comprobar que existe un comando no verifica sus credenciales ni todos sus flujos.

Los escritorios locales muestran cinco posiciones por salida y mantienen identificadores estables. Los atajos de otra pantalla no trasladan automáticamente las ventanas existentes. [Detalles](DESKTOP_STABILITY.md).

## Diagnóstico

Ejecuta `~/.local/bin/cheatsheet --check` para consultar las dependencias. Si F1 no aparece, comprueba que la actualización haya instalado `cheatsheet` y su inclusión en la configuración activa. El instalador conserva bindings personales y evita registrar F1 por duplicado.
