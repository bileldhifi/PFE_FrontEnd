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

