import 'dart:io';
import 'package:dio/dio.dart';
import 'package:travel_diary_frontend/core/network/network_service.dart';

class AvatarRepository {
  final _apiClient = networkService.apiClient;

  /// Upload avatar image for current user
  /// Requires authentication
  Future<String> uploadAvatar(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final response = await _apiClient.post<String>(
        '/users/me/avatar',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        // Convert relative path to full URL
        String avatarPath = response.data!;
        if (avatarPath.startsWith('/')) {
          // Remove leading slash and construct full URL
          avatarPath = avatarPath.substring(1);
        }
        return 'http://localhost:8089/app-backend/$avatarPath';
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          error: 'Failed to upload avatar',
        );
      }
    } on DioException catch (e) {
      throw _handleAvatarError(e);
    }
  }

  /// Delete current user's avatar
  /// Requires authentication
  Future<void> deleteAvatar() async {
    try {
      final response = await _apiClient.delete('/users/me/avatar');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: 'Failed to delete avatar',
        );
      }
    } on DioException catch (e) {
      throw _handleAvatarError(e);
    }
  }

  /// Handle avatar-related errors
  Exception _handleAvatarError(DioException e) {
    switch (e.response?.statusCode) {
      case 400:
        return Exception('Invalid request. Please check your file and try again.');
      case 401:
        return Exception('Authentication failed. Please login again.');
      case 403:
        return Exception('Access forbidden. You do not have permission to perform this action.');
      case 413:
        return Exception('File too large. Please choose a smaller image.');
      case 415:
        return Exception('Unsupported file type. Please choose an image file.');
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
