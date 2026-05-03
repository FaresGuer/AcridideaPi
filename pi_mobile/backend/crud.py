from sqlalchemy.orm import Session
from datetime import datetime
from models import User, Container, WorkerInvitation, ContainerData, ContainerSensorHistory, FeedingSchedule
from schemas import (
    UserCreate,
    UserUpdate,
    ContainerCreate,
    ContainerUpdate,
    ContainerDataUpdate,
    FeedingScheduleCreate,
    FeedingScheduleUpdate,
)
from auth import hash_password
from database import mirror_to_mysql


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


def _apply_automatic_actuator_logic(db_data: ContainerData, manual_overrides: set[str] | None = None):
    """Update actuator booleans from sensor values and configured min/max thresholds."""
    manual_overrides = manual_overrides or set()
    temp_min, temp_max = _resolve_min_max(db_data.target_temperature_min, db_data.target_temperature)
    humidity_min, humidity_max = _resolve_min_max(db_data.target_humidity_min, db_data.target_humidity)
    light_min, light_max = _resolve_min_max(db_data.target_light_level_min, db_data.target_light_level)
    gas_min, gas_max = _resolve_min_max(db_data.target_gas_level_min, db_data.target_gas_level)

    temp_too_low = False
    temp_too_high = False
    humidity_too_high = False
    gas_too_high = False

    if db_data.temperature is not None and temp_min is not None and temp_max is not None:
        temp_too_low = db_data.temperature < temp_min
        temp_too_high = db_data.temperature > temp_max

    if db_data.humidity is not None and humidity_min is not None and humidity_max is not None:
        humidity_too_high = db_data.humidity > humidity_max

    if db_data.gas_level is not None and gas_min is not None and gas_max is not None:
        gas_too_high = db_data.gas_level > gas_max

    # Temperature below min needs heating; otherwise heater is off.
    if "heater_status" not in manual_overrides:
        db_data.heater_status = temp_too_low

    # Fan is required when cooling/dehumidifying/venting is needed.
    if "fan_status" not in manual_overrides:
        db_data.fan_status = temp_too_high or humidity_too_high or gas_too_high

    # Humidity controls humidifier.
    if (
        "humidifier_status" not in manual_overrides
        and db_data.humidity is not None
        and humidity_min is not None
        and humidity_max is not None
    ):
        if db_data.humidity < humidity_min:
            db_data.humidifier_status = True
        elif db_data.humidity > humidity_max:
            db_data.humidifier_status = False
        else:
            db_data.humidifier_status = False

    # Light controls lighting system (brighten when low, dim/off when high).
    if (
        "light_status" not in manual_overrides
        and db_data.light_level is not None
        and light_min is not None
        and light_max is not None
    ):
        if db_data.light_level < light_min:
            db_data.light_status = True
        elif db_data.light_level > light_max:
            db_data.light_status = False
        else:
            db_data.light_status = False


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
    # Mirror to Neon/Postgres (best-effort)
    try:
        from database import mirror_to_mysql

        user_query = (
            "INSERT INTO users (id, email, full_name, hashed_password, role, is_active, role_selected, two_factor_enabled) "
            "VALUES (%s, %s, %s, %s, %s, %s, %s, %s) ON CONFLICT (id) DO NOTHING"
        )
        user_vals = (
            int(db_user.id),
            db_user.email,
            db_user.full_name,
            db_user.hashed_password,
            db_user.role,
            bool(db_user.is_active),
            bool(db_user.role_selected),
            bool(db_user.two_factor_enabled),
        )

        ok = mirror_to_mysql(user_query, user_vals)
        if not ok:
            print("[DB-REPL] Neon user insert failed")
    except Exception as e:
        print(f"[DB-REPL] User replication exception: {e}")

    return db_user


