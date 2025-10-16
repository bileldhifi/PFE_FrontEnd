import 'package:dio/dio.dart';
import '../../../auth/data/models/user.dart';
import '../../../core/network/network_service.dart';
import '../dtos/update_profile_request.dart';

class ProfileRepository {
  final _apiClient = networkService.apiClient;

  /// Get current user profile
  /// Requires authentication
  Future<User> getCurrentUser() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/users/me');

      if (response.statusCode == 200 && response.data != null) {
        return User.fromJson(response.data!);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          error: 'Failed to get user profile',
        );
      }
    } on DioException catch (e) {
      throw _handleProfileError(e);
    }
  }

  /// Get user profile by ID
  /// Requires authentication
  /// Note: This endpoint was removed, using getCurrentUser instead
  Future<User> getUserById(String userId) async {
    try {
      // For now, we'll use getCurrentUser since we removed the /users/{userId} endpoint
      // TODO: Re-implement this endpoint if needed for viewing other users' profiles
      final response = await _apiClient.get<Map<String, dynamic>>('/users/me');

      if (response.statusCode == 200 && response.data != null) {
        return User.fromJson(response.data!);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          error: 'Failed to get user profile',
        );
      }
    } on DioException catch (e) {
      throw _handleProfileError(e);
    }
  }

  /// Update current user profile
  /// Requires authentication
  Future<User> updateProfile(UpdateProfileRequest request) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '/users/me',
        data: request.toJson(),
      );

      if (response.statusCode == 200 && response.data != null) {
        return User.fromJson(response.data!);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          error: 'Failed to update profile',
        );
      }
    } on DioException catch (e) {
      throw _handleProfileError(e);
    }
  }

  /// Delete user account
  /// Requires authentication
  Future<void> deleteAccount() async {
    try {
      final response = await _apiClient.delete('/users/me');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: 'Failed to delete account',
        );
      }
    } on DioException catch (e) {
      throw _handleProfileError(e);
    }
  }

  /// Handle profile-related errors
  Exception _handleProfileError(DioException e) {
    switch (e.response?.statusCode) {
      case 400:
        return Exception('Invalid request. Please check your input and try again.');
      case 401:
        return Exception('Authentication required. Please login again.');
      case 403:
        return Exception('Access forbidden. You may not have permission to perform this action.');
      case 404:
        return Exception('User not found. The profile may have been deleted.');
      case 409:
        return Exception('Username already exists. Please choose a different username.');
      case 422:
        return Exception('Invalid data provided. Please check your input.');
      case 500:
        return Exception('Server error. Please try again later.');
      default:
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          return Exception('Connection timeout. Please check your internet connection and try again.');
        }
        if (e.type == DioExceptionType.connectionError) {
          return Exception('Unable to connect to server. Please check your internet connection.');
        }
        return Exception('An unexpected error occurred. Please try again.');
    }
  }
}
