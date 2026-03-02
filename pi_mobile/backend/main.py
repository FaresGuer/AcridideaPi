from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from datetime import timedelta

from database import Base, engine, get_db, SessionLocal
from models import User, Container
from schemas import (
    UserCreate,
    UserUpdate,
    UserResponse,
    Token,
    ContainerCreate,
    ContainerUpdate,
    ContainerResponse,
    ContainerSimple,
    WorkerInvitationCreate,
    WorkerInvitationRespond,
    WorkerInvitationResponse,
)
from crud import (
    get_user_by_email,
    get_user_by_id,
    get_all_users,
    create_user,
    update_user,
    delete_user,
    get_users_count,
    create_container,
    get_container_by_id,
    get_containers_by_admin,
    get_all_containers,
    update_container,
    delete_container,
    add_worker_to_container,
    remove_worker_from_container,
    create_worker_invitation,
    get_worker_invitation_by_id,
    get_pending_invitation_between_users,
    get_worker_invitations_for_worker,
    get_worker_invitations_for_admin,
    get_accepted_workers_for_admin,
    respond_to_worker_invitation,
)
from auth import (
    verify_password,
    create_access_token,
    get_current_user,
    require_admin,
    ACCESS_TOKEN_EXPIRE_MINUTES,
)

# Create tables
Base.metadata.create_all(bind=engine)

# FastAPI app
app = FastAPI(
    title="Locust Farm Management System",
    description="API for managing locust farms and workers",
    version="1.0.0",
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins - restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ==================== PUBLIC ENDPOINTS ====================

@app.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(user: UserCreate, db: Session = Depends(get_db)):
    """Register a new user."""
    db_user = get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    new_user = create_user(db, user)
    return new_user


@app.post("/token", response_model=Token)
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    """Login endpoint - returns JWT token."""
    user = get_user_by_email(db, email=form_data.username)
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is inactive"
        )
    
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email},
        expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}


# ==================== AUTHENTICATED ENDPOINTS ====================

@app.get("/users/me", response_model=UserResponse)
async def get_current_user_profile(current_user: User = Depends(get_current_user)):
    """Get current user profile."""
    return current_user


@app.put("/users/me", response_model=UserResponse)
async def update_current_user(
    user_update: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update current user's profile (limited fields)."""
    # Allow updating name and role selection only
    update_data = UserUpdate(
        full_name=user_update.full_name,
        role=user_update.role,
        role_selected=user_update.role_selected,
    )
    updated_user = update_user(db, current_user.id, update_data)
    return updated_user


# ==================== ADMIN ENDPOINTS ====================

@app.get("/users", response_model=list[UserResponse])
async def list_all_users(
    skip: int = 0,
    limit: int = 100,
    admin_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """Get all users - Admin only."""
    users = get_all_users(db, skip=skip, limit=limit)
    return users


@app.get("/users/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: int,
    admin_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """Get a specific user - Admin only."""
    db_user = get_user_by_id(db, user_id)
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    return db_user


@app.put("/users/{user_id}", response_model=UserResponse)
async def update_user_admin(
    user_id: int,
    user_update: UserUpdate,
    admin_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """Update any user - Admin only."""
    db_user = get_user_by_id(db, user_id)
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Prevent admin from deactivating themselves
    if user_id == admin_user.id and user_update.is_active is False:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot deactivate your own account"
        )
    
    updated_user = update_user(db, user_id, user_update)
    return updated_user


@app.delete("/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user_admin(
    user_id: int,
    admin_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """Delete a user - Admin only."""
    # Prevent admin from deleting themselves
    if user_id == admin_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete your own account"
        )
    
    db_user = get_user_by_id(db, user_id)
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    delete_user(db, user_id)


# ==================== CONTAINER ENDPOINTS ====================

@app.post("/containers", response_model=ContainerResponse, status_code=status.HTTP_201_CREATED)
async def create_new_container(
    container: ContainerCreate,
    admin_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """Create a new container - Admin only."""
    new_container = create_container(db, container, admin_user.id)
    return new_container


@app.get("/containers", response_model=list[ContainerResponse])
async def list_containers(
    admin_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """Get all containers created by the admin."""
    containers = get_containers_by_admin(db, admin_user.id)
    return containers


@app.get("/containers/{container_id}", response_model=ContainerResponse)
async def get_container(
    container_id: int,
    admin_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """Get a specific container - Admin only."""
    db_container = get_container_by_id(db, container_id)
    if not db_container:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Container not found"
        )
    
    # Verify owner
    if db_container.created_by != admin_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to access this container"
        )
    
    return db_container


@app.put("/containers/{container_id}", response_model=ContainerResponse)
async def update_container_endpoint(
    container_id: int,
    container_update: ContainerUpdate,
    admin_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """Update a container - Admin only."""
    db_container = get_container_by_id(db, container_id)
    if not db_container:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Container not found"
        )
    
    # Verify owner
    if db_container.created_by != admin_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to update this container"
        )
    
    updated_container = update_container(db, container_id, container_update)
    return updated_container


@app.delete("/containers/{container_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_container_endpoint(
    container_id: int,
    admin_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """Delete a container - Admin only."""
    db_container = get_container_by_id(db, container_id)
    if not db_container:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Container not found"
        )
    
    # Verify owner
    if db_container.created_by != admin_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to delete this container"
        )
    
    delete_container(db, container_id)


@app.post("/containers/{container_id}/workers/{worker_id}", status_code=status.HTTP_200_OK)
async def assign_worker_to_container(
    container_id: int,
    worker_id: int,
    admin_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """Assign a worker to a container - Admin only."""
    db_container = get_container_by_id(db, container_id)
    if not db_container:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Container not found"
        )
    
    # Verify owner
    if db_container.created_by != admin_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to modify this container"
        )
    
    db_worker = get_user_by_id(db, worker_id)
    if not db_worker:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Worker not found"
        )
    
    if db_worker.role != "FARMER":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only farmers can be assigned to containers"
        )
    
    success = add_worker_to_container(db, container_id, worker_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to assign worker to container"
        )
    
    updated_container = get_container_by_id(db, container_id)
    return updated_container


