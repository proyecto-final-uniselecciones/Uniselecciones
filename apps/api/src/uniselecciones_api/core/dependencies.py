"""Dependencias para autenticar usuarios mediante JWT."""

import logging
from typing import Annotated

import psycopg
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jwt.exceptions import InvalidTokenError
from psycopg.rows import dict_row

from uniselecciones_api.core.database import connect_db
from uniselecciones_api.core.security import decode_access_token
from uniselecciones_api.schemas.auth import AuthenticatedUser

logger = logging.getLogger(__name__)

_bearer_scheme = HTTPBearer(auto_error=False)


def _unauthorized() -> HTTPException:
    """Genera una respuesta estándar para credenciales inválidas."""
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Token de acceso inválido o ausente.",
        headers={"WWW-Authenticate": "Bearer"},
    )


def get_current_user(
    credentials: Annotated[
        HTTPAuthorizationCredentials | None,
        Depends(_bearer_scheme),
    ],
) -> AuthenticatedUser:
    """Identifica al usuario y comprueba su estado actual en PostgreSQL."""

    if credentials is None:
        raise _unauthorized()

    try:
        payload = decode_access_token(credentials.credentials)

        subject = payload.get("sub")
        email = payload.get("email")
        role = payload.get("role")

        if not isinstance(subject, str):
            raise ValueError("Identificador de usuario inválido.")

        user_id = int(subject)

        if user_id <= 0 or not isinstance(email, str):
            raise ValueError("Identidad del usuario inválida.")

        if not isinstance(role, str):
            raise ValueError("Rol del usuario inválido.")

    except (InvalidTokenError, KeyError, TypeError, ValueError):
        raise _unauthorized() from None

    try:
        with connect_db() as connection:
            with connection.cursor(row_factory=dict_row) as cursor:
                cursor.execute(
                    """
                    SELECT a.id_usuario,
                           a.id_univ,
                           a.nombre_completo,
                           a.correo,
                           a.rol::text AS rol,
                           a.activo,
                           u.nombre AS universidad
                      FROM uniselecciones.usuario AS a
                      JOIN uniselecciones.universidad AS u
                        ON u.id_univ = a.id_univ
                     WHERE a.id_usuario = %s
                     LIMIT 1
                    """,
                    (user_id,),
                )
                account = cursor.fetchone()

    except psycopg.Error:
        logger.exception("No se pudo verificar la cuenta del usuario autenticado.")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="No se pudo verificar la cuenta del usuario.",
        ) from None

    if account is None:
        raise _unauthorized()

    if not account["activo"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="La cuenta está desactivada.",
        )

    # El rol y correo de PostgreSQL son la fuente de autoridad.
    # Si cambiaron desde la emisión del JWT, se exige iniciar sesión de nuevo.
    if account["correo"].casefold() != email.casefold() or account["rol"] != role:
        raise _unauthorized()

    return AuthenticatedUser(
        id_usuario=account["id_usuario"],
        id_univ=account["id_univ"],
        nombre_completo=account["nombre_completo"],
        correo=account["correo"],
        rol=account["rol"],
        universidad=account["universidad"],
    )
