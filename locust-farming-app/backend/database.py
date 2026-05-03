from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
from dotenv import load_dotenv
import os
from importlib.util import find_spec
from urllib.parse import quote_plus

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")


def _try_mysql_connection() -> str | None:
    """Try to build MySQL connection URL from environment variables. Return URL or None if not configured."""
    mysql_host = os.getenv("MYSQL_HOST")
    mysql_port = os.getenv("MYSQL_PORT", "3306")
    mysql_user = os.getenv("MYSQL_USER")
    mysql_password = os.getenv("MYSQL_PASSWORD")
    mysql_db = os.getenv("MYSQL_DB", "locust_farm")

    # Check if MySQL is configured
    if not (mysql_host and mysql_user):
        return None

    has_pymysql = find_spec("pymysql") is not None
    if not has_pymysql:
        print("[DB] PyMySQL not installed, skipping MySQL")
        return None

    encoded_user = quote_plus(mysql_user)
    encoded_password = quote_plus(mysql_password) if mysql_password else ""
    
    url = f"mysql+pymysql://{encoded_user}:{encoded_password}@{mysql_host}:{mysql_port}/{mysql_db}"
    print(f"[DB] Attempting MySQL connection: {mysql_host}:{mysql_port}/{mysql_db}")
    return url


def _resolve_postgres_driver(database_url: str | None) -> tuple[str, str]:
    """Resolve PostgreSQL driver preference."""
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


def _resolve_database_url() -> str:
    """Resolve database URL: try MySQL first, fall back to Neon PostgreSQL."""
    # Try MySQL first (primary)
    mysql_url = _try_mysql_connection()
    if mysql_url:
        return mysql_url

    # Fall back to environment or Neon PostgreSQL (secondary)
    db_url = os.getenv("DATABASE_URL")
    if db_url:
        db_driver, db_url = _resolve_postgres_driver(db_url)
        return db_url

    # Construct from individual env vars (PostgreSQL fallback)
    db_host = os.getenv("DB_HOST", "localhost")
    db_port = os.getenv("DB_PORT", "5432")
    db_user = os.getenv("DB_USER", "postgres")
    db_password = os.getenv("DB_PASSWORD", "")
    db_name = os.getenv("DB_NAME", "locust_farm")

    encoded_user = quote_plus(db_user)
    encoded_password = quote_plus(db_password)
    db_driver, _ = _resolve_postgres_driver(None)
    
    url = f"postgresql+{db_driver}://{encoded_user}:{encoded_password}@{db_host}:{db_port}/{db_name}"
    print(f"[DB] Using PostgreSQL fallback: {db_host}:{db_port}/{db_name}")
    return url


DATABASE_URL = _resolve_database_url()

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
