from collections.abc import Generator
from functools import lru_cache

from fastapi import HTTPException, status
from sqlalchemy import URL, Engine, create_engine
from sqlalchemy.orm import Session

from app.core.config import get_settings


@lru_cache
def get_engine() -> Engine:
    settings = get_settings()
    if not settings.database_is_configured:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="La conexión a la base de datos no está configurada.",
        )

    database_url = URL.create(
        drivername="postgresql+psycopg",
        username=settings.db_user,
        password=settings.db_password,
        host=settings.db_host,
        port=settings.db_port,
        database=settings.db_name,
    )
    return create_engine(database_url, pool_pre_ping=True)


def get_db() -> Generator[Session, None, None]:
    with Session(get_engine()) as session:
        yield session
