from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
from dotenv import load_dotenv
import os
from urllib.parse import quote_plus
import mysql.connector
from mysql.connector import Error as MySQLError

load_dotenv()

# MySQL configuration (only database)
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

# SQLAlchemy engine pointing to MySQL only
DATABASE_URL = f"mysql+mysqlconnector://{quote_plus(MYSQL_USER)}:{quote_plus(MYSQL_PASSWORD)}@{MYSQL_HOST}:{MYSQL_PORT}/{MYSQL_DB}"

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
