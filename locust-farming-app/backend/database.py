from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
from dotenv import load_dotenv
import os
from urllib.parse import quote_plus

load_dotenv()

# MySQL Configuration (Primary Database Only)
MYSQL_HOST = os.getenv("MYSQL_HOST", "localhost")
MYSQL_PORT = os.getenv("MYSQL_PORT", "3306")
MYSQL_USER = os.getenv("MYSQL_USER", "root")
MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD", "")
MYSQL_DB = os.getenv("MYSQL_DB", "locust_farm")

encoded_user = quote_plus(MYSQL_USER)
encoded_password = quote_plus(MYSQL_PASSWORD) if MYSQL_PASSWORD else ""

PRIMARY_DATABASE_URL = f"mysql+pymysql://{encoded_user}:{encoded_password}@{MYSQL_HOST}:{MYSQL_PORT}/{MYSQL_DB}"

print(f"[DB] Primary DB URL: {PRIMARY_DATABASE_URL}")

primary_engine = create_engine(PRIMARY_DATABASE_URL, echo=False, pool_pre_ping=True)
SessionLocalPrimary = sessionmaker(autocommit=False, autoflush=False, bind=primary_engine)

Base = declarative_base()


def get_db():
    db = SessionLocalPrimary()
    try:
        yield db
    finally:
        db.close()
