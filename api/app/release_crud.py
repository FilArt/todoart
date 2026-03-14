from datetime import datetime, timezone
from pathlib import Path
import shutil
import sqlite3
import uuid

from fastapi import HTTPException, UploadFile, status

from .db import connect
from .models import AndroidReleaseRecord

ANDROID_RELEASE_COLUMNS = "version, build_number, notes, filename, published_at"


def create_android_release(
    db_path: str | Path,
    releases_dir: str | Path,
    *,
    version: str,
    build_number: int,
    notes: str,
    apk: UploadFile,
) -> AndroidReleaseRecord:
    releases_path = Path(releases_dir)
    releases_path.mkdir(parents=True, exist_ok=True)

    filename = _build_release_filename(version, build_number)
    destination = releases_path / filename
    published_at = datetime.now(timezone.utc).isoformat()

    try:
        with destination.open("wb") as output_file:
            shutil.copyfileobj(apk.file, output_file)

        with connect(db_path) as connection:
            connection.execute(
                """
                INSERT INTO android_releases (
                    version,
                    build_number,
                    notes,
                    filename,
                    published_at
                )
                VALUES (?, ?, ?, ?, ?)
                """,
                (version, build_number, notes, filename, published_at),
            )
            connection.commit()
            row = connection.execute(
                """
                SELECT
                    version,
                    build_number,
                    notes,
                    filename,
                    published_at
                FROM android_releases
                WHERE filename = ?
                """,
                (filename,),
            ).fetchone()
    except Exception:
        destination.unlink(missing_ok=True)
        raise

    return _release_from_row(_require_row(row))


def get_latest_android_release(db_path: str | Path) -> AndroidReleaseRecord:
    with connect(db_path) as connection:
        row = connection.execute(
            f"""
            SELECT {ANDROID_RELEASE_COLUMNS}
            FROM android_releases
            ORDER BY build_number DESC, id DESC
            LIMIT 1
            """,
        ).fetchone()

    if row is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Android release not found.",
        )

    return _release_from_row(row)


def get_android_release_file(
    db_path: str | Path,
    releases_dir: str | Path,
    filename: str,
) -> Path:
    with connect(db_path) as connection:
        row = connection.execute(
            "SELECT filename FROM android_releases WHERE filename = ?",
            (filename,),
        ).fetchone()

    if row is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Android release not found.",
        )

    release_path = Path(releases_dir) / filename
    if not release_path.is_file():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Android release file not found.",
        )

    return release_path


def _build_release_filename(version: str, build_number: int) -> str:
    slug = "".join(
        character if character.isalnum() else "-"
        for character in version.strip().lower()
    ).strip("-")
    slug = slug or "release"
    return f"todoart-android-{slug}-{build_number}-{uuid.uuid4().hex[:12]}.apk"


def _release_from_row(row: sqlite3.Row) -> AndroidReleaseRecord:
    return AndroidReleaseRecord(
        version=str(row["version"]),
        build_number=int(row["build_number"]),
        notes=str(row["notes"]),
        filename=str(row["filename"]),
        published_at=datetime.fromisoformat(str(row["published_at"])),
    )


def _require_row(row: sqlite3.Row | None) -> sqlite3.Row:
    if row is None:
        raise RuntimeError("Expected Android release row to be present.")
    return row
