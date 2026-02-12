# 🎨 Personalización - BLACK-ICE ARCH

Guía completa para personalizar tu entorno BLACK-ICE ARCH.

---

## 🎨 Temas

### Cambiar Tema GTK

```bash
# Ver tema actual
gsettings get org.gnome.desktop.interface gtk-theme

# Cambiar a Sweet-Dark
gsettings set org.gnome.desktop.interface gtk-theme 'Sweet-Dark'

# Otros temas disponibles
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
```

### Cambiar Tema Qt

```bash
# Editar qt5ct
nano ~/.config/qt5ct/qt5ct.conf

# Cambiar estilo
[Appearance]
style=kvantum
icon_theme=candy-icons
color_scheme_path=~/.config/qt5ct/colors/Sweet-Dark.conf

# Aplicar con qt5ct (GUI)
qt5ct
```

### Kvantum Themes

```bash
# Listar temas disponibles
ls /usr/share/Kvantum/

# Cambiar tema
kvantummanager

# O por comando
kvantummanager --set Sweet-Dark
```

---

## 🖼️ Wallpapers

### Cambiar Wallpaper

```bash
# Selector interactivo
~/.config/bin/wallpaper_switcher

# O con atajo
Super + Alt + W

# Cambiar manualmente
swww img /ruta/a/imagen.png
```

### Agregar Wallpapers Propios

```bash
# Copiar a directorio de wallpapers
cp mi-wallpaper.jpg ~/.config/wallpapers/

# Aplicar
swww img ~/.config/wallpapers/mi-wallpaper.jpg
```

### Wallpaper Aleatorio al Inicio

```bash
# Editar hyprland.conf
nano ~/.config/hypr/hyprland.conf

# Agregar
exec-once = ~/.config/bin/random_wallpaper.sh
```

---

## 🎯 Waybar

### Personalizar Módulos

```bash
# Editar configuración
nano ~/.config/waybar/config

# Ejemplo: Agregar módulo de batería
"battery": {
    "format": "{capacity}% {icon}",
    "format-icons": ["", "", "", "", ""]
}
```

### Cambiar Estilos

```bash
# Editar CSS
nano ~/.config/waybar/style.css

# Ejemplo: Cambiar color de fondo
window#waybar {
    background-color: rgba(26, 27, 38, 0.95);
}
```

### Temas de Waybar

```bash
# Listar temas disponibles
ls ~/.config/waybar/themes/

# Cambiar tema
cp ~/.config/waybar/themes/cyber-neon/config ~/.config/waybar/config
cp ~/.config/waybar/themes/cyber-neon/style.css ~/.config/waybar/style.css

# Reiniciar Waybar
killall waybar && waybar &
```

---

## 🖥️ Hyprland

### Animaciones

```bash
# Editar hyprland.conf
nano ~/.config/hypr/hyprland.conf

# Personalizar animaciones
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

### Bordes de Ventana

```bash
# Colores de borde
general {
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    border_size = 2
}
```

### Espaciado

```bash
# Gaps entre ventanas
general {
    gaps_in = 5
    gaps_out = 10
}
```

### Blur y Transparencia

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

## 🔤 Fuentes

### Cambiar Fuente del Sistema

```bash
# Instalar fuente
sudo pacman -S ttf-fira-code

# Configurar en GTK
gsettings set org.gnome.desktop.interface font-name 'Fira Code 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'Fira Code Mono 10'
```

### Fuente de Terminal (Kitty)

```bash
# Editar kitty.conf
nano ~/.config/kitty/kitty.conf

# Cambiar fuente
font_family JetBrains Mono Nerd Font
bold_font auto
italic_font auto
bold_italic_font auto
font_size 12.0
```

---

## 🎨 Esquemas de Color

### Crear Esquema Personalizado

```bash
# Crear archivo de colores
nano ~/.config/colors/mi-esquema.conf

# Definir colores
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

### Aplicar Esquema

```bash
# En Kitty
nano ~/.config/kitty/kitty.conf

# Incluir esquema
include ~/.config/colors/mi-esquema.conf
```

---

## 🖼️ Fastfetch

### Personalizar Logos

```bash
# Agregar logo personalizado
cp mi-logo.png ~/.config/fastfetch/logos/

# El script random_logo.sh lo seleccionará automáticamente
```

### Configurar Información Mostrada

```bash
# Editar config
nano ~/.config/fastfetch/config.jsonc

# Personalizar módulos
{
    "modules": [
        "title",
        "separator",
        "os",
        "host",
        "kernel",
        "uptime",
        "packages",
        "shell",
        "display",
        "de",
        "wm",
        "wmtheme",
        "theme",
        "icons",
        "font",
        "cursor",
        "terminal",
        "terminalfont",
        "cpu",
        "gpu",
        "memory",
        "disk",
        "battery",
        "locale",
        "break",
        "colors"
    ]
}
```

