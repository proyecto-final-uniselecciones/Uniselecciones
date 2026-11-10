# Registro de decisiones de diseño

Aquí dejamos las decisiones importantes de diseño con su justificación, apoyada en los datos de nuestro propio análisis de consultas. Las decisiones las tomamos y las defendemos nosotros.

## D-001 · Shard key: `id_univ`

**Contexto.** Estimamos las frecuencias diarias de acceso por nodo para las ocho consultas que dominan el sistema. Seis de ellas (check-in, calendario de partidos, plantilla de una selección, lesiones, rutinas y captura de resultados) trabajan siempre dentro de una misma universidad. Las otras dos son analíticas: el reporte de rendimiento por jugador y la tabla general entre universidades. De 1,790 accesos diarios por nodo, 1,760 corresponden a las seis primeras.

**Alternativas.** Consideramos fragmentar por `id_seleccion`, que da la máxima granularidad; por fecha o temporada, que reparte la carga en el tiempo; y por hash de `id_jugador`, que reparte de forma uniforme.

**Decisión.** Fragmentamos por `id_univ`. Cada universidad pertenece a un nodo según el campo `region` de `UNIVERSIDAD`, y todo lo que cuelga de ella (selecciones, jugadores, entrenamientos, rutinas, lesiones, partidos locales y estadísticas) vive en ese nodo.

**Justificación.** Con esas frecuencias, el 98 % de los accesos diarios por nodo usa datos de una sola universidad, así que fragmentar por universidad deja casi todo el tráfico resuelto localmente y solo el 2 % analítico necesita cruzar nodos. Descartamos `id_seleccion` porque generaría más fragmentos que nodos y repartiría el calendario de una misma universidad entre varias selecciones. Descartamos fecha o temporada porque los datos recientes son los más consultados y se concentrarían en un solo fragmento, creando un punto caliente. Descartamos el hash de `id_jugador` porque se pierde la localidad: la plantilla y el calendario de un equipo quedarían repartidos entre los tres nodos.

## D-002 · Postura CAP y consistencia

**Contexto.** Los nodos remotos se alcanzan por VPN desde equipos de los integrantes, así que una partición de red es un escenario realista y no un caso extremo. No todos nuestros datos toleran lo mismo: una lesión mal reportada o un alta de jugador duplicada tienen consecuencias distintas a un check-in que tarda en aparecer.

**Alternativas.** Podíamos aplicar una sola postura a todo el sistema: consistencia fuerte en todo, que bloquearía el uso diario ante cualquier corte de VPN, o disponibilidad en todo, que permitiría mostrar datos médicos desactualizados.

**Decisión.** Separamos por tipo de dato. Tratamos como CP (consistencia fuerte) las lesiones, los datos personales y las altas de jugadores: ante una partición preferimos rechazar la operación antes que entregar un dato desactualizado. Tratamos como AP (consistencia eventual) el calendario, las estadísticas, las rutinas y el check-in: respondemos siempre y sincronizamos después.

**Justificación.** El reparto sigue el riesgo de cada dato. En lo sensible, un dato viejo puede llevar a que un jugador lesionado sea convocado, así que ahí vale más rechazar la operación; además esos fragmentos no se replican entre nodos y llevan un standby síncrono en el mismo nodo. En lo operativo, el costo de esperar es mayor que el de una desincronización breve: un jugador que hace check-in en la cancha necesita que la aplicación responda aunque la VPN esté caída, y el dato se concilia cuando vuelve el enlace.

## D-003 · Distribución de nodos

**Contexto.** Necesitamos tres nodos para demostrar fragmentación, replicación, pérdida de nodo y partición de red, con un presupuesto de cero pesos y dentro del calendario de entregas.

**Alternativas.** Consideramos levantar los tres nodos como contenedores en un solo equipo, y contratar un servidor virtual por nodo, del orden de cinco dólares mensuales cada uno.

**Decisión.** Cada nodo lógico se aloja en el equipo de un integrante: S1 Aguascalientes en el de Luis Gustavo, operativo desde el inicio y con la API y el MongoDB de analítica; S2 Jalisco en el de Obed y S3 Zacatecas en el de Brayan, ambos remotos y accesibles por VPN, con datos sintéticos para demostrar la fragmentación. Todos corren en contenedores definidos en el archivo de composición.

**Justificación.** Tres equipos distintos nos dan una separación física real: apagar una máquina o desconectarla de la VPN produce una caída de nodo y una partición de red auténticas, que es justo lo que tenemos que demostrar. Los tres nodos en un solo equipo no lo permiten, porque la red nunca se parte de verdad. Los servidores virtuales sí lo permitirían, pero cuestan y no aportan nada que no consigamos con nuestros propios equipos. Además, que cada integrante opere su nodo reparte la responsabilidad de la infraestructura.
