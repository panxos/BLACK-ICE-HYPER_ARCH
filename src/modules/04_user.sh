#!/bin/bash
# modules/04_user.sh

install_stage 5 'Usuario y acceso'

# Entorno de consola inicial (Bash por defecto para estabilidad)
# Zsh se configurará en el deploy_hyprland.sh
# pacstrap /mnt zsh zsh-completions grml-zsh-config >/dev/null 2>&1

if [ -n "${ROOT_PASSWORD:-}" ] && [ -n "${USERNAME:-}" ] && [ -n "${USER_PASSWORD:-}" ]; then
    # Modo automatizado
    ROOT_PASS="${ROOT_PASSWORD:-}"
    USER_NAME="${USERNAME:-}"
    USER_PASS="${USER_PASSWORD:-}"
    
    success "Inyección de credenciales completada (Protocolo Auto)."
else
    # --- ROOT PASSWORD SECTION ---
    while true; do
        ROOT_PASS=$(read_password "${NEON_BLUE}[ROOT]${NC} Introduzca una nueva contraseña para root: ")
        ROOT_PASS_CONFIRM=$(read_password "${NEON_BLUE}[ROOT]${NC} Confirme contraseña para root: ")
        
        if [ "$ROOT_PASS" == "$ROOT_PASS_CONFIRM" ] && [ -n "$ROOT_PASS" ]; then
            success "Contraseña de ROOT configurada correctamente."
            break
        else
            log_error "Las frases no coinciden o están vacías. Reintentando..."
        fi
    done
    echo

    # --- USERNAME SECTION ---
    while true; do
        echo -ne "${NEON_BLUE}[USER]${NC} Introduce el nombre del nuevo usuario (ej: benjie): "
        read -r USER_NAME < /dev/tty
        if [[ "$USER_NAME" != "root" && "$USER_NAME" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
            break
        else
            log_error "Identificador inválido. Solo minúsculas, números y guiones."
        fi
    done

    # --- USER PASSWORD SECTION ---
    while true; do
        USER_PASS=$(read_password "${NEON_BLUE}[USER]${NC} Introduzca una contraseña para ${NEON_BLUE}${USER_NAME}${NC}: ")
        USER_PASS_CONFIRM=$(read_password "${NEON_BLUE}[USER]${NC} Confirme contraseña para ${NEON_BLUE}${USER_NAME}${NC}: ")
        
        if [ "$USER_PASS" == "$USER_PASS_CONFIRM" ] && [ -n "$USER_PASS" ]; then
            success "Credenciales para $USER_NAME validadas."
            break
        else
            log_error "Las frases no coinciden para $USER_NAME. Reintentando..."
        fi
    done
fi

export USER_NAME

cat <<'SCRIPT_EOF' > /mnt/root/user_config.sh
#!/bin/bash
set -e

# Credenciales recibidas por stdin; no aparecen en argv ni en archivos temporales.
IFS= read -r -d "" ROOT_PASS
IFS= read -r -d "" USER_NAME
IFS= read -r -d "" USER_PASS

echo "[INFO] Inyectando Hash de ROOT..."
printf "%s:%s\n" "root" "$ROOT_PASS" | chpasswd

echo "[INFO] Autorizando nuevo operador: $USER_NAME..."
# Ensure groups exist
groupadd -f wheel

# Create user with BASH (Stability first)
if ! id "$USER_NAME" &>/dev/null; then
    useradd -m -G wheel,video,audio,storage,input -s /bin/bash "$USER_NAME"
    printf "%s:%s\n" "$USER_NAME" "$USER_PASS" | chpasswd
    echo "[SUCCESS] Operador $USER_NAME activo en el sistema."
else
    echo "[WARN] Operador $USER_NAME ya existe. Actualizando credenciales..."
    printf "%s:%s\n" "$USER_NAME" "$USER_PASS" | chpasswd
fi

# Sudoers hardening
mkdir -p /etc/sudoers.d
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel
chmod 0440 /etc/sudoers.d/wheel
visudo -cf /etc/sudoers.d/wheel
echo "[SUCCESS] Política sudo validada."
SCRIPT_EOF

chmod +x /mnt/root/user_config.sh
log_info "Sincronizando identidades con el núcleo del sistema..."
if ! printf "%s\0%s\0%s\0" "$ROOT_PASS" "$USER_NAME" "$USER_PASS" | arch-chroot /mnt /bin/bash /root/user_config.sh; then
    log_error "Fallo en la sincronización de identidades."
    exit 1
fi
rm /mnt/root/user_config.sh
# Limpiar variables de entorno con contraseñas
unset ROOT_PASS USER_PASS ROOT_PASS_CONFIRM USER_PASS_CONFIRM ROOT_PASSWORD USER_PASSWORD LUKS_PASS LUKS_PASSWORD

success "Entorno de identidades asegurado y Operador listo."