---

## 🎮 Wofi (Launcher)

### Personalizar Apariencia

```bash
# Editar config
nano ~/.config/wofi/config

# Opciones
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

### Estilos CSS

```bash
# Editar style.css
nano ~/.config/wofi/style.css

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

## 🔔 Dunst (Notificaciones)

### Personalizar Notificaciones

```bash
# Editar dunstrc
nano ~/.config/dunst/dunstrc

[global]
    font = JetBrains Mono Nerd Font 10
    
    # Posición
    origin = top-right
    offset = 10x50
    
    # Tamaño
    width = 300
    height = 300
    
    # Colores
    background = "#1a1b26"
    foreground = "#c0caf5"
    frame_color = "#7aa2f7"
    
    # Transparencia
    transparency = 10
    
    # Iconos
    icon_position = left
    max_icon_size = 64
```

---

## 🎨 Crear Tu Propio Tema

### Estructura de Tema

```
~/.config/themes/mi-tema/
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

### Script de Aplicación

```bash
#!/bin/bash
# ~/.config/bin/apply_theme.sh

THEME_NAME="$1"
THEME_DIR="$HOME/.config/themes/$THEME_NAME"

if [ ! -d "$THEME_DIR" ]; then
    echo "Tema no encontrado: $THEME_NAME"
    exit 1
fi

# Copiar configuraciones
cp "$THEME_DIR/hypr/hyprland.conf" ~/.config/hypr/
cp "$THEME_DIR/waybar/config" ~/.config/waybar/
cp "$THEME_DIR/waybar/style.css" ~/.config/waybar/
cp "$THEME_DIR/kitty/kitty.conf" ~/.config/kitty/
cp "$THEME_DIR/wofi/"* ~/.config/wofi/

# Recargar
hyprctl reload
killall waybar && waybar &

echo "Tema $THEME_NAME aplicado"
```

---

## 🖱️ Cursor

### Cambiar Cursor

```bash
# Instalar cursor theme
sudo pacman -S breeze-snow-cursor-theme

# Configurar
gsettings set org.gnome.desktop.interface cursor-theme 'Breeze_Snow'

# Tamaño
gsettings set org.gnome.desktop.interface cursor-size 24

# En hyprland.conf
env = XCURSOR_SIZE,24
env = XCURSOR_THEME,Breeze_Snow
```

---

## 🎵 Sonidos del Sistema

### Configurar Sonidos

```bash
# Instalar tema de sonidos
sudo pacman -S sound-theme-freedesktop

# Configurar
gsettings set org.gnome.desktop.sound theme-name 'freedesktop'
gsettings set org.gnome.desktop.sound event-sounds true
```

---

## 📝 Scripts Personalizados

### Crear Script de Personalización

```bash
# Crear script
nano ~/.config/bin/mi_script.sh

#!/bin/bash
# Tu código aquí

# Dar permisos
chmod +x ~/.config/bin/mi_script.sh

# Agregar atajo en hyprland.conf
bind = SUPER ALT, S, exec, ~/.config/bin/mi_script.sh
```

---

## 🎨 Galería de Temas

### Temas Incluidos

1. **Mecabar-p4nx0z** (Default)
   - Cyberpunk aesthetic
   - Cyan/Purple colors
   - Neon effects

2. **Cyber-Neon**
   - Bright neon colors
   - High contrast
   - Matrix-style

3. **Dark-Matrix**
   - Green on black
   - Minimal
   - Hacker aesthetic

4. **Purple-Haze**
   - Purple/Pink tones
   - Soft gradients
   - Modern look

### Aplicar Tema

```bash
~/.config/bin/theme_selector
```

---

## 💡 Tips de Personalización

1. **Backup antes de cambiar**: Siempre haz backup de tus configuraciones

   ```bash
   cp -r ~/.config ~/.config.backup
   ```

2. **Prueba cambios gradualmente**: No cambies todo a la vez

3. **Documenta tus cambios**: Mantén un registro de lo que modificas

4. **Usa Git**: Versiona tus dotfiles

   ```bash
   cd ~/.config
   git init
   git add .
   git commit -m "Initial config"
   ```

5. **Comparte tus temas**: Contribuye a la comunidad

---

## 📚 Recursos

- [r/unixporn](https://reddit.com/r/unixporn) - Inspiración
- [Dotfiles Gallery](https://dotfiles.github.io/)
- [Hyprland Wiki](https://wiki.hyprland.org/)
- [Waybar Examples](https://github.com/Alexays/Waybar/wiki/Examples)

---

<div align="center">

**[🏠 Volver a Wiki](Home.md)** | **[⌨️ Atajos →](Atajos-Teclado.md)**

**¡Comparte tus personalizaciones!**

</div>
