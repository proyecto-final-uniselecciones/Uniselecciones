"""Punto de entrada de la aplicación FastAPI."""

from fastapi import FastAPI

from uniselecciones_api import __version__
from uniselecciones_api.api.routes.health import router as health_router
from uniselecciones_api.core.middleware import add_error_handling_middleware

app = FastAPI(
    title="UniSelecciones API",
    description=(
        "API REST del proyecto integrador UniSelecciones. "
        "La autenticación y las bases de datos se conectarán en issues posteriores."
    ),
    version=__version__,
)

add_error_handling_middleware(app)
app.include_router(health_router)