def update_user(db: Session, user_id: int, user_update: UserUpdate):
    """Update user information."""
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
    # Mirror update to Neon (best-effort)
    try:
        from database import mirror_to_mysql

        set_parts = []
        vals = []
        if user_update.email is not None:
            set_parts.append("email = %s")
            vals.append(user_update.email)
        if user_update.full_name is not None:
            set_parts.append("full_name = %s")
            vals.append(user_update.full_name)
        if user_update.role is not None:
            set_parts.append("role = %s")
            vals.append(user_update.role)
        if user_update.is_active is not None:
            set_parts.append("is_active = %s")
            vals.append(bool(user_update.is_active))
        if user_update.role_selected is not None:
            set_parts.append("role_selected = %s")
            vals.append(bool(user_update.role_selected))
        if user_update.two_factor_enabled is not None:
            set_parts.append("two_factor_enabled = %s")
            vals.append(bool(user_update.two_factor_enabled))

        if set_parts:
            vals.append(int(db_user.id))
            mirror_to_mysql(f"UPDATE users SET {', '.join(set_parts)} WHERE id = %s", tuple(vals))
    except Exception as e:
        print(f"[DB-REPL] User update replication exception: {e}")

    return db_user


def delete_user(db: Session, user_id: int):
    """Delete a user."""
    db_user = get_user_by_id(db, user_id)
    if not db_user:
        return False
    
    db.delete(db_user)
    db.commit()
    # Mirror delete to Neon (best-effort)
    try:
        from database import mirror_to_mysql
        mirror_to_mysql("DELETE FROM users WHERE id = %s", (int(user_id),))
    except Exception as e:
        print(f"[DB-REPL] User delete replication exception: {e}")
    return True


def get_users_count(db: Session):
    """Get total count of users."""
    return db.query(User).count()


# ==================== CONTAINER FUNCTIONS ====================

def create_container(db: Session, container: ContainerCreate, created_by: int):
    """Create a new container with initial data."""
    db_container = Container(
        name=container.name,
        latitude=container.latitude,
        longitude=container.longitude,
        created_by=created_by,
    )
    db.add(db_container)
    db.flush()  # Flush to get container ID
    
    # Create initial container data
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
        target_temperature=25.0,  # Default target
        target_temperature_min=20.0,
        target_humidity=60.0,  # Default target
        target_humidity_min=40.0,
        target_light_level=75.0,  # Default light target
        target_light_level_min=30.0,
        target_gas_level=350.0,  # Default gas target (ppm)
        target_gas_level_min=150.0,
    )
    db.add(db_container_data)
    db.commit()
    db.refresh(db_container)

    # Replicate to Neon/Postgres (best-effort) using mirror helper
    try:
        from database import mirror_to_mysql

        # Insert container row into Neon (use parameter placeholders for psycopg)
        container_query = (
            "INSERT INTO containers (id, name, created_by, latitude, longitude, created_at, updated_at) "
            "VALUES (%s, %s, %s, %s, %s, %s, %s) ON CONFLICT (id) DO NOTHING"
        )
        container_vals = (
            int(db_container.id),
            db_container.name,
            int(db_container.created_by),
            float(db_container.latitude),
            float(db_container.longitude),
            db_container.created_at.isoformat() if db_container.created_at is not None else None,
            db_container.updated_at.isoformat() if db_container.updated_at is not None else None,
        )

        success = mirror_to_mysql(container_query, container_vals)
        if not success:
            print("[DB-REPL] Neon container insert failed")

        # Insert initial container_data
        data_query = (
            "INSERT INTO container_data (container_id, temperature, humidity, light_level, gas_level, "
            "heater_status, fan_status, light_status, humidifier_status, target_temperature, target_temperature_min, "
            "target_humidity, target_humidity_min, target_light_level, target_light_level_min, target_gas_level, target_gas_level_min, last_updated) "
            "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s) ON CONFLICT (container_id) DO NOTHING"
        )
        data_vals = (
            int(db_container.id),
            None,
            None,
            None,
            None,
            False,
            False,
            False,
            False,
            25.0,
            20.0,
            60.0,
            40.0,
            75.0,
            30.0,
            350.0,
            150.0,
            None,
        )

        success2 = mirror_to_mysql(data_query, data_vals)
        if not success2:
            print("[DB-REPL] Neon container_data insert failed")
    except Exception as e:
        print(f"[DB-REPL] Replication exception: {e}")

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
    # Mirror update to Neon (best-effort)
    try:
        from database import mirror_to_mysql

        set_parts = []
        vals = []
        if container_update.name is not None:
            set_parts.append("name = %s")
            vals.append(container_update.name)
        if container_update.latitude is not None:
            set_parts.append("latitude = %s")
            vals.append(float(container_update.latitude))
        if container_update.longitude is not None:
            set_parts.append("longitude = %s")
            vals.append(float(container_update.longitude))

        if set_parts:
            # update updated_at to match primary's current timestamp
            set_parts.append("updated_at = %s")
            vals.append(db_container.updated_at.isoformat() if db_container.updated_at is not None else None)
            vals.append(int(db_container.id))
            mirror_to_mysql(f"UPDATE containers SET {', '.join(set_parts)} WHERE id = %s", tuple(vals))
    except Exception as e:
        print(f"[DB-REPL] Container update replication exception: {e}")

    return db_container


