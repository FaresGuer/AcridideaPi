from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, Float, DateTime, Table
from sqlalchemy.orm import relationship
from database import Base
from datetime import datetime


# Association table for container workers (many-to-many)
container_workers = Table(
    'container_workers',
    Base.metadata,
    Column('container_id', Integer, ForeignKey('containers.id'), primary_key=True),
    Column('worker_id', Integer, ForeignKey('users.id'), primary_key=True)
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
    
    # Relationships
    created_containers = relationship("Container", back_populates="creator", foreign_keys="Container.created_by")
    assigned_containers = relationship("Container", secondary=container_workers, back_populates="workers")
    sent_worker_invitations = relationship(
        "WorkerInvitation",
        back_populates="admin",
        foreign_keys="WorkerInvitation.admin_id"
    )
    received_worker_invitations = relationship(
        "WorkerInvitation",
        back_populates="worker",
        foreign_keys="WorkerInvitation.worker_id"
    )

    def __repr__(self):
        return f"<User(id={self.id}, email={self.email}, role={self.role})>"


class Container(Base):
    __tablename__ = "containers"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    created_by = Column(Integer, ForeignKey('users.id'), nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    creator = relationship("User", back_populates="created_containers", foreign_keys=[created_by])
    workers = relationship("User", secondary=container_workers, back_populates="assigned_containers")

    def __repr__(self):
        return f"<Container(id={self.id}, name={self.name}, created_by={self.created_by})>"


class WorkerInvitation(Base):
    __tablename__ = "worker_invitations"

    id = Column(Integer, primary_key=True, index=True)
    admin_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    worker_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    status = Column(String(20), default="PENDING", nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    responded_at = Column(DateTime, nullable=True)

    admin = relationship("User", back_populates="sent_worker_invitations", foreign_keys=[admin_id])
    worker = relationship("User", back_populates="received_worker_invitations", foreign_keys=[worker_id])

    def __repr__(self):
        return f"<WorkerInvitation(id={self.id}, admin_id={self.admin_id}, worker_id={self.worker_id}, status={self.status})>"
