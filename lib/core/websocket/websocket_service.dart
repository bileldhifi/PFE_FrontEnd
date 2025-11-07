import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:travel_diary_frontend/core/websocket/websocket_message.dart';
import 'package:travel_diary_frontend/core/websocket/websocket_message_handler.dart';

/// Core WebSocket service that manages connection and message routing
/// This is a low-level service that doesn't know about specific features
class WebSocketService {
  WebSocketChannel? _channel;
  final StreamController<WebSocketMessage> _messageController =
      StreamController<WebSocketMessage>.broadcast();
  final WebSocketMessageHandlerRegistry _handlerRegistry =
      WebSocketMessageHandlerRegistry();

  bool _isConnected = false;
  String? _currentToken;
  String? _baseUrl;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 5);

  /// Stream of all incoming messages
  Stream<WebSocketMessage> get messages => _messageController.stream;

  /// Whether the service is currently connected
  bool get isConnected => _isConnected;

  /// Register a message handler
  void registerHandler(WebSocketMessageHandler handler) {
    _handlerRegistry.register(handler);
  }

  /// Unregister a message handler
  void unregisterHandler(WebSocketMessageHandler handler) {
    _handlerRegistry.unregister(handler);
  }

  /// Connect to WebSocket server
  Future<void> connect(String token, String baseUrl) async {
    if (_isConnected && _currentToken == token) {
      log('WebSocket already connected');
      return;
    }

    _currentToken = token;
    _baseUrl = baseUrl;
    _reconnectAttempts = 0;

    await _doConnect();
  }

  Future<void> _doConnect() async {
    try {
      final wsUrl = _baseUrl!
          .replaceAll('http://', 'ws://')
          .replaceAll('https://', 'wss://');
      final uri = Uri.parse('$wsUrl/ws/websocket');

      log('Connecting to WebSocket: $uri');

      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        _handleRawMessage,
        onError: (error) {
          log('WebSocket error: $error');
          _onConnectionLost();
        },
        onDone: () {
          log('WebSocket connection closed');
          _onConnectionLost();
        },
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      log('WebSocket connected successfully');
    } catch (e) {
      log('Failed to connect WebSocket: $e');
      _isConnected = false;
      _scheduleReconnect();
      rethrow;
    }
  }

  void _handleRawMessage(dynamic rawMessage) {
    try {
      final message = _parseMessage(rawMessage);
      if (message != null) {
        _messageController.add(message);
        _routeMessage(message);
      }
    } catch (e) {
      log('Error handling WebSocket message: $e');
    }
  }

  WebSocketMessage? _parseMessage(dynamic rawMessage) {
    try {
      final data = jsonDecode(rawMessage);

      if (data is List && data.isNotEmpty) {
        final frame = data[0] as String;
        if (frame.startsWith('a[')) {
          final payload = jsonDecode(frame.substring(2, frame.length - 1));
          return _createMessageFromPayload(payload);
        }
      } else if (data is Map) {
        return _createMessageFromPayload(data as Map<String, dynamic>);
      }
    } catch (e) {
      log('Error parsing WebSocket message: $e');
    }
    return null;
  }

  WebSocketMessage? _createMessageFromPayload(Map<String, dynamic> payload) {
    final destination = payload['destination'] as String?;
    final body = payload['body'];
    final type = payload['type'] as String?;

    if (destination == null || body == null) return null;

    final bodyMap = body is Map<String, dynamic>
        ? body
        : body is String
            ? jsonDecode(body) as Map<String, dynamic>
            : null;

    if (bodyMap == null) return null;

    return WebSocketMessage(
      type: type ?? destination.toMessageType().name,
      destination: destination,
      body: bodyMap,
      id: payload['id'] as String?,
      headers: payload['headers'] as Map<String, String>?,
    );
  }

  void _routeMessage(WebSocketMessage message) {
    final handlers =
        _handlerRegistry.getHandlersForDestination(message.destination);

    if (handlers.isEmpty) {
      log('No handler found for destination: ${message.destination}');
      return;
    }

    for (final handler in handlers) {
      try {
        handler.handleMessage(message);
      } catch (e) {
        log('Error in handler ${handler.runtimeType}: $e');
      }
    }
  }

  void _onConnectionLost() {
    _isConnected = false;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      log('Max reconnection attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      _reconnectAttempts++;
      log('Attempting to reconnect WebSocket (attempt $_reconnectAttempts)...');
      if (_currentToken != null && _baseUrl != null) {
        _doConnect();
      }
    });
  }

  /// Subscribe to a topic/destination
  void subscribe(String destination, {String? subscriptionId}) {
    if (!_isConnected) {
      log('Cannot subscribe: WebSocket not connected');
      return;
    }

    final id = subscriptionId ?? 'sub-${destination.hashCode}';
    final subscribeMessage = jsonEncode([
      'SUBSCRIBE',
      {
        'id': id,
        'destination': destination,
      },
      ''
    ]);

    _channel?.sink.add(subscribeMessage);
    log('Subscribed to: $destination');
  }

  /// Unsubscribe from a topic/destination
  void unsubscribe(String destination) {
    if (!_isConnected) return;

    final unsubscribeMessage = jsonEncode([
      'UNSUBSCRIBE',
      {
        'id': 'sub-${destination.hashCode}',
      },
      ''
    ]);

    _channel?.sink.add(unsubscribeMessage);
    log('Unsubscribed from: $destination');
  }

  /// Send a message to the server
  void send(String destination, Map<String, dynamic> body, {String? id}) {
    if (!_isConnected) {
      log('Cannot send: WebSocket not connected');
      return;
    }

    final message = jsonEncode([
      'SEND',
      {
        'destination': destination,
        if (id != null) 'id': id,
      },
      jsonEncode(body),
    ]);

    _channel?.sink.add(message);
  }

  /// Disconnect from WebSocket server
  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    _currentToken = null;
    _baseUrl = null;
    _reconnectAttempts = 0;
    _handlerRegistry.clear();
    log('WebSocket disconnected');
  }

  @override
  String toString() => 'WebSocketService(isConnected: $_isConnected)';
}

