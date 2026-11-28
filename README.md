# UniSelecciones

Sistema de información multiplataforma (Android, Windows y web) para organizar las selecciones de baloncesto universitario: calendario y partidos, entrenamientos con check-in, rutinas, lesiones, plantillas y estadísticas.

Proyecto integrador de 7.º semestre · Universidad Autónoma de Aguascalientes · Ingeniería en Sistemas Computacionales (Plan 2023) · Equipo 12 · Grupo 7C.
Integra las materias de Ingeniería de Datos I, Programación Python, Programación de Dispositivos Móviles y Seguridad en Sistemas de Cómputo I.

Este repositorio vive en la organización de GitHub **Proyecto Final Uniselecciones**.

## Descripción

Hoy cada selección organiza por su cuenta el calendario, los entrenamientos, la asistencia, las rutinas, las lesiones y las estadísticas, sin una herramienta común. Eso complica coordinar partidos entre universidades de estados distintos, dar seguimiento al rendimiento de los jugadores y cuidar información sensible como las lesiones.

UniSelecciones atiende ese problema con tres tipos de usuario: la institución da de alta selecciones, sedes y usuarios y consulta reportes; el entrenador gestiona la plantilla, los entrenamientos, las rutinas y los partidos, y registra resultados y lesiones; el jugador consulta su calendario y sus rutinas, hace check-in y revisa sus estadísticas.

Arrancamos con baloncesto en Aguascalientes y nos expandimos a Jalisco y Zacatecas. Los datos se guardan en una base de datos distribuida fragmentada por universidad, de modo que cada selección trabaja principalmente contra su propio nodo. Trabajamos solo con datos sintéticos.

## Tecnologías

| Componente | Tecnología |
|---|---|
| Aplicación multiplataforma (Android, Windows y web) | Flutter / Dart |
| API REST y servicios | Python con FastAPI, pandas, Matplotlib |
| Base de datos relacional distribuida | PostgreSQL |
| Base de datos de analítica | MongoDB |
| Infraestructura | Docker o Podman, Git, GitHub Actions |

La aplicación no se conecta directamente a las bases de datos: consume la API REST por HTTPS, con autenticación por token, autorización por rol y validación de entradas.

## Nodos

| Nodo | Dónde se aloja | Tipo | Contenido |
|---|---|---|---|
| S1 Aguascalientes | Equipo de Luis Gustavo | Local | Fragmentos `*_AGS`, catálogos, réplicas, API y MongoDB de analítica |
| S2 Jalisco | Equipo de Obed, acceso por VPN | Remoto | Fragmentos `*_JAL` y réplicas |
| S3 Zacatecas | Equipo de Brayan, acceso por VPN | Remoto | Fragmentos `*_ZAC` y réplicas |

Cada nodo corre en contenedores y vive en el equipo de un integrante, así podemos probar la pérdida de un nodo y la partición de red simplemente apagando o desconectando un equipo. La comunicación entre nodos va cifrada con TLS, la administración remota solo por SSH con llaves, y las contraseñas quedan fuera del código.

## Estructura del repositorio

```
.github/
  ISSUE_TEMPLATE/tarea.md      Plantilla de Issue
  pull_request_template.md     Plantilla de pull request
apps/
  api/                         API REST con FastAPI
    src/uniselecciones_api/    Rutas, middleware y modelos de respuesta
  mobile/                      Aplicación Flutter para Android, Windows y web
    lib/app/                   Tema, navegación y estado compartido
    lib/features/auth/         Pantalla inicial de acceso
docs/
  BITACORA_IA.md               Registro de cada uso de IA
  DECISIONES.md                Decisiones de diseño con su justificación
  propuesta/                   Propuesta del equipo y carta de acuerdo de uso de IA
db/
  01_esquema.sql               Esquema relacional de 12 tablas
  02_logica.sql                Funciones, procedimientos, vistas y triggers
  03_roles.sql                 Privilegios de API y analítica
  04_datos_demo.sql            Tres cuentas sintéticas para desarrollo local
  06_catalogo_universidades.sql Catálogo inicial de instituciones afiliadas
.env.example                   Variables de entorno de ejemplo
docker-compose.yml             Tres nodos PostgreSQL y MongoDB de analítica
.gitignore
README.md
```

## Seguridad TLS en PostgreSQL AGS

El nodo PostgreSQL de Aguascalientes utiliza TLS para proteger las
conexiones entre la API y la base de datos.

### Requisitos

- Docker y Docker Compose.
- OpenSSL.
- Linux con permisos de administrador para configurar los permisos
  de la llave privada del servidor.

### Generación de certificados locales

Antes de iniciar PostgreSQL AGS por primera vez, generar los certificados:

```bash
bash scripts/generate_postgres_tls.sh
```

El script crea una autoridad certificadora (CA) local y un certificado
para PostgreSQL. Solicita una contraseña para proteger la llave privada
de la CA.

