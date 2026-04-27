from pydantic import BaseModel, EmailStr, ConfigDict, field_validator
from typing import Optional, List
from datetime import datetime

class UserCreate(BaseModel):
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
    id: int
    email: str
    full_name: str
    role: str
    is_active: bool
    role_selected: bool
    two_factor_enabled: bool

    model_config = ConfigDict(from_attributes=True)

class ContainerCreate(BaseModel):
    name: str
    latitude: float
    longitude: float

class ContainerUpdate(BaseModel):
    name: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None

class ContainerDataUpdate(BaseModel):
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

class ContainerResponse(BaseModel):
    id: int
    name: str
    created_by: int
    latitude: float
    longitude: float
    created_at: datetime
    updated_at: Optional[datetime] = None
    creator: UserResponse
    workers: List[UserResponse]
    data: Optional[ContainerDataResponse] = None

    model_config = ConfigDict(from_attributes=True)

class Token(BaseModel):
    access_token: Optional[str] = None
    token_type: str
    requires_two_factor: bool = False
    verification_token: Optional[str] = None
    message: Optional[str] = None

class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str

class TokenData(BaseModel):
    email: Optional[str] = None

ContainerResponse.model_rebuild()
