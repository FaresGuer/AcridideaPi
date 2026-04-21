"""
Backend minimaliste LocustFarm pour test
"""
from fastapi import FastAPI, HTTPException, Form
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from datetime import datetime, timedelta
import jwt

# Configuration
SECRET_KEY = "your-secret-key-change-in-production"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

app = FastAPI(title="LocustFarm API")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Models
class Token(BaseModel):
    access_token: str
    token_type: str

class User(BaseModel):
    email: str
    full_name: str = "Test User"
    role: str = "farmer"

# Fake database - simple password check
FAKE_USERS_DB = {
    "test@locustfarm.com": {
        "email": "test@locustfarm.com",
        "full_name": "Test User",
        "password": "test123",
        "role": "farmer"
    }
}

def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

@app.get("/")
def read_root():
    return {"message": "Locust Farming API is running", "status": "ok"}

@app.post("/token", response_model=Token)
def login(username: str = Form(...), password: str = Form(...)):
    """Login endpoint - accepts form data"""
    user = FAKE_USERS_DB.get(username)
    if not user or user["password"] != password:
        raise HTTPException(
            status_code=401,
            detail="Incorrect username or password"
        )

    access_token = create_access_token(data={"sub": user["email"]})
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/users/me", response_model=User)
def read_users_me():
    """Get current user - returns test user for now"""
    return User(
        email="test@locustfarm.com",
        full_name="Test User",
        role="farmer"
    )

if __name__ == "__main__":
    import uvicorn
    print("=" * 60)
    print("🚀 Starting LocustFarm Backend")
    print("=" * 60)
    print("📧 Test credentials:")
    print("   Email:    test@locustfarm.com")
    print("   Password: test123")
    print("=" * 60)
    uvicorn.run(app, host="0.0.0.0", port=8000)


