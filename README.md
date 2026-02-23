# 🦗 Locust Farm Management System

A full-stack IoT application for managing locust farms. The system includes a **FastAPI** Python backend with a **MySQL** database, and a **Flutter** mobile app for Android/iOS.

---

## 📋 Table of Contents

- [Technologies Used](#technologies-used)
- [Project Structure](#project-structure)
- [Getting Started — Backend](#getting-started--backend)
- [Getting Started — Mobile App](#getting-started--mobile-app)
- [API Overview](#api-overview)

---

## 🛠 Technologies Used

### Backend
| Technology | Purpose |
|---|---|
| [Python 3.10+](https://www.python.org/) | Backend language |
| [FastAPI](https://fastapi.tiangolo.com/) | REST API framework |
| [SQLAlchemy](https://www.sqlalchemy.org/) | ORM for database interaction |
| [PyMySQL](https://pymysql.readthedocs.io/) | MySQL driver for Python |
| [MySQL](https://www.mysql.com/) | Relational database |
| [python-jose](https://python-jose.readthedocs.io/) | JWT token generation & validation |
| [passlib](https://passlib.readthedocs.io/) | Password hashing (pbkdf2_sha256) |
| [python-dotenv](https://pypi.org/project/python-dotenv/) | Environment variable management |
| [Uvicorn](https://www.uvicorn.org/) | ASGI server to run FastAPI |

### Mobile
| Technology | Purpose |
|---|---|
| [Flutter](https://flutter.dev/) | Cross-platform mobile framework |
| [Dart](https://dart.dev/) | Programming language for Flutter |
| [VS Code](https://code.visualstudio.com/) | IDE for Flutter development |
| [Android Studio](https://developer.android.com/studio) | Used only for the Android emulator |

---

## 🚀 Getting Started — Backend

### Prerequisites

- Python 3.10 or higher
- MySQL server installed and running locally
- pip (Python package manager)

### 1. Create the MySQL Database

Before running the app, create an empty database called `locust_farm`.

**Option A — Using MySQL Workbench:**
1. Open MySQL Workbench and connect to your local server
2. Click the **"+"** icon next to "MySQL Schemas" in the left panel
3. Name it `locust_farm` and click **Apply**

**Option B — Using the MySQL command line:**
```sql
mysql -u root -p
CREATE DATABASE locust_farm;
EXIT;
```

> ⚠️ The database must exist before running the app. The app will create the tables automatically, but not the database itself.

---

### 2. Configure Environment Variables

Create a `.env` file at the root of the project:

```env
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=locust_farm
SECRET_KEY=your_secret_key_here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
```

> Leave `DB_PASSWORD` empty if your local MySQL has no root password set (default XAMPP/WAMP setup).

---
## For these next steps its prefered to go to the backend folder
```bash
cd backend/
```
---
### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

---

### 4. Initialize the Database

This will create all the tables inside the `locust_farm` database:

```bash
python init_db.py
```

---

### 5. Create Demo Users (Optional)

Seeds one **ADMIN** and one **FARMER** user for testing:

```bash
python create_demo_user.py
```

Default demo credentials:
| Role | Email | Password |
|------|-------|----------|
| Admin | `admin@locust.farm` | `Admin123` |
| Farmer | `farmer@locust.farm` | `Farmer123` |

---

### 6. Start the Backend Server

```bash
uvicorn main:app --reload
```

The API will be available at: **http://127.0.0.1:8000**

Interactive API docs (Swagger UI): **http://127.0.0.1:8000/docs**

---

## 📱 Getting Started — Mobile App

### Prerequisites

- [VS Code](https://code.visualstudio.com/) installed
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed
- [Android Studio](https://developer.android.com/studio) installed — **only needed for the emulator**
- Flutter and Dart extensions installed in VS Code

---

### 1. Install Flutter & Dart Extensions in VS Code

1. Open **VS Code**
2. Go to the **Extensions** panel (`Ctrl + Shift + X`)
3. Search for **Flutter** and click **Install**
   - This will also automatically install the **Dart** extension
4. Restart VS Code when prompted

---

### 2. Set Up the Flutter SDK

If you haven't installed Flutter yet:

1. Download Flutter from [flutter.dev](https://docs.flutter.dev/get-started/install) and extract it somewhere on your machine (e.g. `C:\flutter` on Windows or `~/flutter` on Mac/Linux)
2. Add the Flutter `bin` folder to your system **PATH**
3. Open a terminal in VS Code and verify the installation:

```bash
flutter doctor
```

Fix any issues flagged by `flutter doctor` before continuing. You can ignore the "Android Studio" warning — it is only needed for the emulator, not for development.

---

### 3. Set Up the Android Emulator in Android Studio

> You only need Android Studio for the emulator. All coding is done in VS Code.

1. Open **Android Studio**
2. Go to **Tools → Device Manager**
3. Click **Create Device**
4. Choose a phone model (e.g. **Pixel 6**) and click **Next**
5. Select a system image — download **API 33 (Android 13)** or later if not already available
6. Click **Next → Finish**
7. Press the **▶ Play** button next to your new device to launch the emulator
8. Once the emulator is booted, you can minimize Android Studio — you won't need it anymore

---


### 4. Run the Flutter App from VS Code

1. Make sure the Android emulator is running (launched from Android Studio as described above)
2. Open the `mobile/` folder in VS Code
3. Open the **Command Palette** (`Ctrl + Shift + P`) and run:
   ```
   Flutter: Launch Emulator
   ```
   Choose your running emulator from the list
4. Press **F5** to run the app in debug mode, or run from the terminal:

```bash
cd mobile
flutter run
```

VS Code will build and deploy the app directly to the emulator.

---

## 🔌 API Overview

| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| POST | `/register` | Public | Register a new user |
| POST | `/token` | Public | Login and get JWT token |
| GET | `/users/me` | Authenticated | Get current user profile |
| PUT | `/users/me` | Authenticated | Update own profile |
| GET | `/users/` | Admin only | List all users |
| GET | `/users/{id}` | Admin only | Get a specific user |
| PUT | `/users/{id}` | Admin only | Update any user |
| DELETE | `/users/{id}` | Admin only | Delete a user |

> Full interactive documentation is available at `http://127.0.0.1:8000/docs` when the server is running.

---

## 👥 User Roles

| Role | Permissions |
|------|-------------|
| `ADMIN` | Full access — manage all users, devices, and settings |
| `FARMER` | Standard access — view and interact with assigned devices |

---

## 📝 Notes

- Never commit your `.env` file to version control — add it to `.gitignore`
- The backend must be running before launching the mobile app
- Android Studio is only used to launch the emulator, all coding is done in VS Code
- Run backend scripts in this order: `init_db.py` → `create_demo_user.py` → `uvicorn main:app --reload`
