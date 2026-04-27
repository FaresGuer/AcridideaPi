from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
from dotenv import load_dotenv
import os
from importlib.util import find_spec
from urllib.parse import quote_plus

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")


def _resolve_postgres_driver(database_url: str | None) -> tuple[str, str]:
    has_psycopg = find_spec("psycopg") is not None
    has_psycopg2 = find_spec("psycopg2") is not None

    if not has_psycopg and not has_psycopg2:
        raise RuntimeError(
            "No PostgreSQL driver installed. Install one with: pip install 'psycopg[binary]'"
        )

    preferred_driver = "psycopg" if has_psycopg else "psycopg2"

    if database_url and database_url.startswith("postgresql+"):
        if "+psycopg://" in database_url and not has_psycopg and has_psycopg2:
            database_url = database_url.replace("+psycopg://", "+psycopg2://", 1)
        elif "+psycopg2://" in database_url and not has_psycopg2 and has_psycopg:
            database_url = database_url.replace("+psycopg2://", "+psycopg://", 1)

    return preferred_driver, database_url


DB_DRIVER, DATABASE_URL = _resolve_postgres_driver(DATABASE_URL)

if not DATABASE_URL:
    DB_HOST = os.getenv("DB_HOST", "localhost")
    DB_PORT = os.getenv("DB_PORT", "5432")
    DB_USER = os.getenv("DB_USER", "postgres")
    DB_PASSWORD = os.getenv("DB_PASSWORD", "")
    DB_NAME = os.getenv("DB_NAME", "locust_farm")

    encoded_user = quote_plus(DB_USER)
    encoded_password = quote_plus(DB_PASSWORD)
    DATABASE_URL = (
        f"postgresql+{DB_DRIVER}://{encoded_user}:{encoded_password}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    )

engine = create_engine(
    DATABASE_URL,
    echo=False,
    pool_pre_ping=True,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
