import sys
from dotenv import load_dotenv
import os

load_dotenv()

DB_HOST = os.getenv("MYSQL_HOST", "localhost")
DB_PORT = os.getenv("MYSQL_PORT", "3306")
DB_USER = os.getenv("MYSQL_USER", "root")
DB_PASSWORD = os.getenv("MYSQL_PASSWORD", "")
DB_NAME = os.getenv("MYSQL_DB", "locust_farm")


def create_database():
    import pymysql

    try:
        connection = pymysql.connect(
            host=DB_HOST,
            port=int(DB_PORT),
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

        from database import Base, primary_engine

        Base.metadata.create_all(bind=primary_engine)
        print("Database tables created successfully")
    except pymysql.MySQLError as e:
        print(f"MySQL Error: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    print(f"Connecting to MySQL at {DB_HOST}:{DB_PORT}...")
    print(f"Database: {DB_NAME}")
    create_database()
