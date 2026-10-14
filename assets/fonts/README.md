# Fuentes del escritorio

Los archivos incorporados conservan sus licencias originales. `sources.json` registra procedencia, revisión y SHA-256.

| Familia | Ubicación | Licencia incluida |
|---|---|---|
| Inter | `inter/` | OFL |
| Ubuntu Sans | `ubuntu-sans/` | Ubuntu Font Licence |
| Barlow Condensed | `barlowcondensed/` | OFL |
| Oxanium | `oxanium/` | OFL |
| Rajdhani | `rajdhani/` | OFL |
| Share Tech Mono | `share-tech-mono/` | OFL |
| Noto Sans JP | `noto-sans-jp/` | OFL |

Roboto se instala mediante `ttf-roboto`; los símbolos usan las dependencias Nerd Font. El catálogo utiliza siete familias principales, con Noto Sans JP como apoyo para escritorios japoneses.

Los instaladores copian los recursos a `~/.local/share/fonts/black-ice/` con manifiesto y reversión. Comprueba la familia efectiva con `fc-match Inter` o `fc-match 'Ubuntu Sans'`; una configuración CSS por sí sola no prueba que la fuente esté instalada.
