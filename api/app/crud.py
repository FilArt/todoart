import sqlite3
from typing import TypeAlias

from fastapi import HTTPException, status

from .models import Todo, TodoCreate, TodoUpdate

TODO_COLUMNS = "id, title, description, done"

Db: TypeAlias = sqlite3.Connection


def list_todos(db: Db) -> list[Todo]:
    rows = db.execute(
        f"SELECT {TODO_COLUMNS} FROM todos ORDER BY id DESC",
    ).fetchall()

    return [_todo_from_row(row) for row in rows]


def get_todo(db: Db, todo_id: int) -> Todo:
    row = db.execute(
        f"SELECT {TODO_COLUMNS} FROM todos WHERE id = ?",
        (todo_id,),
    ).fetchone()

    if row is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Todo not found.",
        )

    return _todo_from_row(row)


def create_todo(db: Db, payload: TodoCreate) -> Todo:
    cursor = db.execute(
        "INSERT INTO todos (title, description, done) VALUES (?, ?, ?)",
        (payload.title, payload.description, 0),
    )
    db.commit()
    row = db.execute(
        f"SELECT {TODO_COLUMNS} FROM todos WHERE id = ?",
        (cursor.lastrowid,),
    ).fetchone()

    return _todo_from_row(_require_row(row))


def update_todo(db: Db, todo_id: int, payload: TodoUpdate) -> Todo:
    current = db.execute(
        f"SELECT {TODO_COLUMNS} FROM todos WHERE id = ?",
        (todo_id,),
    ).fetchone()

    if current is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Todo not found.",
        )

    title = payload.title if payload.title is not None else current["title"]
    description = payload.description if payload.description is not None else current["description"]
    done = payload.done if payload.done is not None else bool(current["done"])

    db.execute(
        "UPDATE todos SET title = ?, description = ?, done = ? WHERE id = ?",
        (title, description, int(done), todo_id),
    )
    db.commit()
    row = db.execute(
        f"SELECT {TODO_COLUMNS} FROM todos WHERE id = ?",
        (todo_id,),
    ).fetchone()

    return _todo_from_row(_require_row(row))


def delete_todo(db: Db, todo_id: int) -> None:
    cursor = db.execute(
        "DELETE FROM todos WHERE id = ?",
        (todo_id,),
    )
    db.commit()

    if cursor.rowcount == 0:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Todo not found.",
        )


def _todo_from_row(row: sqlite3.Row) -> Todo:
    return Todo(
        id=int(row["id"]),
        title=str(row["title"]),
        description=str(row["description"]),
        done=bool(row["done"]),
    )


def _require_row(row: sqlite3.Row | None) -> sqlite3.Row:
    if row is None:
        raise RuntimeError("Expected SQLite row to be present.")
    return row
