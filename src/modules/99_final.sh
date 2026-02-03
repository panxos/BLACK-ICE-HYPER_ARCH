#!/bin/bash
# modules/99_final.sh

banner "FINALIZING PROTOCOL" "Post-Install Prep"

# Copy the entire project to both the new user's home and /root for persistence
log_info "Injecting full BLACK-ICE project for persistence..."

# User Home
mkdir -p "/mnt/home/${USER_NAME:-}/BLACK-ICE_ARCH"
cp -r "${INSTALL_DIR:-}/"* "/mnt/home/${USER_NAME:-}/BLACK-ICE_ARCH/"

# Root Home
mkdir -p "/mnt/root/BLACK-ICE_ARCH"
cp -r "${INSTALL_DIR:-}/"* "/mnt/root/BLACK-ICE_ARCH/"

# Ensure scripts are executable
chmod +x "/mnt/home/${USER_NAME:-}/BLACK-ICE_ARCH/deploy_hyprland.sh"
chmod +x "/mnt/home/${USER_NAME:-}/BLACK-ICE_ARCH/deploy-modules/"*.sh

# Fix ownership for the new user
arch-chroot /mnt chown -R "${USER_NAME:-}:${USER_NAME:-}" "/home/${USER_NAME:-}/BLACK-ICE_ARCH"

log_info "Setting up MOTD (Message of the Day)..."
cat <<EOF >> "/mnt/home/$USER_NAME/.bash_profile"
# BLACK-ICE ARCH Welcome Message
if [ -d "\$HOME/BLACK-ICE_ARCH" ]; then
    echo -e "\033[0;34m==================================================\033[0m"
    echo -e "\033[1;35m   SYSTEM INITIALIZED: BLACK-ICE ARCH PROTOCOL    \033[0m"
    echo -e "\033[0;34m==================================================\033[0m"
    echo -e "\033[1;33m[!] ACCIÓN REQUERIDA: Inicia sesión como '${USER_NAME:-}' (NO USAR ROOT)\033[0m"
    echo -e "    y ejecuta: cd ~/BLACK-ICE_ARCH && ./deploy_hyprland.sh"
    echo
fi
EOF

# Copy Logs
log_info "Archiving installation logs..."
mkdir -p /mnt/var/log/black-ice
[ -f "${LOG_FILE:-}" ] && cp "${LOG_FILE:-}" "/mnt/var/log/black-ice/install.log"
[ -f "/tmp/full_install.log" ] && cp "/tmp/full_install.log" "/mnt/var/log/black-ice/full_install.log"

# --- FINAL SYSTEM AUDIT ---
log_info "Ejecutando Auditoría Final del Sistema (Post-Install Check)..."

cat <<AUDIT_EOF > /mnt/root/audit_system.sh
#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

FAIL_COUNT=0

echo -e "\n\${GREEN}==============================================\${NC}"
echo -e "\${GREEN}      REPORTE DE INTEGRIDAD DEL SISTEMA       \${NC}"
echo -e "\${GREEN}==============================================\${NC}"

# 1. Check Kernel & Initramfs
if [ -f /boot/vmlinuz-linux ] && [ -f /boot/initramfs-linux.img ]; then
    echo -e "\${GREEN}[PASS]\${NC} Kernel Stable (linux) detectado."
    ls -lh /boot/initramfs-linux.img | awk '{print "[INFO] Initramfs Size: " \$5}'
else
    echo -e "\${RED}[FAIL] CRITICAL: Faltan archivos de arranque en /boot\${NC}"
    ((FAIL_COUNT++))
fi

# 2. Check GRUB Config for Encryption
if grep -q "cryptdevice=UUID=" /boot/grub/grub.cfg; then
    echo -e "\${GREEN}[PASS]\${NC} GRUB configurado con parámetros de cifrado."
else
    echo -e "\${RED}[FAIL] GRUB no tiene configuración de LUKS/Encryption.\${NC}"
    ((FAIL_COUNT++))
fi

# 3. Check Network Persistence
if [ "\$(ls -A /etc/NetworkManager/system-connections/ 2>/dev/null)" ] || [ "\$(ls -A /var/lib/iwd/ 2>/dev/null)" ]; then
    echo -e "\${GREEN}[PASS]\${NC} Perfiles de red (NM/IWD) detectados y persistidos."
else
    echo -e "\${YELLOW}[WARN]\${NC} No se detectaron perfiles de red migrados."
fi

# 4. Check Fstab
if [ -s /etc/fstab ]; then
    echo -e "\${GREEN}[PASS]\${NC} Fstab generado correctamente."
else
    echo -e "\${RED}[FAIL] Fstab está vacío.\${NC}"
    ((FAIL_COUNT++))
fi

echo -e "\${GREEN}==============================================\${NC}"

if [ \$FAIL_COUNT -eq 0 ]; then
    echo -e "\${GREEN}       SISTEMA LISTO PARA REINICIO            \${NC}"
    echo -e "\${GREEN}==============================================\${NC}"
    exit 0
else
    echo -e "\${RED}       !!! AUDITORÍA FINAL FALLIDA !!!        \${NC}"
    echo -e "\${RED}==============================================\${NC}"
    echo -e "\${Red}Se detectaron \$FAIL_COUNT errores críticos.\${NC}"
    echo -e "\${YELLOW}NO REINICIES hasta corregirlos manualmente.\${NC}"
    exit 1
fi
AUDIT_EOF

chmod +x /mnt/root/audit_system.sh
if arch-chroot /mnt /root/audit_system.sh; then
    rm /mnt/root/audit_system.sh
    success "Instalación y Auditoría Completadas. System Ready."
else
    log_warn "La auditoría final detectó problemas."
    log_error "Instalación completada con ERRORES. Revisa el reporte arriba."
    # No borramos el script de auditoría para que el usuario pueda re-ejecutarlo
fi
