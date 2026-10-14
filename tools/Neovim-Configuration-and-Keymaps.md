# 🥷 BLACK-ICE ARCH - NEORIM (NVCHAD) GUIDE

Bienvenidos a la interfaz de desarrollo neural de **BLACK-ICE ARCH**. Hemos configurado un entorno **Neovim (NvChad v2.5)** optimizado para ciberseguridad y desarrollo profesional.

## 🛠️ Entornos de Lenguaje Soportados (LSP)

El sistema detecta y asiste automáticamente en los siguientes lenguajes:

- **Python**: Pyright (LSP), Black (Formatter), Isort, DebugPy (DAP).
- **C/C++**: Clangd (LSP), CodeLLDB (DAP).
- **Docker**: Dockerls, Docker Compose LS.
- **Java**: JDTLS, nvim-java.
- **Lua**: Lua LS (Base NvChad).

---

## ⌨️ Mapa de Teclas (Keymaps)

### General & UI

| Tecla | Acción |
| :--- | :--- |
| `<C-n>` | Abrir/Cerrar Explorador de Archivos (NvimTree) |
| `<leader>th` | Cambiar Tema (Base46) |
| `<leader>ch` | Abrir Dashboard (Nvdash) |
| `<leader>n` | Alternar Números de Línea Relativos |
| `<C-s>` | Guardar Archivo |

### Navegación (Telescope)

| Tecla | Acción |
| :--- | :--- |
| `<leader>ff` | Buscar Archivos |
| `<leader>fw` | Buscar Texto (Live Grep) |
| `<leader>fb` | Listar Buffers Abiertos |
| `<leader>fh` | Ayuda de Neovim |
| `<leader>fo` | Archivos Recientes |

### Desarrollo (LSP)

| Tecla | Acción |
| :--- | :--- |
| `gD` | Ir a Declaración |
| `gd` | Ir a Definición |
| `K` | Mostrar Documentación (Hover) |
| `gi` | Ir a Implementación |
| `<leader>ls` | Mostrar Atajos de LSP |
| `<leader>ra` | Renombrar Símbolo |
| `<leader>ca` | Acciones de Código (Code Actions) |
| `gr` | Mostrar Referencias |

### Terminal Interna

| Tecla | Acción |
| :--- | :--- |
| `<A-i>` | Abrir Terminal Flotante |
| `<A-h>` | Abrir Terminal Horizontal |
| `<A-v>` | Abrir Terminal Vertical |

---

## 🚀 Automatización

El sistema incluye **Auto-format on save** para garantizar que tu código cumpla siempre con los estándares profesionales (PEP8, LLVM, etc).

## 🎨 Tipografía

Para la mejor experiencia visual, asegúrate de usar **JetBrainsMono Nerd Font** en tu terminal. Los íconos y la legibilidad han sido calibrados para esta fuente.
