import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:travel_diary_frontend/core/network/api_client.dart';
import 'package:travel_diary_frontend/messages/data/dtos/conversation_dto.dart';
import 'package:travel_diary_frontend/messages/data/dtos/direct_message_dto.dart';

class MessageRepository {
  MessageRepository() : _apiClient = ApiClient();

  final ApiClient _apiClient;

  Future<List<ConversationDto>> fetchConversations() async {
    try {
      log('Fetching conversations');
      final response = await _apiClient.get('/messages/conversations');
      final data = response.data as List<dynamic>;
      return data
          .map((json) => ConversationDto.fromJson(
                Map<String, dynamic>.from(json as Map),
              ))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        log('No conversations found yet');
        return [];
      }
      _handleDioError('fetch conversations', e);
      rethrow;
    } catch (e) {
      log('Error fetching conversations: $e');
      rethrow;
    }
  }

  Future<ConversationDto> ensureConversation(String otherUserId) async {
    try {
      log('Ensuring conversation with $otherUserId');
      final response = await _apiClient.post(
        '/messages/conversations',
        data: {'otherUserId': otherUserId},
      );
      return ConversationDto.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      _handleDioError('ensure conversation', e);
      rethrow;
    } catch (e) {
      log('Error ensuring conversation: $e');
      rethrow;
    }
  }

  Future<ConversationDto> getConversation(String conversationId) async {
    try {
      log('Fetching conversation $conversationId');
      final response =
          await _apiClient.get('/messages/conversations/$conversationId');
      return ConversationDto.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      _handleDioError('get conversation', e);
      rethrow;
    } catch (e) {
      log('Error fetching conversation: $e');
      rethrow;
    }
  }

  Future<List<DirectMessageDto>> fetchMessages(
    String conversationId, {
    DateTime? before,
    int limit = 50,
  }) async {
    try {
      log('Fetching messages for conversation $conversationId (limit=$limit, before=$before)');
      final queryParameters = <String, dynamic>{
        'limit': limit,
        if (before != null) 'before': before.toIso8601String(),
      };

      final response = await _apiClient.get(
        '/messages/conversations/$conversationId/messages',
        queryParameters: queryParameters,
      );

      final data = response.data as List<dynamic>;
      return data
          .map((json) => DirectMessageDto.fromJson(
                Map<String, dynamic>.from(json as Map),
              ))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        log('No messages yet for conversation $conversationId');
        return [];
      }
      _handleDioError('fetch messages', e);
      rethrow;
    } catch (e) {
      log('Error fetching messages: $e');
      rethrow;
    }
  }

  Future<DirectMessageDto> sendMessage(
    String conversationId,
    String content,
  ) async {
    try {
      log('Sending message in conversation $conversationId');
      final response = await _apiClient.post(
        '/messages/conversations/$conversationId/messages',
        data: {'content': content},
      );

      return DirectMessageDto.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      _handleDioError('send message', e);
      rethrow;
    } catch (e) {
      log('Error sending message: $e');
      rethrow;
    }
  }

  Future<void> markConversationAsRead(String conversationId) async {
    try {
      log('Marking conversation $conversationId as read');
      await _apiClient.post('/messages/conversations/$conversationId/read');
    } on DioException catch (e) {
      _handleDioError('mark conversation as read', e);
      rethrow;
    } catch (e) {
      log('Error marking conversation as read: $e');
      rethrow;
    }
  }

  void _handleDioError(String action, DioException exception) {
    final status = exception.response?.statusCode;
    final reason = exception.response?.statusMessage;
    log('Failed to $action. Status: $status $reason Error: ${exception.message}');
    if (status == 401 || status == 403) {
      throw Exception('Authentication error. Please login again.');
    }
  }
}

