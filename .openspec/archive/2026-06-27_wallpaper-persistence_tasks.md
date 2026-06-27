# Tasks — fix-wallpaper-persistence-and-bugs
**Change:** fix-wallpaper-persistence-and-bugs

- [x] Bug 1: `dotfiles/hypr/scripts/set_wallpaper.sh` — usar waypaper/config.ini como source of truth (grep "^wallpaper " | head -1)
- [x] Bug 2: `dotfiles/bin/theme_selector` — actualizar waypaper/config.ini cuando cambia el wallpaper
- [x] Bug 3: `src/deploy/04_theme_setup.sh` — escribir ~/.cache/current_wallpaper al instalar
- [x] Bug 4: `dotfiles/bin/wofi-launcher` — agregar bit de ejecución (chmod +x)
