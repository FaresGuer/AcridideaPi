from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import text
from datetime import timedelta, datetime
from uuid import uuid4
import base64
import json
from email.mime.text import MIMEText
import os
import random
import smtplib
from urllib.parse import urlencode
from urllib.request import Request, urlopen
from urllib.error import HTTPError
from dotenv import load_dotenv

from database import Base, engine, get_db, SessionLocal
from models import User, Container
from schemas import (
    UserCreate,
    UserUpdate,
    UserResponse,
    Token,
    ChangePasswordRequest,
    TwoFactorVerifyRequest,
    ForgotPasswordRequest,
    ResetPasswordRequest,
    ContainerCreate,
    ContainerUpdate,
    ContainerDataUpdate,
    ContainerDataResponse,
    ContainerSensorHistoryResponse,
    FeedingScheduleCreate,
    FeedingScheduleResponse,
    FeedingScheduleUpdate,
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
    get_container_data,
    reconcile_container_actuators,
    record_container_sensor_history_snapshot,
    get_container_sensor_history,
    update_container_data,
    get_feeding_schedules,
    create_feeding_schedule,
    get_feeding_schedule_by_id,
    update_feeding_schedule,
    delete_feeding_schedule,
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
    revoke_worker_invitation,
)
from auth import (
    verify_password,
    hash_password,
    create_access_token,
    get_current_user,
    require_admin,
    ACCESS_TOKEN_EXPIRE_MINUTES,
)

load_dotenv()

TWO_FACTOR_CODE_EXPIRY_MINUTES = int(os.getenv("TWO_FACTOR_CODE_EXPIRY_MINUTES", "10"))
GATEWAY_FRESHNESS_SECONDS = int(os.getenv("GATEWAY_FRESHNESS_SECONDS", "15"))
CRITICAL_ALERT_PHONE = os.getenv("CRITICAL_ALERT_PHONE", "+216 98264250")
_two_factor_challenges: dict[str, dict] = {}
_password_reset_challenges: dict[str, dict] = {}  # For password reset flow
_critical_state_cache: dict[tuple[int, str], bool] = {}


def _resolve_min_max(min_value: float | None, max_value: float | None):
    """Return a normalized (min, max) tuple when at least one bound exists."""
    if min_value is None and max_value is None:
        return None, None
    if min_value is None:
        min_value = max_value
    if max_value is None:
        max_value = min_value
    if min_value is not None and max_value is not None and min_value > max_value:
        min_value, max_value = max_value, min_value
    return min_value, max_value


def _is_gateway_fresh(data) -> bool:
    """Treat gateway as online while container data updates arrive recently."""
    if not data or not data.last_updated:
        return False

    return (datetime.utcnow() - data.last_updated).total_seconds() <= GATEWAY_FRESHNESS_SECONDS


# Schema migration removed - PostgreSQL schema is already correct



def _send_email(to_email: str, subject: str, body: str) -> bool:
    """Send an email via SMTP. In development without SMTP config, logs to console."""
    smtp_host = os.getenv("SMTP_HOST")
    smtp_port = int(os.getenv("SMTP_PORT", "587"))
    smtp_username = os.getenv("SMTP_USERNAME")
    smtp_password = os.getenv("SMTP_PASSWORD")
    smtp_from = os.getenv("SMTP_FROM", smtp_username or "noreply@locust.farm")

    if not smtp_host or not smtp_username or not smtp_password:
        print(f"[2FA DEV] To: {to_email} | Subject: {subject} | Body: {body}")
        return True

    message = MIMEText(body)
    message["Subject"] = subject
    message["From"] = smtp_from
    message["To"] = to_email

    try:
        with smtplib.SMTP(smtp_host, smtp_port, timeout=20) as server:
            server.starttls()
            server.login(smtp_username, smtp_password)
            server.sendmail(smtp_from, [to_email], message.as_string())
        return True
    except Exception as exc:
        print(f"Failed to send 2FA email: {exc}")
        return False


def _normalize_phone_number(phone_number: str | None) -> str | None:
    if not phone_number:
        return None
    normalized = "".join(ch for ch in phone_number if ch.isdigit() or ch == "+")
    return normalized or None


