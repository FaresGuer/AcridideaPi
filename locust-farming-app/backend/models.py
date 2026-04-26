from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, Float, DateTime, Table
from sqlalchemy.orm import relationship
from database import Base
from datetime import datetime


container_workers = Table(
    "container_workers",
    Base.metadata,
    Column("container_id", Integer, ForeignKey("containers.id"), primary_key=True),
    Column("worker_id", Integer, ForeignKey("users.id"), primary_key=True),
)


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    full_name = Column(String(255), nullable=False)
    hashed_password = Column(String(255), nullable=False)
    role = Column(String(50), default="FARMER", nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    role_selected = Column(Boolean, default=False, nullable=False)
    two_factor_enabled = Column(Boolean, default=False, nullable=False)

    created_containers = relationship("Container", back_populates="creator", foreign_keys="Container.created_by")
    assigned_containers = relationship("Container", secondary=container_workers, back_populates="workers")


class Container(Base):
    __tablename__ = "containers"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    created_by = Column(Integer, ForeignKey("users.id"), nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    creator = relationship("User", back_populates="created_containers", foreign_keys=[created_by])
    workers = relationship("User", secondary=container_workers, back_populates="assigned_containers")
    data = relationship("ContainerData", back_populates="container", uselist=False, cascade="all, delete-orphan")
    feeding_schedules = relationship("FeedingSchedule", back_populates="container", cascade="all, delete-orphan")
    sensor_history = relationship("ContainerSensorHistory", back_populates="container", cascade="all, delete-orphan")


class ContainerData(Base):
    __tablename__ = "container_data"

    id = Column(Integer, primary_key=True, index=True)
    container_id = Column(Integer, ForeignKey("containers.id"), unique=True, nullable=False)

    temperature = Column(Float, nullable=True)
    humidity = Column(Float, nullable=True)
    light_level = Column(Float, nullable=True)
    gas_level = Column(Float, nullable=True)

    heater_status = Column(Boolean, default=False, nullable=False)
    fan_status = Column(Boolean, default=False, nullable=False)
    light_status = Column(Boolean, default=False, nullable=False)
    humidifier_status = Column(Boolean, default=False, nullable=False)

    target_temperature = Column(Float, nullable=True)
    target_humidity = Column(Float, nullable=True)
    target_light_level = Column(Float, nullable=True)
    target_gas_level = Column(Float, nullable=True)
    target_gas_level_min = Column(Float, nullable=True)

    last_updated = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    container = relationship("Container", back_populates="data")


class FeedingSchedule(Base):
    __tablename__ = "feeding_schedules"

    id = Column(Integer, primary_key=True, index=True)
    container_id = Column(Integer, ForeignKey("containers.id"), nullable=False, index=True)
    feeding_at = Column(DateTime, nullable=False, index=True)
    amount = Column(Float, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    container = relationship("Container", back_populates="feeding_schedules")


class ContainerSensorHistory(Base):
    __tablename__ = "container_sensor_history"

    id = Column(Integer, primary_key=True, index=True)
    container_id = Column(Integer, ForeignKey("containers.id"), nullable=False, index=True)
    sensor_type = Column(String(50), nullable=False)
    value = Column(Float, nullable=False)
    recorded_at = Column(DateTime, nullable=False, index=True)

    container = relationship("Container", back_populates="sensor_history")
