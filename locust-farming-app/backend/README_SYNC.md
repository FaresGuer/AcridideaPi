# Web/Mobile Backend Sync

This backend is now aligned with the mobile app backend model for:
- MySQL database (primary database)
- same password hashing (`pbkdf2_sha256`)
- same JWT settings (`SECRET_KEY`, `ALGORITHM`)
- shared user/container/container_data structures

## Quick start

1. Copy `.env.example` to `.env` and configure MySQL settings:
   - `MYSQL_HOST=localhost`
   - `MYSQL_PORT=3306`
   - `MYSQL_USER=root`
   - `MYSQL_PASSWORD=` (empty for no password)
   - `MYSQL_DB=locust_farm`
2. Install dependencies:
   - `pip install -r requirements.txt`
3. Initialize database and tables:
   - `python init_db.py`
4. Optionally create test users:
   - `python create_demo_user.py`
5. Run API:
   - `uvicorn main:app --reload --host 127.0.0.1 --port 8000`

## Main endpoints used by web frontend

- `POST /register`
- `POST /token`
- `GET /users/me`
- `GET /containers`
- `GET /containers/{container_id}/data`
- `PUT /containers/{container_id}/data`

With this setup, mobile and web read/write the same data in real time via the same MySQL database.

