# 🦗 Locust Farm Management System

A comprehensive full-stack IoT application for managing locust farms with real-time monitoring and control capabilities. The system includes a **FastAPI** Python backend with a **MySQL** database, and a modern **Flutter** mobile app with responsive UI for Android/iOS/Web platforms.

**Features:**
- 🔐 Secure authentication with JWT tokens
- 📊 Real-time device monitoring and control
- 📱 Cross-platform mobile application (Android, iOS, Web)
- 👥 Role-based access control (Admin & Farmer)
- 🌡️ Environmental sensor integration
- 📅 Schedule management for farm operations
- 📧 User account management and notifications

---

## 📋 Table of Contents

- [Project Overview](#-locust-farm-management-system)
- [Technologies Used](#technologies-used)
- [Project Structure](#project-structure)
- [Getting Started — Backend](#getting-started--backend)
- [Getting Started — Mobile App](#getting-started--mobile-app)
- [Running the Application](#-running-the-application)
- [API Overview](#api-overview)
- [Troubleshooting](#troubleshooting)

---

## 📂 Project Structure

```
Locustapp/
├── pi_mobile/                    # Flutter mobile application
│   ├── lib/
│   │   ├── main.dart            # Application entry point
│   │   ├── app_colors.dart      # Color scheme definitions
│   │   ├── models/              # Data models
│   │   │   └── auth_user.dart
│   │   ├── screens/             # UI screens
│   │   │   ├── main_navigation.dart
│   │   │   ├── home/            # Dashboard screen
│   │   │   ├── controls/        # Device controls
│   │   │   ├── schedule/        # Schedule management
│   │   │   ├── auth/            # Authentication screens
│   │   │   ├── account/         # User account management
│   │   │   ├── ai/              # AI features
│   │   │   ├── food/            # Food distribution
│   │   │   └── notifications/   # Notifications
│   │   ├── services/
│   │   │   └── auth_service.dart
│   │   └── theme/
│   │       └── app_theme.dart
│   ├── assets/                  # Images and resources
│   ├── android/                 # Android configuration
│   ├── ios/                     # iOS configuration
│   ├── web/                     # Web configuration
│   ├── windows/                 # Windows configuration
│   ├── linux/                   # Linux configuration
│   ├── macos/                   # macOS configuration
│   ├── pubspec.yaml            # Flutter dependencies
│   └── README.md               # Flutter app documentation
│
├── backend/                     # FastAPI Python backend
│   ├── main.py                 # FastAPI application
│   ├── auth.py                 # Authentication logic
│   ├── crud.py                 # Database operations
│   ├── models.py               # SQLAlchemy models
│   ├── schemas.py              # Pydantic schemas
│   ├── database.py             # Database configuration
│   ├── init_db.py              # Database initialization
│   ├── create_demo_user.py     # Demo user creation
│   ├── reset_db.py             # Database reset script
│   ├── requirements.txt        # Python dependencies
│   └── README.md               # Backend documentation
│
└── README.md                    # This file
```

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

This will create the database `locust_farm`:

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
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.0+)
- [Android Studio](https://developer.android.com/studio) — **needed for Android emulator or running on Android devices**
- [Xcode](https://developer.apple.com/xcode/) (macOS only) — for iOS development
- Flutter and Dart extensions installed in VS Code
- Google Chrome (for web development)

---

### 1. Install Flutter & Dart Extensions in VS Code

1. Open **VS Code**
2. Go to the **Extensions** panel (`Ctrl + Shift + X`)
3. Search for **Flutter** and click **Install**
   - This will automatically install the **Dart** extension as well
4. Restart VS Code when prompted
5. Verify the installation by opening the terminal and running:

```bash
flutter doctor
```

---

### 2. Verify Flutter Installation

Run the following command to check your Flutter setup:

```bash
flutter doctor
```

You should see checkmarks (✓) next to:
- ✓ Flutter SDK
- ✓ Dart SDK
- ✓ Android Studio / Xcode (depending on your target platform)

You can ignore warnings about IDE plugins if not using Android Studio for development.

---

### 3. Set Up Emulator or Physical Device

**Option A — Android Emulator (Recommended for beginners):**

1. Open **Android Studio**
2. Click **Tools → Device Manager**
3. Click **Create Device**
4. Select a phone model (e.g., **Pixel 6**)
5. Download and select **API 33** (Android 13) or higher
6. Click **Finish** and start the emulator with the **▶ Play** button
7. Keep the emulator running

**Option B — Physical Android Device:**

1. Enable **Developer Mode**: Settings → About → tap Build Number 7 times
2. Enable **USB Debugging**: Settings → Developer Options → USB Debugging
3. Connect your device via USB
4. Run `flutter devices` to verify detection

**Option C — iOS Simulator (macOS only):**

1. Open Terminal and run:
   ```bash
   open -a Simulator
   ```
2. The iOS simulator will launch

**Option D — Chrome Browser (for web):**

1. Google Chrome must be installed
2. No additional setup needed

---

### 4. Run the Flutter App

Navigate to the mobile app directory:

```bash
cd pi_mobile
```

**Run on a specific device:**

```bash
flutter run
```

This will show available devices and prompt you to select one:
```
Connected devices:
Windows (desktop)  • windows      • windows-x64
Chrome (web)       • chrome       • web-javascript
Android Emulator   • emulator-5554 • android-x86
[1]: Windows
[2]: Chrome
[3]: Android Emulator
Please choose one (or 'q' to quit): 
```

**Run directly on specific target:**

```bash
# Run on Android emulator
flutter run -d emulator-5554

# Run on web (Chrome)
flutter run -d chrome

# Run on iOS simulator
flutter run -d booted

# Run on Windows desktop
flutter run -d windows
```

---

## 🚀 Running the Application

### Step 1: Start the Backend Server

```bash
cd backend
pip install -r requirements.txt
python init_db.py
python create_demo_user.py  # Optional: creates demo accounts
uvicorn main:app --reload
```

The backend will be available at: **http://127.0.0.1:8000**

**Swagger UI Documentation**: http://127.0.0.1:8000/docs

### Step 2: Start the Mobile App

In a new terminal:

```bash
cd pi_mobile
flutter run
```

Select your target device from the list.

### Step 3: Log In

Use the demo credentials (if you created them):
- **Admin**: `admin@locust.farm` / `Admin123`
- **Farmer**: `farmer@locust.farm` / `Farmer123`

---

## 📱 Getting Started — Mobile App (Old Version)

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

## 🐛 Troubleshooting

### Backend Issues

**Issue:** `Failed to connect to MySQL database`
```
Solution:
1. Verify MySQL is running (check XAMPP, WAMP, or MySQL Server)
2. Check DB_HOST, DB_USER, DB_PASSWORD in .env file
3. Ensure database 'locust_farm' exists
4. Run: python init_db.py
```

**Issue:** `ModuleNotFoundError: No module named 'fastapi'`
```
Solution:
cd backend
pip install -r requirements.txt
```

**Issue:** `Port 8000 already in use`
```
Solution:
Use a different port: uvicorn main:app --reload --port 8001
Or kill the process using port 8000
```

### Mobile App Issues

**Issue:** `Flutter doctor shows errors`
```
Solution:
1. Run: flutter clean
2. Run: flutter pub get
3. Run: flutter doctor -v (for detailed info)
4. Fix issues as suggested
```

**Issue:** `Android emulator won't start`
```
Solution:
1. Open Android Studio → Device Manager
2. Click dropdown menu → Wipe Data
3. Click Play button to restart
4. Or run: flutter emulators --launch <emulator_name>
```

**Issue:** `App won't connect to backend (ClientException)`
```
Solution:
1. Backend must be running: uvicorn main:app --reload
2. Check your device/emulator can reach http://10.0.2.2:8000
3. On physical device, replace 10.0.2.2 with your PC's IP address
4. Verify no firewall blocking port 8000
```

**Issue:** `Flutter build fails with "Gradle" errors`
```
Solution:
cd pi_mobile
flutter clean
flutter pub get
flutter run
```

**Issue:** `Web app won't load in browser`
```
Solution:
1. Chrome must be installed
2. Run: flutter run -d chrome
3. Check browser console for errors (F12)
4. Clear browser cache if needed
```

### Database Issues

**Issue:** `Database initialization fails`
```
Solution:
1. Ensure MySQL is running
2. Create database manually:
   mysql -u root -p
   CREATE DATABASE locust_farm;
3. Run: python init_db.py
```

**Issue:** `Want to reset database completely`
```
Solution:
cd backend
python reset_db.py
python init_db.py
python create_demo_user.py
```

---

## 📝 Notes

- Never commit your `.env` file to version control — add it to `.gitignore`
- The backend **must** be running before launching the mobile app
- Android Studio is only used to launch the emulator; all coding is done in VS Code
- Run backend scripts in this order: `init_db.py` → `create_demo_user.py` → `uvicorn main:app --reload`
- For physical Android devices, replace `10.0.2.2` with your computer's IP address
- Default demo accounts are created by `create_demo_user.py`
- Use `flutter run` to rebuild and restart the app after making changes
- Keep your Flutter SDK and dependencies updated for best compatibility

---

## 📚 Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [SQLAlchemy Documentation](https://docs.sqlalchemy.org/)
- [MySQL Documentation](https://dev.mysql.com/doc/)
- [Dart Language Guide](https://dart.dev/guides)

---

## 📞 Support

For issues or questions:
1. Check the Troubleshooting section above
2. Review error messages carefully
3. Check the respective documentation links
4. Ensure all prerequisites are installed

---

**Last Updated:** February 2025
**Version:** 1.0.0
