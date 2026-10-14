# Desktop language

[Español](LANGUAGE.md) · [Guide](GUIDE.en.md) · [README](../README.en.md)

Choose **Control → System → Language → English / Español**. The choice persists in `~/.config/black-ice/language.json`, independently of themes and personal profiles. Without a preference, `LC_ALL`, `LC_MESSAGES` or `LANG` provides the default: Spanish for an `es` prefix, English otherwise.

```bash
black-ice-language status
black-ice-language set en
black-ice-language set es
```

## Coverage

| Surface | Translated presentation |
|---|---|
| Control | Navigation, buttons, descriptions and controls |
| Studio | Tabs, options, messages and preview labels |
| Theme and Conky galleries | Actions, descriptions and positions |
| System center | Software, recovery, projects, laboratories and security |
| Tor | Panel, states and indicator help |
| Rofi | Application title and search |
| SDDM Obsidiana and cybersec | Separate language choice before login |

Open GTK windows check the preference while they exist; switching does not require a theme reload. Typed input, paths, personal names, combo identifiers and brands retain their values. Technical logs and external program output retain their original language.

SDDM runs before the desktop session, so its language is chosen in the greeter. Other external greeters and applications such as browsers, Dolphin and editors manage translations through their settings and locale. A BLACK-ICE preference does not guarantee complete translation of unrelated software.

## Maintenance

`dotfiles/bin/black_ice_i18n.py` shares preference storage and presentation translation. `config/i18n/en.json` maps Spanish text to English. Installers distribute both together. GTK bindings translate visible properties while preserving values used by application logic and user input. Drawn labels and Rofi call the translator explicitly.

Override the language for a test without saving preferences:

```bash
BLACK_ICE_LANGUAGE=en black-ice-theme-studio
BLACK_ICE_LANGUAGE=es black-ice-control
GDK_BACKEND=x11 xvfb-run -a python3 -m unittest discover -s tests -p test_language.py
```

Tests cover persistence, live switching, dynamic labels, restoration to Spanish, option IDs and unchanged typed input. Inspect captures too: catalog tests alone cannot detect an untranslated tab or drawn label.
