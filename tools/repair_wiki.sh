#!/bin/bash
# repair_wiki.sh
set -x
LOG_FILE="/home/faravena/wiki_repair.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting Wiki Repair..."
WIKI_URL="git@github.com:panxos/BLACK-ICE-HYPER_ARCH.wiki.git"
CLONE_DIR="/home/faravena/wiki_deploy"

# Clean previous attempts
rm -rf "$CLONE_DIR"

echo "Cloning Wiki..."
git clone "$WIKI_URL" "$CLONE_DIR"

if [ ! -d "$CLONE_DIR" ]; then
    echo "ERROR: Clone failed or directory disappeared."
    exit 1
fi

cd "$CLONE_DIR"
echo "Current Branch: $(git branch --show-current)"

# Create pages
cat > Home.md << 'EOF'
# BLACK-ICE ARCH Project Wiki

Bienvenido a la documentación oficial.

## Secciones
- [[Neovim-Configuration-and-Keymaps]]
- [[Home]]
EOF

cat > _Sidebar.md << 'EOF'
- [[Home]]
- [[Neovim-Configuration-and-Keymaps]]
EOF

cp /home/faravena/MEGA/Scripts/GitHUB/BLACK-ICE_ARCH/docs/NVIM_KEYMAPS.md ./Neovim-Configuration-and-Keymaps.md

git add .
git commit -m "Full Wiki documentation update"

echo "Attempting to push to master..."
git push origin master
if [ $? -ne 0 ]; then
    echo "Attempting to push to main..."
    git push origin main
fi

echo "Wiki Repair Complete."
