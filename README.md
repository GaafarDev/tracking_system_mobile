# Driver Tracking System Mobile

A comprehensive Flutter-based mobile application for driver tracking and management with real-time location monitoring, scheduling, incident reporting, and emergency SOS features. Built with modern UI/UX principles and glass-morphism design.

## 📱 Features

### Core Functionality

- **🔐 Secure Authentication**: Token-based authentication with secure storage
- **📍 Real-time Location Tracking**: Continuous GPS monitoring with background location services
- **📅 Schedule Management**: View and manage daily driving schedules with route optimization
- **🚨 Incident Reporting**: Comprehensive incident reporting with photo capture and location tagging
- **🆘 Emergency SOS**: One-tap emergency alert system with automatic location sharing
- **🔔 Push Notifications**: Real-time notifications for schedules, incidents, and emergency alerts

### User Experience

- **🎨 Modern Glass-morphism UI**: Clean, transparent design with blur effects
- **📱 Responsive Design**: Optimized for all screen sizes and orientations
- **🌓 Theme Support**: Light/dark mode with customizable themes
- **♿ Accessibility**: Screen reader support and high contrast options
- **🌐 Multi-platform**: Native performance across iOS, Android, Windows, Linux, and Web

## 🏗️ Architecture

The application follows **Clean Architecture** principles with separation of concerns:

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │     Screens     │  │     Widgets     │  │    Themes    │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                     Service Layer                          │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │  Auth Service   │  │ Location Service│  │ SOS Service  │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │Schedule Service │  │Incident Service │  │Notification  │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                            │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │     Models      │  │   Repositories  │  │  Local DB    │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Service Architecture

- **[`AuthService`](lib/core/services/auth_service.dart)**: Authentication and user session management
- **[`LocationService`](lib/core/services/location_service.dart)**: GPS tracking and location data processing
- **[`ScheduleService`](lib/core/services/schedule_service.dart)**: Schedule management and route planning
- **[`IncidentService`](lib/core/services/incident_service.dart)**: Incident reporting and management
- **[`SosService`](lib/core/services/sos_service.dart)**: Emergency alert system with location sharing
- **[`NotificationService`](lib/core/services/notification_service.dart)**: Push notifications and alerts

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: `>=3.0.0` (Latest stable recommended)
- **Dart SDK**: `>=3.0.0`
- **Development Environment**:
  - Android Studio / IntelliJ IDEA
  - VS Code with Flutter extension
  - Xcode (for iOS development on macOS)

### System Requirements

| Platform | Requirements                        |
| -------- | ----------------------------------- |
| Android  | Android SDK 21+ (Android 5.0+)      |
| iOS      | iOS 12.0+, Xcode 14+                |
| Windows  | Windows 10 1903+ (Build 18362+)     |
| Linux    | Ubuntu 18.04+, Debian 10+           |
| Web      | Chrome 84+, Firefox 72+, Safari 14+ |

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/GaafarDev/tracking_system_mobile
   cd tracking_system_mobile
   ```

2. **Install Flutter dependencies**

   ```bash
   flutter pub get
   ```

3. **Generate code (if applicable)**

   ```bash
   flutter packages pub run build_runner build
   ```

4. **Platform-specific setup**

   **Android Configuration:**

   Update [`android/app/build.gradle.kts`](android/app/build.gradle.kts):

   ```kotlin
   defaultConfig {
       applicationId = "com.yourcompany.tracking_system_mobile"
       minSdk = 21
       targetSdk = 34
       versionCode = 1
       versionName = "1.0.0"
   }
   ```

   **iOS Configuration:**

   Configure signing in Xcode and update `ios/Runner/Info.plist` for location permissions:

   ```xml
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>This app needs location access for tracking.</string>
   <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
   <string>This app needs location access for continuous tracking.</string>
   ```

5. **Run the application**

   ```bash
   # Debug mode (hot reload enabled)
   flutter run

   # Release mode (optimized performance)
   flutter run --release

   # Platform-specific execution
   flutter run -d android          # Android device/emulator
   flutter run -d ios              # iOS device/simulator
   flutter run -d windows          # Windows desktop
   flutter run -d linux            # Linux desktop
   flutter run -d chrome           # Web browser
   ```

## 🔨 Build Commands

### Mobile Platforms

**Android:**

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (recommended for Play Store)
flutter build appbundle --release

# Split APKs by architecture
flutter build apk --split-per-abi
```

