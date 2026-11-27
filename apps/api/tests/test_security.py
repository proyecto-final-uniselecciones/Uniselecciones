"""Pruebas unitarias para la validación de tokens JWT."""

from datetime import UTC, datetime, timedelta

import jwt
import pytest
from jwt.exceptions import InvalidTokenError

from uniselecciones_api.core.config import settings
from uniselecciones_api.core.security import (
    create_access_token,
    decode_access_token,
)


def test_valid_token_is_decoded():
    """Un token válido debe devolver sus datos correctamente."""
    token = create_access_token(
        user_id=42,
        email="jugador@ejemplo.com",
        role="jugador",
    )

    payload = decode_access_token(token)

    assert payload["sub"] == "42"
    assert payload["email"] == "jugador@ejemplo.com"
    assert payload["role"] == "jugador"


def test_tampered_token_is_rejected():
    """Un token cuya firma fue modificada debe rechazarse."""
    token = create_access_token(
        user_id=42,
        email="jugador@ejemplo.com",
        role="jugador",
    )

    parts = token.split(".")
    signature = parts[2]
    parts[2] = ("A" if signature[0] != "A" else "B") + signature[1:]

    with pytest.raises(InvalidTokenError):
        decode_access_token(".".join(parts))


def test_expired_token_is_rejected():
    """Un token vencido no debe ser aceptado."""
    now = datetime.now(UTC)

    payload = {
        "sub": "42",
        "email": "jugador@ejemplo.com",
        "role": "jugador",
        "iss": settings.jwt_issuer,
        "iat": now - timedelta(hours=2),
        "exp": now - timedelta(hours=1),
    }

    token = jwt.encode(
        payload,
        settings.jwt_secret,
        algorithm="HS256",
    )

    with pytest.raises(InvalidTokenError):
        decode_access_token(token)


def test_wrong_issuer_is_rejected():
    """Un token emitido por otro emisor debe rechazarse."""
    now = datetime.now(UTC)

    payload = {
        "sub": "42",
        "email": "jugador@ejemplo.com",
        "role": "jugador",
        "iss": "otro-emisor",
        "iat": now,
        "exp": now + timedelta(minutes=30),
    }

    token = jwt.encode(
        payload,
        settings.jwt_secret,
        algorithm="HS256",
    )

    with pytest.raises(InvalidTokenError):
        decode_access_token(token)


def test_token_without_required_claim_is_rejected():
    """Un token sin campos obligatorios debe rechazarse."""
    now = datetime.now(UTC)

    payload = {
        "sub": "42",
        "role": "jugador",
        "iss": settings.jwt_issuer,
        "iat": now,
        "exp": now + timedelta(minutes=30),
    }

    token = jwt.encode(
        payload,
        settings.jwt_secret,
        algorithm="HS256",
    )

    with pytest.raises(InvalidTokenError):
        decode_access_token(token)
