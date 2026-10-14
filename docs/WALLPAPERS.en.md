# Desktop wallpapers

The theme catalog uses source images stored in `assets/wallpapers/cyber/` and `dotfiles/wallpapers/`. It does not include enlarged copies that claim 4K dimensions without adding native detail; those duplicate files added hundreds of MiB to the repository.

Hyprland, Waypaper, Waybar, and SDDM scale images to the available display area. Panoramas keep their aspect ratio and are positioned for the connected monitor layout. Scene profiles preserve their original composition. Final sharpness depends on the source image and the display resolution.

To change a theme wallpaper, edit `dotfiles/waybar/cyber-catalog.json` and regenerate its profiles:

```bash
python3 scripts/build-waybar-themes.py
python3 scripts/check-distribution.py
```

The generator checks that every catalog image exists before writing profile files. `assets/wallpapers/cyber/sources.json` records external resource sources. Assets not listed there are maintained within the project.

SDDM keeps the selected source file's format and bytes. The theme scales it to the display resolution, so it does not need a second UHD copy.
