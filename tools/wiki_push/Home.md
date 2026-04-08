# BLACK-ICE ARCH — Wiki

> Automated Arch Linux installer + Hyprland environment for cybersecurity professionals.  
> v3.2.1 | [GitHub](https://github.com/panxos/BLACK-ICE-ARCH) | [soporteinfo.net](https://soporteinfo.net)

---

## 📚 Contents

- [[Installation-Guide]] — Phase 1 (install.sh) + Phase 2 (deploy_hyprland.sh) step by step
- [[Neovim-Professional-Setup]] — LazyVim config, keybindings, plugins
- [[Waybar-Themes]] — 10 themes, how to switch, how to customize
- [[Security-Tools]] — 104 tools in 10 categories, how to add more
- [[Keyboard-Shortcuts]] — Full keybinding reference
- [[Troubleshooting]] — Common issues and fixes

---

## 🚀 Quick Start

```bash
# Phase 1 — From Arch LiveCD (as root)
git clone https://github.com/panxos/BLACK-ICE-ARCH
cd BLACK-ICE-ARCH
./install.sh

# Phase 2 — After first boot (as your user, NOT root)
cd ~/BLACK-ICE_ARCH
./deploy_hyprland.sh
```

---

## 🎨 Waybar Themes

| Theme | Style | Keybind |
|---|---|---|
| Horus-Cyber | Neon cyan/purple | `Win+Alt+Y` |
| Ra-Solar | Orange solar | `Win+Alt+Y` |
| Isis-Magic | Magenta/dark | `Win+Alt+Y` |
| Anubis-Death | Green/dark | `Win+Alt+Y` |
| s4vitar-darkness | Purple dual-bar | `Win+Alt+Y` |
| Matrix-Hacker | Matrix green | `Win+Alt+Y` |
| Jan-CyberPunk | Neon cyan/pink | `Win+Alt+Y` |
| Emilia-TokyoNight | Blue/purple | `Win+Alt+Y` |
| Marisol-Dracula | Dracula purple | `Win+Alt+Y` |
| Melissa-Nord | Cool blue minimal | `Win+Alt+Y` |

---

## 🛠️ Known Issues & Fixes

### paru ABI mismatch after pacman upgrade
**Symptom:** All packages fail with `libalpm.so.15: cannot open shared object file`  
**Cause:** `pacman` upgraded to 7.x, changing libalpm ABI. Pre-compiled `paru-bin` breaks.  
**Fix (v3.2.1+):** Module 1 now installs `paru` from **chaotic-aur** (compiled against current pacman). Auto-detects and reinstalls if broken.  
**Manual fix:**
```bash
sudo pacman -Rns paru-bin
sudo pacman -S paru   # from chaotic-aur
```

---

## 🙏 Credits

- **[s4vitar](https://www.youtube.com/@s4vitar)** — Workflow inspiration, pentesting setup philosophy, `s4vitar-darkness` theme tribute
- **[gh0stzk](https://github.com/gh0stzk/dotfiles)** — Waybar theme inspiration (Jan, Emilia, Marisol, Melissa)
- **[VandalByte](https://github.com/VandalByte/dedsec-grub2-theme)** — DedSec GRUB theme

Full credits: [CREDITS.md](https://github.com/panxos/BLACK-ICE-ARCH/blob/main/CREDITS.md)

---

## 👤 Author

**Francisco Aravena (P4nx0z)**  
[soporteinfo.net](https://soporteinfo.net) · [LinkedIn](https://linkedin.com/in/faravena) · [YouTube @Soporteinfo](https://www.youtube.com/@Soporteinfo)
