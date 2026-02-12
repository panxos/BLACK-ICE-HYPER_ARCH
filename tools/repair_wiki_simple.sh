#!/bin/bash
# repair_wiki_simple.sh
set -x

echo "Starting Wiki Repair..."
WIKI_URL="git@github.com:panxos/BLACK-ICE-HYPER_ARCH.wiki.git"
CLONE_DIR="/home/faravena/wiki_deploy_simple"

rm -rf "$CLONE_DIR"
git clone "$WIKI_URL" "$CLONE_DIR"
cd "$CLONE_DIR"

printf "# BLACK-ICE ARCH Project Wiki\n\nBienvenido a la documentación oficial.\n\n## Secciones\n- [[Neovim-Configuration-and-Keymaps]]\n- [[Home]]\n" > Home.md
printf "- [[Home]]\n- [[Neovim-Configuration-and-Keymaps]]\n" > _Sidebar.md
cp /home/faravena/MEGA/Scripts/GitHUB/BLACK-ICE_ARCH/docs/NVIM_KEYMAPS.md ./Neovim-Configuration-and-Keymaps.md

git add .
git commit -m "Wiki documentation update"
git push origin master || git push origin main
echo "DONE"
