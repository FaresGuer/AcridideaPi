# Quick Start Guide - Environmental Charts Feature

## What's New

The dashboard now includes **beautiful interactive charts** for all environmental variables:

### Environmental History Charts
- 📈 **Temperature Chart**: Real-time temperature trends over 24 hours
- 💧 **Humidity Chart**: Humidity level monitoring with smooth curves
- 🌫️ **Air Quality Chart**: AQI (Air Quality Index) visualization
- ☁️ **CO₂ Chart**: Carbon dioxide level tracking

### Chart Features
- Custom-built using Flutter's `CustomPainter` for optimal performance
- Smooth bezier curves for data interpolation
- Gradient fill under curves
- Interactive data points with white borders
- Grid lines for easy reading
- Time labels (00:00 to 24:00)
- Trend indicators showing percentage changes

## Starting the Application

### Prerequisites Check
✅ MySQL running in XAMPP (green indicator)
✅ Python 3.8+ installed
✅ Flutter SDK installed

### Step 1: Start MySQL
1. Open XAMPP Control Panel
2. Click "Start" next to MySQL
3. Verify the indicator turns green

### Step 2: Start Backend

**Open PowerShell in backend directory:**
```powershell
cd D:\Locustapp\pi_mobile\backend
python -m uvicorn main:app --host 127.0.0.1 --port 8000
```

**Or start in a new window:**
```powershell
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd D:\Locustapp\pi_mobile\backend; python -m uvicorn main:app --host 127.0.0.1 --port 8000"
```

✅ Backend should show: `Uvicorn running on http://127.0.0.1:8000`

### Step 3: Launch Flutter App

**Open PowerShell in pi_mobile directory:**
```powershell
cd D:\Locustapp\pi_mobile
flutter run -d chrome
```

✅ App should open automatically in Chrome

### Step 4: Login

Use one of these demo accounts:
- **Admin**: `admin@locust.farm` / `Admin123`
- **Farmer**: `farmer@locust.farm` / `Farmer123`

### Step 5: View Charts

After logging in:
1. Navigate to the **Home/Dashboard** page
2. Scroll down past the Live Camera section
3. You'll see the **Environment** metrics cards
4. Below that, find the **Environmental History** section with 4 beautiful charts:
   - Temperature chart (orange)
   - Humidity chart (blue)
   - Air Quality chart (green)
   - CO₂ chart (purple)

## Troubleshooting

### Backend Won't Start

**Problem**: Port 8000 already in use
```powershell
# Kill Python processes
Get-Process -Name "python" | Stop-Process -Force

# Try starting again
cd D:\Locustapp\pi_mobile\backend
python -m uvicorn main:app --host 127.0.0.1 --port 8000
```

**Problem**: MySQL connection error
- Make sure MySQL is running in XAMPP
- Check port 3306 is free: `netstat -ano | findstr :3306`

**Problem**: Database table errors
```powershell
cd D:\Locustapp\pi_mobile\backend
python full_reset_db.py
python create_demo_fixed.py
```

### Flutter Won't Compile

**Problem**: Dependency issues
```powershell
cd D:\Locustapp\pi_mobile
flutter clean
flutter pub get
flutter run -d chrome
```

**Problem**: Charts not showing
- The charts are built with custom `CustomPainter` - they should work automatically
- Try refreshing the browser (F5)
- Check browser console for errors (F12)

### Login Issues

**Problem**: "Failed to fetch" error
- Verify backend is running: `netstat -ano | findstr :8000`
- Check backend logs in PowerShell window
- Try accessing: http://127.0.0.1:8000/health in browser

**Problem**: "Invalid credentials"
- Use exact credentials: `admin@locust.farm` / `Admin123`
- Or recreate users: `python create_demo_fixed.py`

## Quick Commands Reference

```powershell
# Check if MySQL is running
netstat -ano | findstr :3306

# Check if backend is running
netstat -ano | findstr :8000

# Check running processes
Get-Process -Name "python","dart","chrome" | Format-Table

# Kill all Python processes
Get-Process -Name "python" | Stop-Process -Force

# Kill Flutter processes
Get-Process -Name "dart" | Stop-Process -Force

# Restart everything
Get-Process -Name "python","dart","chrome" | Stop-Process -Force
```

## Chart Data Structure

The charts display mock data points. In production, these would come from your IoT sensors:

### Temperature Data (°C)
- 00:00 → 26.5°C
- 04:00 → 27.2°C
- 08:00 → 28.0°C
- 12:00 → 29.5°C (peak)
- 16:00 → 28.8°C
- 20:00 → 28.2°C
- 24:00 → 27.5°C

### Humidity Data (%)
- 00:00 → 58%
- 04:00 → 60.5%
- 08:00 → 62%
- 12:00 → 65% (peak)
- 16:00 → 63.5%
- 20:00 → 61%
- 24:00 → 60%

### Air Quality (AQI)
- Range: 95 - 125 AQI
- Current: 120 AQI (Moderate)

### CO₂ Levels (ppm)
- Range: 400 - 480 ppm
- Current: 450 ppm (Normal)

## Next Steps

To integrate real sensor data:
1. Create API endpoints in `backend/main.py` for sensor data
2. Update chart data methods in `new_dashboard_screen.dart`
3. Implement periodic data fetching (e.g., every 5 minutes)
4. Add WebSocket support for real-time updates

## Support

If you encounter any issues:
1. Check all prerequisites are met
2. Review the troubleshooting section
3. Examine backend logs in PowerShell
4. Check browser console (F12) for frontend errors

Enjoy your new environmental monitoring charts! 📊🌱