def _send_sms(to_phone: str, body: str) -> bool:
    """Send SMS through Twilio. In development without config, log to console."""
    twilio_sid = os.getenv("TWILIO_ACCOUNT_SID")
    twilio_token = os.getenv("TWILIO_AUTH_TOKEN")
    twilio_from = os.getenv("TWILIO_FROM_PHONE")

    if not twilio_sid or not twilio_token or not twilio_from:
        print(f"[SMS DEV] To: {to_phone} | Body: {body}")
        return True

    api_url = f"https://api.twilio.com/2010-04-01/Accounts/{twilio_sid}/Messages.json"
    payload = urlencode({"From": twilio_from, "To": to_phone, "Body": body}).encode("utf-8")
    request = Request(api_url, data=payload, method="POST")
    auth = base64.b64encode(f"{twilio_sid}:{twilio_token}".encode("utf-8")).decode("ascii")
    request.add_header("Authorization", f"Basic {auth}")
    request.add_header("Content-Type", "application/x-www-form-urlencoded")

    try:
        with urlopen(request, timeout=20) as response:
            return 200 <= response.status < 300
    except HTTPError as exc:
        error_body = exc.read().decode("utf-8", errors="ignore")
        print(f"Failed to send SMS ({exc.code}): {error_body}")
        return False
    except Exception as exc:
        print(f"Failed to send SMS: {exc}")
        return False


def _build_critical_sensor_messages(data) -> dict[str, str | None]:
    temp_min, temp_max = _resolve_min_max(data.target_temperature_min, data.target_temperature)
    humidity_min, humidity_max = _resolve_min_max(data.target_humidity_min, data.target_humidity)
    light_min, light_max = _resolve_min_max(data.target_light_level_min, data.target_light_level)
    gas_min, gas_max = _resolve_min_max(data.target_gas_level_min, data.target_gas_level)

    # Fallback defaults for legacy rows that may still have null thresholds.
    if temp_min is None and temp_max is None:
        temp_min, temp_max = 20.0, 25.0
    if humidity_min is None and humidity_max is None:
        humidity_min, humidity_max = 40.0, 60.0
    if light_min is None and light_max is None:
        light_min, light_max = 30.0, 75.0
    if gas_min is None and gas_max is None:
        gas_min, gas_max = 150.0, 350.0

    critical_messages: dict[str, str | None] = {
        "temperature_low": None,
        "temperature_high": None,
        "humidity_low": None,
        "humidity_high": None,
        "light_low": None,
        "light_high": None,
        "gas_low": None,
        "gas_high": None,
    }

    if data.temperature is not None and temp_min is not None and data.temperature < temp_min:
        critical_messages["temperature_low"] = (
            f"Temperature is low ({data.temperature:.2f}C). Minimum is {temp_min:.2f}C."
        )
    if data.temperature is not None and temp_max is not None and data.temperature > temp_max:
        critical_messages["temperature_high"] = (
            f"Temperature is high ({data.temperature:.2f}C). Maximum is {temp_max:.2f}C."
        )

    if data.humidity is not None and humidity_min is not None and data.humidity < humidity_min:
        critical_messages["humidity_low"] = (
            f"Humidity is low ({data.humidity:.2f}%). Minimum is {humidity_min:.2f}%."
        )
    if data.humidity is not None and humidity_max is not None and data.humidity > humidity_max:
        critical_messages["humidity_high"] = (
            f"Humidity is high ({data.humidity:.2f}%). Maximum is {humidity_max:.2f}%."
        )

    if data.light_level is not None and light_min is not None and data.light_level < light_min:
        critical_messages["light_low"] = (
            f"Light level is low ({data.light_level:.2f}). Minimum is {light_min:.2f}."
        )
    if data.light_level is not None and light_max is not None and data.light_level > light_max:
        critical_messages["light_high"] = (
            f"Light level is high ({data.light_level:.2f}). Maximum is {light_max:.2f}."
        )

    if data.gas_level is not None and gas_min is not None and data.gas_level < gas_min:
        critical_messages["gas_low"] = (
            f"Gas level is low ({data.gas_level:.2f} ppm). Minimum is {gas_min:.2f} ppm."
        )
    if data.gas_level is not None and gas_max is not None and data.gas_level > gas_max:
        critical_messages["gas_high"] = (
            f"Gas level is high ({data.gas_level:.2f} ppm). Maximum is {gas_max:.2f} ppm."
        )

    return critical_messages


