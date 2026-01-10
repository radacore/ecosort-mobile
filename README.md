# EcoSort Mobile App

EcoSort is a modern waste sorting application built with Flutter that helps users categorize and manage their waste while earning points for proper recycling habits. The app connects to a Laravel backend API to store and retrieve user data, waste records, and reward information.

## Features

- **User Authentication**: Secure login and registration system
- **Waste Scanning**: Capture photos of waste for digital submission
- **Waste Classification**: Categorize waste into different types (Organic, Plastic, Paper, Metal, Residue)
- **Points System**: Earn points based on waste type and volume
- **Streak Tracking**: Maintain daily streaks for consistent waste sorting
- **Profile Management**: View and update personal information
- **District Selection**: Choose your district (kecamatan) for localized tracking
- **Avatar Customization**: Personalize your profile with avatars

## Screenshots

| Splash Screen | Login Screen | Registration |
|:-------------:|:------------:|:------------:|
| ![Splash](screenshots/splash.png) | ![Login](screenshots/login.png) | ![Register](screenshots/register.png) |

| Main Dashboard | Waste Scanning | Profile |
|:-------------:|:------------:|:--------:|
| ![Dashboard](screenshots/dashboard.png) | ![Scan](screenshots/scan.png) | ![Profile](screenshots/profile.png) |

## Technologies Used

- **Flutter**: Cross-platform mobile development framework
- **Dart**: Programming language for Flutter
- **http**: HTTP client for API communication
- **flutter_secure_storage**: Secure storage for authentication tokens
- **image_picker**: For capturing and selecting images
- **dio**: Advanced HTTP client with multipart support

## Prerequisites

- Flutter SDK 3.9.2 or higher
- Dart SDK 3.9.2 or higher
- Android Studio or VS Code with Flutter extensions
- Physical device or emulator for testing

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd ecosort
```

2. Install dependencies:
```bash
flutter pub get
```

3. Update API configuration:
   - Open `lib/utils/constants.dart`
   - Update `BASE_URL` to match your backend API IP address:
   ```dart
   static const String BASE_URL = 'http://YOUR_IP_ADDRESS:8000/api';
   ```
   
   For different environments:
   - Android Emulator: `http://10.0.2.2:8000/api`
   - iOS Simulator: `http://localhost:8000/api`
   - Physical Device: Your computer's local network IP (e.g., `http://192.168.1.10:8000/api`)

4. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # Entry point
├── models/                   # Data models
│   ├── kecamatan.dart        # District model
│   ├── submission.dart       # Waste submission model
│   ├── user.dart             # User model
│   └── waste_type.dart       # Waste type model
├── screens/                  # UI screens
│   ├── login_screen.dart     # Authentication screen
│   ├── main_screen.dart      # Main app with navigation
│   ├── panduan_screen.dart   # Waste sorting guide
│   ├── profile_screen.dart   # User profile management
│   ├── register_screen.dart  # User registration
│   ├── scan_screen.dart      # Waste submission form
│   └── splash_screen.dart    # Initial loading screen
├── services/                 # Business logic and API services
│   ├── auth_service.dart     # Authentication handling
│   ├── kecamatan_service.dart# District data service
│   ├── profile_service.dart  # Profile management
│   └── submission_service.dart# Waste submission service
└── utils/
    └── constants.dart        # Application constants
```

## Key Components

### Authentication Flow

1. **Splash Screen**: Initial loading screen that checks authentication status
2. **Login Screen**: Email/password authentication
3. **Registration Screen**: New user signup with validation

### Main Features

1. **Scan Screen** (`scan_screen.dart`)
   - Capture or select waste photos
   - Select waste type from dropdown
   - Enter volume in liters
   - Submit waste records to backend
   - Automatic point calculation

2. **Panduan Screen** (`panduan_screen.dart`)
   - Detailed waste sorting guidelines
   - Categories: Organic, Anorganic, Hazardous Waste (B3)
   - Proper sorting tips and best practices

3. **Profile Screen** (`profile_screen.dart`)
   - View/update personal information
   - Change profile avatar
   - Display points and streak statistics
   - District selection
   - Logout functionality

### Services

1. **AuthService** (`auth_service.dart`)
   - User registration
   - User login/logout
   - Token management with secure storage

2. **ProfileService** (`profile_service.dart`)
   - Fetch user profile data
   - Update user information
   - Avatar upload functionality

3. **SubmissionService** (`submission_service.dart`)
   - Submit waste records with photos
   - Point calculation logic
   - Communication with backend API

4. **KecamatanService** (`kecamatan_service.dart`)
   - Fetch district information
   - Populate dropdown selections

### Data Models

1. **User**: User profile information (name, email, points, streak, district)
2. **Kecamatan**: District information for user location
3. **WasteType**: Different categories of waste with point values
4. **Submission**: Waste submission records with metadata

## API Integration

The app communicates with the Laravel backend through RESTful API endpoints:

- Authentication: `/api/login`, `/api/register`, `/api/logout`
- Profile: `/api/profil` (GET/PUT)
- Waste Submission: `/api/setoran-sampah` (POST)
- Districts: `/api/kecamatan` (GET)
- Avatars: `/api/profil/avatar/upload` (POST)

All requests are secured with Bearer token authentication.

## Points System

Users earn points based on waste type and volume:
- Organic: 10 points per liter
- Plastic: 15 points per liter
- Paper: 12 points per liter
- Metal: 20 points per liter
- Residue: 5 points per liter

## Streak System

Users maintain streaks by submitting waste daily:
- Consecutive daily submissions increase streak count
- Missed days reset the streak to 1

## Development

### Code Generation

This project uses the following commands for development:

```bash
# Run the app
flutter run

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
flutter format .
```

### Folder Structure Guidelines

- `lib/models/`: Contains all data models with JSON serialization
- `lib/screens/`: Contains all UI screens as StatefulWidget or StatelessWidget
- `lib/services/`: Contains business logic and API integration services
- `lib/utils/`: Contains utility functions and constants

### State Management

The app uses Flutter's built-in state management with:
- `setState()` for local widget state
- `FutureBuilder` for asynchronous data loading
- Service classes for shared business logic

## Configuration

### API Endpoint Configuration

Update `lib/utils/constants.dart` with your backend IP:

```dart
class AppConstants {
  static const String BASE_URL = 'http://192.168.1.9:8000/api'; // CHANGE THIS
}
```

### Supported Platforms

- Android (SDK 21+)
- iOS (10.0+)
- Web (Chrome, Firefox, Safari)

Note: Camera functionality requires appropriate permissions on mobile platforms.

## Troubleshooting

### Common Issues

1. **API Connection Failed**
   - Ensure backend server is running
   - Verify IP address in `constants.dart` matches backend
   - Check network connectivity
   - Confirm firewall settings allow port access

2. **Authentication Errors**
   - Verify user credentials
   - Check if user is properly registered in backend
   - Ensure Sanctum middleware is configured correctly

3. **Image Upload Issues**
   - Verify file size limits in backend
   - Check image format compatibility
   - Confirm storage permissions on device

### Debugging

Enable logging by checking the console output:
```bash
flutter run --verbose
```

## Testing

Run unit and widget tests:
```bash
flutter test
```

## Deployment

### Android

1. Update `android/app/build.gradle` with signing configuration
2. Build release APK:
```bash
flutter build apk
```

### iOS

1. Update iOS deployment target in Xcode
2. Configure signing in Xcode
3. Build release:
```bash
flutter build ios
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a pull request

## License

This project is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).

## Authors

EcoSort was developed as part of a mobile application project focusing on environmental sustainability and waste management.