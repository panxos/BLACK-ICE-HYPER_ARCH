# CyberSec SDDM Theme

A high-contrast, cyberpunk/infosec themed login screen for SDDM.

## Features

- **Animated Background**: Procedural grid and scanline effects (Shader-based).
- **Secure Visuals**: 'Hidden' password fields, system status indicators.
- **Custom Components**: Neon-styled inputs and buttons.
- **Lightweight**: No heavy image assets, fully QML/GLSL.

## Installation

### Automated (Arch Linux)

Run the included install script as root:

```bash
chmod +x install.sh
sudo ./install.sh
```

### Manual

1. Copy the `cybersec` folder to `/usr/share/sddm/themes/`.
2. Edit `/etc/sddm.conf` or `/etc/sddm.conf.d/theme.conf`:

   ```ini
   [Theme]
   Current=cybersec
   ```

3. Ensure dependencies are installed:
   - `qt5-graphicaleffects`
   - `qt5-quickcontrols2`
   - `ttf-jetbrains-mono` (Font)

## Configuration

Edit `theme.conf` inside the theme directory to change colors or fonts:

```ini
[General]
accentColor=#00ffff
secondaryColor=#8a2be2
background=#000000
```

## Troubleshooting

If you see a white screen or errors:

- Check that `qt5-graphicaleffects` is installed.
- Check logs: `journalctl -u sddm`
