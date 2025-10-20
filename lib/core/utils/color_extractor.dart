import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// Utility class for extracting dominant colors from images
class ColorExtractor {
  /// Extract dominant colors from a network image URL
  static Future<List<Color>> extractColorsFromNetwork(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        return await _extractColorsFromBytes(bytes);
      }
    } catch (e) {
      print('Error loading image for color extraction: $e');
    }
    return _getDefaultColors();
  }

  /// Extract dominant colors from a local file
  static Future<List<Color>> extractColorsFromFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return await _extractColorsFromBytes(bytes);
    } catch (e) {
      print('Error reading file for color extraction: $e');
      return _getDefaultColors();
    }
  }

  /// Extract dominant colors from image bytes
  static Future<List<Color>> _extractColorsFromBytes(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      
      // Resize image to reduce processing time
      final resizedImage = await _resizeImage(image, 100, 100);
      
      // Extract colors using a simple sampling method
      final colors = await _sampleColors(resizedImage);
      
      // Clean up
      image.dispose();
      resizedImage.dispose();
      
      return colors;
    } catch (e) {
      print('Error extracting colors from bytes: $e');
      return _getDefaultColors();
    }
  }

  /// Resize image to reduce processing time
  static Future<ui.Image> _resizeImage(ui.Image image, int width, int height) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint(),
    );
    
    final picture = recorder.endRecording();
    final resizedImage = await picture.toImage(width, height);
    
    picture.dispose();
    return resizedImage;
  }

  /// Sample colors from the image using a grid-based approach
  static Future<List<Color>> _sampleColors(ui.Image image) async {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (bytes == null) return _getDefaultColors();

    final pixelData = bytes.buffer.asUint8List();
    final colors = <Color>[];
    final colorCounts = <int, int>{};

    // Sample pixels in a grid pattern
    final step = 5; // Sample every 5th pixel
    for (int y = 0; y < image.height; y += step) {
      for (int x = 0; x < image.width; x += step) {
        final index = (y * image.width + x) * 4;
        if (index + 3 < pixelData.length) {
          final r = pixelData[index];
          final g = pixelData[index + 1];
          final b = pixelData[index + 2];
          final a = pixelData[index + 3];
          
          // Skip transparent or very dark pixels
          if (a > 50 && (r + g + b) > 100) {
            final color = Color.fromARGB(255, r, g, b);
            final colorValue = color.value;
            colorCounts[colorValue] = (colorCounts[colorValue] ?? 0) + 1;
          }
        }
      }
    }

    // Sort colors by frequency and get top colors
    final sortedColors = colorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Extract top 5 colors
    for (int i = 0; i < math.min(5, sortedColors.length); i++) {
      colors.add(Color(sortedColors[i].key));
    }

    // If we don't have enough colors, fill with variations
    while (colors.length < 3) {
      if (colors.isNotEmpty) {
        colors.add(_adjustColorBrightness(colors.last, 0.3));
      } else {
        colors.addAll(_getDefaultColors());
        break;
      }
    }

    return colors.take(3).toList();
  }

  /// Adjust color brightness
  static Color _adjustColorBrightness(Color color, double factor) {
    final hsl = HSLColor.fromColor(color);
    final adjustedHsl = hsl.withLightness(
      math.max(0.0, math.min(1.0, hsl.lightness + factor))
    );
    return adjustedHsl.toColor();
  }

  /// Get default colors when extraction fails
  static List<Color> _getDefaultColors() {
    return [
      const Color(0xFF00A3E0), // Primary light
      const Color(0xFF0077B6), // Primary dark
      const Color(0xFFFF6B35), // Secondary light
    ];
  }

  /// Create a gradient from extracted colors
  static LinearGradient createGradientFromColors(List<Color> colors) {
    if (colors.length < 2) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF00A3E0),
          Color(0xFF0077B6),
        ],
      );
    }

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
      stops: List.generate(colors.length, (index) => index / (colors.length - 1)),
    );
  }

  /// Create a complementary gradient (for better contrast)
  static LinearGradient createComplementaryGradient(List<Color> colors) {
    if (colors.isEmpty) return _getDefaultColors().createGradientFromColors();

    final primaryColor = colors.first;
    final hsl = HSLColor.fromColor(primaryColor);
    
    // Create complementary colors
    final complementary = hsl.withHue((hsl.hue + 180) % 360).toColor();
    final lighter = hsl.withLightness(math.min(1.0, hsl.lightness + 0.2)).toColor();
    final darker = hsl.withLightness(math.max(0.0, hsl.lightness - 0.2)).toColor();

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primaryColor, lighter, darker],
    );
  }
}

/// Extension to add gradient creation to List<Color>
extension ColorListExtension on List<Color> {
  LinearGradient createGradientFromColors() {
    return ColorExtractor.createGradientFromColors(this);
  }
}
