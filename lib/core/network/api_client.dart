import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String _baseUrl = 'http://localhost:8089/app-backend';
  static const String _storageAccessTokenKey = 'access_token';
  static const String _storageRefreshTokenKey = 'refresh_token';
  
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors
    _dio.interceptors.add(_authInterceptor());
    _dio.interceptors.add(_refreshTokenInterceptor());
    _dio.interceptors.add(_loggingInterceptor());
    _dio.interceptors.add(_errorInterceptor());
  }

  // Auth interceptor to add Bearer token
  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: _storageAccessTokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 errors - token expired
        if (error.response?.statusCode == 401) {
          await clearTokens();
          // You can navigate to login screen here if needed
        }
        handler.next(error);
      },
    );
  }

  // Refresh token interceptor
  Interceptor _refreshTokenInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expired, try to refresh
          try {
            final refreshToken = await getRefreshToken();
            if (refreshToken != null) {
              // Try to refresh the token
              final refreshResponse = await Dio().post(
                '$_baseUrl/auth/refresh',
                data: {'refreshToken': refreshToken},
                options: Options(
                  headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                  },
                ),
              );

              if (refreshResponse.statusCode == 200 && refreshResponse.data != null) {
                final newAccessToken = refreshResponse.data['accessToken'] as String;
                final newRefreshToken = refreshResponse.data['refreshToken'] as String;

                // Save new tokens
                await saveTokens(newAccessToken, newRefreshToken);

                // Retry the original request with new token
                final options = error.requestOptions;
                options.headers['Authorization'] = 'Bearer $newAccessToken';

                final response = await _dio.fetch(options);
                handler.resolve(response);
                return;
              }
            }
          } catch (e) {
            // Refresh failed, clear tokens and continue with error
            await clearTokens();
          }
        }
        handler.next(error);
      },
    );
  }

  // Logging interceptor for debugging
  Interceptor _loggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        if (kDebugMode) {
          print('🚀 REQUEST[${options.method}] => ${options.path}');
          print('Headers: ${options.headers}');
          if (options.data != null) {
            print('Data: ${options.data}');
          }
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          print('✅ RESPONSE[${response.statusCode}] => ${response.requestOptions.path}');
          print('Data: ${response.data}');
        }
        handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          print('❌ ERROR[${error.response?.statusCode}] => ${error.requestOptions.path}');
          print('Message: ${error.message}');
          if (error.response?.data != null) {
            print('Error Data: ${error.response?.data}');
          }
        }
        handler.next(error);
      },
    );
  }

  // Error handling interceptor
  Interceptor _errorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) {
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout) {
          error = DioException(
            requestOptions: error.requestOptions,
            error: 'Connection timeout. Please check your internet connection.',
          );
        }
        handler.next(error);
      },
    );
  }

  // Token management methods
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _storageAccessTokenKey, value: accessToken);
    await _storage.write(key: _storageRefreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _storageAccessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _storageRefreshTokenKey);
  }

  Future<String?> getToken() async {
    return await getAccessToken(); // For backward compatibility
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _storageAccessTokenKey, value: token);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _storageAccessTokenKey);
    await _storage.delete(key: _storageRefreshTokenKey);
  }

  Future<void> clearToken() async {
    await clearTokens(); // For backward compatibility
  }

  // HTTP methods
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
