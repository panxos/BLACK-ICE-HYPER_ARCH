# Pendientes — BLACK-ICE ARCH serie v3.x

> Estado actual: v3.11.0 — serie 3.x activa  
> Fecha: 2026-06-03

---

## 🔴 CRÍTICO (bloquea releases)

### 1. Wallpapers — Git LFS o Release Archive
- **Problema**: 161 wallpapers .webp = ~90MB sin trackear. No pueden ir en git plano (GitHub limita a ~50MB push / 1GB repo).
- **Opciones**:
  - A) `git lfs install` + `.gitattributes` con `*.webp filter=lfs diff=lfs merge=lfs -text`
  - B) Subirlos a GitHub Releases como `wallpapers-pack-v3.x.tar.gz` y bajarlos en `04_theme_setup.sh`
  - C) CDN propio (soporteinfo.net/static/)
- **Recomendación**: opción B — más simple, funciona sin LFS en el servidor de CI.

### 2. Waybar theme selector — integración instalador
- El script `gen_theme_previews` y el selector dependen de `awww`, `grim`, `magick`, `hyprctl`. El instalador no verifica que estén presentes.
- `04_theme_setup.sh` debe instalar: `python-imagemagick` (o `imagemagick`), `grim`, `awww`.
- El `gen_theme_previews` debe correr UNA VEZ al final del deploy para generar los previews en el sistema destino.

### 3. Tests post-install incompletos
- `tests/post-install-validate.sh` no valida:
  - `awww` (wallpaper daemon)
  - `gen_theme_previews` (script de previews)
  - `save_theme_wall`, `theme_visual.sh` (scripts nuevos)
  - `imv` (reemplazó nomacs en 3.10.0)
  - `mimeapps.list` desplegado en `~/.config/`

---

## 🟡 IMPORTANTE (próxima release)

### 4. Emilia-Angular — tema incompleto
- `dotfiles/waybar/themes/Emilia-Angular/` tiene config.jsonc y style.css pero sin preview.png ni definición de paleta completa.
- Decidir: completarlo (archetype Angular HUD para Emilia) o eliminarlo.

### 5. Wallpapers para themes huérfanos
- Anubis-Death, Ra-Solar, Isis-Magic: `_wall_prefix()` en `gen_theme_previews` retorna `""` → usan wallpaper aleatorio.
- Necesitan wallpapers propios o un fallback explícito (`black-ice-default.png`).

### 6. Horus-Cyber — preview.png del repo no regenerado
- El commit actual NO actualizó `dotfiles/waybar/themes/Horus-Cyber/preview.png` en el repo (el que existe es de una sesión anterior).
- Regenerar con `gen_theme_previews Horus-Cyber` y commitar.

### 7. README — versión desactualizada
- `README.md` y `README.en.md` menciona features de v3.7.x. Actualizar a v3.11.0:
  - Sección "Temas Waybar": actualizar a 21 temas, mencionar 6 arquetipos
  - Sección "Instalación": verificar one-liner sigue siendo válido
  - Screenshots: actualizar con los nuevos previews

### 8. src/lib/logging.sh — versión desactualizada
- Actualmente dice v3.11.0 ✅ (ya actualizado en este commit).
- Pero `bootstrap.sh` no tiene referencia de versión — agregar línea de versión al banner.

---

## 🟢 MEJORAS (roadmap)

### 9. Git LFS para assets binarios
- Configurar `.gitattributes` para `*.webp`, `*.png`, `*.jpeg`, `*.mp4`:
  ```
  *.webp filter=lfs diff=lfs merge=lfs -text
  *.png filter=lfs diff=lfs merge=lfs -text
  *.jpeg filter=lfs diff=lfs merge=lfs -text
  ```
- Migrar los 21 `preview.png` y futuros wallpapers a LFS.

### 10. Theme switcher interactivo en deploy
- `04_theme_setup.sh` actualmente hardcodea Horus-Cyber como default.
- Agregar selección interactiva con whiptail mostrando los 21 temas disponibles al final del deploy.
- Script: `~/.config/bin/theme_selector` ya existe — integrarlo.

### 11. Waybar — soporte multi-monitor
- Los `config.jsonc` actuales no definen `"output"`. En sistemas con 2+ monitores, waybar aparece en todos.
- Agregar `"output": "$PRIMARY_MONITOR"` configurable en `install.conf`.

### 12. Module `custom/settarget` — falso positivo en sistema fresh
- En installs nuevos, `target_status` probablemente retorna error/vacío → ícono `inactive` siempre rojo.
- Crear fallback graceful: si el archivo de target no existe, mostrar `─` sin clase `active`/`inactive`.

### 13. Documentación de arquetipos
- `docs/TOOLS_CATALOG.md` no documenta los 6 arquetipos de Waybar themes.
- Agregar sección con tabla: Archetype | Themes | Width | Height | Visual Feature.

### 14. CI/CD — GitHub Actions
- No hay pipeline de CI. Agregar:
  - `shellcheck` en todos los `.sh` al hacer PR
  - `yamllint` en configs JSON/YAML
  - Deploy test en contenedor Arch (opcional, costoso)

### 15. SDDM — CyberSec theme preview desactualizado
- El theme SDDM en `06_sddm_setup.sh` usa un screenshot antiguo.
- Actualizar con screenshot Hyprland real con los nuevos temas.

---

## 📊 Estado General v3.x

| Componente | Estado | Notas |
|-----------|--------|-------|
| Fase 1 (install.sh) | ✅ Estable | Sin cambios pendientes conocidos |
| Fase 2 (deploy.sh) | ✅ Funcional | Falta integración theme selector |
| 21 temas Waybar | ✅ Completos | Pendiente: wallpapers LFS |
| Tests post-install | ⚠️ Parcial | Faltan validaciones de scripts nuevos |
| Wallpapers .webp | ❌ Sin trackear | Pendiente LFS o release archive |
| README bilingüe | ⚠️ Desactualizado | Falta actualizar a v3.11.0 |
| CI/CD | ❌ Sin pipeline | GitHub Actions pendiente |
| Multi-monitor | ❌ No soportado | config.jsonc sin `output` |
| Emilia-Angular | ⚠️ Incompleto | Sin preview ni paleta completa |
