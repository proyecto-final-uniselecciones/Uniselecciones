"""Pruebas de autenticación y consulta de usuarios."""

import psycopg
import pytest
from fastapi import HTTPException
from fastapi.security import HTTPAuthorizationCredentials

from uniselecciones_api.core import dependencies
from uniselecciones_api.core.security import create_access_token


class FakeCursor:
    """Simula el cursor de PostgreSQL."""

    def __init__(self, account):
        self.account = account

    def __enter__(self):
        return self

    def __exit__(self, *args):
        return None

    def execute(self, query, parameters):
        self.query = query
        self.parameters = parameters

    def fetchone(self):
        return self.account


class FakeConnection:
    """Simula una conexión de PostgreSQL."""

    def __init__(self, account):
        self.account = account

    def __enter__(self):
        return self

    def __exit__(self, *args):
        return None

    def cursor(self, row_factory=None):
        return FakeCursor(self.account)


def make_account(*, active=True, role="jugador"):
    """Genera una cuenta sintética para las pruebas."""
    return {
        "id_usuario": 42,
        "id_univ": 1001,
        "nombre_completo": "Jugador de prueba",
        "correo": "jugador@ejemplo.com",
        "rol": role,
        "activo": active,
        "universidad": "Universidad de prueba",
    }


def make_credentials(role="jugador"):
    """Genera credenciales con un JWT válido."""
    token = create_access_token(
        user_id=42,
        email="jugador@ejemplo.com",
        role=role,
    )
    return HTTPAuthorizationCredentials(
        scheme="Bearer",
        credentials=token,
    )


def test_missing_token_returns_401():
    """Una petición sin credenciales debe rechazarse."""
    with pytest.raises(HTTPException) as error:
        dependencies.get_current_user(None)

    assert error.value.status_code == 401


def test_invalid_token_returns_401():
    """Un JWT inválido debe rechazarse sin consultar PostgreSQL."""
    credentials = HTTPAuthorizationCredentials(
        scheme="Bearer",
        credentials="token-invalido",
    )

    with pytest.raises(HTTPException) as error:
        dependencies.get_current_user(credentials)

    assert error.value.status_code == 401


def test_missing_account_returns_401(monkeypatch):
    """Un usuario inexistente no debe autenticarse."""
    monkeypatch.setattr(
        dependencies.psycopg,
        "connect",
        lambda database_url: FakeConnection(None),
    )

    with pytest.raises(HTTPException) as error:
        dependencies.get_current_user(make_credentials())

    assert error.value.status_code == 401


def test_inactive_account_returns_403(monkeypatch):
    """Una cuenta desactivada debe perder el acceso."""
    monkeypatch.setattr(
        dependencies.psycopg,
        "connect",
        lambda database_url: FakeConnection(make_account(active=False)),
    )

    with pytest.raises(HTTPException) as error:
        dependencies.get_current_user(make_credentials())

    assert error.value.status_code == 403


def test_active_user_is_authenticated(monkeypatch):
    """Una cuenta activa debe obtener su identidad desde PostgreSQL."""
    monkeypatch.setattr(
        dependencies.psycopg,
        "connect",
        lambda database_url: FakeConnection(make_account()),
    )

    user = dependencies.get_current_user(make_credentials())

    assert user.id_usuario == 42
    assert user.id_univ == 1001
    assert user.rol == "jugador"
    assert user.correo == "jugador@ejemplo.com"


def test_changed_role_invalidates_old_token(monkeypatch):
    """Un cambio de rol debe invalidar el token anterior."""
    monkeypatch.setattr(
        dependencies.psycopg,
        "connect",
        lambda database_url: FakeConnection(make_account(role="entrenador")),
    )

    with pytest.raises(HTTPException) as error:
        dependencies.get_current_user(make_credentials(role="jugador"))

    assert error.value.status_code == 401


def test_database_error_returns_503(monkeypatch):
    """Un fallo de PostgreSQL debe producir un error controlado."""

    def database_failure(database_url):
        raise psycopg.OperationalError("Error simulado")

    monkeypatch.setattr(
        dependencies.psycopg,
        "connect",
        database_failure,
    )

    with pytest.raises(HTTPException) as error:
        dependencies.get_current_user(make_credentials())

    assert error.value.status_code == 503
