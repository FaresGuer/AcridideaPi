"""
Script to seed realistic sensor data into the database.
This populates container_data with values so charts display properly.
"""
import random
from datetime import datetime, timedelta
from dotenv import load_dotenv

load_dotenv()

from database import SessionLocal
from models import Container, ContainerData
from crud import get_container_data, update_container_data
from schemas import ContainerDataUpdate

def seed_container_data():
    """Populate sensor data for all containers with realistic values."""
    db = SessionLocal()

    try:
        containers = db.query(Container).all()

        if not containers:
            print("No containers found. Create a container first.")
            return

        now = datetime.utcnow()

        for container in containers:
            print(f"Seeding data for container: {container.name} (ID: {container.id})")

            # Generate realistic sensor values
            temperature = round(20 + random.uniform(-5, 15), 1)  # 15-35°C
            humidity = round(50 + random.uniform(-30, 50), 1)    # 20-100%
            light_level = round(random.uniform(200, 1000), 1)    # 200-1000 lux

            # Update container data
            update = ContainerDataUpdate(
                temperature=temperature,
                humidity=humidity,
                light_level=light_level,
                heater_status=temperature < 22,
                fan_status=temperature > 28,
                light_status=light_level > 500,
                humidifier_status=humidity < 60,
                target_temperature=25.0,
                target_humidity=65.0,
                target_light_level=750.0,
            )

            updated = update_container_data(db, container.id, update)

            if updated:
                print(f"  ✓ Temperature: {temperature}°C")
                print(f"  ✓ Humidity: {humidity}%")
                print(f"  ✓ Light Level: {light_level} Lux")
            else:
                print(f"  ✗ Failed to update container {container.id}")

        print("\n✓ Sensor data seeded successfully!")

    except Exception as e:
        print(f"✗ Error seeding data: {e}")
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    print("Seeding sensor data into database...")
    seed_container_data()

