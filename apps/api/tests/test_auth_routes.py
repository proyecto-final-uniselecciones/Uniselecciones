"""Pruebas HTTP de las rutas de autenticación."""

import psycopg
from fastapi.testclient import TestClient

from uniselecciones_api.core import dependencies
from uniselecciones_api.core.security import create_access_token
from uniselecciones_api.main import app


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


def make_account(active=True):
    """Genera una cuenta sintética."""
    return {
        "id_usuario": 42,
        "id_univ": 1001,
        "nombre_completo": "Jugador de prueba",
        "correo": "jugador@ejemplo.com",
        "rol": "jugador",
        "activo": active,
        "universidad": "Universidad de prueba",
    }


def make_token():
    """Genera un JWT válido para las pruebas."""
    return create_access_token(
        user_id=42,
        email="jugador@ejemplo.com",
        role="jugador",
    )


def test_profile_without_token_returns_401():
    """El endpoint debe rechazar solicitudes sin JWT."""
    client = TestClient(app)

    response = client.get("/auth/me")

    assert response.status_code == 401
    assert response.headers["www-authenticate"] == "Bearer"


def test_profile_with_invalid_token_returns_401():
    """El endpoint debe rechazar un JWT inválido."""
    client = TestClient(app)

    response = client.get(
        "/auth/me",
        headers={"Authorization": "Bearer token-invalido"},
    )

    assert response.status_code == 401


def test_profile_with_active_user_returns_200(monkeypatch):
    """Un usuario activo debe obtener su perfil."""
    account = make_account()

    monkeypatch.setattr(
        dependencies.psycopg,
        "connect",
        lambda database_url: FakeConnection(account),
    )

    client = TestClient(app)

    response = client.get(
        "/auth/me",
        headers={"Authorization": f"Bearer {make_token()}"},
    )

    assert response.status_code == 200
    assert response.json()["id_usuario"] == 42
    assert response.json()["id_univ"] == 1001
    assert response.json()["rol"] == "jugador"
    assert response.json()["correo"] == "jugador@ejemplo.com"


def test_profile_with_inactive_user_returns_403(monkeypatch):
    """Una cuenta desactivada debe recibir HTTP 403."""
    account = make_account(active=False)

    monkeypatch.setattr(
        dependencies.psycopg,
        "connect",
        lambda database_url: FakeConnection(account),
    )

    client = TestClient(app)

    response = client.get(
        "/auth/me",
        headers={"Authorization": f"Bearer {make_token()}"},
    )

    assert response.status_code == 403


def test_profile_database_error_returns_503(monkeypatch):
    """Un fallo de PostgreSQL debe producir HTTP 503."""

    def database_failure(database_url):
        raise psycopg.OperationalError("Error simulado")

    monkeypatch.setattr(
        dependencies.psycopg,
        "connect",
        database_failure,
    )

    client = TestClient(app)

    response = client.get(
        "/auth/me",
        headers={"Authorization": f"Bearer {make_token()}"},
    )

    assert response.status_code == 503
