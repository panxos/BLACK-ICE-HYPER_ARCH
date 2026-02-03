# Configuración de URLs Cortas para BLACK-ICE ARCH

Este documento explica cómo configurar las URLs cortas para el bootstrap de instalación.

## URLs Objetivo

- **is.gd**: <http://is.gd/blackice>
- **cutt.ly**: <https://cutt.ly/blackice>

Ambas deben redirigir a:

```
https://raw.githubusercontent.com/panxos/BLACK-ICE-HYPER_ARCH/main/bootstrap.sh
```

---

## Configuración en is.gd

### Paso 1: Acceder a is.gd

1. Visita: <https://is.gd/>
2. No requiere registro

### Paso 2: Crear URL Corta

1. En el campo **"Enter a long URL to make tiny:"**

   ```
   https://raw.githubusercontent.com/panxos/BLACK-ICE-HYPER_ARCH/main/bootstrap.sh
   ```

2. En el campo **"Custom short URL (optional):"**

   ```
   blackice
   ```

3. Click en **"Shorten"**

4. Verificar que la URL resultante sea:

   ```
   http://is.gd/blackice
   ```

### Verificación

```bash
curl -I http://is.gd/blackice
# Debe mostrar: Location: https://raw.githubusercontent.com/panxos/BLACK-ICE-HYPER_ARCH/main/bootstrap.sh
```

---

## Configuración en cutt.ly

### Paso 1: Crear Cuenta

1. Visita: <https://cutt.ly/>
2. Click en **"Sign Up"** (esquina superior derecha)
3. Registrarse con email o Google/Facebook

### Paso 2: Crear URL Corta

1. Una vez logueado, en el dashboard principal
2. En el campo **"Paste a link to shorten it"**

   ```
   https://raw.githubusercontent.com/panxos/BLACK-ICE-HYPER_ARCH/main/bootstrap.sh
   ```

3. Click en el ícono de configuración (⚙️) antes de acortar

4. En **"Custom alias (optional):"**

   ```
   blackice
   ```

5. Click en **"SHORTEN"**

6. Verificar que la URL resultante sea:

   ```
   https://cutt.ly/blackice
   ```

### Verificación

```bash
curl -I https://cutt.ly/blackice
# Debe mostrar: Location: https://raw.githubusercontent.com/panxos/BLACK-ICE-HYPER_ARCH/main/bootstrap.sh
```

---

## Prueba de Instalación

Una vez configuradas las URLs, probar la instalación completa:

### Desde Arch Linux LiveCD

```bash
# Opción 1: is.gd
curl -L http://is.gd/blackice | bash

# Opción 2: cutt.ly
curl -L https://cutt.ly/blackice | bash
```

### Verificación Manual

```bash
# Descargar el bootstrap sin ejecutar
curl -L http://is.gd/blackice -o /tmp/bootstrap.sh

# Verificar contenido
head -20 /tmp/bootstrap.sh
# Debe mostrar el banner de BLACK-ICE ARCH

# Verificar permisos y ejecutar
chmod +x /tmp/bootstrap.sh
/tmp/bootstrap.sh
```

---

## Actualización de URLs

Si necesitas actualizar el bootstrap.sh en el futuro:

1. **Hacer commit y push** de los cambios a GitHub:

   ```bash
   git add bootstrap.sh
   git commit -m "Update bootstrap script"
   git push origin main
   ```

2. **Las URLs cortas seguirán funcionando** automáticamente porque apuntan a:

   ```
   https://raw.githubusercontent.com/panxos/BLACK-ICE-HYPER_ARCH/main/bootstrap.sh
   ```

3. **No necesitas reconfigurar** is.gd ni cutt.ly

---

## Alternativas si las URLs están Tomadas

Si `blackice` ya está en uso en algún servicio:

### is.gd

- `blackice-arch`
- `black-ice`
- `blackicearch`

### cutt.ly

- `blackice-arch`
- `black-ice-hypr`
- `blackice-install`

---

## Troubleshooting

### Error: "Custom alias already taken"

**Solución**: Usar una variación del nombre:

- `blackice2`
- `blackice-v2`
- `blackicearch`

### Error: "URL doesn't redirect"

**Verificar**:

```bash
# Ver headers completos
curl -v http://is.gd/blackice 2>&1 | grep Location

# Debe mostrar:
# < Location: https://raw.githubusercontent.com/panxos/BLACK-ICE-HYPER_ARCH/main/bootstrap.sh
```

### Error: "Bootstrap script not found (404)"

**Causa**: El archivo `bootstrap.sh` no está en la rama `main` de GitHub

**Solución**:

```bash
# Verificar que el archivo existe en GitHub
curl -I https://raw.githubusercontent.com/panxos/BLACK-ICE-HYPER_ARCH/main/bootstrap.sh

# Debe retornar: HTTP/2 200
```

---

## Promoción de las URLs

Una vez configuradas, puedes promocionar la instalación como:

### En Foros/Reddit

```markdown
**Instalación en un solo comando:**

\`\`\`bash
curl -L http://is.gd/blackice | bash
\`\`\`

Instala Arch Linux + Hyprland + 104 herramientas de pentesting automáticamente.
```

### En Documentación

```markdown
## Quick Install

From Arch Linux LiveCD:

\`\`\`bash
curl -L http://is.gd/blackice | bash
\`\`\`
```

### En Videos/Tutoriales

```
"Para instalar BLACK-ICE ARCH, simplemente ejecuta:
curl -L http://is.gd/blackice | bash"
```

---

## Seguridad

### Verificación de Integridad

Los usuarios pueden verificar el script antes de ejecutarlo:

```bash
# Descargar sin ejecutar
curl -L http://is.gd/blackice -o bootstrap.sh

# Revisar contenido
less bootstrap.sh

# Ejecutar manualmente
bash bootstrap.sh
```

### Checksum (Opcional)

Puedes proporcionar un checksum SHA256:

```bash
# Generar checksum
sha256sum bootstrap.sh

# Los usuarios pueden verificar:
curl -L http://is.gd/blackice | sha256sum
# Comparar con el hash publicado
```

---

## Resumen

✅ **is.gd**: <http://is.gd/blackice>  
✅ **cutt.ly**: <https://cutt.ly/blackice>  
✅ **Target**: <https://raw.githubusercontent.com/panxos/BLACK-ICE-HYPER_ARCH/main/bootstrap.sh>  
✅ **Comando**: `curl -L http://is.gd/blackice | bash`

**¡Listo para usar!** 🚀
