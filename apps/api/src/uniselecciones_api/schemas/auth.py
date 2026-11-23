"""Modelos de solicitud y respuesta de autenticación."""

import re
from typing import Literal

from pydantic import BaseModel, Field, field_validator

_EMAIL_PATTERN = re.compile(r"^[^\s@]+@[^\s@]+\.[^\s@]+$")


class LoginRequest(BaseModel):
    """Credenciales recibidas por POST /auth/login."""

    email: str = Field(min_length=3, max_length=254)
    password: str = Field(min_length=1, max_length=128)

    @field_validator("email")
    @classmethod
    def normalize_and_validate_email(cls, value: str) -> str:
        email = value.strip().lower()
        if not _EMAIL_PATTERN.fullmatch(email):
            raise ValueError("Escribe un correo electrónico válido.")
        return email


class RegisterRequest(LoginRequest):
    """Datos para crear una cuenta con uno de los roles disponibles."""

    nombre_completo: str = Field(min_length=3, max_length=160)
    password: str = Field(min_length=8, max_length=128)
    id_univ: int = Field(gt=0)
    rol: Literal["institucion", "entrenador", "jugador"]

    @field_validator("nombre_completo")
    @classmethod
    def normalize_name(cls, value: str) -> str:
        name = " ".join(value.split())
        if len(name) < 3:
            raise ValueError("Escribe tu nombre completo.")
        return name


class AuthenticatedUser(BaseModel):
    """Datos públicos de una cuenta autenticada."""

    id_usuario: int
    id_univ: int
    nombre_completo: str
    correo: str
    rol: Literal["institucion", "entrenador", "jugador"]
    universidad: str


class LoginResponse(BaseModel):
    """Token y datos públicos devueltos tras autenticar."""

    access_token: str
    token_type: Literal["bearer"] = "bearer"
    expires_in: int
    user: AuthenticatedUser


class RegisterResponse(BaseModel):
    """Respuesta al crear una cuenta activa con el rol solicitado."""

    status: Literal["active"] = "active"
    message: str
    access_token: str
    token_type: Literal["bearer"] = "bearer"
    expires_in: int
    user: AuthenticatedUser
