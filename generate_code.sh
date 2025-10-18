#!/bin/bash

echo "🚀 Running code generation for Flutter project..."

# Clean previous generated files
echo "🧹 Cleaning previous generated files..."
find lib -name "*.freezed.dart" -delete
find lib -name "*.g.dart" -delete

# Run code generation
echo "⚡ Running build_runner..."
flutter packages pub run build_runner build --delete-conflicting-outputs

echo "✅ Code generation completed!"
echo ""
echo "📝 Next steps:"
echo "1. Make sure your Spring Boot backend is running on http://localhost:8089"
echo "2. Run 'flutter run' to test the authentication flow"
echo "3. Test login with valid credentials from your backend"