**iOS:**

```bash
# Release build
flutter build ios --release

# Build for specific architecture
flutter build ios --release --no-codesign
```

### Desktop Platforms

**Windows:**

```bash
flutter build windows --release
```

**Linux:**

```bash
flutter build linux --release
```

### Web Platform

```bash
# Production web build
flutter build web --release

# Web build with custom base href
flutter build web --base-href /tracking-system/
```

## ⚙️ Configuration

### Environment Variables

Create environment-specific configuration files:

```
lib/config/
├── development.dart
├── staging.dart
└── production.dart
```

### Required Permissions

The app requires the following permissions based on platform:

#### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.VIBRATE" />
```

#### iOS (`ios/Runner/Info.plist`)

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Location access is required for driver tracking</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Background location is needed for continuous tracking</string>
<key>NSCameraUsageDescription</key>
<string>Camera access for incident photo capture</string>
```

## 📁 Project Structure

```
tracking_system_mobile/
├── lib/
│   ├── main.dart                           # Application entry point
│   ├── core/
│   │   ├── services/                       # Business logic services
│   │   │   ├── auth_service.dart          # Authentication service
│   │   │   ├── location_service.dart      # Location tracking
│   │   │   ├── schedule_service.dart      # Schedule management
│   │   │   ├── incident_service.dart      # Incident reporting
│   │   │   ├── sos_service.dart           # Emergency alerts
│   │   │   └── notification_service.dart  # Push notifications
│   │   ├── theme/
│   │   │   └── app_theme.dart             # Application theming
│   │   ├── models/                        # Data models
│   │   ├── utils/                         # Utility functions
│   │   └── constants/                     # App constants
│   ├── features/
│   │   ├── auth/
│   │   │   └── screens/
│   │   │       └── modern_login_screen.dart
│   │   ├── home/
│   │   │   └── screens/
│   │   │       └── modern_home_screen.dart
│   │   ├── schedule/
│   │   ├── incidents/
│   │   └── profile/
│   └── shared/
│       ├── widgets/                       # Reusable UI components
│       ├── components/                    # Complex components
│       └── dialogs/                       # Modal dialogs
├── assets/
│   ├── images/                           # Image assets
│   ├── icons/                            # Icon assets
│   └── fonts/                            # Custom fonts
├── test/                                 # Unit and widget tests
├── integration_test/                     # Integration tests
├── android/                              # Android-specific files
├── ios/                                  # iOS-specific files
├── web/                                  # Web-specific files
├── windows/                              # Windows-specific files
├── linux/                                # Linux-specific files
└── macos/                                # macOS-specific files
```

## 📦 Dependencies

### Core Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.5 # State management
  flutter_secure_storage: ^9.0.0 # Secure data storage
  geolocator: ^10.1.0 # Location services
  http: ^1.1.0 # HTTP client
  file_selector: ^1.0.1 # File operations
  url_launcher: ^6.2.2 # External URL handling
```

### Development Dependencies

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0 # Linting rules
  build_runner: ^2.4.7 # Code generation
  json_annotation: ^4.8.1 # JSON serialization
```

## 🔌 API Integration

The application integrates with RESTful backend services:

### Authentication Endpoints

- `POST /api/auth/login` - User authentication
- `POST /api/auth/refresh` - Token refresh
- `POST /api/auth/logout` - User logout

### Location Services

- `POST /api/location/update` - Location data sync
- `GET /api/location/history` - Location history

### Schedule Management

