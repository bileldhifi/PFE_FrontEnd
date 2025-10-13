import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary_frontend/app/router.dart';
import 'package:travel_diary_frontend/app/theme/theme.dart';
import 'package:travel_diary_frontend/core/widgets/error_boundary.dart';

class TravelDiaryApp extends ConsumerWidget {
  const TravelDiaryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ErrorBoundary(
      child: MaterialApp.router(
        title: 'Travel Diary',
        debugShowCheckedModeBanner: false,
        
        // Theme
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        
        // Router
        routerConfig: AppRouter.router,
      ),
    );
  }
}

