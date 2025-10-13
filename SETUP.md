# Setup Guide - Travel Diary App

This guide will help you get the Travel Diary app up and running on your local machine.

## Prerequisites

Before you begin, ensure you have the following installed:

1. **Flutter SDK** (3.9.2 or later)
   - Download from: https://flutter.dev/docs/get-started/install
   - Add Flutter to your PATH

2. **Dart SDK** (Comes with Flutter)
   - Version 3.9.2 or later

3. **IDE** (Choose one)
   - VS Code with Flutter extension
   - Android Studio with Flutter plugin
   - IntelliJ IDEA with Flutter plugin

4. **Platform-specific tools**
   - **iOS**: Xcode 14+ (macOS only)
   - **Android**: Android Studio with SDK 26+

## Step-by-Step Setup

### 1. Verify Flutter Installation

```bash
flutter doctor
```

This command checks your environment and displays a report of the status of your Flutter installation.

### 2. Install Dependencies

Navigate to the project directory and run:

```bash
flutter pub get
```

This downloads all the packages specified in `pubspec.yaml`.

### 3. Generate Code

The app uses code generation for models and JSON serialization. Run:

```bash
# One-time generation
flutter pub run build_runner build --delete-conflicting-outputs

# OR use the provided script (make it executable first)
chmod +x generate.sh
./generate.sh

# OR for continuous generation during development
flutter pub run build_runner watch --delete-conflicting-outputs
```

### 4. Run the App

#### For iOS Simulator (macOS only):
```bash
# Start iOS simulator
open -a Simulator

# Run the app
flutter run -d ios
```

#### For Android Emulator:
```bash
# List available devices
flutter devices

# Run on Android
flutter run -d android
```

#### For Physical Device:
1. Enable USB debugging on your device
2. Connect via USB
3. Run: `flutter devices` to see your device
4. Run: `flutter run -d <device_id>`

### 5. Verify Everything Works

Once the app is running, you should see:
- The Feed screen as the home page
- Bottom navigation with 4 tabs
- Fake travel data displayed
- Smooth navigation between screens

## Common Issues & Solutions

### Issue: "Command not found: flutter"
**Solution**: Add Flutter to your PATH
```bash
# For macOS/Linux, add to ~/.bashrc or ~/.zshrc:
export PATH="$PATH:/path/to/flutter/bin"

# Apply changes
source ~/.bashrc  # or source ~/.zshrc
```

### Issue: Build runner fails
**Solution**: Delete generated files and rebuild
```bash
# Delete generated files
find . -name "*.g.dart" -delete
find . -name "*.freezed.dart" -delete

# Clean and rebuild
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue: "CocoaPods not installed" (iOS)
**Solution**: Install CocoaPods
```bash
sudo gem install cocoapods
pod setup
```

### Issue: Android licenses not accepted
**Solution**: Accept Android licenses
```bash
flutter doctor --android-licenses
```

### Issue: Gradle build fails (Android)
**Solution**: 
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

## Development Workflow

### 1. Making Changes to Models

When you modify any file with `@freezed` or `@JsonSerializable`:

```bash
# Automatic regeneration (recommended during development)
flutter pub run build_runner watch --delete-conflicting-outputs
```

### 2. Hot Reload & Hot Restart

- **Hot Reload** (r): Quickly reload code changes
  - Preserves app state
  - Fast (~1 second)
  - Use for UI changes

- **Hot Restart** (R): Restarts the app
  - Resets app state
  - Slower (~3 seconds)
  - Use for state/logic changes

### 3. Testing

```bash
# Run all tests
flutter test

# Run specific test
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage
```

### 4. Building for Release

#### Android APK:
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

#### Android App Bundle:
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

#### iOS:
```bash
flutter build ios --release
# Then use Xcode to archive and export
```

## Project Structure Overview

```
travel_diary_frontend/
├── lib/
│   ├── main.dart              # Entry point
│   ├── app/                   # App configuration
│   │   ├── app.dart          # Main app widget
│   │   ├── router.dart       # Navigation
│   │   └── theme/            # Theming
│   ├── core/                  # Shared code
│   │   ├── widgets/          # Reusable widgets
│   │   ├── utils/            # Utilities
│   │   └── data/             # Fake data
│   ├── auth/                  # Auth feature
│   ├── trips/                 # Trips feature
│   ├── feed/                  # Feed feature
│   ├── map/                   # Map feature
│   ├── profile/               # Profile feature
│   ├── settings/              # Settings feature
│   └── search/                # Search feature
├── assets/                    # Images, icons, etc.
├── test/                      # Tests
└── pubspec.yaml              # Dependencies
```

## Next Steps

1. **Explore the code**: Start with `lib/main.dart` and follow the navigation
2. **Try features**: Test all screens and interactions
3. **Customize theme**: Modify colors in `lib/app/theme/colors.dart`
4. **Add real data**: Replace fake data with backend integration
5. **Add more features**: Extend the app with your ideas!

## Useful Commands

```bash
# Check Flutter version
flutter --version

# Check for updates
flutter upgrade

# Clean build files
flutter clean

# Analyze code
flutter analyze

# Format code
dart format .

# List devices
flutter devices

# Check app size
flutter build apk --analyze-size
```

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)
- [Riverpod Documentation](https://riverpod.dev)
- [GoRouter Documentation](https://pub.dev/packages/go_router)
- [Freezed Documentation](https://pub.dev/packages/freezed)

## Support

If you encounter issues:
1. Check `flutter doctor` output
2. Ensure all dependencies are installed
3. Try `flutter clean` and `flutter pub get`
4. Delete generated files and regenerate
5. Check the [Flutter GitHub issues](https://github.com/flutter/flutter/issues)

---

Happy Coding! 🚀

