import 'dart:async';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary_frontend/core/websocket/websocket_service.dart';
import 'package:travel_diary_frontend/core/network/api_client.dart';
import 'package:travel_diary_frontend/auth/presentation/controllers/auth_controller.dart';

/// Singleton WebSocket manager that manages connection lifecycle
/// This should be initialized at app startup and used throughout the app
class WebSocketManager {
  final WebSocketService _service = WebSocketService();
  bool _isInitialized = false;

  WebSocketService get service => _service;

  /// Initialize WebSocket connection (called at app startup)
  Future<void> initialize(String token) async {
    if (_isInitialized) {
      log('WebSocket already initialized');
      return;
    }

    try {
      await _service.connect(token, ApiClient.baseUrl);
      _isInitialized = true;
      log('WebSocket manager initialized');
    } catch (e) {
      log('Failed to initialize WebSocket: $e');
      rethrow;
    }
  }

  /// Reconnect with a new token
  Future<void> reconnect(String token) async {
    _service.disconnect();
    await _service.connect(token, ApiClient.baseUrl);
    _isInitialized = true;
  }

  /// Disconnect and cleanup
  void dispose() {
    _service.disconnect();
    _isInitialized = false;
    log('WebSocket manager disposed');
  }

  bool get isInitialized => _isInitialized;
}

/// Riverpod provider for WebSocket manager
final webSocketManagerProvider = Provider<WebSocketManager>((ref) {
  final manager = WebSocketManager();
  final apiClient = ApiClient();

  // Auto-connect when authenticated
  ref.listen<AuthState>(authControllerProvider, (previous, next) async {
    if (next.isAuthenticated) {
      final token = await apiClient.getAccessToken();
      if (token != null) {
        manager.initialize(token).catchError((e) {
          log('Error initializing WebSocket: $e');
        });
      }
    } else {
      manager.dispose();
    }
  });

  // Cleanup on dispose
  ref.onDispose(() {
    manager.dispose();
  });

  return manager;
});

