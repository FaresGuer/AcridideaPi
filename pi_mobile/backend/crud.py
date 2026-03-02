from sqlalchemy.orm import Session
from datetime import datetime
from models import User, Container, WorkerInvitation
from schemas import UserCreate, UserUpdate, ContainerCreate, ContainerUpdate
from auth import hash_password


def get_user_by_email(db: Session, email: str):
    """Get user by email."""
    return db.query(User).filter(User.email == email).first()


def get_user_by_id(db: Session, user_id: int):
    """Get user by ID."""
    return db.query(User).filter(User.id == user_id).first()


def get_all_users(db: Session, skip: int = 0, limit: int = 100):
    """Get all users with pagination."""
    return db.query(User).offset(skip).limit(limit).all()


def create_user(db: Session, user: UserCreate):
    """Create a new user."""
    if get_user_by_email(db, user.email):
        return None  # User already exists
    
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
    """Update user information."""
    db_user = get_user_by_id(db, user_id)
    if not db_user:
        return None
    
    if user_update.full_name is not None:
        db_user.full_name = user_update.full_name
    if user_update.role is not None:
        db_user.role = user_update.role
    if user_update.is_active is not None:
        db_user.is_active = user_update.is_active
    if user_update.role_selected is not None:
        db_user.role_selected = user_update.role_selected
    
    db.commit()
    db.refresh(db_user)
    return db_user


def delete_user(db: Session, user_id: int):
    """Delete a user."""
    db_user = get_user_by_id(db, user_id)
    if not db_user:
        return False
    
    db.delete(db_user)
    db.commit()
    return True


def get_users_count(db: Session):
    """Get total count of users."""
    return db.query(User).count()


# ==================== CONTAINER FUNCTIONS ====================

def create_container(db: Session, container: ContainerCreate, created_by: int):
    """Create a new container."""
    db_container = Container(
        name=container.name,
        latitude=container.latitude,
        longitude=container.longitude,
        created_by=created_by,
    )
    db.add(db_container)
    db.commit()
    db.refresh(db_container)
    return db_container


def get_container_by_id(db: Session, container_id: int):
    """Get container by ID."""
    return db.query(Container).filter(Container.id == container_id).first()


def get_containers_by_admin(db: Session, admin_id: int):
    """Get all containers created by an admin."""
    return db.query(Container).filter(Container.created_by == admin_id).all()


def get_all_containers(db: Session, skip: int = 0, limit: int = 100):
    """Get all containers with pagination."""
    return db.query(Container).offset(skip).limit(limit).all()


def update_container(db: Session, container_id: int, container_update: ContainerUpdate):
    """Update container information."""
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


def delete_container(db: Session, container_id: int):
    """Delete a container."""
    db_container = get_container_by_id(db, container_id)
    if not db_container:
        return False
    
    db.delete(db_container)
    db.commit()
    return True


def add_worker_to_container(db: Session, container_id: int, worker_id: int):
    """Add a worker to a container."""
    db_container = get_container_by_id(db, container_id)
    db_worker = get_user_by_id(db, worker_id)
    
    if not db_container or not db_worker:
        return False
    
    if db_worker not in db_container.workers:
        db_container.workers.append(db_worker)
        db.commit()
        db.refresh(db_container)
    
    return True


def remove_worker_from_container(db: Session, container_id: int, worker_id: int):
    """Remove a worker from a container."""
    db_container = get_container_by_id(db, container_id)
    db_worker = get_user_by_id(db, worker_id)
    
    if not db_container or not db_worker:
        return False
    
    if db_worker in db_container.workers:
        db_container.workers.remove(db_worker)
        db.commit()
        db.refresh(db_container)
    
    return True


# ==================== WORKER INVITATION FUNCTIONS ====================

def create_worker_invitation(db: Session, admin_id: int, worker_id: int):
    """Create a worker invitation."""
    invitation = WorkerInvitation(
        admin_id=admin_id,
        worker_id=worker_id,
        status="PENDING",
    )
    db.add(invitation)
    db.commit()
    db.refresh(invitation)
    return invitation


def get_worker_invitation_by_id(db: Session, invitation_id: int):
    """Get worker invitation by ID."""
    return db.query(WorkerInvitation).filter(WorkerInvitation.id == invitation_id).first()


def get_pending_invitation_between_users(db: Session, admin_id: int, worker_id: int):
    """Get pending invitation between same admin and worker if exists."""
    return (
        db.query(WorkerInvitation)
        .filter(
            WorkerInvitation.admin_id == admin_id,
            WorkerInvitation.worker_id == worker_id,
            WorkerInvitation.status == "PENDING",
        )
        .first()
    )


def get_worker_invitations_for_worker(db: Session, worker_id: int):
    """List invitations received by worker."""
    return (
        db.query(WorkerInvitation)
        .filter(WorkerInvitation.worker_id == worker_id)
        .order_by(WorkerInvitation.created_at.desc())
        .all()
    )


def get_worker_invitations_for_admin(db: Session, admin_id: int):
    """List invitations sent by admin."""
    return (
        db.query(WorkerInvitation)
        .filter(WorkerInvitation.admin_id == admin_id)
        .order_by(WorkerInvitation.created_at.desc())
        .all()
    )


def get_accepted_workers_for_admin(db: Session, admin_id: int):
    """List distinct workers who accepted invitation from this admin."""
    return (
        db.query(User)
        .join(WorkerInvitation, WorkerInvitation.worker_id == User.id)
        .filter(
            WorkerInvitation.admin_id == admin_id,
            WorkerInvitation.status == "ACCEPTED",
            User.role == "FARMER",
        )
        .distinct(User.id)
        .all()
    )


def respond_to_worker_invitation(db: Session, invitation_id: int, action: str):
    """Respond to invitation with ACCEPT or REJECT."""
    invitation = get_worker_invitation_by_id(db, invitation_id)
    if not invitation:
        return None

    invitation.status = "ACCEPTED" if action == "ACCEPT" else "REJECTED"
    invitation.responded_at = datetime.utcnow()
    db.commit()
    db.refresh(invitation)
    return invitation
