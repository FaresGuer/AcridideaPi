from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import inspect, text
from datetime import timedelta, datetime

from database import Base, engine, get_db
from models import User, Container, ContainerSensorHistory
from schemas import (
    UserCreate,
    UserUpdate,
    UserResponse,
    Token,
    ChangePasswordRequest,
    ContainerCreate,
    ContainerUpdate,
    ContainerDataUpdate,
    ContainerDataResponse,
    ContainerResponse,
)
from crud import (
    get_user_by_email,
    create_user,
    update_user,
    create_container,
    get_container_by_id,
    get_containers_by_admin,
    update_container,
    get_container_data,
    update_container_data,
)
from auth import (
    verify_password,
    hash_password,
    create_access_token,
    get_current_user,
    require_admin,
    ACCESS_TOKEN_EXPIRE_MINUTES,
)


def _ensure_user_schema_columns() -> None:
    inspector = inspect(engine)
    user_columns = {column["name"] for column in inspector.get_columns("users")}

    with engine.begin() as connection:
        if "role_selected" not in user_columns:
            connection.execute(
                text("ALTER TABLE users ADD COLUMN role_selected BOOLEAN NOT NULL DEFAULT FALSE")
            )

        if "two_factor_enabled" not in user_columns:
            connection.execute(
                text("ALTER TABLE users ADD COLUMN two_factor_enabled BOOLEAN NOT NULL DEFAULT FALSE")
            )


def _ensure_container_data_schema_columns() -> None:
    inspector = inspect(engine)
    container_data_columns = {column["name"] for column in inspector.get_columns("container_data")}

    with engine.begin() as connection:
        if "target_light_level" not in container_data_columns:
            connection.execute(
                text("ALTER TABLE container_data ADD COLUMN target_light_level FLOAT NULL")
            )

        if "humidifier_status" not in container_data_columns:
            connection.execute(
                text("ALTER TABLE container_data ADD COLUMN humidifier_status BOOLEAN NOT NULL DEFAULT FALSE")
            )

        if "gas_level" not in container_data_columns:
            connection.execute(
                text("ALTER TABLE container_data ADD COLUMN gas_level FLOAT NULL")
            )

        if "target_gas_level" not in container_data_columns:
            connection.execute(
                text("ALTER TABLE container_data ADD COLUMN target_gas_level FLOAT NULL")
            )

        if "target_gas_level_min" not in container_data_columns:
            connection.execute(
                text("ALTER TABLE container_data ADD COLUMN target_gas_level_min FLOAT NULL")
            )

        if "target_temperature_min" not in container_data_columns:
            connection.execute(
                text("ALTER TABLE container_data ADD COLUMN target_temperature_min FLOAT NULL")
            )

        if "target_humidity_min" not in container_data_columns:
            connection.execute(
                text("ALTER TABLE container_data ADD COLUMN target_humidity_min FLOAT NULL")
            )

        if "target_light_level_min" not in container_data_columns:
            connection.execute(
                text("ALTER TABLE container_data ADD COLUMN target_light_level_min FLOAT NULL")
            )


Base.metadata.create_all(bind=engine)
_ensure_user_schema_columns()
_ensure_container_data_schema_columns()

app = FastAPI(
    title="Locust Farm Management API",
    description="Web and mobile shared backend",
    version="2.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(user: UserCreate, db: Session = Depends(get_db)):
    existing = get_user_by_email(db, email=user.email)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered",
        )

    new_user = create_user(db, user)
    return new_user


@app.post("/token", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
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
            detail="User account is inactive",
        )

    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(data={"sub": user.email}, expires_delta=access_token_expires)
    return {"access_token": access_token, "token_type": "bearer"}


@app.get("/users/me", response_model=UserResponse)
async def read_current_user(current_user: User = Depends(get_current_user)):
    return current_user


@app.put("/users/me", response_model=UserResponse)
async def update_current_user(
    user_update: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if user_update.role is not None and user_update.role != current_user.role and current_user.role != "ADMIN":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can change roles",
        )

    updated_user = update_user(db, current_user.id, user_update)
    if not updated_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    return updated_user


