from pathlib import Path

import pytest
from pydantic import ValidationError

from app.settings import DefaultSettings


def test_env_loaded_to_settings(monkeypatch: pytest.MonkeyPatch):
    db_path = "ddd"
    releases_dir = "rrr"
    release_upload_token = "secret-token"
    monkeypatch.setenv("TODOART_DB_PATH", db_path)
    monkeypatch.setenv("TODOART_RELEASES_DIR", releases_dir)
    monkeypatch.setenv(
        "TODOART_RELEASE_UPLOAD_TOKEN",
        release_upload_token,
    )
    settings = DefaultSettings()

    assert settings.db_path == Path(db_path)
    assert settings.releases_dir == Path(releases_dir)
    assert settings.release_upload_token == release_upload_token


def test_release_upload_token_is_required(monkeypatch: pytest.MonkeyPatch):
    monkeypatch.delenv("TODOART_RELEASE_UPLOAD_TOKEN", raising=False)

    with pytest.raises(ValidationError):
        DefaultSettings()
