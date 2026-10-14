# Editor visual independiente — propuesta guardada

Estado: aplazado por decisión de faravena, 2026-10-12. El Estudio actual sigue como configurador simple de perfiles, posiciones, colores, fuentes, módulos y Conky. No se crea otro proyecto ni se sustituye Control en esta etapa.

## Objetivo futuro

Diseñador visual para escritorios que ejecuten Hyprland: lienzo con uno/dos/tres monitores, capas, selección directa, propiedades de cada elemento, arrastre, alineación, tamaño, colores, fuentes, biblioteca de barras/módulos/Conky y deshacer/rehacer. Guardar proyectos editables y exportar configuración utilizable.

## Separación de responsabilidades

- Documento versionado: pantallas, geometría/escala, capas, componentes, recursos, paletas y variantes; no confundirlo con JSONC/CSS finales.
- Lienzo: vista aproximada e interacción directa; panel de propiedades para el elemento seleccionado.
- Exportadores: Waybar JSONC/CSS, Conky y referencias Hyprland; extensión posterior a launcher, bloqueo y SDDM.
- Validador Linux: sintaxis, fuentes, recursos y prueba real aislada antes de aplicar; conservar configuración personal y permitir reversión.
- Adaptadores: comenzar por BLACK-ICE sin acoplar el documento a este repositorio; otras distribuciones con Hyprland mediante rutas/capacidades declaradas.

## Límites que hay que resolver

Mover componentes de Waybar no equivale a posiciones arbitrarias: Waybar organiza módulos en zonas y grupos. El exportador debe explicar y validar restricciones, no prometer una composición imposible. La vista previa dibujada no sustituye GTK/QML/Conky real. Importar una configuración arbitraria de scripts/CSS tampoco garantiza reconstruir un documento editable.

No ejecutar scripts de proyectos importados durante una vista previa. Mantener secretos y perfiles VPN fuera del documento exportable. Distinguir diseño multiplataforma de ejecución real: cualquier host Linux compatible con Hyprland es objetivo; soporte Windows/macOS para diseñar requiere decidir tecnología y validación remota posteriormente.

## Primer alcance para retomar

Definir esquema del documento y prototipo de selección/propiedades con una barra, cinco módulos y un Conky. Exportar, validar y aplicar a una sesión desechable. Luego incorporar múltiples pantallas, biblioteca y migración de perfiles BLACK-ICE. Elegir stack y nombre al iniciar el proyecto; no están decididos.
