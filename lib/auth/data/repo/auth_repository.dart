import 'package:dio/dio.dart';
import '../../../../core/network/network_service.dart';
import '../dtos/login_request.dart';
import '../dtos/auth_response.dart';
import '../dtos/register_request.dart';
import '../dtos/forgot_password_request.dart';
import '../dtos/change_password_request.dart';
import '../models/user.dart';

class AuthRepository {
  final _apiClient = networkService.apiClient;

  /// Login with email and password
  /// Returns AuthResponse with access token and user data
  Future<AuthResponse> login(String email, String password) async {
    try {
      final request = LoginRequest(email: email, password: password);
      
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/auth/login',
        data: request.toJson(),
      );

      if (response.statusCode == 200 && response.data != null) {
        final authResponse = AuthResponse.fromJson(response.data!);
        
        // Save tokens to secure storage
        if (authResponse.refreshToken != null) {
          await _apiClient.saveTokens(authResponse.accessToken, authResponse.refreshToken!);
        } else {
          // Fallback to old method if refresh token is not available
          await _apiClient.saveToken(authResponse.accessToken);
        }
        
        return authResponse;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          error: 'Login failed: Invalid response',
        );
      }
    } on DioException catch (e) {
      // Check if it's a login failure (403)
      if (e.response?.statusCode == 403) {
        throw Exception('Invalid email or password. Please check your credentials and try again.');
      }
      throw _handleAuthError(e);
    }
  }

  /// Register a new user
  /// Returns User data of the created user
  Future<User> register({
    required String username,
    required String email,
    required String password,
    String defaultVisibility = 'FRIENDS',
  }) async {
    try {
      final request = RegisterRequest(
        username: username,
        email: email,
        password: password,
        defaultVisibility: defaultVisibility,
      );

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/auth/register',
        data: request.toJson(),
      );

      if (response.statusCode == 200 && response.data != null) {
        return User.fromJson(response.data!);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          error: 'Registration failed: Invalid response',
        );
      }
    } on DioException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Send forgot password email
  /// Returns success message
  Future<String> forgotPassword(String email) async {
    try {
      final response = await _apiClient.post<String>(
        '/auth/forgot-password',
        queryParameters: {'email': email},
      );

      if (response.statusCode == 200) {
        return response.data ?? 'Password reset email sent!';
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          error: 'Failed to send reset email',
        );
      }
    } on DioException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Reset password with token
  /// Returns success message
  Future<String> resetPassword(String token, String newPassword) async {
    try {
      final response = await _apiClient.post<String>(
        '/auth/reset-password',
        queryParameters: {
          'token': token,
          'newPassword': newPassword,
        },
      );

      if (response.statusCode == 200) {
        return response.data ?? 'Password reset successful!';
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          error: 'Failed to reset password',
        );
      }
    } on DioException catch (e) {
      throw _handleAuthError(e);
    }
  }

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
      throw _handleAuthError(e);
    }
  }

  /// Change password for authenticated user
  /// Requires authentication
  Future<String> changePassword(String currentPassword, String newPassword) async {
    try {
      final request = ChangePasswordRequest(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      final response = await _apiClient.put<String>(
        '/auth/change-password',
        data: request.toJson(),
      );

      if (response.statusCode == 200 && response.data != null) {
        // Backend returns a plain string, not JSON
        return response.data!;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          error: 'Failed to change password',
        );
      }
    } on DioException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Check if user is authenticated
  /// Returns true if valid token exists
  Future<bool> isAuthenticated() async {
    final token = await _apiClient.getToken();
    return token != null && token.isNotEmpty;
  }

  /// Refresh access token using refresh token
  /// Returns new AuthResponse with fresh tokens
  Future<AuthResponse> refreshToken() async {
    try {
      final refreshToken = await _apiClient.getRefreshToken();
      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final authResponse = AuthResponse.fromJson(response.data!);

        // Save new tokens
        if (authResponse.refreshToken != null) {
          await _apiClient.saveTokens(authResponse.accessToken, authResponse.refreshToken!);
        } else {
          await _apiClient.saveToken(authResponse.accessToken);
        }

        return authResponse;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          error: 'Token refresh failed: Invalid response',
        );
      }
    } on DioException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Logout user
  /// Clears stored tokens
  Future<void> logout() async {
    await _apiClient.clearTokens();
  }

  /// Handle authentication errors
  Exception _handleAuthError(DioException e) {
    switch (e.response?.statusCode) {
      case 400:
        return Exception('Invalid request. Please check your input and try again.');
      case 401:
        return Exception('Authentication failed. Please check your credentials.');
      case 403:
        // This could be CORS, login failure, or wrong current password - check the endpoint
        final path = e.requestOptions.path;
        if (path.contains('/auth/login')) {
          return Exception('Invalid email or password. Please check your credentials and try again.');
        }
        if (path.contains('/auth/change-password')) {
          return Exception('Current password is incorrect. Please check your current password and try again.');
        }
        return Exception('Access forbidden. This might be a CORS issue if running on web. Try running on a mobile device or emulator.');
      case 409:
        return Exception('Email or username already exists. Please use different credentials.');
      case 404:
        return Exception('User not found. Please check your email address.');
      case 422:
        return Exception('Invalid token or token expired. Please login again.');
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
