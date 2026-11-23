# UniSelecciones API

API REST de UniSelecciones en FastAPI. Conecta al nodo PostgreSQL AGS, informa
el estado real de la base de datos y autentica usuarios con contraseña Argon2id.
El inicio de sesión devuelve un JWT firmado con HS256.

## Requisitos

- Python 3.11 o posterior.
- Docker Desktop con el nodo `pg_ags` iniciado.
- Esquema y usuarios demo aplicados en PostgreSQL (consulta `../../db/README.md`).
- Archivo `.env` en la raíz del repositorio con credenciales PostgreSQL,
  `API_DB_USER`, `API_DB_PASSWORD` y una clave `JWT_SECRET` aleatoria de al
  menos 32 caracteres.

## Preparar el entorno en Windows (PowerShell)

Desde la raíz del repositorio:

```powershell
Set-Location apps/api
py -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -e ".[dev]"
python scripts/configure_db_login.py
```

`configure_db_login.py` usa la cuenta administradora local para crear o
actualizar `API_DB_USER` y concederle el rol de mínimos privilegios `u_api`.
La API usa esa cuenta; no se conecta como superusuario.

Si aún no definiste las claves locales, genera valores y guárdalos como
`JWT_SECRET` y `API_DB_PASSWORD` en el `.env` raíz:

```powershell
python -c "import secrets; print(secrets.token_urlsafe(48))"
```

## Ejecutar

```powershell
python -m uvicorn uniselecciones_api.main:app --reload
```

- Salud de API y PostgreSQL: <http://127.0.0.1:8000/health>
- Documentación interactiva: <http://127.0.0.1:8000/docs>
- Esquema OpenAPI: <http://127.0.0.1:8000/openapi.json>
- Documentación alternativa: <http://127.0.0.1:8000/redoc>

`GET /health` devuelve `database: "connected"` si PostgreSQL responde y HTTP
503 con `database: "disconnected"` cuando no puede consultar la base.

## Inicio de sesión

La ruta `POST /auth/login` recibe JSON y devuelve el perfil público y un token
de acceso:

```json
{
  "email": "al999901@edu.uaa.mx",
  "password": "UniDemo#2026"
}
```

Para probar las tres cuentas sintéticas locales:

| Correo | Rol | Contraseña |
|---|---|---|
| `al999901@edu.uaa.mx` | institución | `UniDemo#2026` |
| `al999902@edu.uaa.mx` | entrenador | `UniDemo#2026` |
| `al999903@edu.uaa.mx` | jugador | `UniDemo#2026` |

El correo no existe y la contraseña incorrecta producen la misma respuesta
401. No se devuelve el hash ni se registra la contraseña. Los tokens vencen
según `ACCESS_TOKEN_MINUTES` (60 por defecto).

El registro usa `POST /auth/register` con `nombre_completo`, `email`, `password`,
`id_univ` y `rol` (`jugador`, `entrenador` o `institucion`). Cualquier persona
puede elegir cualquiera de esos roles; la cuenta queda activa y recibe un JWT
al registrarse.

Para UAA, los jugadores usan `al` + seis dígitos + `@edu.uaa.mx`. Para los otros
roles y las demás universidades se valida el formato general hasta definir los
dominios institucionales. El catálogo se consulta con `GET /universidades` o se
filtra por estado, por ejemplo `GET /universidades?region=JAL`.

## Probar desde Flutter

Inicia esta API primero en una terminal y, en otra, desde la raíz:

```powershell
Set-Location apps/mobile
flutter pub get
flutter run -d chrome
```

La aplicación web y Windows usan `http://127.0.0.1:8000` por defecto. La API
permite CORS solo desde `localhost` y `127.0.0.1` en HTTP para desarrollo local.
Para el teléfono físico, configura la URL de la IP del equipo que ejecuta la API
mediante `--dart-define=API_BASE_URL=http://<ip-del-equipo>:8000` y expón Uvicorn
solo en la red de desarrollo. En producción se requiere HTTPS.

## Estilo

El proyecto usa Ruff con reglas compatibles con PEP 8. Desde esta carpeta:

```powershell
ruff check src
ruff format --check src
```