def delete_container(db: Session, container_id: int):
    """Delete a container."""
    db_container = get_container_by_id(db, container_id)
    if not db_container:
        return False
    
    db.delete(db_container)
    db.commit()
    # Mirror delete cascade to Neon (best-effort)
    try:
        from database import mirror_to_mysql

        # Attempt to delete dependent rows first, then container
        mirror_to_mysql("DELETE FROM container_sensor_history WHERE container_id = %s", (int(container_id),))
        mirror_to_mysql("DELETE FROM feeding_schedules WHERE container_id = %s", (int(container_id),))
        mirror_to_mysql("DELETE FROM container_workers WHERE container_id = %s", (int(container_id),))
        mirror_to_mysql("DELETE FROM container_data WHERE container_id = %s", (int(container_id),))
        mirror_to_mysql("DELETE FROM containers WHERE id = %s", (int(container_id),))
    except Exception as e:
        print(f"[DB-REPL] Container delete replication exception: {e}")

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
        # Mirror association to Neon (best-effort)
        try:
            from database import mirror_to_mysql

            mirror_to_mysql(
                "INSERT INTO container_workers (container_id, worker_id) VALUES (%s, %s) ON CONFLICT (container_id, worker_id) DO NOTHING",
                (int(container_id), int(worker_id)),
            )
        except Exception as e:
            print(f"[DB-REPL] container_workers replication exception: {e}")
    
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
        # Mirror deletion from Neon (best-effort)
        try:
            from database import mirror_to_mysql

            mirror_to_mysql(
                "DELETE FROM container_workers WHERE container_id = %s AND worker_id = %s",
                (int(container_id), int(worker_id)),
            )
        except Exception as e:
            print(f"[DB-REPL] container_workers delete replication exception: {e}")

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
    # Mirror to Neon (best-effort)
    try:
        from database import mirror_to_mysql

        inv_query = (
            "INSERT INTO worker_invitations (id, admin_id, worker_id, status, created_at, responded_at) "
            "VALUES (%s, %s, %s, %s, %s, %s) ON CONFLICT (id) DO NOTHING"
        )
        inv_vals = (
            int(invitation.id),
            int(invitation.admin_id),
            int(invitation.worker_id),
            invitation.status,
            invitation.created_at.isoformat() if invitation.created_at is not None else None,
            invitation.responded_at.isoformat() if invitation.responded_at is not None else None,
        )
        ok = mirror_to_mysql(inv_query, inv_vals)
        if not ok:
            print("[DB-REPL] Neon worker_invitation insert failed")
    except Exception as e:
        print(f"[DB-REPL] WorkerInvitation replication exception: {e}")

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
    # Mirror status change to Neon (best-effort)
    try:
        from database import mirror_to_mysql
        mirror_to_mysql(
            "UPDATE worker_invitations SET status = %s, responded_at = %s WHERE id = %s",
            (invitation.status, invitation.responded_at.isoformat() if invitation.responded_at is not None else None, int(invitation.id)),
        )
    except Exception as e:
        print(f"[DB-REPL] WorkerInvitation respond replication exception: {e}")

    return invitation


