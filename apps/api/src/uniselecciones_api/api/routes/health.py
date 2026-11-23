"""Endpoints de disponibilidad de la API."""

import psycopg
from fastapi import APIRouter
from fastapi.responses import JSONResponse

from uniselecciones_api import __version__
from uniselecciones_api.core.config import settings
from uniselecciones_api.schemas.health import HealthResponse

router = APIRouter(tags=["health"])


@router.get(
    "/health",
    response_model=HealthResponse,
    summary="Consultar disponibilidad de la API",
)
def health_check() -> HealthResponse | JSONResponse:
    """Comprueba que la API responde y que PostgreSQL acepta consultas."""
    try:
        with psycopg.connect(settings.database_url) as connection:
            connection.execute("SELECT 1")
    except psycopg.Error:
        return JSONResponse(
            status_code=503,
            content=HealthResponse(
                status="degraded",
                service="uniselecciones-api",
                version=__version__,
                database="disconnected",
            ).model_dump(),
        )

    return HealthResponse(
        status="ok",
        service="uniselecciones-api",
        version=__version__,
        database="connected",
    )
