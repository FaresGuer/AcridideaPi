from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
from dotenv import load_dotenv
import os
from urllib.parse import quote_plus

load_dotenv()

# Prefer DATABASE_URL (for Neon, cloud services) over individual env vars
DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    # Fallback: build from individual environment variables for local Postgres
    DB_HOST = os.getenv("DB_HOST", "localhost")
    DB_PORT = os.getenv("DB_PORT", "5432")
    DB_USER = os.getenv("DB_USER", "postgres")
    DB_PASSWORD = os.getenv("DB_PASSWORD", "")
    DB_NAME = os.getenv("DB_NAME", "locust_farm")
    
    encoded_user = quote_plus(DB_USER)
    encoded_password = quote_plus(DB_PASSWORD)
    DATABASE_URL = f"postgresql+psycopg://{encoded_user}:{encoded_password}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

# Create engine with connection pooling
engine = create_engine(
    DATABASE_URL,
    echo=False,  # Set to True for SQL debugging
    pool_pre_ping=True,
    connect_args={"connect_timeout": 10},
)

# Session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base class for models
Base = declarative_base()


def get_db():
    """Dependency for getting database session."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
