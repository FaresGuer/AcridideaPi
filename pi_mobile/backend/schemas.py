from pydantic import BaseModel, EmailStr, ConfigDict, field_validator
from typing import Optional


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
    full_name: Optional[str] = None
    role: Optional[str] = None
    is_active: Optional[bool] = None

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

    model_config = ConfigDict(from_attributes=True)


class Token(BaseModel):
    """Schema for token response."""
    access_token: str
    token_type: str


class TokenData(BaseModel):
    """Schema for token data."""
    email: Optional[str] = None
