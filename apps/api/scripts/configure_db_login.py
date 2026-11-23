"""Crea o actualiza el LOGIN de PostgreSQL con permisos u_api."""

import os
from pathlib import Path

import psycopg
from dotenv import load_dotenv
from psycopg import sql
from psycopg.conninfo import make_conninfo

PROJECT_ROOT = Path(__file__).resolve().parents[3]
load_dotenv(PROJECT_ROOT / ".env")

api_user = os.getenv("API_DB_USER", "uniselecciones_api")
api_password = os.getenv("API_DB_PASSWORD", "")
admin_password = os.getenv("POSTGRES_PASSWORD", "")

if not api_password or api_password.startswith("replace_with_"):
    raise SystemExit("Configura API_DB_PASSWORD en el .env raíz.")
if not admin_password or admin_password.startswith("replace_with_"):
    raise SystemExit("Configura POSTGRES_PASSWORD en el .env raíz.")

admin_conninfo = make_conninfo(
    host=os.getenv("API_DB_HOST", "127.0.0.1"),
    port=os.getenv("PG_AGS_PORT", "5432"),
    user=os.getenv("POSTGRES_USER", "uniselecciones"),
    password=admin_password,
    dbname=os.getenv("POSTGRES_DB", "uniselecciones"),
    connect_timeout=3,
)

with psycopg.connect(admin_conninfo, autocommit=True) as connection:
    with connection.cursor() as cursor:
        cursor.execute("SELECT 1 FROM pg_roles WHERE rolname = %s", (api_user,))
        role_exists = cursor.fetchone() is not None
        if role_exists:
            cursor.execute(
                sql.SQL("ALTER ROLE {} WITH LOGIN PASSWORD {}").format(
                    sql.Identifier(api_user), sql.Literal(api_password)
                )
            )
        else:
            cursor.execute(
                sql.SQL("CREATE ROLE {} LOGIN PASSWORD {}").format(
                    sql.Identifier(api_user), sql.Literal(api_password)
                )
            )
        cursor.execute(sql.SQL("GRANT u_api TO {}").format(sql.Identifier(api_user)))

print(f"El rol {api_user} quedó configurado con los permisos de u_api.")