@app.post("/users/me/change-password", status_code=status.HTTP_200_OK)
async def change_password(
    req: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if not verify_password(req.current_password, current_user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current password is incorrect",
        )

    current_user.hashed_password = hash_password(req.new_password)
    db.commit()
    return {"message": "Password updated successfully"}


@app.post("/containers", response_model=ContainerResponse, status_code=status.HTTP_201_CREATED)
async def create_new_container(
    container: ContainerCreate,
    admin_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    return create_container(db, container, admin_user.id)


@app.get("/containers", response_model=list[ContainerResponse])
async def list_containers(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if current_user.role == "ADMIN":
        return get_containers_by_admin(db, current_user.id)
    return current_user.assigned_containers


@app.get("/containers/{container_id}", response_model=ContainerResponse)
async def get_container(container_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    db_container = get_container_by_id(db, container_id)
    if not db_container:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Container not found")

    if current_user.role == "ADMIN":
        if db_container.created_by != current_user.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")
    else:
        if not any(worker.id == current_user.id for worker in db_container.workers):
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    return db_container


@app.put("/containers/{container_id}", response_model=ContainerResponse)
async def update_container_endpoint(
    container_id: int,
    container_update: ContainerUpdate,
    admin_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    db_container = get_container_by_id(db, container_id)
    if not db_container:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Container not found")

    if db_container.created_by != admin_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    updated = update_container(db, container_id, container_update)
    if not updated:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Container not found")
    return updated


@app.get("/containers/{container_id}/data", response_model=ContainerDataResponse)
async def get_container_data_endpoint(
    container_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get persisted operational data for a container (no simulated values)."""

    db_container = get_container_by_id(db, container_id)
    if not db_container:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Container not found")

    if current_user.role == "ADMIN":
        if db_container.created_by != current_user.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")
    else:
        if not any(worker.id == current_user.id for worker in db_container.workers):
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    # Get or create container data
    data = get_container_data(db, container_id)
    if not data:
        data = update_container_data(db, container_id, ContainerDataUpdate())

    return data


@app.put("/containers/{container_id}/data", response_model=ContainerDataResponse)
async def update_container_data_endpoint(
    container_id: int,
    data_update: ContainerDataUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    db_container = get_container_by_id(db, container_id)
    if not db_container:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Container not found")

    if current_user.role == "ADMIN":
        if db_container.created_by != current_user.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")
    else:
        if not any(worker.id == current_user.id for worker in db_container.workers):
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    return update_container_data(db, container_id, data_update)


@app.get("/containers/{container_id}/data/history")
async def get_container_data_history(
    container_id: int,
    hours: int = 24,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get historical sensor data using persisted database values only."""

    db_container = get_container_by_id(db, container_id)
    if not db_container:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Container not found")

    if current_user.role == "ADMIN":
        if db_container.created_by != current_user.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")
    else:
        if not any(worker.id == current_user.id for worker in db_container.workers):
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    cutoff = datetime.utcnow() - timedelta(hours=hours)
    rows = (
        db.query(ContainerSensorHistory)
        .filter(
            ContainerSensorHistory.container_id == container_id,
            ContainerSensorHistory.recorded_at >= cutoff,
        )
        .order_by(ContainerSensorHistory.recorded_at.asc(), ContainerSensorHistory.id.asc())
        .all()
    )

    # Pivot sensor rows into chart points keyed by timestamp.
    by_ts: dict[str, dict] = {}
    for row in rows:
        ts = row.recorded_at.isoformat() + "Z"
        if ts not in by_ts:
            by_ts[ts] = {
                "timestamp": ts,
                "temperature": None,
                "humidity": None,
                "light_level": None,
                "gas_level": None,
            }

        sensor_type = (row.sensor_type or "").lower()
        if sensor_type in ("temperature", "temp"):
            by_ts[ts]["temperature"] = row.value
        elif sensor_type in ("humidity", "hum"):
            by_ts[ts]["humidity"] = row.value
        elif sensor_type in ("light_level", "light", "luminosity", "lux"):
            by_ts[ts]["light_level"] = row.value
        elif sensor_type in ("gas_level", "gas", "co2"):
            by_ts[ts]["gas_level"] = row.value

    history = list(by_ts.values())
    return {"history": history}


@app.get("/health")
async def health_check():
    return {"status": "ok", "service": "Locust Farm Management API"}


@app.get("/")
async def root():
    return {"message": "Locust Farming API is running"}
