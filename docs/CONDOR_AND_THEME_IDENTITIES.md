# Condor, identidad de temas y avisos USB

## Homenaje Kevin Mitnick

**Kevin-Mitnick-Condor** es un tema independiente. La revisión v4 presenta a Kevin joven en un refugio cinematográfico inspirado en *Takedown*, con equipos Sun SPARCstation, telefonía y un ave simbólica hecha de líneas de comunicación. V3 recibió nuevas observaciones sobre el teclado; v4 cambia la cámara a una vista posterior sobre el hombro y utiliza una [referencia real del Sun Type 5](https://eintr.net/systems/sun/kbd-type5c-mouse-type5/index.html). Negro, petróleo y lima proceden de la [portada española de Un fantasma en el sistema](https://capitanswing.com/catalogo/un-fantasma-en-el-sistema/). Postura y parecido quedan sujetos a revisión visual; las variantes reemplazadas sin uso se retiran durante la limpieza autorizada.

El rostro joven utiliza una [fotografía publicada por Golem](https://www.golem.de/news/nachruf-hacker-und-sicherheitsberater-kevin-mitnick-gestorben-2307-176014.html); el equipo, la [referencia Sun SPARCstation 10](https://blog.adafruit.com/2024/12/20/day-20-retrocomputing-advent-calendar-sun-sparcstation-10-retrocomputing-firstcomputer-electronics/). El terminal «SAS» es una interpretación visual solicitada: su correspondencia con software o una escena exacta de la película no está verificada. La escena es un homenaje, no una reconstrucción histórica. Las fechas se contrastaron con el [homenaje de KnowBe4 y su familia](https://www.knowbe4.com/press/knowbe4-and-the-mitnick-family-honor-the-life-and-legacy-of-kevin-mitnick).

La barra superior angular tiene marco con relieve, emblema alado, escritorios con rombos, Barlow Condensed y datos en Roboto. Conserva IP, VPN, objetivo, controles y bandeja; Docker/VM mantienen detección automática. Conky Obsidiana utiliza una cinta compacta inferior con opacidad 0,58. Kitty, menú y notificaciones siguen la paleta mediante el aplicador compartido.

**Kevin-Mitnick-Condor-Noir** añade una escena independiente inspirada en `assets/wallpapers/cyber/mr-robot.png`: cuarto industrial oscuro, lluvia, Kevin a la derecha, resplandor tenue del CRT y pequeños indicadores rojos. Deja espacio oscuro a la izquierda. Usa Ubuntu Sans, acentos gris azulado/rojo y barra superior angular. Ambas variantes incluyen imagen individual y panorama continuo.

Se elige en **Super+Alt+T → Apariencia → Galería de temas**. Una pantalla usa imagen individual; varias alineadas comparten panorama y las de otra fila conservan imagen independiente. La selección de pantallas de Conky sigue disponible en el Estudio.

## Mr-Robot Underground, Safehouse y emblemas

La composición v5 reconstruye el arcade con referencias de [Portia Doubleday](https://www.vanityfair.com/hollywood/2016/07/portia-doubleday-angela-mr-robot-season-2), [Ron Cephas Jones](https://www.nbc.com/nbc-insider/ron-cephas-jones-movies-tv-shows) y [Grace Gummer](https://seat42f.com/mr-robot-season-2-cast-promo-photos/). Angela pasa al primer plano; las sillas, bancos y suelo comparten perspectiva. Los gabinetes envejecidos Mortal Kombat II, Ultimate Mortal Kombat 3 y Mortal Kombat 4 tienen arte propio y pantallas distintas: combate 2D, fatality y combate 3D, respectivamente.

El pase v6 trabaja solo los rostros de las tres mujeres: Angela con apariencia más joven, Darlene con nueva [referencia de Carly Chaikin](https://seat42f.com/mr-robot-season-3-cast-promo-photos/) y expresión más natural, y Dominique con facciones ajustadas. El parecido final y la fidelidad de los detalles requieren aprobación visual; v4 fue rechazada y v5 recibió observaciones sobre las mujeres.

La revisión **Underground** sustituye v6 después de nuevas observaciones: baja la luz ambiental, recupera sombras azules y envejece los arcades con polvo, pintura descascarada y controles gastados. Revisa Angela con primeros planos de Portia Doubleday [en la serie](https://www.vanityfair.com/hollywood/2015/09/mr-robot-finale-virginia-shooting) y [en la entrevista de GQ](https://www.gq.com/story/mr-robot-finale-portia-doubleday); Darlene utiliza la referencia de Carly Chaikin. El parecido sigue pendiente de aprobación visual. Fuente individual: `mr-robot-underground.png`; panorama: `mr-robot-underground-panorama.png`, ambos con derivados `-uhd`.

En la revisión posterior, los tres arcades de Underground quedan apagados: CRT negros con reflejos tenues de ventanas y lámparas sobre el vidrio gastado, sin juegos visibles. La iluminación ambiental baja ligeramente más. Se actualizan las fuentes y derivados vigentes en sus mismos nombres, sin acumular variantes.

**Mr-Robot-Safehouse** usa el fondo original `mr-robot.png`, conservado sin modificar, como base para `mr-robot-safehouse-fsociety.png`: máscara Fsociety gris clara en el muro oscuro izquierdo. Su panorama amplía el mismo cuarto; ya no comparte el arcade del otro tema. Conserva barra angular superior y su paleta oscura.

Los temas MK usan un dragón circular inspirado en la marca; los de autos, Toyota/Honda/Nissan; Matrix, un emblema propio de código vertical. Procedencia y licencias en [assets/icons/README.md](../assets/icons/README.md). SVG locales, sin procesos adicionales ni dependencia de glifos para el lanzador.

Las fuentes de los derivados vigentes se conservan. Nuevos derivados: individual 3840×2162, panorama 6480×2160; son reescalados locales, no detalle nativo 4K. Hashes, dimensiones y referencias constan en `assets/wallpapers/cyber/{prompts,upscaled}.json`.

## Limpieza de recursos reemplazados

La limpieza autorizada retira únicamente fondos generados registrados sin referencias en el catálogo, configuraciones instaladas, perfiles personales ni selección activa. Conserva fuentes de derivados vigentes, enlaces personales y `mr-robot.png` original. Las copias instaladas se retiran solo si su hash coincide con el recurso descartado; los registros de imágenes y recuperación se depuran. Limpieza comprobada: 39 recursos del repositorio y 21 copias instaladas, aproximadamente 423 MiB en conjunto. Las revisiones anteriores descritas arriba son historial, no alternativas instaladas.

## Corrección USB

udiskie usa **segundos**: los valores 8000/4000 retenían avisos durante horas y `job_failed: 0` desactivaba los errores. Ahora son 8/4 segundos y errores con tiempo predeterminado (`-1`). La actualización migra únicamente esa combinación defectuosa conocida; conserva configuraciones distintas y enlaces personales.

Prueba del manejador real `udiskie.notify.Notify.device_mounted` con evento simulado: aviso visible en monitor activo a 1 s, oculto a 11 s, entrada conservada en historial y acciones de carpeta/terminal presentes. No se desmontó el disco. Falta confirmar una nueva reconexión física y el uso de acciones.

## Revisión de s4vitar y MK11

s4vitar vuelve a una barra superior con escritorios centrados, seguridad a la izquierda y controles a la derecha, según la instrucción previa de distribución. La coincidencia exacta con la captura solicitada sigue pendiente de confirmar: la distribución anterior a la izquierda fue rechazada.

MK11-SubZero y MK11-Scorpion no mostraban superficies con el dragón sin dimensiones intrínsecas acotadas. Declarar `width="64" height="64"` en el SVG corrigió ambos: se verificó una barra real en cada una de las tres salidas. El preflight CSS por sí solo no detectaba este fallo de carga de imagen.

Los 54 temas eliminan los trazos superior/inferior sobre la ventana completa. Los contornos permanecen en los bloques de módulos: SVG con trazo 1,6 px y opacidad 0,96; extremos angulares con corte de borde de 2 px. Se conserva el relieve dentro de cada bloque.

## Civic Mugen

La revisión v3 sustituye ambas llantas por el diseño Mugen GP de siete radios, según [referencia fotográfica del vehículo](https://www.hagerty.com/media/market-trends/hagerty-insider/even-in-a-cooling-market-this-40k-civic-doesnt-shock-us/). Honda documenta las [ruedas originales forjadas de 18×7,5](https://hondanews.com/en-US/releases/release-eacf570b89db7f4119c339004c34bdc5-2008-honda-civic-mugen-si-sedan-specifications). Se conservan el taller y el auto azul.
