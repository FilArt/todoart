from contextlib import asynccontextmanager
import os
from pathlib import Path

from fastapi import FastAPI

from .db import init_db

from .routes import releases, todos

DEFAULT_DB_PATH = Path(__file__).resolve().parent.parent / "todoart.db"
DEFAULT_RELEASES_DIR = Path(__file__).resolve().parent.parent / "releases"


def create_app(
    db_path: str | Path | None = None,
    releases_dir: str | Path | None = None,
) -> FastAPI:
    resolved_db_path = Path(
        db_path or os.environ.get("TODOART_DB_PATH") or DEFAULT_DB_PATH,
    )
    resolved_releases_dir = Path(
        releases_dir or os.environ.get("TODOART_RELEASES_DIR") or DEFAULT_RELEASES_DIR,
    )

    @asynccontextmanager
    async def lifespan(app: FastAPI):
        app.state.db_path = resolved_db_path
        app.state.releases_dir = resolved_releases_dir
        app.state.release_upload_token = os.environ.get("TODOART_RELEASE_UPLOAD_TOKEN")
        init_db(resolved_db_path)
        resolved_releases_dir.mkdir(parents=True, exist_ok=True)
        yield

    app = FastAPI(title="TodoArt API", lifespan=lifespan)
    app.include_router(releases.router)
    app.include_router(todos.router)

    @app.get("/")
    def read_root() -> dict[str, str]:  # pyright: ignore[reportUnusedFunction]
        return {
            "message": "TodoArt API is running",
            "status": "ok",
        }

    @app.get("/health")
    def healthcheck() -> dict[str, str]:  # pyright: ignore[reportUnusedFunction]
        return {"status": "ok"}

    return app


app = create_app()