def revoke_worker_invitation(db: Session, admin_id: int, worker_id: int):
    """Revoke (delete) an accepted worker invitation by admin."""
    invitation = (
        db.query(WorkerInvitation)
        .filter(
            WorkerInvitation.admin_id == admin_id,
            WorkerInvitation.worker_id == worker_id,
            WorkerInvitation.status == "ACCEPTED",
        )
        .first()
    )
    if not invitation:
        return False

    db.delete(invitation)
    db.commit()
    # Mirror delete to Neon (best-effort)
    try:
        from database import mirror_to_mysql
        mirror_to_mysql(
            "DELETE FROM worker_invitations WHERE admin_id = %s AND worker_id = %s AND status = %s",
            (int(admin_id), int(worker_id), "ACCEPTED"),
        )
    except Exception as e:
        print(f"[DB-REPL] WorkerInvitation revoke replication exception: {e}")

    return True


# ==================== CONTAINER DATA FUNCTIONS ====================

def get_container_data(db: Session, container_id: int):
    """Get container data by container ID."""
    return db.query(ContainerData).filter(ContainerData.container_id == container_id).first()


def get_latest_sensor_history_value(db: Session, container_id: int, sensor_type: str):
    """Get the most recent history value for a sensor type."""
    return (
        db.query(ContainerSensorHistory)
        .filter(
            ContainerSensorHistory.container_id == container_id,
            ContainerSensorHistory.sensor_type == sensor_type,
        )
        .order_by(ContainerSensorHistory.recorded_at.desc(), ContainerSensorHistory.id.desc())
        .first()
    )


def record_container_sensor_history_snapshot(db: Session, container_id: int, data: ContainerData):
    """Store the latest sensor readings if they changed since the last sample."""
    sensor_values = {
        "temperature": data.temperature,
        "humidity": data.humidity,
        "light_level": data.light_level,
        "gas_level": data.gas_level,
    }

    created = False
    now = datetime.utcnow()
    for sensor_type, value in sensor_values.items():
        if value is None:
            continue

        latest = get_latest_sensor_history_value(db, container_id, sensor_type)
        latest_value = latest.value if latest else None
        if latest_value == value:
            continue

        db_entry = ContainerSensorHistory(
            container_id=container_id,
            sensor_type=sensor_type,
            value=value,
        )
        db.add(db_entry)
        
        # Mirror to MySQL (best-effort)
        mirror_to_mysql(
            "INSERT INTO container_sensor_history (container_id, sensor_type, value, recorded_at) VALUES (%s, %s, %s, %s)",
            (container_id, sensor_type, value, now),
        )
        
        created = True

    if created:
        db.commit()


def get_container_sensor_history(db: Session, container_id: int, limit: int = 120):
    """Get sensor history entries for a container."""
    return (
        db.query(ContainerSensorHistory)
        .filter(ContainerSensorHistory.container_id == container_id)
        .order_by(ContainerSensorHistory.recorded_at.asc(), ContainerSensorHistory.id.asc())
        .limit(limit)
        .all()
    )


def reconcile_container_actuators(db: Session, container_id: int):
    """Recompute actuator states from current readings/thresholds and persist them."""
    db_data = get_container_data(db, container_id)
    if not db_data:
        return None

    _apply_automatic_actuator_logic(db_data)
    db.commit()
    db.refresh(db_data)
    return db_data


