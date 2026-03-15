from pathlib import Path
from app.settings import DefaultSettings
import os


def test_env_loaded_to_settings():
    db_path = "ddd"
    releases_dir = "rrr"
    os.environ.update(
        dict(
            TODOART_DB_PATH=db_path,
            TODOART_RELEASES_DIR=releases_dir,
        )
    )
    settings = DefaultSettings()

    assert settings.db_path == Path(db_path)
    assert settings.releases_dir == Path(releases_dir)
