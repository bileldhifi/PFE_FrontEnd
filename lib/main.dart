import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary_frontend/app/app.dart';
import 'package:travel_diary_frontend/core/env/mapbox_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Mapbox
  MapboxConfig.initialize();
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  runApp(
    const ProviderScope(
      child: TravelDiaryApp(),
    ),
  );
}
