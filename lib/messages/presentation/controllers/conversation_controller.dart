import 'dart:async';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary_frontend/auth/presentation/controllers/auth_controller.dart';
import 'package:travel_diary_frontend/core/websocket/websocket_manager.dart';
import 'package:travel_diary_frontend/core/network/api_client.dart';
import 'package:travel_diary_frontend/messages/data/dtos/direct_message_dto.dart';
import 'package:travel_diary_frontend/messages/data/dtos/direct_message_update.dart';
import 'package:travel_diary_frontend/messages/data/repositories/message_repository.dart';

class ConversationState {
  const ConversationState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.hasMore = true,
    this.error,
  });

  final List<DirectMessageDto> messages;
  final bool isLoading;
  final bool isSending;
  final bool hasMore;
  final String? error;

  ConversationState copyWith({
    List<DirectMessageDto>? messages,
    bool? isLoading,
    bool? isSending,
    bool? hasMore,
    String? error,
  }) {
    return ConversationState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

class ConversationController extends StateNotifier<ConversationState> {
  ConversationController(
    this._ref, {
    required this.conversationId,
  })  : _repository = MessageRepository(),
        super(const ConversationState()) {
    Future.microtask(_ensureWebSocketReady);
    _subscribeToTopic();
    _loadInitialMessages();
  }

  final Ref _ref;
  final MessageRepository _repository;
  final String conversationId;

  bool _isMarkingRead = false;
  DateTime? _lastReadRequest;

  String? get _currentUserId =>
      _ref.read(authControllerProvider).user?.id;

  WebSocketManager get _manager => _ref.read(webSocketManagerProvider);

  Future<void> _ensureWebSocketReady() async {
    if (_manager.service.isConnected) {
      log('[ConversationController] WebSocket already connected');
      return;
    }
    log('[ConversationController] WebSocket not connected, attempting init');
    try {
      final token = await ApiClient().getAccessToken();
      if (token != null) {
        await _manager.initialize(token);
        log('[ConversationController] WebSocket initialized');
      } else {
        log('[ConversationController] No access token available; cannot init WebSocket');
      }
    } catch (e) {
      log('Error initializing WebSocket: $e');
    }
  }

  Future<void> _loadInitialMessages() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final messages = await _repository.fetchMessages(
        conversationId,
        limit: 50,
      );
      state = state.copyWith(
        messages: messages,
        hasMore: messages.length == 50,
        isLoading: false,
      );
      await _maybeMarkAsRead();
    } catch (e) {
      log('Error loading conversation $conversationId messages: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    final oldest = state.messages.isEmpty ? null : state.messages.first.createdAt;
    if (oldest == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final messages = await _repository.fetchMessages(
        conversationId,
        limit: 50,
        before: oldest,
      );
      final combined = [...messages, ...state.messages];
      state = state.copyWith(
        messages: combined,
        hasMore: messages.length == 50,
        isLoading: false,
      );
    } catch (e) {
      log('Error loading older messages: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || state.isSending) return;
    state = state.copyWith(isSending: true);
    try {
      final message = await _repository.sendMessage(conversationId, content.trim());
      _addOrUpdateMessage(message);
      state = state.copyWith(isSending: false);
    } catch (e) {
      log('Error sending message: $e');
      state = state.copyWith(
        isSending: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> markAsRead() async {
    await _markConversationAsRead();
  }

  void handleWebSocketUpdate(DirectMessageUpdateDto update) {
    try {
      if (update.message != null) {
        log(
          '[ConversationController] $conversationId '
          'received message ${update.message!.id} '
          'from ${update.message!.senderId}',
        );
        _addOrUpdateMessage(update.message!);
        final currentUserId = _currentUserId;
        if (currentUserId != null &&
            update.message!.senderId != currentUserId) {
          _maybeMarkAsRead();
        }
      } else if (update.recipientId != null &&
          update.recipientId != _currentUserId) {
        // Other participant marked as read - nothing to do for now
      }
    } catch (e) {
      log('Error processing DM update: $e');
    }
  }

  void _addOrUpdateMessage(DirectMessageDto message) {
    final list = [...state.messages];
    final index = list.indexWhere((m) => m.id == message.id);

    if (index != -1) {
      log('[ConversationController] updating existing message ${message.id}');
      list[index] = message;
    } else {
      log('[ConversationController] adding new message ${message.id}');
      list.add(message);
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    state = state.copyWith(
      messages: list,
      hasMore: list.length >= 50 ? state.hasMore : state.hasMore,
    );
  }

  Future<void> _maybeMarkAsRead() async {
    final userId = _currentUserId;
    if (userId == null) return;

    final lastIncoming = state.messages.where(
      (m) => m.senderId != userId && m.readAt == null,
    );

    if (lastIncoming.isEmpty) return;

    final now = DateTime.now();
    if (_isMarkingRead) return;
    if (_lastReadRequest != null &&
        now.difference(_lastReadRequest!).inSeconds < 3) {
      return;
    }

    await _markConversationAsRead();
  }

  Future<void> _markConversationAsRead() async {
    if (_isMarkingRead) return;
    _isMarkingRead = true;
    _lastReadRequest = DateTime.now();
    try {
      await _repository.markConversationAsRead(conversationId);
    } catch (e) {
      log('Error marking conversation as read: $e');
    } finally {
      _isMarkingRead = false;
    }
  }

  void _subscribeToTopic() {
    final topic = '/topic/dm/$conversationId';
    _manager.service.subscribe(topic);
    _ref.onDispose(() {
      _manager.service.unsubscribe(topic);
    });
  }
}

final conversationControllerProvider = StateNotifierProvider.autoDispose
    .family<ConversationController, ConversationState, String>(
  (ref, conversationId) => ConversationController(
    ref,
    conversationId: conversationId,
  ),
);

