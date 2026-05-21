# 🎨 Customization - BLACK-ICE ARCH

Complete guide for customizing your BLACK-ICE ARCH environment.

---

## 🎨 Themes

### Change GTK Theme

```bash
# View current theme
gsettings get org.gnome.desktop.interface gtk-theme

# Switch to Sweet-Dark
gsettings set org.gnome.desktop.interface gtk-theme 'Sweet-Dark'

# Other available themes
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
```

### Change Qt Theme

```bash
# Edit qt5ct
nano ~/.config/qt5ct/qt5ct.conf

# Change style
[Appearance]
style=kvantum
icon_theme=candy-icons
color_scheme_path=~/.config/qt5ct/colors/Sweet-Dark.conf

# Apply via qt5ct (GUI)
qt5ct
```

### Kvantum Themes

```bash
# List available themes
ls /usr/share/Kvantum/

# Change theme via GUI
kvantummanager

# Or via command
kvantummanager --set Sweet-Dark
```

---

## 🖼️ Wallpapers

### Change Wallpaper

```bash
# Interactive selector
~/.config/bin/wallpaper_switcher

# Or with shortcut
Super + Alt + W

# Change manually
awww img /path/to/image.png
```

### Add Your Own Wallpapers

```bash
# Copy to wallpapers directory
cp my-wallpaper.jpg ~/.config/wallpapers/

# Apply
awww img ~/.config/wallpapers/my-wallpaper.jpg
```

### Random Wallpaper on Startup

```bash
# Edit hyprland.conf
nano ~/.config/hypr/hyprland.conf

# Add
exec-once = ~/.config/bin/random_wallpaper.sh
```

---

## 🎯 Waybar

### Customize Modules

```bash
# Edit configuration
nano ~/.config/waybar/config

# Example: Add battery module
"battery": {
    "format": "{capacity}% {icon}",
    "format-icons": ["", "", "", "", ""]
}
```

### Change Styles

```bash
# Edit CSS
nano ~/.config/waybar/style.css

# Example: Change background color
window#waybar {
    background-color: rgba(26, 27, 38, 0.95);
}
```

### Waybar Themes

```bash
# List available themes
ls ~/.config/waybar/themes/

# Switch theme
cp ~/.config/waybar/themes/cyber-neon/config ~/.config/waybar/config
cp ~/.config/waybar/themes/cyber-neon/style.css ~/.config/waybar/style.css

# Restart Waybar
killall waybar && waybar &
```

---

## 🖥️ Hyprland

### Animations

```bash
# Edit hyprland.conf
nano ~/.config/hypr/hyprland.conf

# Customize animations
animations {
    enabled = yes

    bezier = myBezier, 0.05, 0.9, 0.1, 1.05

    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}
```

### Window Borders

```bash
# Border colors
general {
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    border_size = 2
}
```

### Gaps

```bash
# Gaps between windows
general {
    gaps_in = 5
    gaps_out = 10
}
```

### Blur and Transparency

```bash
decoration {
    rounding = 10

    blur {
        enabled = true
        size = 3
        passes = 1
    }

    drop_shadow = yes
    shadow_range = 4
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
}
```

---

## 🔤 Fonts

### Change System Font

```bash
# Install font
sudo pacman -S ttf-fira-code

# Configure via GTK
gsettings set org.gnome.desktop.interface font-name 'Fira Code 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'Fira Code Mono 10'
```

### Terminal Font (Kitty)

```bash
# Edit kitty.conf
nano ~/.config/kitty/kitty.conf

# Change font
font_family JetBrains Mono Nerd Font
bold_font auto
italic_font auto
bold_italic_font auto
font_size 12.0
```

---

## 🎨 Color Schemes

### Create a Custom Scheme

```bash
# Create color file
nano ~/.config/colors/my-scheme.conf

# Define colors
background=#1a1b26
foreground=#c0caf5
color0=#15161e
color1=#f7768e
color2=#9ece6a
color3=#e0af68
color4=#7aa2f7
color5=#bb9af7
color6=#7dcfff
color7=#a9b1d6
```

### Apply Scheme

```bash
# In Kitty
nano ~/.config/kitty/kitty.conf

# Include scheme
include ~/.config/colors/my-scheme.conf
```

---

## 🖼️ Fastfetch

### Customize Logos

```bash
# Add a custom logo
cp my-logo.png ~/.config/fastfetch/logos/

# random_logo.sh will pick it up automatically
```

### Configure Displayed Info

```bash
# Edit config
nano ~/.config/fastfetch/config.jsonc

# Customize modules
{
    "modules": [
        "title", "separator", "os", "host", "kernel",
        "uptime", "packages", "shell", "display",
        "de", "wm", "wmtheme", "theme", "icons",
        "font", "cursor", "terminal", "terminalfont",
        "cpu", "gpu", "memory", "disk", "battery",
        "locale", "break", "colors"
    ]
}
```

---

## 🎮 Wofi (Launcher)

### Customize Appearance

