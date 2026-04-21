"""
Script to generate historical sensor data (mock API endpoint for testing).
This simulates a time series of sensor readings.
"""
import random
from datetime import datetime, timedelta
from dotenv import load_dotenv

load_dotenv()

from database import SessionLocal
from models import Container


def generate_sensor_history(container_id: int, hours: int = 24) -> list:
    """
    Generate realistic sensor history data for the last N hours.

    Returns a list of dicts with timestamp, temperature, humidity, light_level.
    """
    db = SessionLocal()
    history = []
    now = datetime.utcnow()

    try:
        container = db.query(Container).filter(Container.id == container_id).first()
        if not container:
            return []

        # Generate hourly data for the past N hours
        for i in range(hours, 0, -1):
            timestamp = now - timedelta(hours=i)

            # Realistic sensor patterns
            base_temp = 24
            temp_variation = random.gauss(0, 2)  # Gaussian noise
            temperature = round(base_temp + temp_variation, 1)

            base_humidity = 65
            hum_variation = random.gauss(0, 5)
            humidity = max(20, min(100, round(base_humidity + hum_variation, 1)))

            # Light follows day/night cycle
            hour = timestamp.hour
            if 6 <= hour <= 18:  # Day time: 600-900 Lux
                light_level = round(600 + random.uniform(-100, 300), 1)
            else:  # Night time: 0-50 Lux
                light_level = round(random.uniform(0, 50), 1)

            history.append({
                'timestamp': timestamp.isoformat() + 'Z',
                'temperature': temperature,
                'humidity': humidity,
                'light_level': light_level,
            })

        return history
    finally:
        db.close()


def print_sample_history():
    """Print sample historical data."""
    history = generate_sensor_history(1, hours=24)
    print(f"Generated {len(history)} hours of sensor history:")
    for i, record in enumerate(history[-6:]):  # Show last 6 hours
        print(f"  {record['timestamp']}: T={record['temperature']}°C, H={record['humidity']}%, L={record['light_level']} Lux")


if __name__ == "__main__":
    print_sample_history()

