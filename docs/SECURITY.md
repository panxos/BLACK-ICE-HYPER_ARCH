# 🔒 Análisis de Seguridad - BLACK-ICE ARCH

Análisis completo de seguridad del proyecto BLACK-ICE ARCH.

---

## 📋 Resumen Ejecutivo

BLACK-ICE ARCH es un sistema de despliegue automatizado de Arch Linux diseñado con seguridad en mente. Este documento detalla:

- Superficie de ataque
- Medidas de seguridad implementadas
- Auditoría de código
- Mejores prácticas
- Recomendaciones

**Estado de Seguridad**: ✅ SEGURO  
**Última Auditoría**: 2026-04-07  
**Auditor**: Francisco Aravena (P4nX0Z)

> **v3.2.0 Security Changes**: Eliminado bloque BlackArch que escribía `allow-weak-key-signatures` en el GPG system config (downgrade de seguridad). Eliminada referencia a `blackarch.gpg` en `rebuild_keyring()`. Variables sin default con `set -u` corregidas para evitar ejecución inesperada de código.

---

## 🎯 Superficie de Ataque

### Vectores de Entrada

1. **Bootstrap Script** (`bootstrap.sh`)
   - Ejecutado vía `curl | bash`
   - Descarga código desde GitHub
   - Ejecuta con privilegios de usuario

2. **Installation Script** (`install.sh`)
   - Requiere privilegios root
   - Modifica particiones de disco
   - Instala paquetes del sistema

3. **Deployment Scripts** (`deploy_hyprland.sh`, `src/deploy/*.sh`)
   - Ejecutan con sudo
   - Modifican configuraciones del sistema
   - Instalan software de terceros

4. **Dotfiles**
   - Configuraciones de usuario
   - Scripts ejecutables
   - Archivos de configuración

### Componentes Críticos

| Componente | Nivel de Riesgo | Mitigación |
|------------|-----------------|------------|
| `install.sh` | ALTO | Validación de inputs, error handling |
| `bootstrap.sh` | MEDIO | Verificación de entorno, checksums |
| Scripts de deployment | MEDIO | Permisos mínimos, validación |
| Dotfiles | BAJO | Sin credenciales, permisos correctos |

---

## 🛡️ Medidas de Seguridad Implementadas

### 1. Validación de Inputs

**Implementado en todos los scripts**:

```bash
# Validación de variables
if [ -z "$VARIABLE" ]; then
    log_error "Variable no definida"
    exit 1
fi

# Validación de paths
if [ ! -d "$DIRECTORY" ]; then
    log_error "Directorio no existe"
    exit 1
fi

# Sanitización de inputs de usuario
HOSTNAME=$(echo "$INPUT" | tr -cd '[:alnum:]-')
```

### 2. Principio de Mínimo Privilegio

**Separación de privilegios**:

```bash
# Scripts que NO requieren root
- bootstrap.sh (usuario normal)
- Dotfiles setup (usuario normal)

# Scripts que requieren root (justificado)
- install.sh (particionado, pacstrap)
- deploy_hyprland.sh (instalación de paquetes)
- 02_security_tools.sh (instalación de herramientas)
```

**Verificación de privilegios**:

```bash
# Verificar que NO se ejecuta como root (bootstrap)
if [ "$EUID" -eq 0 ]; then
    log_error "No ejecutes como root"
    exit 1
fi

# Verificar que SÍ se ejecuta como root (install)
if [ "$EUID" -ne 0 ]; then
    log_error "Requiere privilegios root"
    exit 1
fi
```

### 3. Error Handling Robusto

**Configuración estricta**:

```bash
set -euo pipefail
# -e: Exit on error
# -u: Exit on undefined variable
# -o pipefail: Exit on pipe failure
```

**Traps para cleanup**:

```bash
cleanup() {
    local exit_code=$?
    log_info "Ejecutando limpieza..."
    # Operaciones de limpieza
    exit ${exit_code}
}

trap cleanup EXIT
trap 'error_exit "Error en línea $LINENO"' ERR
```

### 4. Logging y Auditoría

**Logging completo**:

