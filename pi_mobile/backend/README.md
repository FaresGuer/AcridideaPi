# Locust Farm Management System - Backend API

FastAPI backend for managing locust farms and workers with user authentication and role-based access control.

## Project Structure

```
backend/
├── __init__.py
├── main.py              # FastAPI application and routes
├── database.py          # Database configuration (SQLAlchemy + PyMySQL)
├── models.py            # SQLAlchemy ORM models
├── schemas.py           # Pydantic schemas
├── crud.py              # CRUD operations
├── auth.py              # Authentication and security
├── init_db.py           # Database initialization script
├── create_demo_user.py  # Demo user creation script
├── requirements.txt     # Python dependencies
└── .env                 # Environment variables
```

## Setup Instructions

### 1. Prerequisites
- Python 3.9+
- MySQL 5.7+ (or MariaDB)
- pip

### 2. Install Dependencies

```bash
cd backend
pip install -r requirements.txt
```

### 3. Configure Environment Variables

Edit `.env` file with your database credentials:

```env
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=locust_farm
SECRET_KEY=your_secret_key_here_change_in_production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
```

### 4. Initialize Database

```bash
# Create database and tables
python init_db.py

# (Optional) Create demo users
python create_demo_user.py
```

### 5. Start the Server

```bash
uvicorn main:app --reload
```

The API will be available at: `http://localhost:8000`

- API Documentation: `http://localhost:8000/docs` (Swagger UI)
- Alternative Docs: `http://localhost:8000/redoc` (ReDoc)

## API Endpoints

### Public Endpoints (No Authentication Required)

#### Register User
```
POST /register
Content-Type: application/json

{
  "email": "user@example.com",
  "full_name": "John Doe",
  "password": "password123",
  "role": "FARMER"  # or "ADMIN"
}

Response: 201 Created
{
  "id": 1,
  "email": "user@example.com",
  "full_name": "John Doe",
  "role": "FARMER",
  "is_active": true,
  "created_at": "2024-02-23T10:00:00"
}
```

#### Login
```
POST /token
Content-Type: application/x-www-form-urlencoded

username=user@example.com&password=password123

Response: 200 OK
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

### Authenticated Endpoints (JWT Required)

#### Get Current User Profile
```
GET /users/me
Authorization: Bearer <access_token>

Response: 200 OK
{
  "id": 1,
  "email": "user@example.com",
  "full_name": "John Doe",
  "role": "FARMER",
  "is_active": true,
  "created_at": "2024-02-23T10:00:00"
}
```

#### Update Current User
```
PUT /users/me
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "full_name": "Jane Doe"  # Can only update own full_name
}

Response: 200 OK
```

### Admin-Only Endpoints

#### List All Users
```
GET /users?skip=0&limit=100
Authorization: Bearer <admin_token>

Response: 200 OK
[
  {
    "id": 1,
    "email": "user@example.com",
    "full_name": "John Doe",
    "role": "FARMER",
    "is_active": true,
    "created_at": "2024-02-23T10:00:00"
  }
]
```

#### Get Specific User
```
GET /users/{user_id}
Authorization: Bearer <admin_token>

Response: 200 OK
```

#### Update User (Admin)
```
PUT /users/{user_id}
Authorization: Bearer <admin_token>
Content-Type: application/json

{
  "full_name": "John Smith",
  "role": "ADMIN",
  "is_active": true
}

Response: 200 OK
```

#### Delete User (Admin)
```
DELETE /users/{user_id}
Authorization: Bearer <admin_token>

Response: 204 No Content
```

### Health Check

```
GET /health

Response: 200 OK
{
  "status": "ok",
  "service": "Locust Farm Management API"
}
```

## Database Schema

### Users Table

```sql
CREATE TABLE users (
  id INT PRIMARY KEY AUTO_INCREMENT,
  email VARCHAR(255) UNIQUE NOT NULL,
  full_name VARCHAR(255) NOT NULL,
  hashed_password VARCHAR(255) NOT NULL,
  role VARCHAR(50) DEFAULT 'FARMER',
  is_active BOOLEAN DEFAULT TRUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

## Business Rules

1. **Email Uniqueness**: Emails must be unique; registration fails if email exists
2. **Role-Based Access**: Only ADMIN users can access admin endpoints
3. **Self-Protection**: Users cannot delete or deactivate their own accounts
4. **Role Management**: Users cannot change their own role (admin must do it)
5. **Inactive Protection**: Inactive users cannot log in
6. **No Password in Response**: Passwords are never returned in any API response

## Authentication

- **Method**: JWT Bearer Token (OAuth2)
- **Hash Algorithm**: pbkdf2_sha256
- **Token Expiration**: 30 minutes (configurable in .env)
- **Store Token**: Include in `Authorization: Bearer <token>` header

## Demo Users

After running `create_demo_user.py`:

| Email | Password | Role |
|-------|----------|------|
| admin@locust.farm | Admin123 | ADMIN |
| farmer@locust.farm | Farmer123 | FARMER |

## Error Handling

- **400 Bad Request**: Invalid input or duplicate email
- **401 Unauthorized**: Invalid or expired token
- **403 Forbidden**: Insufficient permissions
- **404 Not Found**: Resource not found
- **500 Internal Server Error**: Server-side error

## Testing with cURL

```bash
# Register
curl -X POST "http://localhost:8000/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "full_name": "Test User",
    "password": "password123",
    "role": "FARMER"
  }'

# Login
curl -X POST "http://localhost:8000/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=test@example.com&password=password123"

# Get current user
curl -X GET "http://localhost:8000/users/me" \
  -H "Authorization: Bearer <access_token>"
```

## Security Considerations

1. Change `SECRET_KEY` in production
2. Use HTTPS in production
3. Set `allow_origins` to specific domains in CORS configuration
4. Use strong passwords for database credentials
5. Keep dependencies updated: `pip install --upgrade -r requirements.txt`

## Troubleshooting

### "Connection refused" Error
- Ensure MySQL is running
- Check DB_HOST, DB_USER, DB_PASSWORD in .env

### "Table doesn't exist" Error
- Run `python init_db.py` to create tables

### "Email already registered" Error
- The email is already in the database
- Use a different email or delete the user from the database

## Development

To enable SQL query logging, set `echo=True` in `database.py`:

```python
engine = create_engine(
    DATABASE_URL,
    echo=True,  # Enable query logging
)
```

## License

MIT
