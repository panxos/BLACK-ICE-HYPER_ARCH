# Idioma del escritorio

[English](LANGUAGE.en.md) · [Guía](GUIDE.md) · [README](../README.md)

Elige **Control → Sistema → Idioma → Español / English**. La elección se guarda en `~/.config/black-ice/language.json`; no pertenece a un tema ni cambia tus perfiles. Sin preferencia, se utiliza el idioma de `LC_ALL`, `LC_MESSAGES` o `LANG`: español si comienza por `es`, inglés en los demás casos.

```bash
black-ice-language status
black-ice-language set en
black-ice-language set es
```

## Qué cambia

| Superficie | Comportamiento |
|---|---|
| Control | Navegación, botones, descripciones y controles |
| Estudio | Pestañas, opciones, mensajes y etiquetas de la vista previa |
| Galerías de temas y Conky | Acciones, descripciones y posiciones |
| Centro de sistema | Software, recuperación, proyectos, laboratorios y seguridad |
| Tor | Panel, estados y ayuda del indicador |
| Rofi | Título y búsqueda de aplicaciones |
| SDDM Obsidiana y cybersec | Selector propio de idioma antes del acceso |

Las ventanas GTK abiertas revisan la preferencia mientras existen; los cambios no requieren recargar el tema. El texto de entradas, rutas, nombres personales, identificadores de combos y marcas se conserva. Los registros técnicos y la salida de programas externos mantienen su idioma de origen.

SDDM es un proceso anterior a la sesión: su elección se hace en el propio acceso. Otros greeters externos y aplicaciones como navegadores, Dolphin o editores gestionan sus traducciones mediante sus ajustes y el locale. La preferencia de BLACK-ICE no implica que cualquier programa ajeno tenga traducción completa.

## Cómo se mantiene

`dotfiles/bin/black_ice_i18n.py` comparte lectura, persistencia y traducción de presentación. `config/i18n/en.json` relaciona texto español e inglés. Los instaladores distribuyen ambos juntos. El binding GTK traduce propiedades visibles; conserva los valores usados por la lógica y los datos del usuario. Las etiquetas dibujadas y Rofi llaman explícitamente al traductor.

Puedes forzar el idioma de una prueba sin guardar preferencias:

```bash
BLACK_ICE_LANGUAGE=en black-ice-theme-studio
BLACK_ICE_LANGUAGE=es black-ice-control
GDK_BACKEND=x11 xvfb-run -a python3 -m unittest discover -s tests -p test_language.py
```

Las pruebas comprueban persistencia, cambios en vivo, textos dinámicos, restauración al español, IDs de opciones y conservación del texto escrito. Las capturas deben revisarse también: un test de catálogo no detecta por sí solo una pestaña o una etiqueta dibujada que quedó sin traducir.