def _get_container_recipients() -> list[str]:
    normalized_phone = _normalize_phone_number(CRITICAL_ALERT_PHONE)
    if not normalized_phone:
        return []
    return [normalized_phone]


def _notify_container_critical_states(container: Container, data) -> None:
    critical_messages = _build_critical_sensor_messages(data)
    newly_triggered: list[str] = []

    for condition_key, message in critical_messages.items():
        cache_key = (container.id, condition_key)
        was_critical = _critical_state_cache.get(cache_key, False)
        is_critical = message is not None

        if is_critical and not was_critical and message is not None:
            newly_triggered.append(message)

        _critical_state_cache[cache_key] = is_critical

    if not newly_triggered:
        return

    recipients = _get_container_recipients()
    if not recipients:
        print(
            f"No SMS recipients for critical alert in container {container.id} ({container.name})."
        )
        return

    timestamp = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")
    for message in newly_triggered:
        sms_body = (
            f"Critical alert for {container.name}: {message} "
            f"Detected at {timestamp}."
        )
        for recipient in recipients:
            _send_sms(recipient, sms_body)

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
    
    if user.two_factor_enabled:
        verification_code = f"{random.randint(0, 999999):06d}"
        verification_token = str(uuid4())
        expires_at = datetime.utcnow() + timedelta(minutes=TWO_FACTOR_CODE_EXPIRY_MINUTES)

        _two_factor_challenges[verification_token] = {
            "user_email": user.email,
            "code": verification_code,
            "expires_at": expires_at,
        }

        email_sent = _send_email(
            to_email=user.email,
            subject="Your Locust Farm verification code",
            body=(
                f"Your verification code is: {verification_code}\n"
                f"This code expires in {TWO_FACTOR_CODE_EXPIRY_MINUTES} minutes."
            ),
        )

        if not email_sent:
            _two_factor_challenges.pop(verification_token, None)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Unable to send verification email"
            )

        return {
            "token_type": "bearer",
            "requires_two_factor": True,
            "verification_token": verification_token,
            "message": "Verification code sent to your email",
        }

    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email},
        expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}


@app.post("/token/verify-2fa", response_model=Token)
async def verify_two_factor_token(
    payload: TwoFactorVerifyRequest,
    db: Session = Depends(get_db)
):
    """Verify 2FA code and complete login."""
    challenge = _two_factor_challenges.get(payload.verification_token)
    if not challenge:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired verification session"
        )

    if challenge["expires_at"] < datetime.utcnow():
        _two_factor_challenges.pop(payload.verification_token, None)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Verification code has expired"
        )

    if payload.code != challenge["code"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid verification code"
        )

    user = get_user_by_email(db, challenge["user_email"])
    if not user or not user.is_active:
        _two_factor_challenges.pop(payload.verification_token, None)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not available for login",
            headers={"WWW-Authenticate": "Bearer"},
        )

    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email},
        expires_delta=access_token_expires
    )
    _two_factor_challenges.pop(payload.verification_token, None)
    return {"access_token": access_token, "token_type": "bearer"}


@app.post("/forgot-password")
async def forgot_password(
    payload: ForgotPasswordRequest,
    db: Session = Depends(get_db)
):
    """Request a password reset code via email."""
    user = get_user_by_email(db, payload.email)
    if not user:
        # Don't reveal if email exists for security
        return {"message": "If an account exists with this email, a reset code will be sent"}

    reset_code = f"{random.randint(0, 999999):06d}"
    reset_token = str(uuid4())
    expires_at = datetime.utcnow() + timedelta(minutes=TWO_FACTOR_CODE_EXPIRY_MINUTES)

    _password_reset_challenges[reset_token] = {
        "user_email": user.email,
        "code": reset_code,
        "expires_at": expires_at,
    }

    email_sent = _send_email(
        to_email=user.email,
        subject="Password Reset Code - Locust Farm",
        body=(
            f"Your password reset code is: {reset_code}\n"
            f"This code expires in {TWO_FACTOR_CODE_EXPIRY_MINUTES} minutes.\n\n"
            f"If you didn't request a password reset, ignore this email."
        ),
    )

    if not email_sent:
        _password_reset_challenges.pop(reset_token, None)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Unable to send reset email"
        )

    return {
        "reset_token": reset_token,
        "message": "Password reset code sent to your email"
    }


