import os

import pytest

from app.settings import get_settings

os.environ.setdefault("TODOART_RELEASE_UPLOAD_TOKEN", "test-suite-import-token")


@pytest.fixture(autouse=True)
def clear_settings_cache() -> None:
    get_settings.cache_clear()
    yield
    get_settings.cache_clear()
