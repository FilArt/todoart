from contextlib import asynccontextmanager
import os
from pathlib import Path

from fastapi import FastAPI, Response, status

from . import crud
from .db import init_db
from .models import Todo, TodoCreate, TodoUpdate


DEFAULT_DB_PATH = Path(__file__).resolve().parent.parent / "todoart.db"


def create_app(db_path: str | Path | None = None) -> FastAPI:
    resolved_db_path = Path(
        db_path or os.environ.get("TODOART_DB_PATH") or DEFAULT_DB_PATH,
    )

    @asynccontextmanager
    async def lifespan(app: FastAPI):
        app.state.db_path = resolved_db_path
        init_db(resolved_db_path)
        yield

    app = FastAPI(title="TodoArt API", lifespan=lifespan)

    @app.get("/")
    def read_root() -> dict[str, str]:
        return {
            "message": "TodoArt API is running",
            "status": "ok",
        }

    @app.get("/health")
    def healthcheck() -> dict[str, str]:
        return {"status": "ok"}

    @app.get("/todos", response_model=list[Todo])
    def list_todo_items() -> list[Todo]:
        return crud.list_todos(app.state.db_path)

    @app.post("/todos", response_model=Todo, status_code=status.HTTP_201_CREATED)
    def create_todo_item(payload: TodoCreate) -> Todo:
        return crud.create_todo(app.state.db_path, payload)

    @app.get("/todos/{todo_id}", response_model=Todo)
    def get_todo_item(todo_id: int) -> Todo:
        return crud.get_todo(app.state.db_path, todo_id)

    @app.patch("/todos/{todo_id}", response_model=Todo)
    def update_todo_item(todo_id: int, payload: TodoUpdate) -> Todo:
        return crud.update_todo(app.state.db_path, todo_id, payload)

    @app.delete("/todos/{todo_id}", status_code=status.HTTP_204_NO_CONTENT)
    def delete_todo_item(todo_id: int) -> Response:
        crud.delete_todo(app.state.db_path, todo_id)
        return Response(status_code=status.HTTP_204_NO_CONTENT)

    return app


app = create_app()