```bash
# Formato estructurado
[TIMESTAMP] [LEVEL] [USER] [ACTION] [RESULT]

# Ejemplo
[2026-01-28 02:30:15] [INFO] [faravena] [Installing nmap] [SUCCESS]
```

**Logs almacenados en**:

- `/var/log/black-ice-install.log`
- `/tmp/cybersec_install_*.log`
- `~/.config/hypr/logs/`

### 5. Sin Credenciales Hardcodeadas

**Verificado**:

```bash
# Búsqueda de credenciales
grep -r "password\|passwd\|secret\|api_key" src/ dotfiles/

# Resultado: No se encontraron credenciales hardcodeadas
```

**Uso de variables de entorno**:

```bash
# Ejemplo correcto
API_KEY="${API_KEY:-}"
if [ -z "$API_KEY" ]; then
    log_error "API_KEY no configurada"
    exit 1
fi
```

### 6. Permisos de Archivos

**Permisos correctos aplicados**:

```bash
# Scripts ejecutables
chmod 755 *.sh

# Configuraciones sensibles
chmod 600 ~/.ssh/config
chmod 700 ~/.ssh/

# Dotfiles
chmod 644 ~/.config/**/*.conf
chmod 755 ~/.config/bin/*
```

### 7. Cifrado LUKS (Opcional)

**Soporte para cifrado de disco completo**:

```bash
# Instalación con cifrado
ENCRYPT=yes ./install.sh

# Configuración LUKS
cryptsetup luksFormat /dev/sdX
cryptsetup open /dev/sdX cryptroot
mkfs.ext4 /dev/mapper/cryptroot
```

---

## 🔍 Auditoría de Código

### Scripts Auditados

| Script | Estado | Vulnerabilidades | Correcciones |
|--------|--------|------------------|--------------|
| `bootstrap.sh` | ✅ SEGURO | Ninguna | N/A |
| `install.sh` | ✅ SEGURO | Ninguna | N/A |
| `deploy_hyprland.sh` | ✅ SEGURO | Ninguna | N/A |
| `02_security_tools.sh` | ✅ SEGURO | Ninguna | N/A |
| Todos los módulos | ✅ SEGURO | Ninguna | N/A |

### Herramientas de Auditoría Utilizadas

1. **ShellCheck** - Análisis estático de bash

   ```bash
   shellcheck *.sh src/**/*.sh
   # Resultado: Sin errores críticos
   ```

2. **Bandit** - Análisis de seguridad (para scripts Python si los hay)

   ```bash
   bandit -r .
   ```

3. **Manual Code Review** - Revisión manual línea por línea

### Hallazgos

**No se encontraron vulnerabilidades críticas o altas.**

**Mejoras menores implementadas**:

- Validación adicional de inputs de usuario
- Mejora en mensajes de error
- Documentación de permisos requeridos

---

## 🔐 Mejores Prácticas Implementadas

### 1. OWASP Top 10 (Aplicable)

✅ **A01:2021 - Broken Access Control**

- Validación de permisos en cada script
- Separación de privilegios usuario/root

✅ **A02:2021 - Cryptographic Failures**

- Soporte LUKS para cifrado de disco
- No se almacenan credenciales en texto plano

✅ **A03:2021 - Injection**

- Sanitización de inputs de usuario
- Uso de comillas en variables
- Validación de paths

✅ **A05:2021 - Security Misconfiguration**

- Permisos de archivos correctos
- Sin configuraciones por defecto inseguras
- Error handling apropiado

✅ **A09:2021 - Security Logging**

- Logging completo de operaciones
- Logs con timestamps
- Auditoría de acciones críticas

### 2. CIS Benchmarks

Implementación parcial de CIS Benchmarks para Linux:

✅ **Filesystem Configuration**

- Permisos restrictivos en archivos sensibles
- Separación de particiones (opcional)

✅ **Access Control**

- Sudo configurado correctamente
- Usuarios con privilegios mínimos

✅ **Logging and Auditing**

- Systemd journal habilitado
- Logs persistentes

### 3. Hardening del Sistema

**Kernel Hardening** (opcional):

```bash
# sysctl hardening
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
kernel.unprivileged_bpf_disabled = 1
```

**Firewall** (ufw incluido):

