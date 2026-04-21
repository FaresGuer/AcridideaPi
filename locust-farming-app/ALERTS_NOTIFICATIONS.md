# ✅ Real-Time Alerts & Notifications System

## 🎯 Features Implemented

### 1️⃣ Real-Time Alert Generation ✓
- Monitors all containers every 5 seconds
- Generates alerts when sensor values enter Warning or Critical zones
- **Thresholds**:
  - **Temperature**: Critical < 15°C or > 35°C | Warning < 20°C or > 30°C
  - **Humidity**: Critical < 20% or > 95% | Warning < 40% or > 80%
  - **Luminosity**: Critical < 100 Lux or > 1000 Lux | Warning < 300 Lux or > 900 Lux

### 2️⃣ Notification Bell with Counter ✓
- Bell icon in top-right header
- **Red badge** showing total notification count
- Shows "9+" if more than 9 notifications
- Notification counter dynamically updates

### 3️⃣ Notification Panel ✓
- Click bell icon to open/close
- Shows last 10 notifications
- Each notification displays:
  - Sensor icon (colored)
  - Alert title and description
  - Source container name
  - Timestamp
- Link to "View All Alerts" if > 10 notifications

### 4️⃣ Clear All Button ✓
- "Clear All" button in notification panel
- Clears all notifications at once
- Shows notification count
- Button only visible if notifications exist

### 5️⃣ Dynamic Alerts Page ✓
- **Source Node** shows **container name** (not mock data)
- Alerts update in real-time
- Filter by severity: All, Critical, Warning, System
- Search by title, description, source
- Pagination and count display
- Summary stats with progress bars

---

## 🏗️ Technical Architecture

### New Files Created

```
src/
├── context/
│   └── NotificationContext.jsx       # Global notification state
├── services/
│   └── alertService.js               # Alert generation logic
├── hooks/
│   └── useContainerMonitoring.js     # Container monitoring hook
```

### Modified Files

```
src/
├── App.jsx                           # Added NotificationProvider
├── pages/
│   └── Alerts.jsx                    # Dynamic alerts from notifications
│   └── Dashboard.jsx                 # Added monitoring hook
└── components/
    └── MainLayout.jsx                # Added notification bell + panel
```

---

## 📊 Alert System Flow

```
1. Dashboard Loads
   ↓
2. useContainerMonitoring Hook Activates
   ↓
3. Every 5 seconds:
   - Fetch all containers
   - Get sensor data for each container
   - Generate alerts based on thresholds
   - Add to global notifications state
   ↓
4. Notifications automatically appear:
   - Bell counter updates
   - Notification panel updates
   - Alerts page gets new entries
   ↓
5. User can:
   - View notifications in panel
   - Open Alerts page for details
   - Clear all notifications
   - Filter & search alerts
```

---

## 🎨 UI Components

### Notification Bell
- Location: Top-right header
- Red badge with count
- Click to toggle panel
- Only shows if notifications exist

### Notification Panel
```
┌─────────────────────────────┐
│ Notifications (N)    [Clear] │
├─────────────────────────────┤
│ 🌡️ Temperature Critical      │
│    Value: 38°C              │
│    Container: Greenhouse-A  │
│    10:42:15 AM              │
├─────────────────────────────┤
│ 💧 Humidity Warning         │
│    Value: 88%               │
│    Container: Greenhouse-B  │
│    10:35:22 AM              │
├─────────────────────────────┤
│      View All Alerts →       │
└─────────────────────────────┘
```

### Alerts Page Enhancements
- Real-time data (not mocked)
- Source Node = Container Name
- Color-coded icons by sensor type
- Summary stats:
  - Critical count with progress bar
  - Warning count with progress bar
  - System count with progress bar
- Search and filter functionality
- Theme-aware (light/dark mode)

---

## 🔧 Configuration

### Alert Thresholds
Location: `src/services/alertService.js`

```javascript
ALERT_THRESHOLDS = {
  temperature: {
    critical: { min: 15, max: 35 },
    warning: { min: 20, max: 30 },
  },
  humidity: {
    critical: { min: 20, max: 95 },
    warning: { min: 40, max: 80 },
  },
  light_level: {
    critical: { min: 100, max: 1000 },
    warning: { min: 300, max: 900 },
  },
}
```

### Monitoring Interval
Location: `src/hooks/useContainerMonitoring.js`
```javascript
const timer = setInterval(checkContainers, 5000); // 5 seconds
```

### Notification Deduplication
Max one alert per sensor per severity every 30 seconds (prevents spam)

---

## ✨ Key Features

| Feature | Description |
|---------|-------------|
| **Auto-Detection** | Monitors all containers automatically |
| **Real-Time** | Updates every 5 seconds |
| **Smart Dedup** | Prevents duplicate notifications |
| **Source Info** | Shows container name in alerts |
| **Theme Support** | Works in light and dark modes |
| **Responsive** | Panel scales on mobile |
| **Persistent** | Notifications stay until cleared |
| **Quick Access** | Bell icon always visible |

---

## 🧪 Testing

### To See Alerts in Action:
1. Open http://localhost:5173/dashboard
2. Monitoring starts automatically
3. Check the bell icon (top-right) for notifications
4. Click bell to see notification panel
5. Go to Alerts page to see all alerts
6. Adjust sensor value ranges in backend to trigger different thresholds

### Test Scenarios:
- **High Temperature**: Value > 30°C triggers Warning
- **Critical Temperature**: Value > 35°C triggers Critical
- **Low Humidity**: Value < 40% triggers Warning
- **High Humidity**: Value > 80% triggers Warning
- **Low Light**: Value < 300 Lux triggers Warning
- **High Light**: Value > 900 Lux triggers Warning

---

## 📝 Next Steps (Optional)

1. **Sound Notifications**: Add notification sounds
2. **Email Alerts**: Send email for critical alerts
3. **Alert History**: Persist alerts to database
4. **Auto-Remediation**: Trigger actions based on alerts
5. **Custom Thresholds**: Per-container threshold configuration
6. **Alert Rules**: Complex rules (e.g., "if temp > 35 AND humidity < 40")
7. **Escalation**: Send to different users based on severity

---

## 🚀 Status

**✅ Complete and Working!**

All features are implemented, tested, and running in real-time.
The app now provides production-ready alerting capabilities.

