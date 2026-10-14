#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"
mapfile -t scripts < <(rg --files -g '*.sh' src scripts tests)
bash -n install.sh deploy_hyprland.sh bootstrap.sh
for script in "${scripts[@]}"; do bash -n "$script"; done
shellcheck -S error install.sh deploy_hyprland.sh bootstrap.sh "${scripts[@]}"
shellcheck -S warning install.sh deploy_hyprland.sh bootstrap.sh src/lib/install-safety.sh src/deploy/05_software_suite.sh dotfiles/bin/black-ice-apps
ruff check scripts/select-apps.py scripts/upscale-wallpapers.py scripts/configure-vm-boot.py tests/test_vm_boot.py tests/test_installer_modernization.py tests/test_hyprland_ipc.py dotfiles/bin/black-ice-hypr dotfiles/bin/black-ice-doctor dotfiles/bin/hyprland-migrate dotfiles/bin/black-ice-appearance scripts/install-cyber-themes.py
if ! command -v xvfb-run >/dev/null; then
    printf 'Pruebas GTK aisladas pendientes: instala xorg-server-xvfb.\n' >&2
    exit 1
fi
GDK_BACKEND=x11 xvfb-run -a python3 -m unittest discover -s tests -p 'test_*.py'
ruff check src/system/manager.py scripts/module-state.py scripts/system-transaction.py scripts/qa-system.py scripts/recreate-qa-vm.py dotfiles/bin/black-ice-system tests/test_system_manager.py tests/test_control_navigation.py
ruff check scripts/install-agency-themes.py scripts/build-waybar-themes.py tests/test_agency_themes.py
ruff check dotfiles/bin/black_ice_workspaces.py dotfiles/bin/black-ice-workspaces dotfiles/bin/black_ice_shortcuts.py dotfiles/bin/cheatsheet dotfiles/bin/conky_visual tests/test_workspaces.py tests/test_conky_gallery.py tests/test_shortcuts.py
ruff check dotfiles/bin/black_ice_launcher.py dotfiles/bin/black-ice-launcher tests/test_launcher.py
ruff check scripts/render-theme-gallery.py scripts/check-distribution.py tests/test_distribution.py tests/test_wallpaper_upscale.py
ruff check dotfiles/bin scripts src/system tests
ruff check dotfiles/bin/black-ice-waybar-binary
python3 scripts/check-distribution.py
xvfb-run -a python3 -m unittest discover -s tests -p 'test_control_navigation.py'
GDK_BACKEND=x11 xvfb-run -a python3 -m unittest discover -s tests -p 'test_guided_labs.py' -k GuidedLabsGtkTests
GDK_BACKEND=x11 xvfb-run -a -s '-screen 0 1280x900x24' python3 -m unittest discover -s tests -p 'test_theme_gallery.py'
GDK_BACKEND=x11 xvfb-run -a -s '-screen 0 1280x900x24' python3 -m unittest discover -s tests -p 'test_conky_gallery.py'
GDK_BACKEND=x11 xvfb-run -a python3 -m unittest discover -s tests -p 'test_language.py'
printf 'Comprobaciones de desarrollo aprobadas. La instalación real en VM requiere una prueba aparte.\n'
