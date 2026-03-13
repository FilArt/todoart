from pathlib import Path
import sqlite3

from fastapi import HTTPException, status

from .db import connect
from .models import Todo, TodoCreate, TodoUpdate


def list_todos(db_path: str | Path) -> list[Todo]:
    with connect(db_path) as connection:
        rows = connection.execute(
            "SELECT id, title, done FROM todos ORDER BY id DESC",
        ).fetchall()

    return [_todo_from_row(row) for row in rows]


def get_todo(db_path: str | Path, todo_id: int) -> Todo:
    with connect(db_path) as connection:
        row = connection.execute(
            "SELECT id, title, done FROM todos WHERE id = ?",
            (todo_id,),
        ).fetchone()

    if row is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Todo not found.",
        )

    return _todo_from_row(row)


def create_todo(db_path: str | Path, payload: TodoCreate) -> Todo:
    with connect(db_path) as connection:
        cursor = connection.execute(
            "INSERT INTO todos (title, done) VALUES (?, ?)",
            (payload.title, 0),
        )
        connection.commit()
        row = connection.execute(
            "SELECT id, title, done FROM todos WHERE id = ?",
            (cursor.lastrowid,),
        ).fetchone()

    return _todo_from_row(_require_row(row))


def update_todo(db_path: str | Path, todo_id: int, payload: TodoUpdate) -> Todo:
    with connect(db_path) as connection:
        current = connection.execute(
            "SELECT id, title, done FROM todos WHERE id = ?",
            (todo_id,),
        ).fetchone()

        if current is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Todo not found.",
            )

        title = payload.title if payload.title is not None else current["title"]
        done = payload.done if payload.done is not None else bool(current["done"])

        connection.execute(
            "UPDATE todos SET title = ?, done = ? WHERE id = ?",
            (title, int(done), todo_id),
        )
        connection.commit()
        row = connection.execute(
            "SELECT id, title, done FROM todos WHERE id = ?",
            (todo_id,),
        ).fetchone()

    return _todo_from_row(_require_row(row))


def delete_todo(db_path: str | Path, todo_id: int) -> None:
    with connect(db_path) as connection:
        cursor = connection.execute(
            "DELETE FROM todos WHERE id = ?",
            (todo_id,),
        )
        connection.commit()

    if cursor.rowcount == 0:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Todo not found.",
        )


def _todo_from_row(row: sqlite3.Row) -> Todo:
    return Todo(
        id=int(row["id"]),
        title=str(row["title"]),
        done=bool(row["done"]),
    )


def _require_row(row: sqlite3.Row | None) -> sqlite3.Row:
    if row is None:
        raise RuntimeError("Expected SQLite row to be present.")
    return row
