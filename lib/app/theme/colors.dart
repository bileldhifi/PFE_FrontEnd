import 'package:flutter/material.dart';

/// App color palette for Travel Diary
class AppColors {
  AppColors._();

  // Primary colors - inspired by travel and adventure
  static const Color primaryLight = Color(0xFF00A3E0); // Sky blue
  static const Color primaryDark = Color(0xFF0077B6); // Deep ocean blue
  
  // Secondary colors
  static const Color secondaryLight = Color(0xFFFF6B35); // Sunset orange
  static const Color secondaryDark = Color(0xFFE63946); // Adventure red
  
  // Accent colors
  static const Color accent = Color(0xFF06D6A0); // Tropical green
  static const Color accentVariant = Color(0xFFFFC300); // Golden hour
  
  // Neutral colors - Light mode
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF5F5F5);
  
  // Neutral colors - Dark mode
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceVariantDark = Color(0xFF2A2A2A);
  
  // Text colors - Light mode
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF666666);
  static const Color textTertiaryLight = Color(0xFF999999);
  
  // Text colors - Dark mode
  static const Color textPrimaryDark = Color(0xFFE0E0E0);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  static const Color textTertiaryDark = Color(0xFF808080);
  
  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Visibility indicators
  static const Color visibilityPublic = Color(0xFF10B981);
  static const Color visibilityFriends = Color(0xFFF59E0B);
  static const Color visibilityPrivate = Color(0xFF6B7280);
  
  // Gradient backgrounds
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, Color(0xFF0096D6)],
  );
  
  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B35), Color(0xFFFF8E53), Color(0xFFFFA07A)],
  );
  
  static const LinearGradient adventureGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, accent],
  );
  
  // Map overlay colors
  static const Color mapOverlay = Color(0x80000000);
  static const Color markerCluster = Color(0xFF00A3E0);
  
  // Shimmer colors for skeleton loaders
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color shimmerBaseDark = Color(0xFF2A2A2A);
  static const Color shimmerHighlightDark = Color(0xFF3A3A3A);
}

