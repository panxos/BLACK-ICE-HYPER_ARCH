# 🧊 BLACK-ICE ARCH Wiki

Bienvenido a la wiki oficial de **BLACK-ICE ARCH**, el sistema de despliegue automatizado de Arch Linux para profesionales de ciberseguridad.

---

## 📚 Contenido de la Wiki

### 🚀 Primeros Pasos

- **[📦 Instalación](Instalacion.md)** - Guía completa de instalación paso a paso
  - Requisitos del sistema
  - Preparación del USB booteable
  - Instalación con bootstrap (un comando)
  - Instalación manual detallada
  - Verificación post-instalación

- **[⚙️ Configuración](Configuracion.md)** - Configuración avanzada del sistema
  - Configuración de red
  - Personalización de Hyprland
  - Configuración de Waybar
  - [🥷 Configuración Profesional de Neovim](Neovim-Professional-Setup.md)
  - Ajustes de rendimiento
  - Variables de entorno

### 🛡️ Herramientas y Seguridad

- **[🛡️ Herramientas de Seguridad](Herramientas-Seguridad.md)** - Catálogo completo de 104 herramientas
  - Reconocimiento y Escaneo (14 herramientas)
  - Hacking Web (16 herramientas)
  - Wireless y Bluetooth (8 herramientas)
  - Windows y Active Directory (10 herramientas)
  - Cracking de Contraseñas (10 herramientas)
  - Frameworks de Explotación (6 herramientas)
  - Sniffing y Spoofing (9 herramientas)
  - Ingeniería Inversa (9 herramientas)
  - Forense Digital (12 herramientas)
  - Utilidades de Red (10 herramientas)

### 🎨 Personalización

- **[🎨 Personalización](Personalizacion.md)** - Temas, wallpapers y customización
  - Cambiar temas GTK/Qt
  - Gestión de wallpapers
  - Personalizar Waybar
  - Modificar Fastfetch
  - Crear tus propios temas

- **[⌨️ Atajos de Teclado](Atajos-Teclado.md)** - Cheat sheet completo
  - Atajos esenciales
  - Gestión de ventanas
  - Workspaces
  - Aplicaciones
  - Multimedia
  - Capturas de pantalla

### 🔧 Soporte

- **[🔧 Troubleshooting](Troubleshooting.md)** - Solución de problemas comunes
  - Problemas de instalación
  - Problemas de red
  - Problemas de display
  - Problemas de audio
  - Problemas de temas
  - Problemas de rendimiento

- **[❓ FAQ](FAQ.md)** - Preguntas frecuentes
  - Preguntas generales
  - Instalación
  - Configuración
  - Herramientas de seguridad
  - Rendimiento

### 🤝 Comunidad

- **[🤝 Contribuir](Contribuir.md)** - Guía para contribuir al proyecto
  - Código de conducta
  - Cómo reportar bugs
  - Cómo sugerir features
  - Proceso de pull request
  - Estándares de código

---

## 🎯 Inicio Rápido

### Instalación en 30 Segundos

```bash
curl -L http://is.gd/blackice | bash
```

### Primeros Pasos Después de Instalar

1. **Actualizar el sistema**

   ```bash
   sudo pacman -Syu
   ```

2. **Instalar herramientas de seguridad**

   ```bash
   sudo ./src/deploy/02_security_tools.sh
   ```

3. **Personalizar tu entorno**

   ```bash
   ~/.config/bin/theme_selector
   ~/.config/bin/wallpaper_switcher
   ```

---

## 📖 Documentación Adicional

### Documentación Técnica

- [🏗️ Arquitectura del Sistema](../../ARCHITECTURE.md)
- [🔒 Análisis de Seguridad](../../SECURITY.md)
- [📦 Documentación de Módulos](../../MODULES.md)
- [📝 Registro de Cambios](../../CHANGELOG.md)

### Enlaces Externos

- [Hyprland Documentation](https://wiki.hyprland.org/)
- [Arch Linux Wiki](https://wiki.archlinux.org/)
- [Waybar Wiki](https://github.com/Alexays/Waybar/wiki)

---

## 🆘 ¿Necesitas Ayuda?

- **Issues en GitHub**: [Reportar un problema](https://github.com/panxos/BLACK-ICE-HYPER_ARCH/issues)
- **Discusiones**: [Foro de la comunidad](https://github.com/panxos/BLACK-ICE-HYPER_ARCH/discussions)
- **Email**: Contacta al autor para consultas específicas

---

## 🌟 Contribuye

¿Encontraste un error en la documentación? ¿Quieres agregar contenido?

1. Fork el repositorio
2. Edita la documentación
3. Envía un pull request

Toda contribución es bienvenida!

---

<div align="center">

**[🏠 Volver al README](../../../README.md)** | **[🇬🇧 English Wiki](../en/Home.md)**

Hecho con ❤️ para la Comunidad de Ciberseguridad

</div>
