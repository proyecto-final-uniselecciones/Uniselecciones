"""Modelos para seleccionar una institución educativa."""

from typing import Literal

from pydantic import BaseModel


class UniversitySummary(BaseModel):
    """Datos públicos de una institución del catálogo."""

    id_univ: int
    nombre: str
    ciudad: str
    region: Literal["AGS", "JAL", "ZAC"]
