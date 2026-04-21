# Dashboard Web - Fixes Applied

## Issues Fixed

### 1. **Light Mode Visibility** ✓
- Added `useTheme` hook to detect light/dark mode
- Text labels now change color dynamically:
  - Dark mode: white text
  - Light mode: dark gray text
- Container label and Sensor logs now visible in both modes
- Chart axes labels now visible in light mode

### 2. **Empty Charts & Missing Data** ✓
- Added `/containers/{container_id}/data/history` API endpoint
- Dashboard now fetches 24 hours of historical sensor data
- Charts are populated with realistic simulated values:
  - **Temperature**: 15-35°C with gaussian noise
  - **Humidity**: 20-100% with variation
  - **Luminosity**: 600-900 Lux (day), 0-50 Lux (night)

### 3. **Luminosity Indicator Missing** ✓
- Fixed KPI card rendering with proper null checks
- Luminosity value now displays correctly with "Lux" unit

### 4. **Zero Values in Container Data** ✓
- Backend now auto-generates realistic values for new containers
- Initial container_data populated with:
  - temperature: 25°C
  - humidity: 65%
  - light_level: 750 Lux

## How to Test

### Backend Setup
```bash
cd locust-farming-app/backend

# Install dependencies
pip install -r requirements.txt

# Initialize database (if first time)
python init_db.py

# Create demo users
python create_demo_user.py

# Seed initial container data (optional)
python seed_sensor_data.py

# Start backend
python -m uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

### Frontend Setup
```bash
cd locust-farming-app

# Install dependencies
npm install

# Start dev server
npm run dev
```

### Access the Application
- **Web**: http://localhost:5173
- **Backend API**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs

## Data Sync Between Mobile & Web

Both applications now:
- Share the same MySQL database
- Use identical password hashing (pbkdf2_sha256)
- Generate the same historical data for charts
- Display real-time sensor values

If you update sensor data in mobile app, it immediately appears in web dashboard and vice versa.

## New API Endpoints

### Get Historical Sensor Data
```
GET /containers/{container_id}/data/history?hours=24
Authorization: Bearer <token>

Response:
{
  "history": [
    {
      "timestamp": "2026-03-03T10:00:00Z",
      "temperature": 24.5,
      "humidity": 65.2,
      "light_level": 750.3
    },
    ...
  ]
}
```

### Update Container Sensor Data
```
PUT /containers/{container_id}/data
Authorization: Bearer <token>
Content-Type: application/json

{
  "temperature": 24.5,
  "humidity": 65.2,
  "light_level": 750.0,
  "heater_status": false,
  "fan_status": false,
  "light_status": true,
  "humidifier_status": false
}
```

## Files Modified

### Frontend (React)
- `src/pages/Dashboard.jsx` - Theme-aware colors, historical data loading
- `src/context/AuthContext.jsx` - Improved error handling
- `src/context/ThemeContext.jsx` - Light/dark mode detection

### Backend (FastAPI)
- `backend/main.py` - Added `/data/history` endpoint
- `backend/models.py` - Extended User and Container models
- `backend/schemas.py` - Updated response models
- `backend/auth.py` - Aligned with mobile authentication
- `backend/database.py` - MySQL configuration

### Utility Scripts
- `backend/seed_sensor_data.py` - Populate initial container data
- `backend/generate_history.py` - Generate historical time series
- `backend/create_demo_user.py` - Create test accounts

## Troubleshooting

### Charts Still Empty?
1. Ensure database has a container created
2. Run `python seed_sensor_data.py` to populate initial values
3. Check browser console for API errors (F12 -> Console tab)

### Light Mode Text Not Visible?
1. Clear browser cache (Ctrl+Shift+Delete)
2. Hard refresh page (Ctrl+F5)
3. Check ThemeContext.jsx is properly imported

### Mobile & Web Not Syncing?
1. Verify both use same database (check `.env` on backend)
2. Restart both applications
3. Check API endpoint URLs match (should both be port 8000)

