"""Verificación de contraseñas y emisión de tokens de acceso."""

from datetime import UTC, datetime, timedelta

import jwt
from argon2 import PasswordHasher
from argon2.exceptions import VerificationError

from uniselecciones_api.core.config import settings

_password_hasher = PasswordHasher()
_dummy_password_hash = _password_hasher.hash("not-a-real-uniselecciones-password")


def hash_password(password: str) -> str:
    """Genera un hash Argon2id para una cuenta nueva."""
    return _password_hasher.hash(password)


def verify_password(password: str, password_hash: str) -> bool:
    """Compara la contraseña con un hash Argon2id sin propagar errores del hash."""
    try:
        return _password_hasher.verify(password_hash, password)
    except VerificationError:
        return False


def perform_dummy_password_check(password: str) -> None:
    """Reduce la diferencia de tiempo cuando el correo no existe."""
    verify_password(password, _dummy_password_hash)


def create_access_token(*, user_id: int, email: str, role: str) -> str:
    """Emite un JWT firmado para el usuario autenticado."""
    now = datetime.now(UTC)
    expires_at = now + timedelta(minutes=settings.access_token_minutes)
    return jwt.encode(
        {
            "sub": str(user_id),
            "email": email,
            "role": role,
            "iss": settings.jwt_issuer,
            "iat": now,
            "exp": expires_at,
        },
        settings.jwt_secret,
        algorithm="HS256",
    )
