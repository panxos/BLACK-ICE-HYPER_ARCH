# Datos de Conky en máquinas virtuales

Los veinte estilos seleccionan datos disponibles en el equipo donde se ejecutan. Una VM KVM normalmente no expone sensores físicos de temperatura ni ventiladores. El recolector conserva esos campos ausentes; el dibujo cambia de métrica y muestra su unidad real.

| Sensor disponible | Sin ese sensor |
| --- | --- |
| CPU / TEMP.: temperatura del procesador en °C | CPU / CARGA: uso agregado de CPU en % |
| NVMe: temperatura en °C | DISCO: ocupación del sistema de archivos de HOME en % |
| FAN: velocidad en RPM, incluido cero real | vCPU en VM o HILOS en equipo físico: CPU lógicas disponibles |

«Paquete» era una traducción técnica del conjunto físico del procesador. Se retiró de las etiquetas: no describe un paquete de software. Temperatura y carga son mediciones diferentes y no comparten unidades. La carga media de un minuto se conserva en los datos de diagnóstico, pero no sustituye al porcentaje de uso en los widgets.

CPU, RAM, tráfico y tiempo activo proceden de `/proc`; espacio libre y ocupación, del sistema de archivos de HOME. La interfaz de red sigue la ruta predeterminada. En VM, el pie muestra el hipervisor y tiempo activo. Un diseño compacto presenta menos campos; Fracture permite ver CPU, RAM, disco y red juntos.

## Verificación

Caso supervisado en s3th, 2026-10-13: VM KVM con cuatro vCPU y sin dispositivos hwmon. El uso subió de 2,9 % a 29,1 % al cargar una CPU; una descarga HTTPS de 130 359 bytes produjo aproximadamente 69 KiB/s de recepción. RAM, espacio libre, CPU disponibles y tiempo activo también se comprobaron contra el recolector.

Las regresiones ejecutan el renderizador Lua real en ochenta casos: veinte estilos, dos anchos y equipos con/sin sensores. Comprueban unidades, etiquetas, sensores físicos y ventilador detenido. No sustituyen la validación visual ni la prueba de sensores en hardware adicional.

El instalador distribuye el recolector y renderizador actualizados mediante la fase del escritorio; no requiere copiar un binario ni obtener datos del host de virtualización.
