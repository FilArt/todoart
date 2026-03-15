from functools import lru_cache
from typing import Annotated, TypeAlias
from fastapi import Depends
from pydantic_settings import BaseSettings

from pathlib import Path


class DefaultSettings(BaseSettings):
    todoart_db_path: Path = Path(__file__).resolve().parent.parent / "todoart.db"
    todoart_releases_dir: Path = Path(__file__).resolve().parent.parent / "releases"

    @property
    def db_path(self) -> Path:
        return self.todoart_db_path

    @property
    def releases_dir(self) -> Path:
        return self.todoart_releases_dir


@lru_cache(maxsize=1)
def get_settings():
    return DefaultSettings()


Settings: TypeAlias = Annotated[DefaultSettings, Depends(get_settings)]
