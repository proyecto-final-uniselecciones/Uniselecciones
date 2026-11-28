"""Gestión centralizada de conexiones seguras a PostgreSQL."""

from collections.abc import Iterator
from contextlib import contextmanager

import psycopg

from uniselecciones_api.core.config import settings


@contextmanager
def connect_db() -> Iterator[psycopg.Connection]:
    """Abre una conexión y configura las variables por transacción."""
    with psycopg.connect(settings.database_url) as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT
                    set_config('app.region_nodo', %s, true),
                    set_config('app.cripto_key', %s, true),
                    set_config('app.matricula_key', %s, true),
                    set_config('app.enforce_cp', %s, true)
                """,
                (
                    settings.region_nodo,
                    settings.cripto_key,
                    settings.matricula_key,
                    str(settings.enforce_cp).lower(),
                ),
            )

        yield connection
