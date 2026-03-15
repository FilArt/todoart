from contextlib import asynccontextmanager
import os
from pathlib import Path

from fastapi import FastAPI

from app.settings import DefaultSettings

from .db import init_db

from .routes import releases, todos, base


def create_app(
    db_path: Path,
    releases_dir: Path,
) -> FastAPI:

    @asynccontextmanager
    async def lifespan(
        app: FastAPI,
    ):
        app.state.db_path = db_path
        app.state.releases_dir = releases_dir or settings.releases_dir
        app.state.release_upload_token = os.environ.get("TODOART_RELEASE_UPLOAD_TOKEN")
        init_db(db_path)
        releases_dir.mkdir(parents=True, exist_ok=True)
        yield

    app = FastAPI(title="TodoArt API", lifespan=lifespan)
    app.include_router(base.router)
    app.include_router(releases.router)
    app.include_router(todos.router)

    return app


settings = DefaultSettings()
app = create_app(
    settings.db_path,
    settings.releases_dir,
)
