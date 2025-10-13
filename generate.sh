#!/bin/bash

# Script to generate code using build_runner

echo "🔨 Running build_runner..."
echo ""

flutter pub run build_runner build --delete-conflicting-outputs

echo ""
echo "✅ Code generation complete!"
echo ""
echo "Generated files:"
echo "  - *.g.dart (JSON serialization)"
echo "  - *.freezed.dart (Freezed models)"

