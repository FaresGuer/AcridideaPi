from pydantic import BaseModel, EmailStr, ConfigDict, field_validator
from typing import Optional, List
from datetime import datetime


class UserCreate(BaseModel):
    """Schema for creating a new user."""
    email: EmailStr
    full_name: str
    password: str
    role: str = "FARMER"

    @field_validator("role")
    @classmethod
    def validate_role(cls, v):
        if v not in ["ADMIN", "FARMER"]:
            raise ValueError("Role must be ADMIN or FARMER")
        return v


class UserUpdate(BaseModel):
    """Schema for updating user information."""
    email: Optional[EmailStr] = None
    full_name: Optional[str] = None
    role: Optional[str] = None
    is_active: Optional[bool] = None
    role_selected: Optional[bool] = None
    two_factor_enabled: Optional[bool] = None

    @field_validator("role")
    @classmethod
    def validate_role(cls, v):
        if v is not None and v not in ["ADMIN", "FARMER"]:
            raise ValueError("Role must be ADMIN or FARMER")
        return v


class UserResponse(BaseModel):
    """Schema for user response (no password)."""
    id: int
    email: str
    full_name: str
    role: str
    is_active: bool
    role_selected: bool
    two_factor_enabled: bool

    model_config = ConfigDict(from_attributes=True)


class ContainerCreate(BaseModel):
    """Schema for creating a new container."""
    name: str
    latitude: float
    longitude: float


class ContainerUpdate(BaseModel):
    """Schema for updating a container."""
    name: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class ContainerResponse(BaseModel):
    """Schema for container response."""
    id: int
    name: str
    created_by: int
    latitude: float
    longitude: float
    created_at: datetime
    updated_at: Optional[datetime] = None
    creator: UserResponse
    workers: List[UserResponse]
    data: Optional['ContainerDataResponse'] = None

    model_config = ConfigDict(from_attributes=True)


class ContainerSimple(BaseModel):
    """Schema for container response (simplified, no nested users)."""
    id: int
    name: str
    created_by: int
    latitude: float
    longitude: float
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ContainerDataUpdate(BaseModel):
    """Schema for updating container data."""
    temperature: Optional[float] = None
    humidity: Optional[float] = None
    light_level: Optional[float] = None
    gas_level: Optional[float] = None
    heater_status: Optional[bool] = None
    fan_status: Optional[bool] = None
    light_status: Optional[bool] = None
    humidifier_status: Optional[bool] = None
    target_temperature: Optional[float] = None
    target_temperature_min: Optional[float] = None
    target_humidity: Optional[float] = None
    target_humidity_min: Optional[float] = None
    target_light_level: Optional[float] = None
    target_light_level_min: Optional[float] = None
    target_gas_level: Optional[float] = None
    target_gas_level_min: Optional[float] = None


class ContainerDataResponse(BaseModel):
    """Schema for container data response."""
    id: int
    container_id: int
    temperature: Optional[float] = None
    humidity: Optional[float] = None
    light_level: Optional[float] = None
    gas_level: Optional[float] = None
    heater_status: bool
    fan_status: bool
    light_status: bool
    humidifier_status: bool
    target_temperature: Optional[float] = None
    target_temperature_min: Optional[float] = None
    target_humidity: Optional[float] = None
    target_humidity_min: Optional[float] = None
    target_light_level: Optional[float] = None
    target_light_level_min: Optional[float] = None
    target_gas_level: Optional[float] = None
    target_gas_level_min: Optional[float] = None
    last_updated: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class ContainerSensorHistoryResponse(BaseModel):
    """Schema for a sensor history entry."""
    id: int
    container_id: int
    sensor_type: str
    value: float
    recorded_at: datetime

    model_config = ConfigDict(from_attributes=True)


class FeedingScheduleCreate(BaseModel):
    feeding_at: datetime
    amount: float


class FeedingScheduleUpdate(BaseModel):
    feeding_at: Optional[datetime] = None
    amount: Optional[float] = None


class FeedingScheduleResponse(BaseModel):
    id: int
    container_id: int
    feeding_at: datetime
    amount: float
    created_at: datetime
    updated_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class WorkerInvitationCreate(BaseModel):
    """Schema for sending a worker invitation by email."""
    email: EmailStr


class WorkerInvitationRespond(BaseModel):
    """Schema for worker response to invitation."""
    action: str

    @field_validator("action")
    @classmethod
    def validate_action(cls, v):
        if v not in ["ACCEPT", "REJECT"]:
            raise ValueError("Action must be ACCEPT or REJECT")
        return v


class WorkerInvitationResponse(BaseModel):
    """Schema for worker invitation response."""
    id: int
    admin_id: int
    worker_id: int
    status: str
    created_at: datetime
    responded_at: Optional[datetime] = None
    admin: UserResponse
    worker: UserResponse

    model_config = ConfigDict(from_attributes=True)


class Token(BaseModel):
    """Schema for token response."""
    access_token: Optional[str] = None
    token_type: str
    requires_two_factor: bool = False
    verification_token: Optional[str] = None
    message: Optional[str] = None


class ChangePasswordRequest(BaseModel):
    """Schema for changing current user's password."""
    current_password: str
    new_password: str


class TwoFactorVerifyRequest(BaseModel):
    """Schema for completing 2FA challenge."""
    verification_token: str
    code: str


class ForgotPasswordRequest(BaseModel):
    """Schema for requesting a password reset code."""
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    """Schema for resetting password with verification code."""
    reset_token: str
    code: str
    new_password: str


class TokenData(BaseModel):
    """Schema for token data."""
    email: Optional[str] = None


ContainerResponse.model_rebuild()
