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


def _required_key(name: str) -> str:
    """Valida una llave criptográfica de al menos 256 bits."""
    key = os.getenv(name, "")
    if (
        len(key) < 64
        or key.startswith("replace_with_")
        or any(character.isspace() for character in key)
    ):
        raise RuntimeError(
            f"Configura {name} con una llave aleatoria de al menos 64 caracteres."
        )
    return key


def _region_nodo() -> str:
    region = os.getenv("APP_REGION_NODO", "").upper()
    if region not in {"AGS", "JAL", "ZAC"}:
        raise RuntimeError("APP_REGION_NODO debe ser AGS, JAL o ZAC.")
    return region


def _enforce_cp() -> bool:
    value = os.getenv("APP_ENFORCE_CP", "false").lower()
    if value not in {"true", "false"}:
        raise RuntimeError("APP_ENFORCE_CP debe ser true o false.")
    return value == "true"


@dataclass(frozen=True)
class Settings:
    database_url: str
    jwt_secret: str
    access_token_minutes: int
    region_nodo: str
    cripto_key: str
    matricula_key: str
    enforce_cp: bool
    jwt_issuer: str = "uniselecciones-api"


settings = Settings(
    database_url=_database_url(),
    jwt_secret=_jwt_secret(),
    access_token_minutes=int(os.getenv("ACCESS_TOKEN_MINUTES", "60")),
    region_nodo=_region_nodo(),
    cripto_key=_required_key("APP_CRIPTO_KEY"),
    matricula_key=_required_key("APP_MATRICULA_KEY"),
    enforce_cp=_enforce_cp(),
)
