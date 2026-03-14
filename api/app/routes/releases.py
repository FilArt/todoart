from typing import Annotated
from fastapi import APIRouter, Form, HTTPException, Request, UploadFile, status, File, Header

from fastapi.responses import FileResponse

from app.db import Db
from app.models import AndroidRelease, AndroidReleaseRecord
from app.crud import releases as crud


router = APIRouter()


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
        request.url_for("download", filename=release.filename),
    )
    return AndroidRelease(
        version=release.version,
        build_number=release.build_number,
        notes=release.notes,
        download_url=download_url,
        published_at=release.published_at,
    )


@router.post(
    "/releases/android",
    response_model=AndroidRelease,
    status_code=status.HTTP_201_CREATED,
)
async def upload(
    db: Db,
    request: Request,
    build_number: Annotated[int, Form(ge=1)],
    version: Annotated[str, Form(min_length=1, max_length=100)],
    apk: Annotated[UploadFile, File(...)],
    release_token: Annotated[str | None, Header(alias="X-Release-Token")] = None,
    notes: Annotated[str, Form(max_length=4000)] = "",
) -> AndroidRelease:
    _authorize_release_upload(request, release_token)
    release = crud.create_android_release(
        db,
        request.app.state.releases_dir,
        version=version.strip(),
        build_number=build_number,
        notes=notes.strip(),
        apk=apk,
    )
    return _serialize_android_release(request, release)


@router.get("/releases/android/latest", response_model=AndroidRelease)
def get_latest(db: Db, request: Request) -> AndroidRelease:
    release = crud.get_latest_android_release(db)
    return _serialize_android_release(request, release)


@router.get("/releases/android/download/{filename}")
def download(request: Request, db: Db, filename: str) -> FileResponse:
    release_path = crud.get_android_release_file(
        db,
        request.app.state.releases_dir,
        filename,
    )
    return FileResponse(
        release_path,
        media_type="application/vnd.android.package-archive",
        filename=filename,
    )
