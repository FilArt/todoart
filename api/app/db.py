from pathlib import Path
import sqlite3


SCHEMA = """
CREATE TABLE IF NOT EXISTS todos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    done INTEGER NOT NULL DEFAULT 0 CHECK (done IN (0, 1))
);
"""


def init_db(db_path: str | Path) -> None:
    path = Path(db_path)
    path.parent.mkdir(parents=True, exist_ok=True)

    with sqlite3.connect(path) as connection:
        connection.execute(SCHEMA)
        _ensure_description_column(connection)
        connection.commit()


def connect(db_path: str | Path) -> sqlite3.Connection:
    connection = sqlite3.connect(db_path)
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
