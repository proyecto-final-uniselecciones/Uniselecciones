"""Modelos de respuesta para disponibilidad."""

from typing import Literal

from pydantic import BaseModel


class HealthResponse(BaseModel):
    """Estado de la API y su conexión con PostgreSQL."""

    status: Literal["ok", "degraded"]
    service: str
    version: str
    database: Literal["connected", "disconnected"]
