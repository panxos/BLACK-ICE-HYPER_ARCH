# ❓ Preguntas Frecuentes (FAQ) - BLACK-ICE ARCH

Respuestas a las preguntas más comunes sobre BLACK-ICE ARCH.

---

## 📦 Instalación

### ¿Puedo instalar BLACK-ICE ARCH en una máquina virtual?

**Sí**, BLACK-ICE ARCH funciona perfectamente en:

- VMware Workstation/Player
- VirtualBox
- KVM/QEMU
- Hyper-V

**Configuración recomendada**:

- 4 GB RAM mínimo (8 GB recomendado)
- 2 CPU cores mínimo
- 30 GB disco
- Habilitar 3D acceleration

### ¿Puedo hacer dual boot con Windows?

**Sí**, el instalador detecta automáticamente Windows y lo agrega al menú de GRUB.

**Recomendaciones**:

1. Instala Windows primero
2. Deja espacio sin particionar
3. Instala BLACK-ICE ARCH en el espacio libre

### ¿Necesito conexión a Internet para instalar?

**Sí**, la conexión a Internet es **obligatoria** durante la instalación para:

- Descargar paquetes
- Actualizar el sistema
- Instalar herramientas

### ¿Cuánto tiempo toma la instalación?

**Instalación base**: 15-20 minutos  
**Deployment de Hyprland**: 15-20 minutos  
**Herramientas de seguridad**: 30-60 minutos (depende de la selección)

**Total**: 1-2 horas aproximadamente

### ¿Se borrarán todos mis datos?

**Sí**, el instalador formateará el disco seleccionado. **Haz backup** de tus datos importantes antes de instalar.

---

## 🛡️ Herramientas de Seguridad

### ¿Cuántas herramientas de seguridad incluye?

**104 herramientas** organizadas en 10 categorías:

- Reconocimiento: 14
- Web Hacking: 16
- Wireless: 8
- Windows/AD: 10
- Cracking: 10
- Explotación: 6
- Sniffing: 9
- Reverse Engineering: 9
- Forense: 12
- Networking: 10

### ¿Puedo instalar solo algunas herramientas?

**Sí**, el instalador interactivo permite:

- Instalación por categorías
- Selección individual de herramientas
- Opción "Instalar Todo"

### ¿Las herramientas se actualizan automáticamente?

**No**, debes actualizar manualmente con:

```bash
sudo pacman -Syu  # Actualizar herramientas de repos oficiales
yay -Syu          # Actualizar herramientas de AUR
```

### ¿Puedo agregar más herramientas después?

**Sí**, puedes:

1. Ejecutar el instalador nuevamente: `sudo ./src/deploy/02_security_tools.sh`
2. Instalar manualmente: `sudo pacman -S nombre-herramienta`
3. Desde AUR: `yay -S nombre-herramienta`

---

## 🎨 Personalización

### ¿Puedo cambiar el tema?

**Sí**, BLACK-ICE ARCH incluye varios temas:

```bash
~/.config/bin/theme_selector
```

También puedes instalar temas adicionales desde:

- GTK: `~/.themes/`
- Icons: `~/.icons/`
- Kvantum: `~/.config/Kvantum/`

### ¿Cómo cambio el wallpaper?

```bash
# Selector interactivo
~/.config/bin/wallpaper_switcher

# O usar atajo
Super + Alt + W
```

### ¿Puedo personalizar Waybar?

**Sí**, edita:

```bash
~/.config/waybar/config     # Configuración
~/.config/waybar/style.css  # Estilos
```

Después reinicia Waybar:

```bash
killall waybar && waybar &
```

### ¿Cómo cambio los atajos de teclado?

Edita el archivo de configuración de Hyprland:

```bash
nano ~/.config/hypr/hyprland.conf
```

Busca la sección `bind =` y modifica según necesites.

Recarga la configuración:

```bash
hyprctl reload
```

---

## ⚙️ Configuración

### ¿Cómo cambio la distribución del teclado?

```bash
# Temporal
setxkbmap es

# Permanente - edita hyprland.conf
nano ~/.config/hypr/hyprland.conf

# Busca y modifica:
input {
    kb_layout = es
}
```

### ¿Cómo configuro múltiples monitores?

