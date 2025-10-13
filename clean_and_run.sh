#!/bin/bash

echo "🧹 Cleaning up old build files..."
echo ""

# Remove all build artifacts
rm -rf build/
rm -rf ios/Pods/
rm -rf ios/Podfile.lock
rm -rf ios/.symlinks/
rm -rf .dart_tool/
rm -rf .flutter-plugins
rm -rf .flutter-plugins-dependencies

echo "✅ Cleanup complete!"
echo ""
echo "📦 Installing fresh dependencies..."
flutter pub get

echo ""
echo "🔨 Generating code..."
flutter pub run build_runner build --delete-conflicting-outputs

echo ""
echo "📱 Installing iOS pods..."
cd ios
pod install
cd ..

echo ""
echo "✅ Setup complete! Ready to run!"
echo ""
echo "🚀 Starting app..."
flutter run