@app.delete("/containers/{container_id}/workers/{worker_id}", status_code=status.HTTP_200_OK)
async def remove_worker_from_container_endpoint(
    container_id: int,
    worker_id: int,
    admin_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """Remove a worker from a container - Admin only."""
    db_container = get_container_by_id(db, container_id)
    if not db_container:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Container not found"
        )
    
    # Verify owner
    if db_container.created_by != admin_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to modify this container"
        )
    
    db_worker = get_user_by_id(db, worker_id)
    if not db_worker:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Worker not found"
        )
    
    success = remove_worker_from_container(db, container_id, worker_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to remove worker from container"
        )
    
    updated_container = get_container_by_id(db, container_id)
    return updated_container


# ==================== WORKER INVITATION ENDPOINTS ====================

@app.post("/worker-invitations", response_model=WorkerInvitationResponse, status_code=status.HTTP_201_CREATED)
async def send_worker_invitation(
    invitation: WorkerInvitationCreate,
    admin_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """Send invitation to worker by email - Admin only."""
    worker = get_user_by_email(db, invitation.email)
    if not worker:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No user found with this email"
        )

    if worker.role != "FARMER":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invitations can only be sent to farmer accounts"
        )

    if worker.id == admin_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You cannot invite yourself"
        )

    pending = get_pending_invitation_between_users(db, admin_user.id, worker.id)
    if pending:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A pending invitation already exists for this worker"
        )

    created = create_worker_invitation(db, admin_user.id, worker.id)
    return created


@app.get("/worker-invitations/received", response_model=list[WorkerInvitationResponse])
async def list_received_worker_invitations(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """List invitations received by current user."""
    invitations = get_worker_invitations_for_worker(db, current_user.id)
    return invitations


@app.get("/worker-invitations/sent", response_model=list[WorkerInvitationResponse])
async def list_sent_worker_invitations(
    admin_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """List invitations sent by current admin."""
    invitations = get_worker_invitations_for_admin(db, admin_user.id)
    return invitations


@app.get("/admin/workers/accepted", response_model=list[UserResponse])
async def list_accepted_workers_for_admin(
    admin_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """List workers who accepted this admin's invitation."""
    workers = get_accepted_workers_for_admin(db, admin_user.id)
    return workers


@app.post("/worker-invitations/{invitation_id}/respond", response_model=WorkerInvitationResponse)
async def respond_worker_invitation(
    invitation_id: int,
    payload: WorkerInvitationRespond,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Worker accepts or rejects an invitation."""
    invitation = get_worker_invitation_by_id(db, invitation_id)
    if not invitation:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Invitation not found"
        )

    if invitation.worker_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not allowed to respond to this invitation"
        )

    if invitation.status != "PENDING":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This invitation has already been responded to"
        )

    updated = respond_to_worker_invitation(db, invitation_id, payload.action)
    return updated


# ==================== HEALTH CHECK ====================

@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "ok", "service": "Locust Farm Management API"}
