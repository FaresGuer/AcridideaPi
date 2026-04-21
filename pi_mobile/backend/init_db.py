"""
Initialize the database and create tables.
Run this script before starting the application for the first time.
"""
import sys
from dotenv import load_dotenv
import os

load_dotenv()

from database import Base, engine


def create_tables():
    """Create ORM tables in the configured database."""
    try:
        # For managed databases (Neon, etc.), the database already exists.
        # For local Postgres, use createdb separately or create schema here.
        Base.metadata.create_all(bind=engine)
        print("✓ Database tables created successfully")
        print("\nNext steps:")
        print("1. Run: python create_demo_user.py (optional, to create demo users)")
        print("2. Run: uvicorn main:app --reload (to start the API server)")
        
    except Exception as e:
        print(f"✗ Error creating tables: {e}")
        sys.exit(1)


if __name__ == "__main__":
    database_url = os.getenv("DATABASE_URL")
    if database_url:
        print("Connecting using DATABASE_URL (Neon or cloud service)...")
    else:
        db_host = os.getenv("DB_HOST", "localhost")
        db_name = os.getenv("DB_NAME", "locust_farm")
        print(f"Connecting to PostgreSQL at {db_host}...")
        print(f"Database: {db_name}")
    create_tables()
