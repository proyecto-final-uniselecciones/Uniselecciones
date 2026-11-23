"""Listado de instituciones educativas disponibles para registrarse."""

import logging
from typing import Literal

import psycopg
from fastapi import APIRouter, HTTPException, Query, status
from psycopg.rows import dict_row

from uniselecciones_api.core.config import settings
from uniselecciones_api.schemas.university import UniversitySummary

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/universidades", tags=["universidades"])


@router.get(
    "",
    response_model=list[UniversitySummary],
    summary="Listar instituciones educativas",
)
def list_universities(
    region: Literal["AGS", "JAL", "ZAC"] | None = Query(default=None),
) -> list[UniversitySummary]:
    """Devuelve las instituciones del catálogo, opcionalmente filtradas por estado."""
    try:
        with psycopg.connect(settings.database_url) as connection:
            with connection.cursor(row_factory=dict_row) as cursor:
                query = """
                    SELECT id_univ, nombre, ciudad, region::text AS region
                      FROM uniselecciones.universidad
                """
                parameters: tuple[str, ...] = ()
                if region is not None:
                    query += " WHERE region::text = %s"
                    parameters = (region,)
                query += " ORDER BY region, nombre"
                cursor.execute(query, parameters)
                rows = cursor.fetchall()
    except psycopg.Error:
        logger.exception("No se pudo consultar el catálogo de universidades.")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="No se pudo consultar el catálogo de instituciones.",
        ) from None

    return [UniversitySummary(**row) for row in rows]
