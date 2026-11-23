"""Endpoints de autenticación."""

import logging
import re

import psycopg
from fastapi import APIRouter, HTTPException, status
from psycopg.rows import dict_row

from uniselecciones_api.core.config import settings
from uniselecciones_api.core.security import (
    create_access_token,
    hash_password,
    perform_dummy_password_check,
    verify_password,
)
from uniselecciones_api.schemas.auth import (
    AuthenticatedUser,
    LoginRequest,
    LoginResponse,
    RegisterRequest,
    RegisterResponse,
)

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/auth", tags=["auth"])
_UAA_STUDENT_EMAIL = re.compile(r"^al\d{6}@edu\.uaa\.mx$", re.IGNORECASE)


@router.post(
    "/login",
    response_model=LoginResponse,
    summary="Iniciar sesión",
    responses={
        401: {"description": "Correo o contraseña incorrectos."},
        403: {"description": "La cuenta está desactivada."},
        503: {"description": "La base de datos no está disponible."},
    },
)
def login(credentials: LoginRequest) -> LoginResponse:
    """Verifica credenciales contra PostgreSQL y devuelve un JWT."""
    try:
        with psycopg.connect(settings.database_url) as connection:
            with connection.cursor(row_factory=dict_row) as cursor:
                cursor.execute(
                    """
                    SELECT a.id_usuario, a.id_univ, a.nombre_completo, a.correo,
                           a.rol::text AS rol, a.hash_clave, a.activo,
                           u.nombre AS universidad
                      FROM uniselecciones.usuario AS a
                      JOIN uniselecciones.universidad AS u
                        ON u.id_univ = a.id_univ
                     WHERE lower(a.correo) = %s
                     LIMIT 1
                    """,
                    (credentials.email,),
                )
                account = cursor.fetchone()
    except psycopg.Error:
        logger.exception("No se pudo consultar PostgreSQL durante el login.")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="La base de datos no está disponible.",
        ) from None

    if account is None:
        perform_dummy_password_check(credentials.password)
        raise _invalid_credentials()

    if not verify_password(credentials.password, account["hash_clave"]):
        raise _invalid_credentials()

    if not account["activo"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Esta cuenta está desactivada.",
        )

    user = AuthenticatedUser(
        id_usuario=account["id_usuario"],
        id_univ=account["id_univ"],
        nombre_completo=account["nombre_completo"],
        correo=account["correo"],
        rol=account["rol"],
        universidad=account["universidad"],
    )
    token = create_access_token(
        user_id=user.id_usuario,
        email=user.correo,
        role=user.rol,
    )
    return LoginResponse(
        access_token=token,
        expires_in=settings.access_token_minutes * 60,
        user=user,
    )


@router.post(
    "/register",
    response_model=RegisterResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar una cuenta",
    responses={
        409: {"description": "El correo ya está registrado."},
        422: {"description": "La universidad o el correo no es válido."},
        503: {"description": "La base de datos no está disponible."},
    },
)
def register(credentials: RegisterRequest) -> RegisterResponse:
    """Crea una cuenta activa con el rol elegido y devuelve un JWT."""
    try:
        with psycopg.connect(settings.database_url) as connection:
            with connection.cursor(row_factory=dict_row) as cursor:
                cursor.execute(
                    """
                    SELECT id_univ, nombre, region::text AS region
                      FROM uniselecciones.universidad
                     WHERE id_univ = %s
                    """,
                    (credentials.id_univ,),
                )
                university = cursor.fetchone()
                if university is None:
                    raise HTTPException(
                        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                        detail="Selecciona una universidad del catálogo.",
                    )

                if (
                    university["id_univ"] == 1001
                    and credentials.rol == "jugador"
                    and not _UAA_STUDENT_EMAIL.fullmatch(credentials.email)
                ):
                    raise HTTPException(
                        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                        detail=(
                            "Para UAA, los jugadores deben usar al + seis dígitos "
                            "+ @edu.uaa.mx."
                        ),
                    )

                cursor.execute(
                    """
                    INSERT INTO uniselecciones.usuario (
                        id_univ, nombre_completo, correo, hash_clave, rol, activo
                    ) VALUES (%s, %s, %s, %s, %s, %s)
                    RETURNING id_usuario, id_univ, nombre_completo, correo,
                              rol::text AS rol
                    """,
                    (
                        university["id_univ"],
                        credentials.nombre_completo,
                        credentials.email,
                        hash_password(credentials.password),
                        credentials.rol,
                        True,
                    ),
                )
                account = cursor.fetchone()
                account["universidad"] = university["nombre"]
    except HTTPException:
        raise
    except psycopg.errors.UniqueViolation:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Ya existe una cuenta con ese correo.",
        ) from None
    except psycopg.Error:
        logger.exception("No se pudo crear una cuenta en PostgreSQL.")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="No se pudo registrar la cuenta en la base de datos.",
        ) from None

    user = AuthenticatedUser(
        id_usuario=account["id_usuario"],
        id_univ=account["id_univ"],
        nombre_completo=account["nombre_completo"],
        correo=account["correo"],
        rol=account["rol"],
        universidad=account["universidad"],
    )
    token = create_access_token(
        user_id=user.id_usuario,
        email=user.correo,
        role=user.rol,
    )
    return RegisterResponse(
        message="Cuenta creada. Ya puedes entrar a UniSelecciones.",
        access_token=token,
        expires_in=settings.access_token_minutes * 60,
        user=user,
    )


def _invalid_credentials() -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Correo o contraseña incorrectos.",
        headers={"WWW-Authenticate": "Bearer"},
    )