@app.post("/reset-password")
async def reset_password(
    payload: ResetPasswordRequest,
    db: Session = Depends(get_db)
):
    """Reset password using verification code."""
    challenge = _password_reset_challenges.get(payload.reset_token)
    if not challenge:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired reset session"
        )

    if challenge["expires_at"] < datetime.utcnow():
        _password_reset_challenges.pop(payload.reset_token, None)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Reset code has expired"
        )

    if payload.code != challenge["code"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid reset code"
        )

    user = get_user_by_email(db, challenge["user_email"])
    if not user:
        _password_reset_challenges.pop(payload.reset_token, None)
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    # Update password
    user.hashed_password = hash_password(payload.new_password)
    db.commit()
    db.refresh(user)

    _password_reset_challenges.pop(payload.reset_token, None)
    return {
        "message": "Password reset successfully",
        "email": user.email
    }


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
    if user_update.email is not None and user_update.email != current_user.email:
        existing = get_user_by_email(db, user_update.email)
        if existing and existing.id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )

    update_data = UserUpdate(
        email=user_update.email,
        full_name=user_update.full_name,
        role=user_update.role,
        role_selected=user_update.role_selected,
        two_factor_enabled=user_update.two_factor_enabled,
    )
    updated_user = update_user(db, current_user.id, update_data)
    return updated_user


@app.post("/users/me/change-password", status_code=status.HTTP_200_OK)
async def change_current_user_password(
    payload: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Change current user's password."""
    if not verify_password(payload.current_password, current_user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current password is incorrect"
        )

    if payload.current_password == payload.new_password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="New password must be different from current password"
        )

    current_user.hashed_password = hash_password(payload.new_password)
    db.commit()
    return {"detail": "Password changed successfully"}


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

    if user_update.email is not None and user_update.email != db_user.email:
        existing = get_user_by_email(db, user_update.email)
        if existing and existing.id != db_user.id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
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
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get containers for current user.

    - ADMIN: containers created by the admin
    - FARMER: containers assigned to the worker
    """
    if current_user.role == "ADMIN":
        containers = get_containers_by_admin(db, current_user.id)
    else:
        containers = current_user.assigned_containers
    return containers


@app.get("/containers/{container_id}", response_model=ContainerResponse)
async def get_container(
    container_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get a specific container available to current user."""
    db_container = get_container_by_id(db, container_id)
    if not db_container:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Container not found"
        )

    if current_user.role == "ADMIN":
        if db_container.created_by != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to access this container"
            )
    else:
        is_assigned = any(worker.id == current_user.id for worker in db_container.workers)
        if not is_assigned:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to access this container"
            )
    
    return db_container


@app.get("/containers/{container_id}/data", response_model=ContainerDataResponse)
async def get_container_data_endpoint(
    container_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get operational data for a container available to current user."""
    db_container = get_container_by_id(db, container_id)
    if not db_container:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Container not found"
        )

    if current_user.role == "ADMIN":
        if db_container.created_by != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to access this container"
            )
    else:
        is_assigned = any(worker.id == current_user.id for worker in db_container.workers)
        if not is_assigned:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to access this container"
            )

    data = get_container_data(db, container_id)
    if not data:
        data = update_container_data(
            db,
            container_id,
            ContainerDataUpdate(),
            apply_automatic_logic=False,
        )
    elif not _is_gateway_fresh(data):
        data = reconcile_container_actuators(db, container_id)

    # Evaluate critical-state transitions on reads as well, so alerts still
    # fire when sensor values are updated by external writers.
    _notify_container_critical_states(db_container, data)

    record_container_sensor_history_snapshot(db, container_id, data)

    return data


@app.put("/containers/{container_id}/data", response_model=ContainerDataResponse)
async def update_container_data_endpoint(
    container_id: int,
    data_update: ContainerDataUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update operational data for a container available to current user."""
    db_container = get_container_by_id(db, container_id)
    if not db_container:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Container not found"
        )

    if current_user.role == "ADMIN":
        if db_container.created_by != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to update this container"
            )
    else:
        is_assigned = any(worker.id == current_user.id for worker in db_container.workers)
        if not is_assigned:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to update this container"
            )

    existing_data = get_container_data(db, container_id)
    gateway_fresh = _is_gateway_fresh(existing_data)

    updated_data = update_container_data(
        db,
        container_id,
        data_update,
        apply_automatic_logic=not gateway_fresh,
    )

    _notify_container_critical_states(db_container, updated_data)
    return updated_data


