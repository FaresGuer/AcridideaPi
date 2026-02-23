"""
Create demo users in the database.
Run this script after initializing the database.
Demo credentials:
  ADMIN: admin@locust.farm / Admin123
  FARMER: farmer@locust.farm / Farmer123
"""
import sys
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
    """Create demo users if they don't already exist."""
    db: Session = SessionLocal()
    
    try:
        for user_data in DEMO_USERS:
            # Check if user already exists
            existing_user = db.query(User).filter(User.email == user_data["email"]).first()
            
            if existing_user:
                print(f"✓ User '{user_data['email']}' already exists")
                continue
            
            # Create new user
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
            
            print(f"✓ Created demo user: {user_data['email']} ({user_data['role']})")
        
        print("\nDemo users created successfully!")
        print("\nTestable credentials:")
        for user in DEMO_USERS:
            print(f"  Email: {user['email']}, Password: {user['password']}")
        
    except Exception as e:
        print(f"✗ Error creating demo users: {e}")
        db.rollback()
        sys.exit(1)
    finally:
        db.close()


if __name__ == "__main__":
    print("Creating demo users...")
    create_demo_users()
