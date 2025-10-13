# Travel Diary - Frontend

A beautiful, modern Flutter app for tracking and sharing travel adventures, built with best practices and a clean architecture.

## 🌟 Features

- **Authentication** - Beautiful login, register, and password recovery screens
- **Feed** - Infinite scroll feed with travel posts from users you follow
- **My Trips** - Create, manage, and view your travel trips
- **Trip Details** - Timeline, Map, and Gallery views for each trip
- **World Map** - Visualize all your travels on an interactive world map
- **Profile** - User profile with stats and settings
- **Search** - Search for trips, people, and places
- **Settings** - Comprehensive app settings and preferences

## 🏗️ Architecture

Built with **feature-first architecture** for scalability and maintainability:

```
lib/
├── app/                 # App-level configuration
│   ├── router.dart     # Go Router navigation
│   ├── app.dart        # Main app widget
│   └── theme/          # Theme, colors, typography
├── core/               # Shared utilities
│   ├── widgets/        # Reusable UI components
│   ├── utils/          # Helper functions
│   └── data/           # Fake data for testing
├── auth/               # Authentication feature
├── trips/              # Trips management
├── feed/               # Social feed
├── map/                # World map
├── profile/            # User profile
├── settings/           # App settings
└── search/             # Search functionality
```

## 🛠️ Tech Stack

- **State Management**: Riverpod
- **Routing**: GoRouter
- **HTTP**: Dio
- **Code Generation**: Freezed + json_serializable
- **Local DB**: Drift (SQLite)
- **Storage**: flutter_secure_storage, shared_preferences
- **UI**: Material 3 with custom theme
- **Images**: cached_network_image
- **Maps**: Placeholder UI (Google Maps not included for easier setup)

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.9.2 or later)
- Dart SDK (3.9.2 or later)
- iOS: Xcode 14+ (for iOS development)
- Android: Android Studio with SDK 26+ (for Android development)

### Installation

1. **Clone the repository**
   ```bash
   cd travel_diary_frontend
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**
   ```bash
   # For iOS
   flutter run -d ios

   # For Android
   flutter run -d android

   # For a specific device
   flutter devices
   flutter run -d <device_id>
   ```

## 📱 Screens

### Authentication
- **Login Screen** - Email/password with social login options
- **Register Screen** - Create account with validation
- **Forgot Password** - Password recovery flow

### Main App (Bottom Navigation)
- **Feed** - Discover posts from travelers
- **My Trips** - Your trip collection
- **World Map** - Visual travel history
- **Profile** - Your profile and stats

### Other Screens
- **Trip Detail** - Timeline, Map, and Gallery tabs
- **Search** - Find trips, people, and places
- **Settings** - App preferences and account settings

## 🎨 Design System

### Theme
- **Light & Dark Mode** - Automatic system preference detection
- **Material 3** - Modern Material Design components
- **Custom Colors** - Travel-inspired color palette
- **Typography** - Clean, readable Inter/Roboto fonts

### Colors
- Primary: Sky Blue (#00A3E0)
- Secondary: Sunset Orange (#FF6B35)
- Accent: Tropical Green (#06D6A0)
- Supporting gradients for visual appeal

## 🧪 Testing

The app uses fake data for testing. All features work with mock data to demonstrate functionality.

To run tests:
```bash
flutter test
```

## 📦 Build

### Android APK
```bash
flutter build apk --release
```

### iOS IPA
```bash
flutter build ios --release
```

## 🔧 Code Generation

When you modify models with `@freezed` or `@JsonSerializable`:

```bash
# Watch mode (auto-regenerate on changes)
flutter pub run build_runner watch --delete-conflicting-outputs

# One-time build
flutter pub run build_runner build --delete-conflicting-outputs
```

## 📝 Key Files

- `lib/main.dart` - App entry point
- `lib/app/app.dart` - Main app widget
- `lib/app/router.dart` - Navigation configuration
- `lib/app/theme/` - Theme configuration
- `lib/core/data/fake_data.dart` - Mock data for testing

## 🌐 Backend Integration

Currently uses fake data. To connect to a real backend:

1. Update the base URL in `lib/core/env/env.dart`
2. Implement API clients in `data/sources/` folders
3. Update repositories to use real data sources
4. Remove fake data providers

## 🤝 Contributing

This is a frontend demo application showcasing best practices in Flutter development.

## 📄 License

This project is for demonstration purposes.

## 🎯 Future Enhancements

- [ ] Real backend integration
- [ ] Offline-first with Drift sync
- [ ] Google Maps integration
- [ ] Photo filters and editing
- [ ] Social features (comments, likes)
- [ ] Push notifications
- [ ] Multi-language support
- [ ] Analytics integration

---

**Built with ❤️ using Flutter**
