# Repository Guidelines

## Estructura y módulos

`install.sh` instala Arch desde la ISO; `deploy_hyprland.sh` configura el escritorio desde el usuario instalado. Sus etapas viven en `src/modules/` y `src/deploy/`; las utilidades comunes, en `src/lib/`. `src/system/manager.py` implementa software, proyectos y laboratorios.

`dotfiles/` contiene configuración y ejecutables del escritorio. `assets/` reúne imágenes, fuentes, iconos y accesos SDDM. `config/apps.json` define aplicaciones y grupos; `VERSION`, la versión propia. `tests/` contiene pruebas y `docs/`, las guías.

## Desarrollo y comprobaciones

- `bash deploy_hyprland.sh --dry-run --profile minimal`: inspecciona el plan sin instalar.
- `bash scripts/check-project.sh`: ejecuta sintaxis Bash, ShellCheck, Ruff, unittest y pruebas GTK bajo Xvfb.
- `python3 -m unittest discover -s tests`: ejecuta pruebas funcionales; algunas requieren pantalla.
- `python3 scripts/build-waybar-themes.py --theme Fsociety`: regenera un tema desde sus catálogos.
- `python3 scripts/install-cyber-themes.py --dry-run`: revisa cambios antes de aplicar al usuario actual.

No hay compilación única del proyecto. Usa Arch y sus paquetes de desarrollo; para GTK necesitas `python-gobject`, `gtk3` y `xorg-server-xvfb`.

## Estilo y nombres

Python utiliza cuatro espacios, funciones `snake_case`, `pathlib` y Ruff. Bash debe citar rutas, comprobar errores y pasar ShellCheck. Conserva las convenciones del archivo existente. Los ejecutables públicos usan `black-ice-*`; los perfiles personales, `User-*`. Modifica el catálogo de Waybar antes de regenerar sus derivados.

## Pruebas

Nombra archivos `test_*.py` y clases derivadas de `unittest.TestCase`. Verifica comportamiento y casos de error; no uses discos reales, suspensión ni servicios personales como fixtures. No hay umbral porcentual de cobertura definido. La instalación y recuperación reales tienen aceptación independiente de las pruebas unitarias.

## Commits y revisión

El historial utiliza principalmente `fix:` y `feat:` con descripciones concretas. Explica problema, cambio y validación en cada PR; enlaza el issue cuando exista. Adjunta capturas para cambios visuales y declara pruebas físicas pendientes. No incluyas credenciales, registros personales ni metadatos locales; revisa `.gitignore` y `config/distribution-excludes.txt`.
