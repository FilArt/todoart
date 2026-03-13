import os
from pathlib import Path

from app.__main__ import main


def test_cli_runs_uvicorn_with_expected_settings(
    monkeypatch,
    tmp_path: Path,
) -> None:
    db_path = tmp_path / "todoart.db"
    captured: dict[str, object] = {}

    def fake_run(app: str, host: str, port: int) -> None:
        captured["app"] = app
        captured["host"] = host
        captured["port"] = port
        captured["db_path"] = os.environ.get("TODOART_DB_PATH")

    monkeypatch.delenv("TODOART_DB_PATH", raising=False)
    monkeypatch.setattr("app.__main__.uvicorn.run", fake_run)

    exit_code = main(
        [
            "--host",
            "0.0.0.0",
            "--port",
            "9000",
            "--db-path",
            str(db_path),
        ],
    )

    assert exit_code == 0
    assert captured == {
        "app": "app.main:app",
        "host": "0.0.0.0",
        "port": 9000,
        "db_path": str(db_path),
    }
