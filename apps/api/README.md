# UniSelecciones API

Esqueleto de la API REST. Por ahora expone una comprobación de disponibilidad;
la conexión a PostgreSQL, MongoDB y la autenticación se integrarán en sus
issues correspondientes.

## Requisitos

- Python 3.11 o posterior.

## Preparar el entorno en Windows (PowerShell)

Desde la raíz del repositorio:

```powershell
Set-Location apps/api
py -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -e ".[dev]"
```

## Ejecutar

```powershell
python -m uvicorn uniselecciones_api.main:app --reload
```

- Salud de la API: <http://127.0.0.1:8000/health>
- Documentación interactiva: <http://127.0.0.1:8000/docs>
- Esquema OpenAPI: <http://127.0.0.1:8000/openapi.json>
- Documentación alternativa: <http://127.0.0.1:8000/redoc>

`/health` reporta que el proceso de la API responde; no indica todavía el estado
de las bases de datos.

## Estilo

El proyecto usa Ruff con reglas compatibles con PEP 8. Desde esta carpeta:

```powershell
ruff check src
ruff format --check src
```
