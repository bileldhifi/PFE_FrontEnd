import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_diary_frontend/auth/presentation/forgot_password_screen.dart';
import 'package:travel_diary_frontend/auth/presentation/login_screen.dart';
import 'package:travel_diary_frontend/auth/presentation/register_screen.dart';
import 'package:travel_diary_frontend/auth/presentation/change_password_screen.dart';
import 'package:travel_diary_frontend/feed/presentation/feed_screen.dart';
import 'package:travel_diary_frontend/home/presentation/home_screen.dart';
import 'package:travel_diary_frontend/map/presentation/world_map_screen.dart';
import 'package:travel_diary_frontend/profile/presentation/profile_screen.dart';
import 'package:travel_diary_frontend/profile/presentation/edit_profile_screen.dart';
import 'package:travel_diary_frontend/search/presentation/search_screen.dart';
import 'package:travel_diary_frontend/settings/presentation/settings_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary_frontend/app/splash_screen.dart';
import 'package:travel_diary_frontend/auth/presentation/controllers/auth_controller.dart';
import 'package:travel_diary_frontend/profile/presentation/controllers/profile_controller.dart';
import 'package:travel_diary_frontend/trips/presentation/create_trip_screen.dart';
import 'package:travel_diary_frontend/trips/presentation/my_trips_screen.dart';
import 'package:travel_diary_frontend/trips/presentation/trip_detail_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      // Splash screen
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Auth routes
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/auth/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),

      // Main app with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ScaffoldWithBottomNav(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/feed',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FeedScreen(),
            ),
          ),
          GoRoute(
            path: '/trips',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MyTripsScreen(),
            ),
          ),
          GoRoute(
            path: '/map',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: WorldMapScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),

      // Create trip (must come before /trips/:id to avoid route conflict)
      GoRoute(
        path: '/trips/create',
        builder: (context, state) => const CreateTripScreen(),
      ),

      // Trip detail (outside shell to have its own app bar)
      GoRoute(
        path: '/trips/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TripDetailScreen(tripId: id);
        },
      ),

      // Other routes
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) {
          // Get current user from provider
          final container = ProviderScope.containerOf(context);
          final currentUser = container.read(currentUserProvider);
          if (currentUser == null) {
            // Redirect to login if no user
            return const LoginScreen();
          }
          return EditProfileScreen(user: currentUser);
        },
      ),
    ],
  );
}

// Bottom navigation scaffold
class ScaffoldWithBottomNav extends StatelessWidget {
  final Widget child;

  const ScaffoldWithBottomNav({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.luggage_outlined),
            activeIcon: Icon(Icons.luggage),
            label: 'Trips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location == '/' || location.startsWith('/home')) return 0;
    if (location.startsWith('/trips')) return 1;
    if (location.startsWith('/map')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/trips');
        break;
      case 2:
        context.go('/map');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }
}