```bash
sudo ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

---

## ⚠️ Riesgos Conocidos

### 1. Ejecución de Bootstrap vía curl

**Riesgo**: Ejecutar código remoto sin verificación

**Mitigación**:

- Código open-source auditable
- Repositorio público en GitHub
- Usuarios pueden descargar y revisar antes de ejecutar:

  ```bash
  curl -L http://is.gd/blackice -o bootstrap.sh
  less bootstrap.sh
  bash bootstrap.sh
  ```

**Recomendación**: Verificar checksum SHA256

```bash
curl -L http://is.gd/blackice | sha256sum
# Comparar con hash publicado
```

### 2. Instalación de Paquetes AUR

**Riesgo**: Paquetes de AUR no son oficialmente auditados

**Mitigación**:

- Revisar PKGBUILDs antes de instalar
- Usar yay con confirmación manual
- Solo instalar paquetes populares y mantenidos

**Recomendación**:

```bash
# Revisar PKGBUILD antes de instalar
yay -G nombre-paquete
cd nombre-paquete
less PKGBUILD
makepkg -si
```

### 3. Privilegios Root en Scripts

**Riesgo**: Scripts con sudo pueden dañar el sistema

**Mitigación**:

- Código open-source revisable
- Error handling robusto
- Confirmaciones de usuario para operaciones destructivas
- Dry-run mode disponible

**Recomendación**: Revisar scripts antes de ejecutar con sudo

---

## 📊 Matriz de Riesgos

| Amenaza | Probabilidad | Impacto | Riesgo | Mitigación |
|---------|--------------|---------|--------|------------|
| Código malicioso en bootstrap | BAJA | ALTO | MEDIO | Open-source, auditable |
| Paquete AUR comprometido | BAJA | MEDIO | BAJO | Revisar PKGBUILDs |
| Error en script de instalación | MEDIA | ALTO | MEDIO | Error handling, testing |
| Credenciales expuestas | MUY BAJA | ALTO | BAJO | Sin credenciales hardcodeadas |
| Permisos incorrectos | BAJA | MEDIO | BAJO | Verificación automática |
| ABI mismatch de paru tras upgrade pacman | MEDIA | ALTO | MEDIO | `safe_install` valida `paru --version`; `00_repositories.sh` reinstala paru-bin si ABI rompe |

---

## ✅ Checklist de Seguridad

### Para Usuarios

- [ ] Revisar código antes de ejecutar
- [ ] Hacer backup antes de instalar
- [ ] Usar contraseñas fuertes
- [ ] Habilitar cifrado LUKS si es necesario
- [ ] Mantener sistema actualizado
- [ ] Revisar logs periódicamente

### Para Desarrolladores

- [ ] Ejecutar ShellCheck en todos los scripts
- [ ] Validar todos los inputs de usuario
- [ ] Usar `set -euo pipefail`
- [ ] Implementar error handling
- [ ] No hardcodear credenciales
- [ ] Documentar permisos requeridos
- [ ] Probar en entorno limpio

---

## 🔄 Proceso de Actualización Segura

```bash
# 1. Verificar integridad del repositorio
cd BLACK-ICE_ARCH
git fetch origin
git verify-commit origin/main

# 2. Revisar cambios
git log HEAD..origin/main
git diff HEAD..origin/main

# 3. Actualizar si todo está bien
git pull origin main

# 4. Ejecutar deployment
./deploy_hyprland.sh
```

---

## 📞 Reportar Vulnerabilidades

Si encuentras una vulnerabilidad de seguridad:

1. **NO la publiques públicamente**
2. **Envía un email privado** al autor
3. **Incluye**:
   - Descripción detallada
   - Pasos para reproducir
   - Impacto potencial
   - Sugerencia de fix (opcional)

**Tiempo de respuesta**: 48 horas  
**Tiempo de fix**: 7 días para vulnerabilidades críticas

---

## 📚 Referencias

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)
- [Arch Linux Security](https://wiki.archlinux.org/title/Security)
- [Bash Security Best Practices](https://mywiki.wooledge.org/BashGuide/Practices)

---

<div align="center">

**[🏠 Volver a Documentación](../README.md)** | **[🇬🇧 English Version](SECURITY.en.md)**

**Última actualización**: 2026-01-28

</div>
