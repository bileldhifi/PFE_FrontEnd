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
  
  // Track active subscriptions to re-subscribe on reconnect
  final Set<String> _activeSubscriptions = {};

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
      
      // Small delay to ensure connection is fully established
      await Future.delayed(const Duration(milliseconds: 100));

      _sendStompFrame('CONNECT', {
        'accept-version': '1.1,1.2',
        'heart-beat': '10000,10000',
        if (_currentToken != null) 'Authorization': 'Bearer $_currentToken',
      });
      
      // Re-subscribe to all active subscriptions
      _resubscribeAll();
    } catch (e) {
      log('Failed to connect WebSocket: $e');
      _isConnected = false;
      _scheduleReconnect();
      rethrow;
    }
  }

  void _handleRawMessage(dynamic rawMessage) {
    if (rawMessage is! String) return;

    try {
      log('[WebSocket] raw message: $rawMessage');

      if (rawMessage == 'o') {
        log('[WebSocket] connection opened');
        return;
      }

      if (rawMessage == 'h') {
        log('[WebSocket] heartbeat');
        return;
      }

      if (rawMessage.startsWith('a')) {
        final payload = rawMessage.substring(1);
        final List<dynamic> messages = jsonDecode(payload);
        for (final entry in messages) {
          if (entry is String) {
            _handleStompFrame(entry);
          }
        }
        return;
      }

      if (rawMessage.startsWith('c')) {
        log('[WebSocket] connection closed by server: $rawMessage');
        _onConnectionLost();
        return;
      }
    } catch (e) {
      log('Error handling WebSocket message: $e');
    }
  }

  void _handleStompFrame(String frame) {
    final cleaned = frame.replaceAll('\x00', '');
    final parts = cleaned.split('\n\n');
    final headerSection = parts.first;
    final body = parts.length > 1 ? parts.sublist(1).join('\n\n') : '';

    final lines = headerSection.split('\n');
    final command = lines.first.trim();
    final headers = <String, String>{};
    for (final line in lines.skip(1)) {
      final idx = line.indexOf(':');
      if (idx > 0) {
        final key = line.substring(0, idx);
        final value = line.substring(idx + 1);
        headers[key] = value;
      }
    }

    log('[WebSocket] STOMP frame $command headers=$headers body=$body');

    if (command == 'CONNECTED') {
      return;
    }

    if (command != 'MESSAGE') {
      return;
    }

    final destination = headers['destination'];
    if (destination == null) {
      log('STOMP MESSAGE frame missing destination');
      return;
    }

    try {
      final bodyMap = body.isNotEmpty ? jsonDecode(body) as Map<String, dynamic> : <String, dynamic>{};
      final message = WebSocketMessage(
        type: destination.toMessageType().name,
        destination: destination,
        body: bodyMap,
        id: headers['message-id'],
        headers: headers,
      );
      _messageController.add(message);
      _routeMessage(message);
    } catch (e) {
      log('Error parsing STOMP body: $e');
    }
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
    // Track subscription even if not connected (will subscribe on connect)
    _activeSubscriptions.add(destination);
    
    if (!_isConnected) {
      log('WebSocket not connected, subscription queued: $destination');
      return;
    }

    final id = subscriptionId ?? 'sub-${destination.hashCode}';
    _sendStompFrame('SUBSCRIBE', {
      'id': id,
      'destination': destination,
    });
    log('Subscribed to: $destination');
  }

  /// Unsubscribe from a topic/destination
  void unsubscribe(String destination) {
    if (!_isConnected) return;

    _sendStompFrame('UNSUBSCRIBE', {
      'id': 'sub-${destination.hashCode}',
    });
    log('Unsubscribed from: $destination');
  }

  /// Send a message to the server
  void send(String destination, Map<String, dynamic> body, {String? id}) {
    if (!_isConnected) {
      log('Cannot send: WebSocket not connected');
      return;
    }

    _sendStompFrame('SEND', {
      'destination': destination,
      if (id != null) 'id': id,
    }, jsonEncode(body));
  }

  /// Re-subscribe to all active subscriptions
  void _resubscribeAll() {
    if (_activeSubscriptions.isEmpty) {
      log('No active subscriptions to restore');
      return;
    }
    
    log('Re-subscribing to ${_activeSubscriptions.length} topics...');
    for (final destination in _activeSubscriptions) {
      final id = 'sub-${destination.hashCode}';
      _sendStompFrame('SUBSCRIBE', {
        'id': id,
        'destination': destination,
      });
      log('Re-subscribed to: $destination');
    }
  }
  
  /// Get list of active subscriptions
  Set<String> get activeSubscriptions => Set.unmodifiable(_activeSubscriptions);
  
  /// Clear all subscriptions
  void clearSubscriptions() {
    _activeSubscriptions.clear();
  }

  /// Disconnect from WebSocket server
  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    _currentToken = null;
    _baseUrl = null;
    _reconnectAttempts = 0;
    // Don't clear handlers or subscriptions on disconnect - they'll be restored on reconnect
    log('WebSocket disconnected');
  }

  void _sendStompFrame(
      String command, Map<String, String> headers, [String body = '']) {
    final buffer = StringBuffer()..write(command)..write('\n');
    headers.forEach((key, value) {
      buffer.write('$key:$value\n');
    });
    buffer.write('\n');
    if (body.isNotEmpty) {
      buffer.write(body);
    }
    buffer.write('\x00');
    final frame = buffer.toString();
    log('[WebSocket] sending frame: $frame');
    final envelope = jsonEncode([frame]);
    _channel?.sink.add(envelope);
  }

  @override
  String toString() => 'WebSocketService(isConnected: $_isConnected)';
}