Edita `~/.config/hypr/hyprland.conf`:

```bash
# Ejemplo para 2 monitores
monitor=DP-1,1920x1080@60,0x0,1
monitor=HDMI-A-1,1920x1080@60,1920x0,1
```

Recarga: `hyprctl reload`

### ¿Cómo habilito el cifrado LUKS?

Durante la instalación:

```bash
ENCRYPT=yes ./install.sh
```

Para sistemas ya instalados, necesitas reinstalar.

### ¿Cómo configuro WiFi automático?

```bash
# Guardar red
nmcli device wifi connect "TU_RED" password "TU_PASSWORD"

# La red se conectará automáticamente en futuros arranques
```

---

## 🔧 Troubleshooting

### Waybar no aparece al iniciar

```bash
# Reiniciar Waybar
killall waybar
sleep 1 && waybar &

# Verificar errores
waybar -l debug
```

### Fastfetch muestra ASCII en lugar de imagen

```bash
# Verificar terminal Kitty
echo $TERM
# Debe mostrar: xterm-kitty

# Reinstalar fastfetch
sudo pacman -S fastfetch

# Verificar logos
ls ~/.config/fastfetch/logos/
```

### Aplicaciones KDE no usan tema oscuro

```bash
# Reconfigurar temas Qt
cp dotfiles/qt5ct/qt5ct.conf ~/.config/qt5ct/
cp dotfiles/qt6ct/qt6ct.conf ~/.config/qt6ct/

# Reiniciar Hyprland
Super + Shift + R
```

### No hay sonido

```bash
# Verificar PulseAudio/Pipewire
pactl info

# Reiniciar servicio de audio
systemctl --user restart pipewire pipewire-pulse

# Verificar volumen
pactl set-sink-volume @DEFAULT_SINK@ 50%
```

### Pantalla negra después de instalar

**Posibles causas**:

1. Drivers de GPU incorrectos
2. Hyprland no instalado correctamente
3. SDDM no habilitado

**Solución**:

```bash
# Desde TTY (Ctrl+Alt+F2)
cd BLACK-ICE_ARCH
./deploy_hyprland.sh

# Habilitar SDDM
sudo systemctl enable sddm
sudo systemctl start sddm
```

---

## 🚀 Rendimiento

### ¿Cuánta RAM usa Hyprland?

**En reposo**: 800 MB - 1.2 GB  
**Con aplicaciones**: 2-4 GB  
**Con herramientas pesadas**: 4-8 GB

### ¿Funciona en hardware antiguo?

**Mínimo recomendado**:

- CPU: Dual Core 64-bit (2010+)
- RAM: 4 GB
- GPU: Intel HD 4000 o equivalente

Para hardware más antiguo, considera usar un WM más ligero.

### ¿Cómo optimizo el rendimiento?

```bash
# Deshabilitar animaciones (hyprland.conf)
animations {
    enabled = no
}

# Reducir blur
decoration {
    blur = no
}

# Usar compositor más ligero
# Considera Sway en lugar de Hyprland
```

### ¿Consume mucha batería en laptop?

Hyprland es eficiente, pero puedes optimizar:

```bash
# Instalar TLP
sudo pacman -S tlp
sudo systemctl enable tlp
sudo systemctl start tlp

# Reducir brillo
brightnessctl set 50%

# Deshabilitar efectos
# Edita ~/.config/hypr/hyprland.conf
```

---

## 🔒 Seguridad

### ¿Es seguro usar BLACK-ICE ARCH?

**Sí**, BLACK-ICE ARCH:

- Usa repositorios oficiales de Arch
- Scripts open-source auditables
- Sin telemetría ni backdoors
- Actualizaciones regulares

### ¿Incluye firewall?

**Sí**, `ufw` (Uncomplicated Firewall) está incluido y configurado.

```bash
# Verificar estado
sudo ufw status

# Habilitar
sudo ufw enable

# Permitir puerto
sudo ufw allow 22/tcp
```

### ¿Puedo usar BLACK-ICE ARCH para pentesting profesional?

**Sí**, incluye herramientas profesionales como:

- Metasploit
- Burp Suite
- Wireshark
- Nmap
- Bloodhound
- Y 99 más...

