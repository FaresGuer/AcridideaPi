import os
import sys

# Ensure backend directory is in path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy.orm import Session
from database import SessionLocal, engine, Base
from models import User, Container, ContainerData, container_workers
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def get_password_hash(password):
    return pwd_context.hash(password)

def seed_containers():
    db = SessionLocal()
    try:
        # Get Admin User (create if not exists)
        admin_email = "admin@locust.farm"
        admin = db.query(User).filter(User.email == admin_email).first()

        if not admin:
            print(f"User {admin_email} not found. Creating...")
            admin = User(
                email=admin_email,
                full_name="Admin User",
                hashed_password=get_password_hash("Admin123"),
                role="ADMIN",
                is_active=True,
                role_selected=True
            )
            db.add(admin)
            db.commit()
            db.refresh(admin)

        containers_to_create = [
            {
                "name": "Production",
                "lat": 36.8,
                "lng": 10.18,
                "temp": 29.0,
                "hum": 72.0,
                "status": "WARNING" # Logic handled in frontend
            },
            {
                "name": "Testing Subject",
                "lat": 36.81,
                "lng": 10.19,
                "temp": 36.0,
                "hum": 40.0,
                 "status": "CRITICAL" # Logic handled in frontend
            },
            {
                "name": "Growth Container",
                "lat": 36.82,
                "lng": 10.20,
                "temp": 24.0,
                "hum": 55.0,
                 "status": "ACTIVE" # Logic handled in frontend
            },
            # Add some dummy containers to fill up
            {
                 "name": "Lab Unit A",
                 "lat": 36.83,
                 "lng": 10.21,
                 "temp": 25.0,
                 "hum": 60.0,
                 "status": "ACTIVE"
            },
             {
                 "name": "Quarantine Zone",
                 "lat": 36.84,
                 "lng": 10.22,
                 "temp": 26.0,
                 "hum": 62.0,
                 "status": "ACTIVE"
            },
             {
                 "name": "Storage B",
                 "lat": 36.85,
                 "lng": 10.23,
                 "temp": 22.0,
                 "hum": 50.0,
                 "status": "ACTIVE"
            },
             {
                 "name": "Nursery 01",
                 "lat": 36.86,
                 "lng": 10.24,
                 "temp": 28.0,
                 "hum": 65.0,
                 "status": "ACTIVE"
            }
        ]

        print("Seeding containers...")

        for c_info in containers_to_create:
            # Check if exists
            existing = db.query(Container).filter(Container.name == c_info["name"]).first()
            if existing:
                print(f"Updating existing container: {c_info['name']}")
                container = existing
                container.latitude = c_info["lat"]
                container.longitude = c_info["lng"]
            else:
                print(f"Creating container: {c_info['name']}")
                container = Container(
                    name=c_info["name"],
                    created_by=admin.id,
                    latitude=c_info["lat"],
                    longitude=c_info["lng"]
                )
                db.add(container)
                db.commit() # Commit to generate ID
                db.refresh(container)

            # Check/Create ContainerData
            data = db.query(ContainerData).filter(ContainerData.container_id == container.id).first()
            if not data:
                data = ContainerData(
                    container_id=container.id,
                    target_temperature=25.0,
                    target_humidity=60.0,
                    target_light_level=75.0
                )
                db.add(data)

            # Update data values
            data.temperature = c_info["temp"]
            data.humidity = c_info["hum"]

            db.commit()

        print("Seeding complete!")

    except Exception as e:
        print(f"Error seeding DB: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_containers()