def update_container_data(
    db: Session,
    container_id: int,
    data_update: ContainerDataUpdate,
    apply_automatic_logic: bool = True,
):
    """Update container data."""
    db_data = get_container_data(db, container_id)
    if not db_data:
        # Create new data if doesn't exist
        db_data = ContainerData(container_id=container_id)
        db.add(db_data)
    
    has_sensor_or_threshold_updates = any(
        value is not None
        for value in (
            data_update.temperature,
            data_update.humidity,
            data_update.light_level,
            data_update.gas_level,
            data_update.target_temperature,
            data_update.target_temperature_min,
            data_update.target_humidity,
            data_update.target_humidity_min,
            data_update.target_light_level,
            data_update.target_light_level_min,
            data_update.target_gas_level,
            data_update.target_gas_level_min,
        )
    )

    # Track fields for MySQL mirror
    mysql_updates = {}

    # Update fields
    manual_overrides: set[str] = set()

    if data_update.temperature is not None:
        db_data.temperature = data_update.temperature
        mysql_updates['temperature'] = data_update.temperature
    if data_update.humidity is not None:
        db_data.humidity = data_update.humidity
        mysql_updates['humidity'] = data_update.humidity
    if data_update.light_level is not None:
        db_data.light_level = data_update.light_level
        mysql_updates['light_level'] = data_update.light_level
    if data_update.gas_level is not None:
        db_data.gas_level = data_update.gas_level
        mysql_updates['gas_level'] = data_update.gas_level
    if data_update.heater_status is not None:
        db_data.heater_status = data_update.heater_status
        mysql_updates['heater_status'] = data_update.heater_status
        if not has_sensor_or_threshold_updates:
            manual_overrides.add("heater_status")
    if data_update.fan_status is not None:
        db_data.fan_status = data_update.fan_status
        mysql_updates['fan_status'] = data_update.fan_status
        if not has_sensor_or_threshold_updates:
            manual_overrides.add("fan_status")
    if data_update.light_status is not None:
        db_data.light_status = data_update.light_status
        mysql_updates['light_status'] = data_update.light_status
        if not has_sensor_or_threshold_updates:
            manual_overrides.add("light_status")
    if data_update.humidifier_status is not None:
        db_data.humidifier_status = data_update.humidifier_status
        mysql_updates['humidifier_status'] = data_update.humidifier_status
        if not has_sensor_or_threshold_updates:
            manual_overrides.add("humidifier_status")
    if data_update.target_temperature is not None:
        db_data.target_temperature = data_update.target_temperature
        mysql_updates['target_temperature'] = data_update.target_temperature
    if data_update.target_temperature_min is not None:
        db_data.target_temperature_min = data_update.target_temperature_min
        mysql_updates['target_temperature_min'] = data_update.target_temperature_min
    if data_update.target_humidity is not None:
        db_data.target_humidity = data_update.target_humidity
        mysql_updates['target_humidity'] = data_update.target_humidity
    if data_update.target_humidity_min is not None:
        db_data.target_humidity_min = data_update.target_humidity_min
        mysql_updates['target_humidity_min'] = data_update.target_humidity_min
    if data_update.target_light_level is not None:
        db_data.target_light_level = data_update.target_light_level
        mysql_updates['target_light_level'] = data_update.target_light_level
    if data_update.target_light_level_min is not None:
        db_data.target_light_level_min = data_update.target_light_level_min
        mysql_updates['target_light_level_min'] = data_update.target_light_level_min
    if data_update.target_gas_level is not None:
        db_data.target_gas_level = data_update.target_gas_level
        mysql_updates['target_gas_level'] = data_update.target_gas_level
    if data_update.target_gas_level_min is not None:
        db_data.target_gas_level_min = data_update.target_gas_level_min
        mysql_updates['target_gas_level_min'] = data_update.target_gas_level_min

    if apply_automatic_logic:
        _apply_automatic_actuator_logic(db_data, manual_overrides=manual_overrides)
    
    db.commit()
    db.refresh(db_data)
    
    # Mirror to MySQL (best-effort)
    if mysql_updates:
        set_clause = ", ".join(f"{k} = %s" for k in mysql_updates.keys())
        values = list(mysql_updates.values())
        values.append(container_id)
        mirror_to_mysql(
            f"UPDATE container_data SET {set_clause} WHERE container_id = %s",
            tuple(values),
        )
    
    return db_data


