# Base de datos relacional

Esta carpeta contiene una adaptación de **12 tablas relacionales** para el
alcance actual de UniSelecciones. Conserva las funciones del producto:
universidades, sedes, torneos, cuentas y roles, selecciones, jugadores,
entrenamientos, check-in, rutinas, lesiones, partidos y estadísticas.

## Las 12 tablas

1. `universidad`
2. `sede`
3. `torneo`
4. `usuario`
5. `seleccion`
6. `jugador`
7. `entrenamiento`
8. `checkin`
9. `rutina`
10. `lesion`
11. `partido`
12. `estadistica`

## Adaptaciones para mantener el límite de 12

La propuesta inicial modela 13 tablas y la segunda entrega amplía el esquema a
17. Esta versión mantiene las entidades funcionales y aplica estas
reducciones:

- El catálogo `deporte` se omite porque el alcance actual es solo baloncesto.
- `tipo_lesion` se guarda como texto no vacío; no tiene atributos dependientes
  propios en esta versión.
- `directorio_fragmentos` se deriva de `universidad.region` y de la
  configuración de nodos del despliegue.
- Los fragmentos deportivos y privados de `jugador` se unifican en una tabla.
  Matrícula, fecha de nacimiento, teléfono, contacto de emergencia, tipo de
  sangre y alergias se guardan como columnas `bytea` cifradas. La matrícula
  además tiene un HMAC para detectar duplicados. `v_plantilla` y las vistas de
  analítica no exponen esos campos.
- `BITACORA_CAMBIOS` no entra en el límite de 12. La auditoría debe implementarse
  en el componente de seguridad/eventos; no está incluida todavía en estos
  scripts. Si la rúbrica exige que sea una tabla PostgreSQL, habrá que ampliar
  el modelo a 13 tablas o acordar cuál entidad sustituir.

El registro estadístico permanece en PostgreSQL porque se usa para cerrar
partidos y consultar rendimiento por jugador. La unicidad de las métricas usa
la llave compuesta `(id_partido, id_jugador, metrica)`. No se declara FK local
para el jugador en `estadistica`: el jugador visitante puede vivir en otro
nodo.

## Normalización

- **1FN:** cada columna contiene un solo valor relacional. Los datos privados
  cifrados están en columnas `bytea` individuales, no en arreglos ni objetos
  JSON.
- **2FN:** las tablas con llave compuesta (`checkin` y `estadistica`) guardan
  atributos que dependen de la llave completa.
- **3FN:** universidades, sedes, selecciones, torneos, usuarios y jugadores
  tienen identidad propia. Los datos que dependen de otra entidad se referencian
  con FK; no se repite la universidad en cada fila hija. La pertenencia local se
  obtiene desde la selección y se valida con triggers para jugadores,
  entrenamientos y partidos. Las regiones, roles, estados y métricas usan tipos
  de dominio enumerados.

`partido.id_sel_visita` y `estadistica.id_jugador` no tienen FK local porque
pueden apuntar a datos de otro nodo. La API valida esas referencias consultando
el nodo propietario. El esquema valida el formato básico de correo; el alta
debe aplicar el patrón institucional configurado para cada universidad. Para
UAA, el patrón de estudiante es `^al[0-9]{6}@edu\.uaa\.mx$`.

La matrícula se guarda cifrada y su HMAC incluye el identificador de universidad
para que dos instituciones puedan usar matrículas coincidentes sin colisión.
La analítica usa seudónimos HMAC, no hashes simples de IDs predecibles; configura
`app.seudonimo_key` en la conexión que consulta las vistas de analítica.

## Catálogo para el registro

`06_catalogo_universidades.sql` carga 16 instituciones afiliadas a ANUIES:
7 de Aguascalientes, 7 de Jalisco y 2 de Zacatecas. Los IDs de los catálogos
deben ser idénticos en todos los nodos. Es una lista inicial verificable, no
el padrón completo de instituciones con RVOE; la institución puede agregar
otras al catálogo si hace falta.

## Rangos de identificadores por nodo

`01_esquema.sql` acepta `id_inicio` de `psql` y crea secuencias para los
registros locales. Usa `1000000` para AGS, `2000000` para JAL y `3000000` para
ZAC. Si no se pasa el parámetro, se usa AGS. Los catálogos replicados
(`universidad`, `sede`, `torneo`) reciben IDs explícitos e idénticos en los tres
nodos; así sus llaves foráneas siguen siendo válidas en todas las réplicas.

## Aplicar los scripts

Desde la raíz del repositorio, en PowerShell:

```powershell
psql -h localhost -p 5432 -U uniselecciones -d uniselecciones `
  -v id_inicio=1000000 -f db/01_esquema.sql
psql -h localhost -p 5432 -U uniselecciones -d uniselecciones `
  -f db/06_catalogo_universidades.sql
psql -h localhost -p 5432 -U uniselecciones -d uniselecciones `
  -f db/02_logica.sql
psql -h localhost -p 5432 -U uniselecciones -d uniselecciones `
  -f db/03_roles.sql
```

Para los otros nodos, cambia el puerto e `id_inicio` por `5433`/`2000000` y
`5434`/`3000000`. Antes de crear selecciones, cada sesión debe fijar su región:

```sql
SET app.region_nodo = 'AGS';
```

La API debe fijar `app.region_nodo`, `app.cripto_key` y `app.matricula_key` en
cada conexión. La conexión de analítica también fija `app.seudonimo_key`. En
entornos con réplica síncrona, debe activar `app.enforce_cp`; el perfil local
sin réplica lo deja desactivado.

`03_roles.sql` crea roles de privilegios sin contraseña. Las cuentas de inicio
de sesión se crean en el despliegue con secretos externos y heredan esos roles.
El catálogo se basa en el [directorio de instituciones afiliadas de ANUIES](https://www.anuies.mx/instituciones-afiliadas/).

## Cuentas sintéticas de prueba

`04_datos_demo.sql` crea la universidad UAA con ID estable `1001` si aún no
existe y agrega tres usuarios ficticios con roles distintos para probar
permisos. Comparte la contraseña temporal `UniDemo#2026`; úsala solo en la base
local de desarrollo. No son cuentas reales y el inicio de sesión de Flutter
puede probarse contra FastAPI en el nodo local de Aguascalientes.
