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
docs/
  BITACORA_IA.md               Registro de cada uso de IA
  DECISIONES.md                Decisiones de diseño con su justificación
  img/                         Bosquejo de pantallas y esquema relacional
  propuesta/                   Propuesta del equipo y carta de acuerdo de uso de IA
.env.example                   Variables de entorno de ejemplo
docker-compose.yml             PostgreSQL y MongoDB del nodo
.gitignore
README.md
```

## Cómo levantar los contenedores

```bash
cp .env.example .env
```

Llena `.env` con tus propios valores y nunca lo subas al repositorio: está en `.gitignore`. Después:

```bash
docker compose up -d
```

Eso levanta PostgreSQL en el puerto 5432 y MongoDB en el 27017.

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
