from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=False,
    )

    db_host: str = ""
    db_port: int = 5432
    db_name: str = ""
    db_user: str = ""
    db_password: str = ""

    @property
    def database_is_configured(self) -> bool:
        return all((self.db_host, self.db_name, self.db_user, self.db_password))


@lru_cache
def get_settings() -> Settings:
    return Settings()
