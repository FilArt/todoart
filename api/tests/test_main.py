from collections.abc import Iterator
from pathlib import Path

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
    created = client.post("/todos", json={"title": "Buy oat milk"})

    assert created.status_code == 201
    assert created.json() == {
        "id": 1,
        "title": "Buy oat milk",
        "done": False,
    }

    listed = client.get("/todos")

    assert listed.status_code == 200
    assert listed.json() == [
        {
            "id": 1,
            "title": "Buy oat milk",
            "done": False,
        },
    ]


def test_can_update_and_delete_todos(client: TestClient) -> None:
    created = client.post("/todos", json={"title": "Book train tickets"})
    todo_id = created.json()["id"]

    updated = client.patch(
        f"/todos/{todo_id}",
        json={"title": "Book train tickets home", "done": True},
    )

    assert updated.status_code == 200
    assert updated.json() == {
        "id": todo_id,
        "title": "Book train tickets home",
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
