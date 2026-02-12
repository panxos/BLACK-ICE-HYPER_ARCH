# 🤝 Guía de Contribución - BLACK-ICE ARCH

¡Gracias por tu interés en contribuir a BLACK-ICE ARCH! Esta guía te ayudará a empezar.

---

## 📋 Código de Conducta

Al participar en este proyecto, te comprometes a mantener un ambiente respetuoso y profesional.

### Nuestros Estándares

✅ **Comportamiento aceptable**:

- Ser respetuoso con otros contribuyentes
- Aceptar críticas constructivas
- Enfocarse en lo mejor para la comunidad
- Mostrar empatía hacia otros miembros

❌ **Comportamiento inaceptable**:

- Lenguaje ofensivo o discriminatorio
- Ataques personales
- Trolling o comentarios despectivos
- Acoso público o privado

---

## 🚀 Formas de Contribuir

### 1. Reportar Bugs

¿Encontraste un bug? [Abre un issue](https://github.com/panxos/BLACK-ICE_ARCH/issues/new)

**Incluye**:

- Descripción clara del problema
- Pasos para reproducir
- Comportamiento esperado vs actual
- Screenshots si aplica
- Información del sistema:

  ```bash
  uname -a
  hyprctl version
  pacman -Q | grep hyprland
  ```

### 2. Sugerir Features

¿Tienes una idea? [Abre un issue](https://github.com/panxos/BLACK-ICE_ARCH/issues/new) con la etiqueta `enhancement`

**Incluye**:

- Descripción detallada del feature
- Casos de uso
- Beneficios para la comunidad
- Posible implementación (opcional)

### 3. Mejorar Documentación

La documentación siempre puede mejorar:

- Corregir errores tipográficos
- Aclarar instrucciones confusas
- Agregar ejemplos
- Traducir a otros idiomas

### 4. Contribuir Código

- Agregar nuevas herramientas
- Mejorar scripts existentes
- Optimizar rendimiento
- Agregar features

### 5. Crear Temas

- Diseñar nuevos temas para Waybar
- Crear esquemas de color
- Diseñar wallpapers

---

## 🔧 Configuración del Entorno de Desarrollo

### Fork y Clone

```bash
# Fork el repositorio en GitHub
# Luego clona tu fork
git clone https://github.com/TU_USUARIO/BLACK-ICE_ARCH.git
cd BLACK-ICE_ARCH

# Agregar upstream
git remote add upstream https://github.com/panxos/BLACK-ICE_ARCH.git
```

### Crear Rama

```bash
# Actualizar main
git checkout main
git pull upstream main

# Crear rama para tu feature
git checkout -b feature/nombre-descriptivo
```

### Hacer Cambios

```bash
# Editar archivos
nano archivo.sh

# Probar cambios
./test-script.sh

# Commit
git add .
git commit -m "feat: descripción clara del cambio"
```

---

## 📝 Estándares de Código

### Bash Scripts

```bash
#!/bin/bash
#
# Script: nombre_descriptivo.sh
# Description: Propósito del script
# Author: Tu Nombre
#

set -euo pipefail

# Variables en MAYÚSCULAS
readonly VARIABLE_CONSTANTE="valor"
variable_local="valor"

# Funciones con snake_case
function_name() {
    local param="$1"
    # Código aquí
}

# Logging
log_info "Mensaje informativo"
log_error "Mensaje de error"

# Error handling
if ! command; then
    log_error "Comando falló"
    exit 1
fi
```

### Convenciones

- **Indentación**: 4 espacios (no tabs)
- **Nombres de variables**: `snake_case`
- **Nombres de funciones**: `snake_case`
- **Constantes**: `UPPER_CASE`
- **Comentarios**: Claros y concisos
- **Error handling**: Siempre usar `set -e` y validar inputs

### ShellCheck

Todos los scripts deben pasar ShellCheck:

```bash
shellcheck script.sh
```

---

## 🧪 Testing

### Pruebas Locales

```bash
# Ejecutar en VM o sistema de prueba
./install.sh

# Verificar deployment
./deploy_hyprland.sh

# Probar scripts individuales
./src/deploy/02_security_tools.sh
```

### Checklist de Testing

- [ ] Script ejecuta sin errores
- [ ] Manejo de errores funciona
- [ ] Logging es claro
- [ ] No hay credenciales hardcodeadas
- [ ] Permisos de archivos correctos
- [ ] Funciona en instalación limpia
- [ ] Documentación actualizada

---

## 📤 Pull Request

### Antes de Enviar

1. **Actualiza tu rama**:

   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Prueba tus cambios**:

   ```bash
   ./test-all.sh
   ```

3. **Verifica ShellCheck**:

   ```bash
   find . -name "*.sh" -exec shellcheck {} \;
   ```

4. **Actualiza documentación** si es necesario

### Crear Pull Request

```bash
# Push a tu fork
git push origin feature/nombre-descriptivo
```

Luego en GitHub:

1. Abre Pull Request
2. Describe tus cambios claramente
3. Referencia issues relacionados
4. Espera revisión

### Template de PR

```markdown
## Descripción
Descripción clara de los cambios

## Tipo de cambio
- [ ] Bug fix
- [ ] Nuevo feature
- [ ] Breaking change
- [ ] Documentación

## Testing
- [ ] Probado en instalación limpia
- [ ] Probado en VM
- [ ] ShellCheck pasado
- [ ] Documentación actualizada

## Screenshots
(Si aplica)

## Checklist
- [ ] Mi código sigue el estilo del proyecto
- [ ] He comentado código complejo
- [ ] He actualizado la documentación
- [ ] Mis cambios no generan warnings
- [ ] He agregado tests si aplica
```

---

## 🎨 Contribuir Temas

### Estructura de Tema

```
dotfiles/waybar/themes/mi-tema/
├── config          # Configuración de Waybar
├── style.css       # Estilos CSS
└── README.md       # Descripción del tema
```

### Ejemplo de Tema

```css
/* style.css */
* {
    font-family: "JetBrains Mono Nerd Font";
    font-size: 13px;
}

window#waybar {
    background-color: rgba(26, 27, 38, 0.9);
    color: #cdd6f4;
}

#workspaces button {
    background-color: transparent;
    color: #89b4fa;
}

#workspaces button.active {
    background-color: #89b4fa;
    color: #1e1e2e;
}
```

### Enviar Tema

1. Crea tu tema en `dotfiles/waybar/themes/`
2. Agrega README.md con screenshots
3. Prueba el tema
4. Envía PR con etiqueta `theme`

---

## 🛠️ Agregar Herramientas de Seguridad

### Verificar Disponibilidad

```bash
# Verificar en repos oficiales
pacman -Ss nombre-herramienta

# Verificar en AUR
yay -Ss nombre-herramienta
```

### Agregar a Instalador

Edita `src/deploy/02_security_tools.sh`:

```bash
# Agregar a la categoría apropiada
declare -A RECON_TOOLS=(
    ["nmap"]="Network scanner"
    ["tu-herramienta"]="Descripción"  # ← Agregar aquí
)
```

### Documentar

Agrega la herramienta a `docs/wiki/es/Herramientas-Seguridad.md`:

```markdown
### tu-herramienta

**Categoría**: Reconocimiento  
**Descripción**: Descripción detallada  
**Uso básico**:
\`\`\`bash
tu-herramienta -h
\`\`\`

**Links**:
- [Documentación oficial](https://...)
- [GitHub](https://...)
```

---

## 📚 Mejorar Documentación

### Wiki

Las páginas de la wiki están en:

- Español: `docs/wiki/es/`
- English: `docs/wiki/en/`

### Formato

- Usar Markdown estándar
- Incluir ejemplos de código
- Agregar screenshots cuando sea útil
- Mantener consistencia con otras páginas

### Traducción

Si traduces documentación:

1. Mantén la estructura original
2. Adapta ejemplos culturalmente si es necesario
3. Verifica ortografía y gramática
4. Usa terminología técnica correcta

---

## 🏆 Reconocimiento

Los contribuyentes serán reconocidos en:

- README.md (sección de agradecimientos)
- CONTRIBUTORS.md
- Release notes

---

## 📞 Contacto

- **Issues**: [GitHub Issues](https://github.com/panxos/BLACK-ICE_ARCH/issues)
- **Discussions**: [GitHub Discussions](https://github.com/panxos/BLACK-ICE_ARCH/discussions)
- **Email**: Para consultas privadas

---

## 📄 Licencia

Al contribuir, aceptas que tus contribuciones se licencien bajo la [Licencia MIT](../../LICENSE).

---

<div align="center">

**[🏠 Volver a Wiki](Home.md)**

**¡Gracias por contribuir a BLACK-ICE ARCH!** 🎉

</div>
