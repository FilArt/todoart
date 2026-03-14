from collections.abc import Iterator
from pathlib import Path
import sqlite3

import pytest
from fastapi.testclient import TestClient

from app.main import create_app


@pytest.fixture
def client(tmp_path: Path) -> Iterator[TestClient]:
    test_app = create_app(
        db_path=tmp_path / "todoart-test.db",
        releases_dir=tmp_path / "releases",
    )

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


def test_can_upload_fetch_and_download_android_release(client: TestClient) -> None:
    created = client.post(
        "/releases/android",
        data={
            "version": "1.2.0",
            "build_number": "12",
            "notes": "Improved update flow",
        },
        files={
            "apk": (
                "todoart.apk",
                b"fake-apk-binary",
                "application/vnd.android.package-archive",
            ),
        },
    )

    assert created.status_code == 201
    payload = created.json()
    assert payload["version"] == "1.2.0"
    assert payload["build_number"] == 12
    assert payload["notes"] == "Improved update flow"
    assert payload["download_url"].startswith("http://testserver/")
    filename = payload["download_url"].rsplit("/", 1)[-1]
    assert filename.endswith(".apk")

    latest = client.get("/releases/android/latest")

    assert latest.status_code == 200
    assert latest.json() == payload

    downloaded = client.get(f"/releases/android/download/{filename}")

    assert downloaded.status_code == 200
    assert downloaded.content == b"fake-apk-binary"
    assert (
        downloaded.headers["content-type"]
        == "application/vnd.android.package-archive"
    )


def test_latest_android_release_returns_highest_build_number(
    client: TestClient,
) -> None:
    client.post(
        "/releases/android",
        data={
            "version": "1.1.0",
            "build_number": "3",
        },
        files={"apk": ("v3.apk", b"v3", "application/vnd.android.package-archive")},
    )
    client.post(
        "/releases/android",
        data={
            "version": "1.2.0",
            "build_number": "4",
        },
        files={"apk": ("v4.apk", b"v4", "application/vnd.android.package-archive")},
    )

    latest = client.get("/releases/android/latest")

    assert latest.status_code == 200
    assert latest.json()["version"] == "1.2.0"
    assert latest.json()["build_number"] == 4


def test_upload_requires_matching_release_token_when_configured(
    monkeypatch: pytest.MonkeyPatch,
    tmp_path: Path,
) -> None:
    monkeypatch.setenv("TODOART_RELEASE_UPLOAD_TOKEN", "secret-token")
    test_app = create_app(
        db_path=tmp_path / "todoart-auth.db",
        releases_dir=tmp_path / "releases-auth",
    )

    with TestClient(test_app) as authed_client:
        missing = authed_client.post(
            "/releases/android",
            data={"version": "1.2.0", "build_number": "8"},
            files={
                "apk": (
                    "todoart.apk",
                    b"fake-apk-binary",
                    "application/vnd.android.package-archive",
                ),
            },
        )
        wrong = authed_client.post(
            "/releases/android",
            headers={"X-Release-Token": "wrong-token"},
            data={"version": "1.2.0", "build_number": "8"},
            files={
                "apk": (
                    "todoart.apk",
                    b"fake-apk-binary",
                    "application/vnd.android.package-archive",
                ),
            },
        )
        ok = authed_client.post(
            "/releases/android",
            headers={"X-Release-Token": "secret-token"},
            data={"version": "1.2.0", "build_number": "8"},
            files={
                "apk": (
                    "todoart.apk",
                    b"fake-apk-binary",
                    "application/vnd.android.package-archive",
                ),
            },
        )

    assert missing.status_code == 401
    assert wrong.status_code == 401
    assert ok.status_code == 201


def test_latest_android_release_returns_404_when_missing(
    client: TestClient,
) -> None:
    response = client.get("/releases/android/latest")

    assert response.status_code == 404
    assert response.json() == {"detail": "Android release not found."}
