# WebSocket Architecture

This directory contains the core WebSocket infrastructure for the app. It's designed to be extensible and reusable for future features.

## Architecture Overview

```
core/websocket/
├── websocket_service.dart       # Low-level connection management
├── websocket_manager.dart        # Singleton manager for app-wide connection
├── websocket_message.dart        # Base message types and enums
├── websocket_message_handler.dart # Handler interface and registry
└── README.md                     # This file
```

## Usage

### 1. Register a Handler (Feature-Specific)

Each feature (social, chat, notifications) should create its own handler:

```dart
// social/data/services/social_websocket_handler.dart
class SocialWebSocketHandler implements WebSocketMessageHandler {
  @override
  WebSocketMessageType get messageType => WebSocketMessageType.like;
  
  @override
  String get destinationPattern => '/topic/posts/';
  
  @override
  bool handleMessage(WebSocketMessage message) {
    // Handle like/comment updates
    return true;
  }
}
```

### 2. Register Handler in Your Screen

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final manager = ref.read(webSocketManagerProvider);
    final handler = SocialWebSocketHandler(ref);
    manager.service.registerHandler(handler);
  });
}
```

### 3. Subscribe to Topics

```dart
final manager = ref.read(webSocketManagerProvider);
manager.service.subscribe('/topic/posts/$postId/likes');
```

### 4. Send Messages

```dart
manager.service.send('/app/chat/send', {
  'userId': userId,
  'message': message,
});
```

## Adding New Features

### Example: Chat Feature

1. Create handler:
```dart
// chat/data/services/chat_websocket_handler.dart
class ChatWebSocketHandler implements WebSocketMessageHandler {
  @override
  WebSocketMessageType get messageType => WebSocketMessageType.chat;
  
  @override
  String get destinationPattern => '/topic/chat/';
  
  @override
  bool handleMessage(WebSocketMessage message) {
    // Handle chat messages
    return true;
  }
}
```

2. Register in chat screen
3. Subscribe to chat topics
4. Done!

## Benefits

- **Separation of Concerns**: Core WebSocket logic is separate from feature logic
- **Extensibility**: Easy to add new features without modifying core code
- **Reusability**: Single connection for all features
- **Testability**: Each handler can be tested independently
- **Maintainability**: Clear structure for future developers

## Future Features

This architecture supports:
- ✅ Likes/Comments (implemented)
- 🔄 Notifications
- 🔄 Chat/Messaging
- 🔄 Typing indicators
- 🔄 Online status
- 🔄 Live location updates
- 🔄 Real-time trip sharing

