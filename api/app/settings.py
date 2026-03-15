from functools import lru_cache
from typing import Annotated, TypeAlias
from fastapi import Depends
from pydantic_settings import BaseSettings

from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


class DefaultSettings(BaseSettings):
    todoart_db_path: Path = ROOT / "todoart.db"
    todoart_releases_dir: Path = ROOT / "releases"
    todoart_release_upload_token: str

    @property
    def db_path(self) -> Path:
        return self.todoart_db_path

    @property
    def releases_dir(self) -> Path:
        return self.todoart_releases_dir

    @property
    def release_upload_token(self) -> str:
        return self.todoart_release_upload_token


@lru_cache(maxsize=1)
def get_settings() -> DefaultSettings:
    return DefaultSettings()


Settings: TypeAlias = Annotated[DefaultSettings, Depends(get_settings)]
