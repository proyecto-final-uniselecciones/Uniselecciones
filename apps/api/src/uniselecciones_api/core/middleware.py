"""Middleware para errores inesperados e identificación de solicitudes."""

import logging
from collections.abc import Awaitable, Callable
from time import perf_counter
from uuid import uuid4

from fastapi import FastAPI, Request, Response
from fastapi.responses import JSONResponse

logger = logging.getLogger(__name__)


def add_error_handling_middleware(app: FastAPI) -> None:
    """Registra errores no controlados sin filtrar detalles internos."""

    @app.middleware("http")
    async def error_handling_middleware(
        request: Request,
        call_next: Callable[[Request], Awaitable[Response]],
    ) -> Response:
        request_id = str(uuid4())
        started_at = perf_counter()

        try:
            response = await call_next(request)
        except Exception:
            logger.exception(
                "Unhandled request error: method=%s path=%s request_id=%s",
                request.method,
                request.url.path,
                request_id,
            )
            response = JSONResponse(
                status_code=500,
                content={
                    "error": {
                        "code": "internal_server_error",
                        "message": "Ocurrió un error inesperado.",
                        "request_id": request_id,
                    }
                },
                headers={"X-Request-ID": request_id},
            )
        else:
            response.headers["X-Request-ID"] = request_id
        finally:
            elapsed_ms = (perf_counter() - started_at) * 1000
            logger.info(
                "Request completed: method=%s path=%s elapsed_ms=%.2f request_id=%s",
                request.method,
                request.url.path,
                elapsed_ms,
                request_id,
            )

        return response
