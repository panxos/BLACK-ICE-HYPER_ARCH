# Puestos de trabajo de agencias

Tres variantes nuevas representan el equipo de trabajo de un agente. Los temas anteriores NSA-Signal, FBI-Casefile y MI5-Thames conservan sus fondos y diseños.

| Tema | Identidad | Fuente | Barras |
|---|---|---|---|
| FBI-Fieldwork | Azul oscuro y latón | Barlow Condensed | Una arriba |
| NSA-Intercept | Medianoche, plata y cian suave | Inter | Dos, escritorios abajo |
| MI5-Operations | Carbón verde y champagne | Ubuntu Sans | Una abajo |

Todos incluyen cortes angulares con bisel, contraste reforzado, módulos de seguridad y Conky discreto en el espacio vacío del fondo. Cada salida recibe su barra; bandeja y controles permanecen a la derecha. Las preferencias permiten mover, cambiar estilo o desactivar Conky.

## Elegir escritorio y acceso

Abre Control → Apariencia con **Super+Alt+T** y aplica la variante; SDDM recibe su paleta y fondo para el próximo acceso. El Estudio de temas → Acceso/bloqueo permite revisar la vista previa y ajustar esta preferencia. Instalar un pack o guardar un perfil personal no cambia el acceso automáticamente.

Los temas de acceso se llaman `black-ice-fbi-fieldwork`, `black-ice-nsa-intercept` y `black-ice-mi5-operations`. El instalador los incorpora en el módulo SDDM. En una instalación existente:

```bash
python3 scripts/install-cyber-themes.py --apply
sudo python3 scripts/install-agency-themes.py --apply
```

Cada pack incluye su fuente y licencia; SDDM no depende de fuentes privadas del usuario. Instalarlo no cambia la selección global de acceso.

## Validación local

Las tres vistas previas de acceso abrieron en la VM sin errores QML; se revisaron las capturas y la carga de fuentes. Cada variante pasó autenticación real de Benjie y volvió al escritorio sin errores de configuración. Los registros de SDDM confirman la ruta de cada tema; después se retiró la selección temporal de QA. También se aplicaron los tres escritorios, revisando barras y Conky, y se restauró Anubis-Sethek en la VM. El catálogo contiene 54 temas. Las 195 pruebas automatizadas, dos pruebas GTK, Ruff y ShellCheck pasaron; estos resultados no sustituyen la revisión personal en varias pantallas.

## Recursos y calidad

Las composiciones y derivados están en `assets/wallpapers/cyber/`; las dimensiones, métodos y hashes están en `upscaled.json`. Los derivados superan 3840×2160 mediante reescalado Lanczos local; no se presentan como detalle nativo 4K. Las vistas previas personales de SDDM conservan los bytes y la resolución del fondo seleccionado.

Los emblemas son interpretaciones cinematográficas, no réplicas oficiales. La zona izquierda queda libre para el formulario real de SDDM; el fondo no contiene campos de contraseña ni indicadores inventados.
