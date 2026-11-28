"""Pruebas de configuración segura de conexiones PostgreSQL."""

from uniselecciones_api.core import database


class FakeCursor:
    """Simula un cursor de PostgreSQL."""

    def __init__(self):
        self.query = None
        self.parameters = None

    def __enter__(self):
        return self

    def __exit__(self, *args):
        return None

    def execute(self, query, parameters):
        self.query = query
        self.parameters = parameters


class FakeConnection:
    """Simula una conexión de PostgreSQL."""

    def __init__(self):
        self.fake_cursor = FakeCursor()
        self.closed = False

    def __enter__(self):
        return self

    def __exit__(self, *args):
        self.closed = True
        return None

    def cursor(self):
        return self.fake_cursor


def test_connect_db_configures_security_variables(monkeypatch):
    """La conexión debe establecer las cuatro variables por transacción."""
    fake_connection = FakeConnection()
    received = {}

    def fake_connect(database_url):
        received["database_url"] = database_url
        return fake_connection

    monkeypatch.setattr(database.psycopg, "connect", fake_connect)

    with database.connect_db() as connection:
        assert connection is fake_connection

    query = fake_connection.fake_cursor.query

    assert "set_config('app.region_nodo', %s, true)" in query
    assert "set_config('app.cripto_key', %s, true)" in query
    assert "set_config('app.matricula_key', %s, true)" in query
    assert "set_config('app.enforce_cp', %s, true)" in query

    assert fake_connection.fake_cursor.parameters == (
        database.settings.region_nodo,
        database.settings.cripto_key,
        database.settings.matricula_key,
        str(database.settings.enforce_cp).lower(),
    )

    assert received["database_url"] == database.settings.database_url
    assert fake_connection.closed
