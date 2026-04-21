from sqlalchemy.orm import Session
from dotenv import load_dotenv

load_dotenv()

from database import SessionLocal
from models import User
from auth import hash_password

DEMO_USERS = [
    {
        "email": "admin@locust.farm",
        "full_name": "Admin User",
        "password": "Admin123",
        "role": "ADMIN",
    },
    {
        "email": "farmer@locust.farm",
        "full_name": "Farmer User",
        "password": "Farmer123",
        "role": "FARMER",
    },
]


def create_demo_users():
    db: Session = SessionLocal()
    try:
        for user_data in DEMO_USERS:
            existing_user = db.query(User).filter(User.email == user_data["email"]).first()
            if existing_user:
                print(f"User '{user_data['email']}' already exists")
                continue

            new_user = User(
                email=user_data["email"],
                full_name=user_data["full_name"],
                hashed_password=hash_password(user_data["password"]),
                role=user_data["role"],
                is_active=True,
            )
            db.add(new_user)
            db.commit()
            db.refresh(new_user)
            print(f"Created demo user: {user_data['email']} ({user_data['role']})")

        print("Demo users created successfully")
    except Exception as e:
        print(f"Error creating demo users: {e}")
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    create_demo_users()