@app.get("/containers/{container_id}/history", response_model=list[ContainerSensorHistoryResponse])
async def get_container_history_endpoint(
    container_id: int,
    limit: int = 120,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get historical sensor readings for a container available to current user."""
    db_container = get_container_by_id(db, container_id)
    if not db_container:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Container not found"
        )

    if current_user.role == "ADMIN":
        if db_container.created_by != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to access this container"
            )
    else:
        is_assigned = any(worker.id == current_user.id for worker in db_container.workers)
        if not is_assigned:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to access this container"
            )

    return get_container_sensor_history(db, container_id, limit=limit)


@app.get("/containers/{container_id}/feeding-schedules", response_model=list[FeedingScheduleResponse])
async def get_feeding_schedules_endpoint(
    container_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get feeding schedules for a container."""
    db_container = get_container_by_id(db, container_id)
    if not db_container:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Container not found"
        )

    if current_user.role == "ADMIN":
        if db_container.created_by != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to access this container"
            )
    else:
        is_assigned = any(worker.id == current_user.id for worker in db_container.workers)
        if not is_assigned:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to access this container"
            )

    return get_feeding_schedules(db, container_id)


@app.post("/containers/{container_id}/feeding-schedules", response_model=FeedingScheduleResponse, status_code=status.HTTP_201_CREATED)
async def create_feeding_schedule_endpoint(
    container_id: int,
    schedule: FeedingScheduleCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a feeding schedule entry for a container."""
    db_container = get_container_by_id(db, container_id)
    if not db_container:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Container not found"
        )

    if current_user.role == "ADMIN":
        if db_container.created_by != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to update this container"
            )
    else:
        is_assigned = any(worker.id == current_user.id for worker in db_container.workers)
        if not is_assigned:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to update this container"
            )

    return create_feeding_schedule(db, container_id, schedule)


@app.put("/containers/{container_id}/feeding-schedules/{schedule_id}", response_model=FeedingScheduleResponse)
async def update_feeding_schedule_endpoint(
    container_id: int,
    schedule_id: int,
    schedule_update: FeedingScheduleUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update a feeding schedule entry for a container."""
    db_container = get_container_by_id(db, container_id)
    if not db_container:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Container not found"
        )

    if current_user.role == "ADMIN":
        if db_container.created_by != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to update this container"
            )
    else:
        is_assigned = any(worker.id == current_user.id for worker in db_container.workers)
        if not is_assigned:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to update this container"
            )

    existing = get_feeding_schedule_by_id(db, schedule_id)
    if not existing or existing.container_id != container_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Feeding schedule not found"
        )

    updated = update_feeding_schedule(db, schedule_id, schedule_update)
    if not updated:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Feeding schedule not found"
        )

    return updated


@app.delete("/containers/{container_id}/feeding-schedules/{schedule_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_feeding_schedule_endpoint(
    container_id: int,
    schedule_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete a feeding schedule entry for a container."""
    db_container = get_container_by_id(db, container_id)
    if not db_container:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Container not found"
        )

    if current_user.role == "ADMIN":
        if db_container.created_by != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to update this container"
            )
    else:
        is_assigned = any(worker.id == current_user.id for worker in db_container.workers)
        if not is_assigned:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to update this container"
            )

    existing = get_feeding_schedule_by_id(db, schedule_id)
    if not existing or existing.container_id != container_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Feeding schedule not found"
        )

    success = delete_feeding_schedule(db, schedule_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Feeding schedule not found"
        )


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


@app.post("/containers/{container_id}/workers/{worker_id}", response_model=ContainerResponse, status_code=status.HTTP_200_OK)
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


@app.delete("/containers/{container_id}/workers/{worker_id}", response_model=ContainerResponse, status_code=status.HTTP_200_OK)
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


@app.delete("/admin/workers/{worker_id}/revoke", status_code=status.HTTP_204_NO_CONTENT)
async def revoke_worker_by_admin(
    worker_id: int,
    admin_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """Admin ends collaboration with a worker (revokes accepted invitation, does not delete worker account)."""
    success = revoke_worker_invitation(db, admin_user.id, worker_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No accepted worker collaboration found to revoke"
        )


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
