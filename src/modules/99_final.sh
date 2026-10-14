#!/bin/bash
# modules/99_final.sh

install_stage 8 'Verificación y preparación del escritorio'

# Copy the entire project to both the new user's home and /root for persistence
log_info "Injecting full BLACK-ICE project for persistence..."
: "${INSTALL_DIR:?INSTALL_DIR no definido — aborting cp}"
: "${USER_NAME:?USER_NAME no definido — aborting cp}"

for destination in "/mnt/home/${USER_NAME}/BLACK-ICE_ARCH" /mnt/root/BLACK-ICE_ARCH; do
    mkdir -p "$destination"
    tar -C "$INSTALL_DIR" --exclude-from="$INSTALL_DIR/config/distribution-excludes.txt" \
        -cf - . | tar -C "$destination" -xf -
    printf 'SELECTED_COUNTRY=%q\nKEYBOARD_LAYOUT=%q\nSYSTEM_LANG=%q\nSYSTEM_LOCALE=%q\n' \
        "${SELECTED_COUNTRY:-Chile}" "${KEYMAP:-us}" "${SYSTEM_LANG:-en_US}" "${SYSTEM_LOCALE:-es_CL}" > "$destination/install.conf.auto"
    chmod 600 "$destination/install.conf.auto"
done

# Ensure scripts are executable
chmod +x "/mnt/home/${USER_NAME:-}/BLACK-ICE_ARCH/deploy_hyprland.sh"
chmod +x "/mnt/home/${USER_NAME:-}/BLACK-ICE_ARCH/src/deploy/"*.sh

# Fix ownership for the new user
arch-chroot /mnt chown -R "${USER_NAME:-}:${USER_NAME:-}" "/home/${USER_NAME:-}/BLACK-ICE_ARCH"

log_info "Setting up MOTD (Message of the Day)..."
mkdir -p "/mnt/home/$USER_NAME/.config"
cat <<EOF > "/mnt/home/$USER_NAME/.config/black-ice-welcome.sh"
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
# HOME se expande al iniciar la sesión del usuario.
# shellcheck disable=SC2016
welcome_hook='[[ -f "$HOME/.config/black-ice-welcome.sh" ]] && source "$HOME/.config/black-ice-welcome.sh"'
grep -Fxq "$welcome_hook" "/mnt/home/$USER_NAME/.bash_profile" 2>/dev/null || printf '%s\n' "$welcome_hook" >> "/mnt/home/$USER_NAME/.bash_profile"
arch-chroot /mnt chown -R "$USER_NAME:$USER_NAME" "/home/$USER_NAME/.config" "/home/$USER_NAME/.bash_profile"

# Copy Logs
log_info "Archiving installation logs..."
mkdir -p /mnt/var/log/black-ice
[ -f "${LOG_FILE:-}" ] && cp "${LOG_FILE:-}" "/mnt/var/log/black-ice/install.log"
[ -f "/tmp/full_install.log" ] && cp "/tmp/full_install.log" "/mnt/var/log/black-ice/full_install.log"

# --- FINAL SYSTEM AUDIT ---
log_info "Ejecutando Auditoría Final del Sistema (Post-Install Check)..."

source "$INSTALL_DIR/src/lib/post-install-audit.sh"
if audit_installed_system /mnt "${SELECTED_KERNEL:-linux}" "${ENCRYPT:-false}"; then
    printf 'BLACK_ICE_VERSION=%s\n' "$BLACK_ICE_VERSION" > /mnt/etc/black-ice-release
    log_success "Instalación y auditoría completadas."
else
    log_error "La auditoría final falló. Corrige los errores antes de reiniciar."
    exit 1
fi