Los certificados y llaves se almacenan en `certs/postgres/ags/`.
Este directorio está excluido de Git. Cada integrante debe generar sus
propios certificados y proteger sus llaves privadas.

No compartir ni subir `ca.key`, `server.key` ni el archivo `.env`.

### Variables de entorno

Agregar al `.env`:

```dotenv
API_DB_SSLMODE=verify-full
API_DB_SSLROOTCERT=certs/postgres/ags/ca.crt
```

Estas variables permiten que FastAPI verifique la identidad del
servidor PostgreSQL mediante el certificado de la CA.

### Activación de TLS

Validar la configuración:

```bash
docker compose --profile local --env-file .env -f docker-compose.yml config -q
```

Iniciar PostgreSQL AGS:

```bash
docker compose --profile local --env-file .env -f docker-compose.yml up -d pg_ags
```

Si el contenedor ya existía y se modificó su configuración:

```bash
docker compose --profile local --env-file .env -f docker-compose.yml up -d --no-deps --force-recreate pg_ags
```

### Verificación

Desde la API, comprobar la sesión activa:

```sql
SELECT ssl, version, cipher
FROM pg_stat_ssl
WHERE pid = pg_backend_pid();
```

Se espera que `ssl` sea `true` y que la conexión utilice TLS.

**Alcance actual:** el certificado generado incluye `localhost` y
`127.0.0.1`. La verificación TLS está probada para la conexión local
con PostgreSQL AGS. Para conexiones distribuidas mediante VPN será
necesario emitir certificados con los nombres o direcciones de los
nodos correspondientes. Jalisco y Zacatecas todavía requieren su
propia configuración TLS.

## Cómo levantar los contenedores

Si todavía no tienes un `.env`, cópialo desde el ejemplo y cambia las
contraseñas de ejemplo. No reemplaces un `.env` que ya contiene tus valores:
añádele las variables nuevas que necesites. El archivo `.env` está ignorado
por Git.

```bash
cp .env.example .env
```

El perfil `local` levanta tres bases PostgreSQL independientes para Aguascalientes,
Jalisco y Zacatecas, además de MongoDB para analítica. Los puertos locales por
defecto son `5432`, `5433`, `5434` y `27017`.

```bash
docker compose up -d
docker compose ps
```

Para la demostración distribuida, configura `COMPOSE_PROFILES` en el `.env` de
cada computadora: `ags` para S1 (PostgreSQL y MongoDB), `jalisco` para S2 o
`zacatecas` para S3. En ese modo cambia `DB_BIND_IP` a la IP VPN del equipo y
limita el firewall a conexiones desde la VPN. El perfil `local` sirve para
desarrollar en una computadora; la demostración de particiones debe usar los
tres equipos físicos descritos en `docs/DECISIONES.md`.

## Aplicación Flutter

El proyecto multiplataforma está en desarrollo en `apps/mobile`. El primer
corte incluye el tema Material 3, registro e inicio de sesión conectados a
FastAPI. Al entrar, jugador, entrenador e institución reciben un panel propio;
sus módulos deportivos específicos se integrarán en siguientes pasos.

Desde PowerShell:

```powershell
Set-Location apps/mobile
flutter pub get
flutter run -d chrome
```

Para ejecutar la aplicación nativa de Windows, usa `flutter run -d windows`.
Para Android, conecta un dispositivo con depuración USB y selecciónalo con
`flutter devices`.

## API REST

La API FastAPI conecta con PostgreSQL, expone `GET /health` para revisar la
conexión, y autentica con `POST /auth/login`. La guía de configuración, entorno
virtual y prueba está en [`apps/api/README.md`](apps/api/README.md). La
documentación interactiva queda en `/docs`.

## Responsables

| Integrante | Componente |
|---|---|
| Luis Gustavo Martínez Muñoz | Base de datos distribuida y MongoDB; seguridad e infraestructura |
| Obed Alejandro Loera Quiroz | API y servicios en Python |
| Brayan Alejandro Pamila Torres | Aplicación Flutter (móvil, escritorio y web) |

Somos tres integrantes y cuatro componentes, así que Luis Gustavo asume dos: la infraestructura de los nodos está muy ligada a la base de datos distribuida. Cada quien defiende de forma individual el componente del que es responsable.

## Flujo de trabajo

- `main` está protegida y solo recibe versiones integradas y funcionales.
- Trabajamos en ramas `feature/`, `fix/`, `docs/` y `test/`.
- Toda tarea es un Issue con responsable y criterios de terminado.
- Todo cambio entra por pull request revisado y aprobado por un integrante distinto al autor.
- No subimos contraseñas, tokens ni llaves, y usamos solo datos sintéticos.

## Uso de IA

Usamos IA conforme a nuestra carta de acuerdo, que está en `docs/propuesta/Carta_Acuerdo_Uso_IA_UniSelecciones.docx`. Cada uso queda registrado en `docs/BITACORA_IA.md`, y los commits con código asistido o generado por IA lo indican al final del mensaje.
