import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:travel_diary_frontend/core/network/api_client.dart';
import 'package:travel_diary_frontend/social/data/dtos/comment_request.dart';
import 'package:travel_diary_frontend/social/data/dtos/comment_response.dart';
import 'package:travel_diary_frontend/social/data/dtos/post_comment_update.dart';

class CommentRepository {
  final ApiClient _apiClient = ApiClient();

  Future<PostCommentUpdate> addComment(String postId, String content) async {
    try {
      log('Adding comment to post: $postId');
      final request = CommentRequest(postId: postId, content: content);
      final response = await _apiClient.post(
        '/posts/$postId/comments',
        data: request.toJson(),
      );
      return PostCommentUpdate.fromJson(response.data);
    } catch (e) {
      log('Error adding comment: $e');
      rethrow;
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      log('Deleting comment: $commentId');
      await _apiClient.delete('/posts/comments/$commentId');
    } on DioException catch (e) {
      log('Error deleting comment: $e');
      final statusCode = e.response?.statusCode;
      if (statusCode == 404) {
        throw Exception('Comment not found');
      } else if (statusCode == 403 || statusCode == 401) {
        throw Exception('Not authorized to delete this comment');
      } else {
        throw Exception('Failed to delete comment. Please try again.');
      }
    } catch (e) {
      log('Error deleting comment: $e');
      rethrow;
    }
  }

  Future<List<CommentResponse>> getComments(String postId) async {
    try {
      final response = await _apiClient.get('/posts/$postId/comments');
      final List<dynamic> data = response.data;
      return data.map((json) => CommentResponse.fromJson(json)).toList();
    } catch (e) {
      log('Error fetching comments: $e');
      rethrow;
    }
  }
}

