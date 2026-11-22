"""Modelos de respuesta para disponibilidad."""

from typing import Literal

from pydantic import BaseModel


class HealthResponse(BaseModel):
    """Estado básico del proceso de API."""

    status: Literal["ok"]
    service: str
    version: str
