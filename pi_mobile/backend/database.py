from sqlalchemy import create_engine, text
from sqlalchemy.orm import declarative_base, sessionmaker
from dotenv import load_dotenv
import os
from urllib.parse import quote_plus
import mysql.connector
from mysql.connector import Error as MySQLError

load_dotenv()

# Local MySQL configuration (for mobile app fast reads / gateway local DB)
MYSQL_HOST = os.getenv("DB_HOST", "127.0.0.1")
MYSQL_PORT = int(os.getenv("DB_PORT", "3306"))
MYSQL_USER = os.getenv("DB_USER", "root")
MYSQL_PASSWORD = os.getenv("DB_PASSWORD", "")
MYSQL_DB = os.getenv("DB_NAME", "locust_farm")
MYSQL_CONFIG = {
    "host": MYSQL_HOST,
    "port": MYSQL_PORT,
    "user": MYSQL_USER,
    "password": MYSQL_PASSWORD,
    "database": MYSQL_DB,
}

# Primary: MySQL (local, fast)
DATABASE_URL = f"mysql+mysqlconnector://{quote_plus(MYSQL_USER)}:{quote_plus(MYSQL_PASSWORD)}@{MYSQL_HOST}:{MYSQL_PORT}/{MYSQL_DB}"

# Secondary: Neon Postgres (cloud, for mirroring)
NEON_DATABASE_URL = os.getenv("DATABASE_URL")

if not NEON_DATABASE_URL:
    # Fallback: build Neon URL from env vars if not set
    DB_HOST_NEON = os.getenv("DB_HOST_NEON", "localhost")
    DB_PORT_NEON = os.getenv("DB_PORT_NEON", "5432")
    DB_USER_NEON = os.getenv("DB_USER_NEON", "postgres")
    DB_PASSWORD_NEON = os.getenv("DB_PASSWORD_NEON", "")
    DB_NAME_NEON = os.getenv("DB_NAME_NEON", "locust_farm")
    
    encoded_user_neon = quote_plus(DB_USER_NEON)
    encoded_password_neon = quote_plus(DB_PASSWORD_NEON)
    NEON_DATABASE_URL = f"postgresql+psycopg://{encoded_user_neon}:{encoded_password_neon}@{DB_HOST_NEON}:{DB_PORT_NEON}/{DB_NAME_NEON}"

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


def get_mysql_connection():
    """Get a MySQL connection. Returns None if connection fails."""
    try:
        conn = mysql.connector.connect(**MYSQL_CONFIG)
        return conn
    except MySQLError as e:
        print(f"[MySQL] Connection failed: {e}")
        return None


def mirror_to_mysql(query: str, values: tuple = ()) -> bool:
    """Execute an INSERT/UPDATE query on Neon Postgres as a mirror (best-effort). Returns True if successful."""
    try:
        # Create a separate engine for Neon mirroring
        neon_engine = create_engine(
            NEON_DATABASE_URL,
            echo=False,
            pool_pre_ping=True,
            connect_args={"connect_timeout": 10},
        )
        connection = neon_engine.connect()
        try:
            cursor = connection.connection.cursor()
            cursor.execute(query, values)
            connection.connection.commit()
            cursor.close()
        finally:
            connection.close()
        return True
    except Exception as e:
        print(f"[Neon] Mirror write failed: {e}")
        return False
