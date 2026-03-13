from collections.abc import Iterator
from pathlib import Path
import sqlite3

import pytest
from fastapi.testclient import TestClient

from app.main import create_app


@pytest.fixture
def client(tmp_path: Path) -> Iterator[TestClient]:
    test_app = create_app(db_path=tmp_path / "todoart-test.db")

    with TestClient(test_app) as test_client:
        yield test_client


def test_healthcheck_returns_ok(client: TestClient) -> None:
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_can_create_and_list_todos(client: TestClient) -> None:
    created = client.post(
        "/todos",
        json={
            "title": "Buy oat milk",
            "description": "For Saturday breakfast",
        },
    )

    assert created.status_code == 201
    assert created.json() == {
        "id": 1,
        "title": "Buy oat milk",
        "description": "For Saturday breakfast",
        "done": False,
    }

    listed = client.get("/todos")

    assert listed.status_code == 200
    assert listed.json() == [
        {
            "id": 1,
            "title": "Buy oat milk",
            "description": "For Saturday breakfast",
            "done": False,
        },
    ]


def test_create_without_description_defaults_to_empty_string(
    client: TestClient,
) -> None:
    created = client.post("/todos", json={"title": "Pay the rent"})

    assert created.status_code == 201
    assert created.json()["description"] == ""


def test_can_update_and_delete_todos(client: TestClient) -> None:
    created = client.post(
        "/todos",
        json={
            "title": "Book train tickets",
            "description": "Use the discount code from email",
        },
    )
    todo_id = created.json()["id"]

    updated = client.patch(
        f"/todos/{todo_id}",
        json={
            "title": "Book train tickets home",
            "description": "Bring the bike reservation too",
            "done": True,
        },
    )

    assert updated.status_code == 200
    assert updated.json() == {
        "id": todo_id,
        "title": "Book train tickets home",
        "description": "Bring the bike reservation too",
        "done": True,
    }

    fetched = client.get(f"/todos/{todo_id}")

    assert fetched.status_code == 200
    assert fetched.json() == updated.json()

    deleted = client.delete(f"/todos/{todo_id}")

    assert deleted.status_code == 204

    missing = client.get(f"/todos/{todo_id}")

    assert missing.status_code == 404
    assert missing.json() == {"detail": "Todo not found."}


def test_existing_database_is_migrated_with_description_column(
    tmp_path: Path,
) -> None:
    db_path = tmp_path / "todoart-legacy.db"
    with sqlite3.connect(db_path) as connection:
        connection.execute(
            """
            CREATE TABLE todos (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                done INTEGER NOT NULL DEFAULT 0 CHECK (done IN (0, 1))
            )
            """,
        )
        connection.execute(
            "INSERT INTO todos (title, done) VALUES (?, ?)",
            ("Existing task", 0),
        )
        connection.commit()

    test_app = create_app(db_path=db_path)

    with TestClient(test_app) as client:
        listed = client.get("/todos")

    assert listed.status_code == 200
    assert listed.json() == [
        {
            "id": 1,
            "title": "Existing task",
            "description": "",
            "done": False,
        },
    ]
