"""Endpoints de disponibilidad de la API."""

from fastapi import APIRouter

from uniselecciones_api import __version__
from uniselecciones_api.schemas.health import HealthResponse

router = APIRouter(tags=["health"])


@router.get(
    "/health",
    response_model=HealthResponse,
    summary="Consultar disponibilidad de la API",
)
async def health_check() -> HealthResponse:
    """Reporta que el proceso de la API responde."""
    return HealthResponse(
        status="ok",
        service="uniselecciones-api",
        version=__version__,
    )
