import 'dart:typed_data';
import 'dart:ui' as ui;

Future<Uint8List> createCircularImageWithBorder(
  Uint8List imageBytes, {
  int size = 80,
  int borderWidth = 6,
  ui.Color borderColor = const ui.Color(0xFFFFFFFF),
  ui.Color accentColor = const ui.Color(0xFFFF6B35),
}) async {
  final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
  final ui.FrameInfo frameInfo = await codec.getNextFrame();
  final ui.Image sourceImage = frameInfo.image;

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  final double radius = size / 2.0;
  final double center = radius;

  final borderPaint = ui.Paint()
    ..color = borderColor
    ..style = ui.PaintingStyle.fill;
  canvas.drawCircle(ui.Offset(center, center), radius, borderPaint);

  final innerRadius = radius - borderWidth;
  canvas.save();
  canvas.clipPath(
    ui.Path()
      ..addOval(
        ui.Rect.fromCircle(
          center: ui.Offset(center, center),
          radius: innerRadius,
        ),
      ),
  );

  canvas.drawImageRect(
    sourceImage,
    ui.Rect.fromLTWH(
      0,
      0,
      sourceImage.width.toDouble(),
      sourceImage.height.toDouble(),
    ),
    ui.Rect.fromCircle(
      center: ui.Offset(center, center),
      radius: innerRadius,
    ),
    ui.Paint(),
  );

  canvas.restore();

  final accentPaint = ui.Paint()
    ..color = accentColor
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2.5;
  canvas.drawCircle(
    ui.Offset(center, center),
    radius - borderWidth / 2,
    accentPaint,
  );

  final picture = recorder.endRecording();
  final img = await picture.toImage(size, size);
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

/// Create a marker with rounded rectangle (pill shape) gradient background and text
Future<Uint8List> createTextCircleMarker({
  required String text,
  String? icon, // Not used
  int size = 80,
  ui.Color backgroundColor = const ui.Color(0xFF2196F3), // Gradient start color
  ui.Color? gradientColor, // Gradient end color
  ui.Color textColor = const ui.Color(0xFFFFFFFF), // White text
  int borderWidth = 2,
  ui.Color borderColor = const ui.Color(0xFFFFFFFF), // White border
  bool hasShadow = true, // Shadow for badge
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  
  final double centerX = size / 2.0;
  final double centerY = size / 2.0;
  final double badgeWidth = size * 0.7; // Width of rounded rectangle
  final double badgeHeight = size * 0.4; // Height of rounded rectangle
  final double borderRadius = size * 0.08; // Rounded corners radius
  final double shadowOffset = 2.0;
  final double shadowBlur = 5.0;
  
  // Use gradient end color or create a darker shade
  final endColor = gradientColor ?? ui.Color.fromARGB(
    255,
    (backgroundColor.red * 0.7).round().clamp(0, 255),
    (backgroundColor.green * 0.7).round().clamp(0, 255),
    (backgroundColor.blue * 0.7).round().clamp(0, 255),
  );
  
  // Calculate rounded rectangle bounds
  final rect = ui.RRect.fromRectAndRadius(
    ui.Rect.fromCenter(
      center: ui.Offset(centerX, centerY),
      width: badgeWidth,
      height: badgeHeight,
    ),
    ui.Radius.circular(borderRadius),
  );
  
  // Draw subtle shadow for badge
  if (hasShadow) {
    final shadowRect = ui.RRect.fromRectAndRadius(
      ui.Rect.fromCenter(
        center: ui.Offset(centerX + shadowOffset, centerY + shadowOffset),
        width: badgeWidth,
        height: badgeHeight,
      ),
      ui.Radius.circular(borderRadius),
    );
    final shadowPaint = ui.Paint()
      ..color = const ui.Color(0x40000000) // Shadow color
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, shadowBlur);
    canvas.drawRRect(shadowRect, shadowPaint);
  }
  
  // Draw white border rounded rectangle
  final borderPaint = ui.Paint()
    ..color = borderColor
    ..style = ui.PaintingStyle.fill;
  canvas.drawRRect(rect, borderPaint);
  
  // Draw gradient background rounded rectangle
  final innerRect = ui.RRect.fromRectAndRadius(
    ui.Rect.fromCenter(
      center: ui.Offset(centerX, centerY),
      width: badgeWidth - (borderWidth * 2),
      height: badgeHeight - (borderWidth * 2),
    ),
    ui.Radius.circular(borderRadius - borderWidth),
  );
  
  final gradient = ui.Gradient.linear(
    ui.Offset(centerX, centerY - badgeHeight / 2), // Top center
    ui.Offset(centerX, centerY + badgeHeight / 2), // Bottom center
    [
      backgroundColor, // Start color (lighter)
      endColor, // End color (darker)
    ],
    [0.0, 1.0],
  );
  
  final gradientPaint = ui.Paint()
    ..shader = gradient
    ..style = ui.PaintingStyle.fill;
  canvas.drawRRect(innerRect, gradientPaint);
  
  // Draw text on gradient badge - smaller to fit inside
  final textWidth = badgeWidth - (borderWidth * 4); // Available width for text
  
  final paragraphBuilder = ui.ParagraphBuilder(
    ui.ParagraphStyle(
      textAlign: ui.TextAlign.center,
      textDirection: ui.TextDirection.ltr,
      fontSize: size * 0.18, // Smaller text to fit inside
      fontWeight: ui.FontWeight.bold,
      maxLines: 1, // Single line
    ),
  );
  
  paragraphBuilder.pushStyle(
    ui.TextStyle(
      color: textColor, // White text
      fontFamily: 'Arial',
      shadows: [
        ui.Shadow(
          color: const ui.Color(0x80000000), // Dark shadow for text
          offset: const ui.Offset(0, 1),
          blurRadius: 2,
        ),
      ],
    ),
  );
  paragraphBuilder.addText(text);
  
  final paragraph = paragraphBuilder.build();
  paragraph.layout(ui.ParagraphConstraints(width: textWidth));
  
  // Center the text both horizontally and vertically on badge
  // Since textAlign is center, position the paragraph at the start of the text area
  // and the text will be centered within that area
  final textX = centerX - textWidth / 2;
  final textY = centerY - paragraph.height / 2;
  
  canvas.drawParagraph(
    paragraph,
    ui.Offset(textX, textY),
  );
  
  final picture = recorder.endRecording();
  final img = await picture.toImage(size, size);
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

