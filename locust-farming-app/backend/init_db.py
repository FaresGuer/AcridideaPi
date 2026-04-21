import sys
from dotenv import load_dotenv
import os

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_USER = os.getenv("DB_USER", "root")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")
DB_NAME = os.getenv("DB_NAME", "locust_farm")


def create_database():
    if DATABASE_URL:
        from database import Base, engine

        Base.metadata.create_all(bind=engine)
        print("Database tables created successfully")
        return

    import pymysql

    try:
        connection = pymysql.connect(
            host=DB_HOST,
            user=DB_USER,
            password=DB_PASSWORD if DB_PASSWORD else None,
            charset="utf8mb4",
            cursorclass=pymysql.cursors.DictCursor,
        )

        cursor = connection.cursor()
        cursor.execute(
            f"CREATE DATABASE IF NOT EXISTS {DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
        )
        print(f"Database '{DB_NAME}' created or already exists")

        cursor.close()
        connection.close()

        from database import Base, engine

        Base.metadata.create_all(bind=engine)
        print("Database tables created successfully")
    except pymysql.MySQLError as e:
        print(f"MySQL Error: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    if DATABASE_URL:
        print("Connecting using DATABASE_URL...")
    else:
        print(f"Connecting to MySQL at {DB_HOST}...")
        print(f"Database: {DB_NAME}")
    create_database()