```bash
# Edit config
nano ~/.config/wofi/config

# Options
width=600
height=400
location=center
show=drun
prompt=Search...
filter_rate=100
allow_markup=true
no_actions=true
halign=fill
orientation=vertical
content_halign=fill
insensitive=true
allow_images=true
image_size=40
```

### CSS Styles

```bash
# Edit style.css
nano ~/.config/wofi/style.css
```

```css
window {
    margin: 0px;
    border: 2px solid #7aa2f7;
    background-color: #1a1b26;
    border-radius: 10px;
}

#input {
    margin: 5px;
    border: none;
    color: #c0caf5;
    background-color: #24283b;
}

#entry:selected {
    background-color: #7aa2f7;
}
```

---

## 🔔 Notifications (SwayNC)

### Customize Notifications

```bash
# Edit config
nano ~/.config/swaync/config.json

# Edit styles
nano ~/.config/swaync/style.css
```

Key style options:

```css
.notification {
    background-color: #1a1b26;
    border: 1px solid #7aa2f7;
    border-radius: 8px;
    color: #c0caf5;
}
```

---

## 🎨 Create Your Own Theme

### Theme Structure

```
~/.config/themes/my-theme/
├── hypr/
│   └── hyprland.conf
├── waybar/
│   ├── config
│   └── style.css
├── kitty/
│   └── kitty.conf
├── wofi/
│   ├── config
│   └── style.css
└── colors.conf
```

### Application Script

```bash
#!/bin/bash
# ~/.config/bin/apply_theme.sh

THEME_NAME="$1"
THEME_DIR="$HOME/.config/themes/$THEME_NAME"

if [ ! -d "$THEME_DIR" ]; then
    echo "Theme not found: $THEME_NAME"
    exit 1
fi

cp "$THEME_DIR/hypr/hyprland.conf" ~/.config/hypr/
cp "$THEME_DIR/waybar/config" ~/.config/waybar/
cp "$THEME_DIR/waybar/style.css" ~/.config/waybar/
cp "$THEME_DIR/kitty/kitty.conf" ~/.config/kitty/
cp "$THEME_DIR/wofi/"* ~/.config/wofi/

hyprctl reload
killall waybar && waybar &

echo "Theme $THEME_NAME applied"
```

---

## 🖱️ Cursor

### Change Cursor

```bash
# Install cursor theme
sudo pacman -S breeze-snow-cursor-theme

# Configure
gsettings set org.gnome.desktop.interface cursor-theme 'Breeze_Snow'

# Size
gsettings set org.gnome.desktop.interface cursor-size 24

# In hyprland.conf
env = XCURSOR_SIZE,24
env = XCURSOR_THEME,Breeze_Snow
```

---

## 📝 Custom Scripts

### Create a Customization Script

```bash
# Create script
nano ~/.config/bin/my_script.sh

#!/bin/bash
# Your code here

# Make executable
chmod +x ~/.config/bin/my_script.sh

# Add shortcut in hyprland.conf
bind = SUPER ALT, S, exec, ~/.config/bin/my_script.sh
```

---

## 🎨 Theme Gallery

### Included Themes

1. **s4vitar-darkness** (Default — PRO)
   - Ultra-dark aesthetic
   - Dual status bar
   - Pacman icons in workspaces
   - Purple aura and minimalist design

2. **Matrix-Hacker** (New)
   - Inspired by The Matrix aesthetic
   - Neon green on pure black
   - JetBrains Mono fonts
   - Green gradient effect on borders

3. **Horus-Cyber**
   - Neon blue and cyan tones
   - High-tech futuristic effects
   - Cyberpunk Egyptian inspiration

4. **Isis-Magic**
   - Vibrant purples and magentas
   - Mystical and modern aesthetic
   - Smooth transitions

5. **Ra-Solar**
   - Golden, orange, and red tones
   - Solar energy and warm brightness
   - Balanced contrast

6. **Anubis-Death**
   - Lime greens and deep blacks
   - Classic hacker aesthetic
   - Sharp borders

### Apply a Theme

```bash
~/.config/bin/theme_selector
```

---

## 💡 Customization Tips

1. **Backup before changing** — always back up your configs

   ```bash
   cp -r ~/.config ~/.config.backup
   ```

2. **Test changes gradually** — don't change everything at once

3. **Document your changes** — keep a log of what you modify

4. **Use Git** — version-control your dotfiles

   ```bash
   cd ~/.config
   git init
   git add .
   git commit -m "Initial config"
   ```

5. **Share your themes** — contribute back to the community

---

## 📚 Resources

- [r/unixporn](https://reddit.com/r/unixporn) — Inspiration
- [Dotfiles Gallery](https://dotfiles.github.io/)
- [Hyprland Wiki](https://wiki.hyprland.org/)
- [Waybar Examples](https://github.com/Alexays/Waybar/wiki/Examples)

---

<div align="center">

**[🏠 Back to Wiki](Home.md)** | **[⌨️ Keyboard Shortcuts →](Keyboard-Shortcuts.md)**

**Share your customizations!**

</div>
