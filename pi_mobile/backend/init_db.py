"""
Initialize the database and create tables.
Run this script before starting the application for the first time.
"""
import pymysql
import sys
from dotenv import load_dotenv
import os

load_dotenv()

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_USER = os.getenv("DB_USER", "root")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")
DB_NAME = os.getenv("DB_NAME", "locust_farm")


def create_database():
    """Create the database if it doesn't exist."""
    try:
        # Connect to MySQL without specifying a database
        connection = pymysql.connect(
            host=DB_HOST,
            user=DB_USER,
            password=DB_PASSWORD if DB_PASSWORD else None,
            charset="utf8mb4",
            cursorclass=pymysql.cursors.DictCursor,
        )
        
        cursor = connection.cursor()
        
        # Create database if it doesn't exist
        cursor.execute(f"CREATE DATABASE IF NOT EXISTS {DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci")
        print(f"✓ Database '{DB_NAME}' created or already exists")
        
        cursor.close()
        connection.close()
        
        # Now create tables using SQLAlchemy
        from database import Base, engine
        
        Base.metadata.create_all(bind=engine)
        print("✓ Database tables created successfully")
        print("\nNext steps:")
        print("1. Run: python create_demo_user.py (optional, to create demo users)")
        print("2. Run: uvicorn main:app --reload (to start the API server)")
        
    except pymysql.MySQLError as e:
        print(f"✗ MySQL Error: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"✗ Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    print(f"Connecting to MySQL at {DB_HOST}...")
    print(f"Database: {DB_NAME}")
    create_database()
