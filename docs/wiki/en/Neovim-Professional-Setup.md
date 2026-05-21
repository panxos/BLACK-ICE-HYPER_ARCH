# 🥷 BLACK-ICE ARCH - Professional Neovim Setup (NvChad)

Welcome to the neural development interface of **BLACK-ICE ARCH**. We have configured a **Neovim (NvChad v2.5)** environment optimized for cybersecurity and professional development.

## 🛠️ Supported Language Environments (LSP)

The system automatically detects and assists with the following languages:

- **Python**: Pyright (LSP), Black (Formatter), Isort, DebugPy (DAP).
- **C/C++**: Clangd (LSP), CodeLLDB (DAP).
- **Docker**: Dockerls, Docker Compose LS.
- **Java**: JDTLS, nvim-java.
- **Lua**: Lua LS (NvChad base).

---

## ⌨️ Keymap Reference

### General & UI

| Key | Action |
| :--- | :--- |
| `<C-n>` | Open/Close File Explorer (NvimTree) |
| `<leader>th` | Change Theme (Base46) |
| `<leader>ch` | Open Dashboard (Nvdash) |
| `<leader>n` | Toggle Relative Line Numbers |
| `<C-s>` | Save File |

### Navigation (Telescope)

| Key | Action |
| :--- | :--- |
| `<leader>ff` | Find Files |
| `<leader>fw` | Find Text (Live Grep) |
| `<leader>fb` | List Open Buffers |
| `<leader>fh` | Neovim Help |
| `<leader>fo` | Recent Files |

### Development (LSP)

| Key | Action |
| :--- | :--- |
| `gD` | Go to Declaration |
| `gd` | Go to Definition |
| `K` | Show Documentation (Hover) |
| `gi` | Go to Implementation |
| `<leader>ls` | Show LSP Shortcuts |
| `<leader>ra` | Rename Symbol |
| `<leader>ca` | Code Actions |
| `gr` | Show References |

### Debugging (DAP)

| Key | Action |
| :--- | :--- |
| `<leader>db` | Toggle Breakpoint |
| `<leader>dr` | Continue/Start Debugger |
| `<leader>du` | Show DAP UI |

---

## 🚀 Automation

The system includes **Auto-format on save** to ensure your code always meets professional standards (PEP8, LLVM, etc.).

## 🎨 Typography

For the best visual experience, make sure to use **JetBrainsMono Nerd Font** in your terminal. Icons and readability have been calibrated for this font.

---

<div align="center">

**[🏠 Back to Wiki](Home.md)** | **[⌨️ Keyboard Shortcuts →](Keyboard-Shortcuts.md)**

</div>
