# HealthSync

HealthSync is a state-of-the-art Flutter mobile application designed for real-time physical activity and physiological vital monitoring. It integrates seamlessly with custom ESP32 hardware using Bluetooth Low Energy (BLE) to deliver accurate step counts, heart rates, blood oxygen levels (SpO2), and ambient temperature data. 

The application is built using a robust, clean feature-sliced architecture and utilizes modern Flutter development patterns.

---

## 📱 Key Features

- **Live Physiological Monitoring**: Real-time telemetry tracking Heart Rate (BPM) and Blood Oxygen Saturation (SpO2) synced instantly over BLE.
- **Activity & Step Tracking**: Tracks steps, active minutes, and estimated calories burned, pulling data from physical accelerometer sensors or device fallback.
- **Historical Analytics**: Interactive visual analytics displaying daily and weekly historical vitals and activities via responsive charts.
- **Goals & Progress Tracker**: Custom goal configuration for daily steps, active time, and calorie burned milestones, coupled with animated circular progress indicators.
- **Smart Alerts & Notifications**: Automatic warnings for anomalous vital signs (high/low heart rate, critical SpO2 levels) and goal achievements.
- **Developer Simulator Screen**: Built-in developer dashboard allowing testing of BLE subscriptions and system behaviors with mock telemetry waveforms (no hardware required).
- **Modern Glassmorphic UI**: Premium aesthetics using smooth gradients, dark mode support, subtle micro-animations, and glassmorphism.

---

## 🛠️ Tech Stack & Dependencies

### Core Framework & State Management
- **Flutter & Dart SDK**: Build cross-platform iOS & Android clients.
- **Riverpod (`flutter_riverpod`)**: Reactive caching and state management system.
- **GoRouter (`go_router`)**: Declarative, type-safe navigation and screen routing.

### Data & Connectivity
- **Isar Database (`isar`)**: High-performance local document database for local caching and offline availability.
- **Flutter Blue Plus (`flutter_blue_plus`)**: Core library for BLE scanning, GATT service connection, and characteristic subscription.
- **Dio (`dio`)**: Robust HTTP client for remote server requests.

### Backend Integrations (Firebase)
- **Firebase Auth**: Secure client authentication.
- **Cloud Firestore**: Cloud database syncing.
- **Firebase Analytics & Crashlytics**: Usage telemetry and error monitoring.
- **Firebase Cloud Messaging (FCM)**: Remote push notifications.

### User Interface & Visuals
- **FL Chart (`fl_chart`)**: Responsive graphs for historical health analytics.
- **Lottie (`lottie`)**: High-fidelity vector animations.
- **Google Fonts (`google_fonts`)**: Premium typography styling.

---

## 🔌 Hardware Integration (ESP32)

HealthSync connects to a custom ESP32 client equipped with:
1. **MAX30102**: I2C Pulse Oximeter and Heart-Rate Sensor.
2. **MPU6050**: I2C 3-axis Accelerometer & Gyroscope.

### I2C Wire Connections
- **SDA**: GPIO 21
- **SCL**: GPIO 22
- **Power**: 3.3V VCC & Common Ground

### BLE GATT Service & Characteristics
HealthSync scans and connects to a BLE service with the following UUID properties:

| Characteristic | UUID | Mode | Description |
|---|---|---|---|
| **Service** | `0000A000-0000-1000-8000-00805F9B34FB` | - | Primary GATT Service |
| **Heart Rate** | `0000A001-0000-1000-8000-00805F9B34FB` | Notify | BPM Value (uint8) |
| **Step Count** | `0000A002-0000-1000-8000-00805F9B34FB` | Notify | Total cumulative steps (uint32) |
| **SpO2** | `0000A003-0000-1000-8000-00805F9B34FB` | Notify | Blood Oxygen Saturation % (uint8) |
| **Temperature** | `0000A004-0000-1000-8000-00805F9B34FB` | Notify | Body Temperature in Celsius (float) |
| **Battery Level**| `0000A005-0000-1000-8000-00805F9B34FB` | Read/Notify | Device Battery Capacity % (uint8) |
| **Device Info** | `0000A006-0000-1000-8000-00805F9B34FB` | Read | Static hardware & firmware info |

*Note: For firmware deployment code and libraries, refer to the [README_ESP32.md](README_ESP32.md) file.*

---

## 📂 Project Architecture

The directory layout follows a clean, modular structure:

```text
lib/
├── core/
│   ├── config/          # Global configurations, including GoRouter (routes.dart)
│   ├── theme/           # App-wide visual styles and themes (app_theme.dart)
│   ├── services/        # Singleton services:
│   │   ├── ble/         # Mock & Real Bluetooth Low Energy service layers
│   │   ├── database/    # Isar Database models and helper scripts
│   │   └── notifications/ # Alert dispatcher services
│   └── utils/           # Math & BLE byte-parsing utilities (BMI, Calorie conversion)
├── features/            # Feature-sliced component layouts:
│   ├── activity/        # Activity logs, step count monitors
│   ├── analytics/       # Historical charts and graphical summaries
│   ├── authentication/  # Login, Sign Up, Splash, Onboarding screens
│   ├── dashboard/       # Core app hub & Live telemetry feed (LiveMonitor)
│   ├── device/          # BLE Scan, Connection & Sync status UI
│   ├── goals/           # Step, Calorie, and Activity duration targets
│   ├── notifications/   # System-wide alert feeds
│   ├── profile/         # User bio data configuration
│   └── settings/        # App controls, theme toggle, Dev Simulator Screen
└── shared/              # Reusable app UI widgets (GlassCard, ProgressRing, loaders)
