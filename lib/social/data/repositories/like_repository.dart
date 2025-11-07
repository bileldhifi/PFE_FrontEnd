import 'dart:developer';
import 'package:travel_diary_frontend/core/network/api_client.dart';
import 'package:travel_diary_frontend/social/data/dtos/like_response.dart';
import 'package:travel_diary_frontend/social/data/dtos/post_like_update.dart';

class LikeRepository {
  final ApiClient _apiClient = ApiClient();

  Future<PostLikeUpdate> likePost(String postId) async {
    try {
      log('Liking post: $postId');
      final response = await _apiClient.post('/posts/$postId/like');
      return PostLikeUpdate.fromJson(response.data);
    } catch (e) {
      log('Error liking post: $e');
      rethrow;
    }
  }

  Future<PostLikeUpdate> unlikePost(String postId) async {
    try {
      log('Unliking post: $postId');
      final response = await _apiClient.delete('/posts/$postId/like');
      return PostLikeUpdate.fromJson(response.data);
    } catch (e) {
      log('Error unliking post: $e');
      rethrow;
    }
  }

  Future<bool> isLiked(String postId) async {
    try {
      final response = await _apiClient.get('/posts/$postId/like-status');
      return response.data as bool;
    } catch (e) {
      log('Error checking like status: $e');
      return false;
    }
  }

  Future<List<LikeResponse>> getLikes(String postId) async {
    try {
      final response = await _apiClient.get('/posts/$postId/likes');
      final List<dynamic> data = response.data;
      return data.map((json) => LikeResponse.fromJson(json)).toList();
    } catch (e) {
      log('Error fetching likes: $e');
      rethrow;
    }
  }
}

