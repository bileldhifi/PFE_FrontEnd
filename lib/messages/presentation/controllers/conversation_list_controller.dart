import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary_frontend/auth/presentation/controllers/auth_controller.dart';
import 'package:travel_diary_frontend/core/websocket/websocket_manager.dart';
import 'package:travel_diary_frontend/messages/data/dtos/direct_message_update.dart';
import 'package:travel_diary_frontend/messages/data/repositories/message_repository.dart';
import 'package:travel_diary_frontend/messages/data/dtos/conversation_dto.dart';
import 'package:travel_diary_frontend/messages/presentation/controllers/conversation_controller.dart';

class ConversationListState {
  const ConversationListState({
    this.conversations = const [],
    this.isLoading = false,
    this.error,
  });

  final List<ConversationDto> conversations;
  final bool isLoading;
  final String? error;

  ConversationListState copyWith({
    List<ConversationDto>? conversations,
    bool? isLoading,
    String? error,
  }) {
    return ConversationListState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ConversationListController extends StateNotifier<ConversationListState> {
  ConversationListController(this._ref)
      : _repository = MessageRepository(),
        _manager = _ref.read(webSocketManagerProvider),
        super(const ConversationListState()) {
    _initialization = _loadConversations();
  }

  Future<void>? _initialization;
  final Ref _ref;
  final MessageRepository _repository;
  final WebSocketManager _manager;

  String? get _currentUserId =>
      _ref.read(authControllerProvider).user?.id;

  Future<void> _loadConversations() async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) {
      log('Skipping conversations load: user not authenticated');
      state = state.copyWith(conversations: []);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final conversations = await _repository.fetchConversations();
      state = state.copyWith(
        conversations: conversations,
        isLoading: false,
      );
      for (final conversation in conversations) {
        _subscribeToConversation(conversation.id);
      }
    } catch (e) {
      log('Error loading conversations: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<ConversationDto> ensureConversation(String otherUserId) async {
    try {
      final conversation = await _repository.ensureConversation(otherUserId);
      _upsertConversation(conversation);
      _subscribeToConversation(conversation.id);
      return conversation;
    } catch (e) {
      log('Error ensuring conversation: $e');
      rethrow;
    }
  }

  void refresh() => _loadConversations();

  void handleWebSocketUpdate(DirectMessageUpdateDto update) async {
    if (_initialization != null) {
      await _initialization;
      _initialization = null;
    }
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) return;

    log(
      '[ConversationListController] update for ${update.conversationId} '
      'message=${update.message?.id} recipient=${update.recipientId}',
    );

    try {
      final conversationId = update.conversationId;
      var conversations = [...state.conversations];
      var existingIndex = conversations.indexWhere((c) => c.id == conversationId);

      ConversationDto? existing =
          existingIndex != -1 ? conversations[existingIndex] : null;

      if (existing == null) {
        try {
          final fetched = await _repository.getConversation(conversationId);
          existing = fetched;
          conversations.insert(0, fetched);
          existingIndex = 0;
          _subscribeToConversation(conversationId);
        } catch (e) {
          log('Failed to fetch conversation $conversationId: $e');
          return;
        }
      }

      if (update.message != null) {
        final message = update.message!;
        final unread = update.recipientId == userId
            ? update.recipientUnreadCount ?? existing.unreadCount
            : existing.unreadCount;

        final updated = existing.copyWith(
          lastMessage: message.content,
          lastMessageAt: message.createdAt,
          unreadCount: unread,
        );

        conversations.removeAt(existingIndex);
        conversations.insert(0, updated);
      } else if (update.recipientId == userId) {
        final updated = existing.copyWith(unreadCount: update.recipientUnreadCount ?? 0);
        conversations[existingIndex] = updated;
      } else {
        return;
      }

      state = state.copyWith(conversations: conversations);
      final provider = conversationControllerProvider(conversationId);
      if (_ref.exists(provider)) {
        log('[ConversationListController] notifying active conversation $conversationId');
        _ref.read(provider.notifier).handleWebSocketUpdate(update);
      }
    } catch (e) {
      log('Error handling DM websocket update: $e');
    }
  }

  void _upsertConversation(ConversationDto conversation) {
    final list = [...state.conversations];
    final index = list.indexWhere((c) => c.id == conversation.id);
    if (index != -1) {
      list[index] = conversation;
    } else {
      list.insert(0, conversation);
    }
    state = state.copyWith(conversations: list);
  }

  void _subscribeToConversation(String conversationId) {
    if (conversationId.isEmpty) return;
    final destination = '/topic/dm/$conversationId';
    if (!_manager.service.activeSubscriptions.contains(destination)) {
      _manager.service.subscribe(destination);
    }
  }
}

final conversationListControllerProvider =
    StateNotifierProvider<ConversationListController, ConversationListState>(
  (ref) => ConversationListController(ref),
);

