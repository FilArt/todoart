from collections.abc import Generator
from pathlib import Path
import sqlite3
from typing import Annotated

from fastapi import Depends, Request


SCHEMA = """
CREATE TABLE IF NOT EXISTS todos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    done INTEGER NOT NULL DEFAULT 0 CHECK (done IN (0, 1))
);

CREATE TABLE IF NOT EXISTS android_releases (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    version TEXT NOT NULL,
    build_number INTEGER NOT NULL,
    notes TEXT NOT NULL DEFAULT '',
    filename TEXT NOT NULL UNIQUE,
    published_at TEXT NOT NULL
);
"""


def init_db(db_path: str | Path) -> None:
    path = Path(db_path)
    path.parent.mkdir(parents=True, exist_ok=True)

    with sqlite3.connect(path) as connection:
        connection.executescript(SCHEMA)
        _ensure_description_column(connection)
        connection.commit()


def connect(db_path: str | Path) -> sqlite3.Connection:
    connection = sqlite3.connect(db_path, check_same_thread=False)
    connection.row_factory = sqlite3.Row
    return connection


def _ensure_description_column(connection: sqlite3.Connection) -> None:
    columns = connection.execute("PRAGMA table_info(todos)").fetchall()
    column_names = {column[1] for column in columns}
    if "description" in column_names:
        return

    connection.execute(
        "ALTER TABLE todos ADD COLUMN description TEXT NOT NULL DEFAULT ''",
    )


def get_db(request: Request) -> Generator[sqlite3.Connection, None, None]:
    with connect(request.app.state.db_path) as db:  # pyright: ignore[reportAny]
        yield db


Db = Annotated[sqlite3.Connection, Depends(get_db)]