- `GET /api/schedules` - Fetch schedules
- `POST /api/schedules` - Create schedule
- `PUT /api/schedules/{id}` - Update schedule

### Incident Reporting

- `POST /api/incidents` - Report incident
- `GET /api/incidents` - Fetch incidents
- `PUT /api/incidents/{id}` - Update incident

### Emergency Services

- `POST /api/emergency/sos` - Send SOS alert
- `GET /api/emergency/contacts` - Emergency contacts

## 🧪 Testing

### Running Tests

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/services/auth_service_test.dart

# Run integration tests
flutter test integration_test/
```

### Test Structure

```
test/
├── unit/
│   ├── services/
│   ├── models/
│   └── utils/
├── widget/
│   └── screens/
└── integration/
    └── app_test.dart
```

## 📱 Platform Support

| Platform | Status     | Min Version          | Notes                |
| -------- | ---------- | -------------------- | -------------------- |
| Android  | ✅ Stable  | API 21 (Android 5.0) | Full feature support |
| iOS      | ✅ Stable  | iOS 12.0             | Full feature support |
| Windows  | ✅ Stable  | Windows 10 1903+     | Desktop optimized    |
| Linux    | ✅ Stable  | Ubuntu 18.04+        | GTK-based UI         |
| Web      | ✅ Beta    | Modern browsers      | Progressive Web App  |
| macOS    | 🚧 Planned | macOS 10.14+         | Coming soon          |

## 🔧 Troubleshooting

### Common Issues & Solutions

#### 1. **Location Permissions Not Working**

**Problem**: GPS tracking fails or location is null
**Solutions**:

- Ensure location permissions are granted in device settings
- Check if location services are enabled system-wide
- Verify background location permission (Android 10+)
- Test on physical device (emulator GPS may be unreliable)

```bash
# Check location permissions
flutter run --verbose
```

#### 2. **Build Failures**

**Android Build Issues**:

```bash
# Clean and rebuild
flutter clean
flutter pub get
cd android && ./gradlew clean
flutter build apk
```

**iOS Build Issues**:

```bash
# Update CocoaPods
cd ios
pod install --repo-update
cd ..
flutter build ios
```

**Windows Build Issues**:

```bash
# Ensure Visual Studio Build Tools are installed
flutter doctor -v
flutter build windows
```

#### 3. **Authentication Token Expired**

**Problem**: API calls fail with 401 errors
**Solution**: Implement automatic token refresh in [`AuthService`](lib/core/services/auth_service.dart)

#### 4. **Performance Issues**

**Solutions**:

- Enable release mode: `flutter run --release`
- Profile the app: `flutter run --profile`
- Use `flutter doctor` to check for issues

### Debug Commands

```bash
# Check Flutter installation
flutter doctor -v

# Analyze code quality
flutter analyze

# Check for unused dependencies
flutter pub deps

# Generate dependency graph
flutter pub deps --json > deps.json
```

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Follow coding standards**
   - Run `flutter analyze` before committing
   - Ensure all tests pass: `flutter test`
   - Add tests for new features
4. **Commit your changes**
   ```bash
   git commit -m 'feat: add amazing feature'
   ```
5. **Push to the branch**
   ```bash
   git push origin feature/amazing-feature
   ```
6. **Open a Pull Request**

### Code Style Guidelines

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter format` for consistent formatting
- Add documentation for public APIs
- Write descriptive commit messages

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏆 Acknowledgments

- Flutter team for the amazing framework
- Community contributors and package maintainers
- UI/UX inspiration from modern mobile design trends

## 📞 Support

For support and questions:

- 📧 Email: support@trackingsystem.com
- 💬 Discord: [Join our community](https://discord.gg/trackingsystem)
- 📖 Documentation: [Wiki](https://github.com/yourrepo/tracking_system_mobile/wiki)
- 🐛 Bug Reports: [Issues](https://github.com/yourrepo/tracking_system_mobile/issues)

---

**Built with ❤️ using Flutter**
