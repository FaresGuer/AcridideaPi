from sqlalchemy.orm import Session
from datetime import datetime
from models import User, Container, ContainerData, ContainerSensorHistory
from schemas import UserCreate, UserUpdate, ContainerCreate, ContainerUpdate, ContainerDataUpdate
from auth import hash_password


def get_user_by_email(db: Session, email: str):
    return db.query(User).filter(User.email == email).first()


def get_user_by_id(db: Session, user_id: int):
    return db.query(User).filter(User.id == user_id).first()


def create_user(db: Session, user: UserCreate):
    if get_user_by_email(db, user.email):
        return None

    db_user = User(
        email=user.email,
        full_name=user.full_name,
        hashed_password=hash_password(user.password),
        role=user.role,
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


def update_user(db: Session, user_id: int, user_update: UserUpdate):
    db_user = get_user_by_id(db, user_id)
    if not db_user:
        return None

    if user_update.email is not None:
        db_user.email = user_update.email
    if user_update.full_name is not None:
        db_user.full_name = user_update.full_name
    if user_update.role is not None:
        db_user.role = user_update.role
    if user_update.is_active is not None:
        db_user.is_active = user_update.is_active
    if user_update.role_selected is not None:
        db_user.role_selected = user_update.role_selected
    if user_update.two_factor_enabled is not None:
        db_user.two_factor_enabled = user_update.two_factor_enabled

    db.commit()
    db.refresh(db_user)
    return db_user


def create_container(db: Session, container: ContainerCreate, created_by: int):
    db_container = Container(
        name=container.name,
        latitude=container.latitude,
        longitude=container.longitude,
        created_by=created_by,
    )
    db.add(db_container)
    db.flush()

    db_container_data = ContainerData(
        container_id=db_container.id,
        temperature=None,
        humidity=None,
        light_level=None,
        gas_level=None,
        heater_status=False,
        fan_status=False,
        light_status=False,
        humidifier_status=False,
        target_temperature=25.0,
        target_temperature_min=20.0,
        target_humidity=60.0,
        target_humidity_min=40.0,
        target_light_level=75.0,
        target_light_level_min=30.0,
        target_gas_level=1500.0,
        target_gas_level_min=1000.0,
    )
    db.add(db_container_data)
    db.commit()
    db.refresh(db_container)
    return db_container


def get_container_by_id(db: Session, container_id: int):
    return db.query(Container).filter(Container.id == container_id).first()


def get_containers_by_admin(db: Session, admin_id: int):
    return db.query(Container).filter(Container.created_by == admin_id).all()


def update_container(db: Session, container_id: int, container_update: ContainerUpdate):
    db_container = get_container_by_id(db, container_id)
    if not db_container:
        return None

    if container_update.name is not None:
        db_container.name = container_update.name
    if container_update.latitude is not None:
        db_container.latitude = container_update.latitude
    if container_update.longitude is not None:
        db_container.longitude = container_update.longitude

    db.commit()
    db.refresh(db_container)
    return db_container


def get_container_data(db: Session, container_id: int):
    return db.query(ContainerData).filter(ContainerData.container_id == container_id).first()


def append_container_sensor_history(
    db: Session,
    container_id: int,
    sensor_type: str,
    value: float,
    recorded_at: datetime | None = None,
):
    history_row = ContainerSensorHistory(
        container_id=container_id,
        sensor_type=sensor_type,
        value=value,
        recorded_at=recorded_at or datetime.utcnow(),
    )
    db.add(history_row)
    return history_row


def update_container_data(db: Session, container_id: int, data_update: ContainerDataUpdate):
    db_data = get_container_data(db, container_id)
    if not db_data:
        db_data = ContainerData(container_id=container_id)
        db.add(db_data)

    if data_update.temperature is not None:
        db_data.temperature = data_update.temperature
        append_container_sensor_history(db, container_id, "temperature", data_update.temperature)
    if data_update.humidity is not None:
        db_data.humidity = data_update.humidity
        append_container_sensor_history(db, container_id, "humidity", data_update.humidity)
    if data_update.light_level is not None:
        db_data.light_level = data_update.light_level
        append_container_sensor_history(db, container_id, "light_level", data_update.light_level)
    if data_update.gas_level is not None:
        db_data.gas_level = data_update.gas_level
        append_container_sensor_history(db, container_id, "gas_level", data_update.gas_level)
    if data_update.heater_status is not None:
        db_data.heater_status = data_update.heater_status
    if data_update.fan_status is not None:
        db_data.fan_status = data_update.fan_status
    if data_update.light_status is not None:
        db_data.light_status = data_update.light_status
    if data_update.humidifier_status is not None:
        db_data.humidifier_status = data_update.humidifier_status
    if data_update.target_temperature is not None:
        db_data.target_temperature = data_update.target_temperature
    if data_update.target_temperature_min is not None:
        db_data.target_temperature_min = data_update.target_temperature_min
    if data_update.target_humidity is not None:
        db_data.target_humidity = data_update.target_humidity
    if data_update.target_humidity_min is not None:
        db_data.target_humidity_min = data_update.target_humidity_min
    if data_update.target_light_level is not None:
        db_data.target_light_level = data_update.target_light_level
    if data_update.target_light_level_min is not None:
        db_data.target_light_level_min = data_update.target_light_level_min
    if data_update.target_gas_level is not None:
        db_data.target_gas_level = data_update.target_gas_level
    if data_update.target_gas_level_min is not None:
        db_data.target_gas_level_min = data_update.target_gas_level_min

    db.commit()
    db.refresh(db_data)
    return db_data
