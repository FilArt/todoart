from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_root_returns_status_message() -> None:
    response = client.get("/")

    assert response.status_code == 200
    assert response.json() == {
        "message": "TodoArt API is running",
        "status": "ok",
    }


def test_healthcheck_returns_ok() -> None:
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
