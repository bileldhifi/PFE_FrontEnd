import 'dart:developer';
import 'package:travel_diary_frontend/core/network/api_client.dart';
import 'package:travel_diary_frontend/social/data/dtos/follow_response.dart';

class FollowRepository {
  final ApiClient _apiClient = ApiClient();

  Future<FollowResponse> followUser(String userId) async {
    try {
      log('Following user: $userId');
      final response = await _apiClient.post('/users/$userId/follow');
      return FollowResponse.fromJson(response.data);
    } catch (e) {
      log('Error following user: $e');
      rethrow;
    }
  }

  Future<void> unfollowUser(String userId) async {
    try {
      log('Unfollowing user: $userId');
      await _apiClient.delete('/users/$userId/follow');
    } catch (e) {
      log('Error unfollowing user: $e');
      rethrow;
    }
  }

  Future<bool> isFollowing(String userId) async {
    try {
      final response = await _apiClient.get('/users/$userId/follow-status');
      return response.data as bool;
    } catch (e) {
      log('Error checking follow status: $e');
      return false;
    }
  }

  Future<List<FollowResponse>> getFollowers(String userId) async {
    try {
      final response = await _apiClient.get('/users/$userId/followers');
      final List<dynamic> data = response.data;
      return data.map((json) => FollowResponse.fromJson(json)).toList();
    } catch (e) {
      log('Error fetching followers: $e');
      rethrow;
    }
  }

  Future<List<FollowResponse>> getFollowing(String userId) async {
    try {
      final response = await _apiClient.get('/users/$userId/following');
      final List<dynamic> data = response.data;
      return data.map((json) => FollowResponse.fromJson(json)).toList();
    } catch (e) {
      log('Error fetching following: $e');
      rethrow;
    }
  }
}

