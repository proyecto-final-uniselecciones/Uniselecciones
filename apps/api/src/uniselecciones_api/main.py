"""Punto de entrada de la aplicación FastAPI."""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from uniselecciones_api import __version__
from uniselecciones_api.api.routes.auth import router as auth_router
from uniselecciones_api.api.routes.health import router as health_router
from uniselecciones_api.api.routes.universities import router as universities_router
from uniselecciones_api.core.middleware import add_error_handling_middleware

app = FastAPI(
    title="UniSelecciones API",
    description=(
        "API REST de UniSelecciones para autenticación y acceso a PostgreSQL."
    ),
    version=__version__,
)

add_error_handling_middleware(app)
app.add_middleware(
    CORSMiddleware,
    allow_origins=[],
    allow_origin_regex=r"^http://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
)
app.include_router(health_router)
app.include_router(auth_router)
app.include_router(universities_router)
