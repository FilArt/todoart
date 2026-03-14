from contextlib import asynccontextmanager
import os
from pathlib import Path

from fastapi import (
    FastAPI,
    File,
    Form,
    Header,
    HTTPException,
    Request,
    Response,
    UploadFile,
    status,
)
from fastapi.responses import FileResponse

from . import crud
from . import release_crud
from .db import Db, init_db
from .models import AndroidRelease, AndroidReleaseRecord, Todo, TodoCreate, TodoUpdate


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

    @app.get("/todos", response_model=list[Todo])
    def list_todo_items(db: Db) -> list[Todo]:  # pyright: ignore[reportUnusedFunction]
        return crud.list_todos(db)

    @app.get("/")
    def read_root() -> dict[str, str]:  # pyright: ignore[reportUnusedFunction]
        return {
            "message": "TodoArt API is running",
            "status": "ok",
        }

    @app.get("/health")
    def healthcheck() -> dict[str, str]:  # pyright: ignore[reportUnusedFunction]
        return {"status": "ok"}

    @app.post("/todos", response_model=Todo, status_code=status.HTTP_201_CREATED)
    def create_todo_item(db: Db, payload: TodoCreate) -> Todo:  # pyright: ignore[reportUnusedFunction]
        return crud.create_todo(db, payload)

    @app.get("/todos/{todo_id}", response_model=Todo)
    def get_todo_item(db: Db, todo_id: int) -> Todo:  # pyright: ignore[reportUnusedFunction]
        return crud.get_todo(db, todo_id)

    @app.patch("/todos/{todo_id}", response_model=Todo)
    def update_todo_item(db: Db, todo_id: int, payload: TodoUpdate) -> Todo:  # pyright: ignore[reportUnusedFunction]
        return crud.update_todo(db, todo_id, payload)

    @app.delete("/todos/{todo_id}", status_code=status.HTTP_204_NO_CONTENT)
    def delete_todo_item(db: Db, todo_id: int) -> Response:  # pyright: ignore[reportUnusedFunction]
        crud.delete_todo(db, todo_id)
        return Response(status_code=status.HTTP_204_NO_CONTENT)

    @app.post(
        "/releases/android",
        response_model=AndroidRelease,
        status_code=status.HTTP_201_CREATED,
    )
    async def upload_android_release(  # pyright: ignore[reportUnusedFunction]
        db: Db,
        request: Request,
        version: str = Form(min_length=1, max_length=100),
        build_number: int = Form(ge=1),
        apk: UploadFile = File(...),
        notes: str = Form(default="", max_length=4000),
        release_token: str | None = Header(default=None, alias="X-Release-Token"),
    ) -> AndroidRelease:
        _authorize_release_upload(request, release_token)
        release = release_crud.create_android_release(
            db,
            app.state.releases_dir,
            version=version.strip(),
            build_number=build_number,
            notes=notes.strip(),
            apk=apk,
        )
        return _serialize_android_release(request, release)

    @app.get("/releases/android/latest", response_model=AndroidRelease)
    def get_latest_android_release(db: Db, request: Request) -> AndroidRelease:  # pyright: ignore[reportUnusedFunction]
        release = release_crud.get_latest_android_release(db)
        return _serialize_android_release(request, release)

    @app.get("/releases/android/download/{filename}")
    def download_android_release(db: Db, filename: str) -> FileResponse:  # pyright: ignore[reportUnusedFunction]
        release_path = release_crud.get_android_release_file(
            db,
            app.state.releases_dir,
            filename,
        )
        return FileResponse(
            release_path,
            media_type="application/vnd.android.package-archive",
            filename=filename,
        )

    return app


def _authorize_release_upload(request: Request, release_token: str | None) -> None:
    expected_token = request.app.state.release_upload_token
    if expected_token is None:
        return

    if release_token != expected_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Unauthorized release upload.",
        )


def _serialize_android_release(
    request: Request,
    release: AndroidReleaseRecord,
) -> AndroidRelease:
    download_url = str(
        request.url_for("download_android_release", filename=release.filename),
    )
    return AndroidRelease(
        version=release.version,
        build_number=release.build_number,
        notes=release.notes,
        download_url=download_url,
        published_at=release.published_at,
    )


app = create_app()
