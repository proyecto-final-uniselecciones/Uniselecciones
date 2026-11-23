"""Configuración local de la API; los secretos se leen desde el .env ignorado."""

import os
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv
from psycopg.conninfo import make_conninfo

PROJECT_ROOT = Path(__file__).resolve().parents[5]
load_dotenv(PROJECT_ROOT / ".env")


def _database_url() -> str:
    explicit_url = os.getenv("DATABASE_URL")
    if explicit_url:
        return explicit_url

    password = os.getenv("API_DB_PASSWORD") or os.getenv("POSTGRES_PASSWORD", "")
    if not password or password.startswith("replace_with_"):
        raise RuntimeError(
            "Configura API_DB_PASSWORD o POSTGRES_PASSWORD en el .env del proyecto."
        )

    return make_conninfo(
        host=os.getenv("API_DB_HOST", "127.0.0.1"),
        port=os.getenv("PG_AGS_PORT", "5432"),
        user=os.getenv("API_DB_USER") or os.getenv("POSTGRES_USER", "uniselecciones"),
        password=password,
        dbname=os.getenv("POSTGRES_DB", "uniselecciones"),
        connect_timeout=3,
    )


def _jwt_secret() -> str:
    secret = os.getenv("JWT_SECRET", "")
    if len(secret) < 32 or secret.startswith("replace_with_"):
        raise RuntimeError(
            "Configura JWT_SECRET con al menos 32 caracteres en el .env del proyecto."
        )
    return secret


@dataclass(frozen=True)
class Settings:
    database_url: str
    jwt_secret: str
    access_token_minutes: int
    jwt_issuer: str = "uniselecciones-api"


settings = Settings(
    database_url=_database_url(),
    jwt_secret=_jwt_secret(),
    access_token_minutes=int(os.getenv("ACCESS_TOKEN_MINUTES", "60")),
)
