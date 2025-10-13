#!/bin/bash

echo "🚀 Travel Diary App - Quick Start"
echo "=================================="
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null
then
    echo "❌ Flutter is not installed or not in PATH"
    echo "Please install Flutter from: https://flutter.dev"
    exit 1
fi

echo "📦 Installing dependencies..."
flutter pub get

echo ""
echo "🔨 Generating code files..."
flutter pub run build_runner build --delete-conflicting-outputs

echo ""
echo "✅ Setup complete!"
echo ""
echo "🎯 Available devices:"
flutter devices

echo ""
echo "To run the app, use one of these commands:"
echo "  flutter run                  # Auto-select device"
echo "  flutter run -d ios          # iOS Simulator"
echo "  flutter run -d android      # Android Emulator"
echo "  flutter run -d chrome       # Web Browser"
echo ""
echo "Or simply run: flutter run"
echo ""

read -p "Would you like to run the app now? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]
then
    flutter run
fi