### ¿Cómo actualizo las herramientas de seguridad?

```bash
# Actualizar todo el sistema
sudo pacman -Syu
yay -Syu

# Actualizar herramienta específica
sudo pacman -S nombre-herramienta
```

---

## 🌐 Comunidad

### ¿Dónde reporto bugs?

[GitHub Issues](https://github.com/panxos/BLACK-ICE_ARCH/issues)

### ¿Dónde pido ayuda?

1. [GitHub Discussions](https://github.com/panxos/BLACK-ICE_ARCH/discussions)
2. [Troubleshooting Guide](Troubleshooting.md)
3. [Arch Linux Forums](https://bbs.archlinux.org/)

### ¿Puedo contribuir?

**¡Sí!** Lee la [Guía de Contribución](Contribuir.md)

Formas de contribuir:

- Reportar bugs
- Sugerir features
- Mejorar documentación
- Agregar herramientas
- Crear temas

### ¿Hay un Discord/Telegram?

Actualmente no, pero puedes usar:

- GitHub Discussions para preguntas
- GitHub Issues para bugs
- Email al autor para consultas específicas

---

## 📚 Recursos

### ¿Dónde aprendo más sobre Hyprland?

- [Hyprland Wiki](https://wiki.hyprland.org/)
- [Hyprland GitHub](https://github.com/hyprwm/Hyprland)
- [r/hyprland](https://reddit.com/r/hyprland)

### ¿Dónde aprendo sobre Arch Linux?

- [Arch Wiki](https://wiki.archlinux.org/)
- [Arch Linux Forums](https://bbs.archlinux.org/)
- [r/archlinux](https://reddit.com/r/archlinux)

### ¿Recursos de pentesting?

- [HackTheBox](https://www.hackthebox.com/)
- [TryHackMe](https://tryhackme.com/)
- [PortSwigger Academy](https://portswigger.net/web-security)
- [OWASP](https://owasp.org/)

---

## 💡 Tips y Trucos

### ¿Cómo tomo mejores screenshots?

```bash
# Screenshot con delay
sleep 5 && grim -g "$(slurp)" screenshot.png

# Screenshot de ventana específica
grim -g "$(hyprctl activewindow | grep 'at:' | cut -d' ' -f2-)" window.png
```

### ¿Cómo grabo la pantalla?

```bash
# Instalar wf-recorder
sudo pacman -S wf-recorder

# Grabar pantalla completa
wf-recorder -f recording.mp4

# Grabar región
wf-recorder -g "$(slurp)" -f recording.mp4

# Detener con Ctrl+C
```

### ¿Cómo uso workspaces eficientemente?

**Organización recomendada**:

- Workspace 1: Terminal/Desarrollo
- Workspace 2: Navegador
- Workspace 3: Herramientas de pentesting
- Workspace 4: Documentación
- Workspace 5: Multimedia/Otros

### ¿Cómo automatizo tareas?

```bash
# Crear script en ~/.config/bin/
nano ~/.config/bin/mi_script.sh

# Dar permisos
chmod +x ~/.config/bin/mi_script.sh

# Agregar atajo en hyprland.conf
bind = SUPER ALT, S, exec, ~/.config/bin/mi_script.sh
```

---

## 🔄 Actualizaciones

### ¿Cómo actualizo BLACK-ICE ARCH?

```bash
# Actualizar sistema
sudo pacman -Syu

# Actualizar AUR packages
yay -Syu

# Actualizar dotfiles (opcional)
cd BLACK-ICE_ARCH
git pull
cp -r dotfiles/* ~/.config/
```

### ¿Con qué frecuencia debo actualizar?

**Recomendado**: Semanalmente

```bash
# Actualización semanal
sudo pacman -Syu && yay -Syu
```

### ¿Puedo actualizar a una nueva versión de BLACK-ICE?

**Sí**, cuando hay una nueva versión:

```bash
cd BLACK-ICE_ARCH
git pull
./deploy_hyprland.sh
```

---

<div align="center">

**[🏠 Volver a Wiki](Home.md)** | **[🔧 Troubleshooting](Troubleshooting.md)**

**¿No encontraste tu pregunta? [Abre un issue](https://github.com/panxos/BLACK-ICE_ARCH/issues)**

</div>
