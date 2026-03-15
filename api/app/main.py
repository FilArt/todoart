from contextlib import asynccontextmanager
from fastapi import FastAPI

from app.settings import get_settings

from .db import init_db

from .routes import releases, todos, base


def create_app() -> FastAPI:
    @asynccontextmanager
    async def lifespan(
        app: FastAPI,  # pyright: ignore[reportUnusedParameter]
    ):
        settings = get_settings()
        init_db(settings.db_path)
        settings.releases_dir.mkdir(parents=True, exist_ok=True)
        yield

    app = FastAPI(title="TodoArt API", lifespan=lifespan)
    app.include_router(base.router)
    app.include_router(releases.router)
    app.include_router(todos.router)

    return app


app = create_app()