# ==================== FEEDING SCHEDULE FUNCTIONS ====================

def get_feeding_schedules(db: Session, container_id: int):
    """Get feeding schedules for a container ordered by datetime."""
    return (
        db.query(FeedingSchedule)
        .filter(FeedingSchedule.container_id == container_id)
        .order_by(FeedingSchedule.feeding_at.asc())
        .all()
    )


def create_feeding_schedule(db: Session, container_id: int, schedule: FeedingScheduleCreate):
    """Create one feeding schedule for a container."""
    db_schedule = FeedingSchedule(
        container_id=container_id,
        feeding_at=schedule.feeding_at,
        amount=schedule.amount,
    )
    db.add(db_schedule)
    db.commit()
    db.refresh(db_schedule)
    # Mirror to Neon (best-effort)
    try:
        from database import mirror_to_mysql

        qs = (
            "INSERT INTO feeding_schedules (id, container_id, feeding_at, amount, created_at, updated_at) "
            "VALUES (%s, %s, %s, %s, %s, %s) ON CONFLICT (id) DO NOTHING"
        )
        vals = (
            int(db_schedule.id),
            int(db_schedule.container_id),
            db_schedule.feeding_at.isoformat() if db_schedule.feeding_at is not None else None,
            float(db_schedule.amount),
            db_schedule.created_at.isoformat() if db_schedule.created_at is not None else None,
            db_schedule.updated_at.isoformat() if db_schedule.updated_at is not None else None,
        )
        ok = mirror_to_mysql(qs, vals)
        if not ok:
            print("[DB-REPL] Neon feeding_schedule insert failed")
    except Exception as e:
        print(f"[DB-REPL] FeedingSchedule replication exception: {e}")

    return db_schedule


def get_feeding_schedule_by_id(db: Session, schedule_id: int):
    """Get a feeding schedule by ID."""
    return db.query(FeedingSchedule).filter(FeedingSchedule.id == schedule_id).first()


def update_feeding_schedule(db: Session, schedule_id: int, schedule_update: FeedingScheduleUpdate):
    """Update one feeding schedule."""
    db_schedule = get_feeding_schedule_by_id(db, schedule_id)
    if not db_schedule:
        return None

    if schedule_update.feeding_at is not None:
        db_schedule.feeding_at = schedule_update.feeding_at
    if schedule_update.amount is not None:
        db_schedule.amount = schedule_update.amount

    db.commit()
    db.refresh(db_schedule)
    # Mirror update to Neon (best-effort)
    try:
        from database import mirror_to_mysql
        set_parts = []
        vals = []
        if schedule_update.feeding_at is not None:
            set_parts.append("feeding_at = %s")
            vals.append(schedule_update.feeding_at.isoformat())
        if schedule_update.amount is not None:
            set_parts.append("amount = %s")
            vals.append(float(schedule_update.amount))

        if set_parts:
            vals.append(int(db_schedule.id))
            mirror_to_mysql(f"UPDATE feeding_schedules SET {', '.join(set_parts)} WHERE id = %s", tuple(vals))
    except Exception as e:
        print(f"[DB-REPL] FeedingSchedule update replication exception: {e}")

    return db_schedule


def delete_feeding_schedule(db: Session, schedule_id: int):
    """Delete one feeding schedule by ID."""
    db_schedule = get_feeding_schedule_by_id(db, schedule_id)
    if not db_schedule:
        return False

    db.delete(db_schedule)
    db.commit()
    # Mirror delete to Neon (best-effort)
    try:
        from database import mirror_to_mysql
        mirror_to_mysql("DELETE FROM feeding_schedules WHERE id = %s", (int(schedule_id),))
    except Exception as e:
        print(f"[DB-REPL] FeedingSchedule delete replication exception: {e}")

    return True
