# Patrol Management System - Mobile App

A Flutter-based mobile application for security patrol tracking with real-time GPS monitoring and QR code checkpoint scanning.

![Flutter](https://img.shields.io/badge/Flutter-3.35.7-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.9.2-0175C2?logo=dart)


## Features

- 🔐 **User Authentication** - API key-based authentication with role-based access
- 📍 **Real-time GPS Tracking** - Automatic location tracking every 30 seconds
- 📱 **QR Code Scanning** - Quick checkpoint verification using device camera
- 🗺️ **Interactive Maps** - Route visualization with OpenStreetMap
- 📊 **Patrol History** - Complete historical records with detailed maps
- 👤 **Role-based UI** - Separate interfaces for Guards and Administrators
- 📸 **Route Screenshots** - Automatic map capture on patrol completion

## Tech Stack

- **Framework:** Flutter 3.35.7
- **Language:** Dart 3.9.2
- **HTTP Client:** Dio 5.4.0
- **Maps:** flutter_map ^8.2.2
- **QR Scanning:** mobile_scanner 7.1.3
- **GPS Tracking:** geolocator 14.0.2
- **Local Storage:** shared_preferences 2.2.2

## Prerequisites

Before you begin, ensure you have:

- Flutter SDK 3.16 or higher ([Install Flutter](https://docs.flutter.dev/get-started/install))
- Dart SDK 3.2 or higher
- Android Studio (for deployment)
- Android device/emulator
- Access to Odoo backend server

## Installation

### 1. Clone the repository
```bash
git clone https://github.com/YOUR_USERNAME/patrol-mobile-app.git
cd patrol-mobile-app
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Generate code (for JSON serialization)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Configure API endpoint

Open `lib/core/constants/apiConstants.dart` and update the base URL:
```dart
static const String baseUrl = 'http://YOUR_ODOO_SERVER_IP:8070';
```

### 5. Run the app
```bash
flutter run
```


## Project Structure
```
lib/
├── core/
│   ├── api/
│   │   └── dio_client.dart              # HTTP client & interceptors
│   ├── constants/
│   │   ├── api_constants.dart           # API endpoints
│   │   ├── app_colors.dart              # App color theme
│   │   └── app_strings.dart             # String constants
│   └── utils/
│       ├── logger.dart                  # Logging utility
│       └── preferences.dart             # Local storage helper
├── data/
│   ├── models/                          # Data models with JSON serialization
│   │   ├── checkpoint.dart
│   │   ├── patrol_history.dart
│   │   ├── route_config.dart
│   │   └── ...
│   └── services/                        # API & business logic services
│       ├── patrol_api_service.dart      # Patrol API calls
│       ├── admin_api_service.dart       # Admin API calls
│       ├── gps_service.dart             # GPS tracking service
│       └── map_screenshot_service.dart  # Map capture utility
└── presentation/
    └── screens/                         # UI screens
        ├── login_screen.dart            # User selection screen
        ├── dashboard_screen.dart        # Guard dashboard
        ├── admin_dashboard_screen.dart  # Admin dashboard
        ├── active_patrol_screen.dart    # Active patrol view
        ├── qr_scanner_screen.dart       # QR code scanner
        └── ...
```

## Configuration

### Permissions

The app requires the following permissions (automatically requested at runtime):

- **Location** - For GPS tracking during patrols
- **Camera** - For QR code scanning

### API Integration

The app connects to an Odoo 16 backend. Required API endpoints:

- `POST /api/patrol/start` - Start new patrol session
- `POST /api/patrol/scan` - Record checkpoint scan
- `POST /api/patrol/location` - Update GPS location
- `POST /api/patrol/end` - End patrol session
- `GET /api/patrol/users` - Fetch user list for login
- `GET /api/patrol/routes` - Get routes (admin only)
- `GET /api/patrol/history` - Get patrol history (admin)

See backend repository for complete API documentation.

## Usage

### For Guards

1. **Login:** Select your name from the user list
2. **Start Patrol:** Tap "Start Patrol" button
3. **Review Route:** View assigned checkpoint sequence
4. **Scan Checkpoints:** Use camera to scan QR codes at each checkpoint
5. **View Progress:** Toggle between list and map views
6. **End Patrol:** Tap "End Patrol" when finished

### For Admins

1. **Login:** Select your name (admin badge displayed)
2. **View Dashboard:** See statistics and recent activity
3. **Manage Routes:** Create and configure patrol routes
4. **View History:** Access all patrol records with filters
5. **Monitor Activity:** Track real-time and historical patrols

## Troubleshooting

### Cannot connect to server

**Problem:** App shows connection error

**Solutions:**
- Verify `apiConstants.dart` has correct server IP address
- Ensure Odoo backend is running: `curl http://YOUR_IP:8070/web/login`
- Check firewall settings allow port 8070
- Ensure device and server are on same network (for real devices)

### GPS not working

**Problem:** Location not updating or inaccurate

**Solutions:**
- Enable location permissions in device settings
- Turn on device GPS/Location services
- Move to an area with clear view of sky
- Restart the app
- Check location permission: Settings → Apps → Patrol App → Permissions

### QR scanner not opening

**Problem:** Camera doesn't open or shows black screen

**Solutions:**
- Enable camera permission in device settings
- Ensure adequate lighting
- Clean camera lens
- Close other apps using camera
- Restart the app

### Build errors

**Problem:** Flutter build fails

**Solutions:**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# If still failing, upgrade Flutter
flutter upgrade
```

## Known Issues

- Map screenshot capture may fail on low-memory Android devices
- GPS accuracy varies by device and location conditions
- Offline mode not yet implemented (planned for future release)
- Map rendering may be slow


## Roadmap

- [ ] Offline mode with local SQLite cache
- [ ] Photo capture at checkpoints
- [ ] NFC tag support test
- [ ] Push notifications
- [ ] Biometric authentication
- [ ] Redesign to the login method
- [ ] Switch to GoogleMaps API for better map accuracy
      


## Dependencies

Key dependencies used in this project:
```yaml
dependencies:
  dio: ^5.4.0                    # HTTP client
  geolocator: ^14.0.2            # GPS tracking
  mobile_scanner: ^7.1.3         # QR scanning
  flutter_map: ^8.2.2            # Map display
  latlong2: ^0.9.0               # Coordinate handling
  shared_preferences: ^2.2.2     # Local storage
  intl: ^0.20.2                  # Internationalization
  equatable: ^2.0.5              # Value equality
  json_annotation: ^4.8.1        # JSON serialization
```

See `pubspec.yaml` for complete list.


## Contact

**Developer:** Moez  
**Email:** [daoudi.moez02@gmail.com]  
**GitHub:** [DaoudiMoez](https://github.com/DaoudiMoez)

## Related Projects

**Backend (Odoo Module):** [patrol-odoo-backend](https://github.com/DaoudiMoez/patrol-odoo-module)


**Last Updated:** November 2025  
**Version:** 1.0.0
