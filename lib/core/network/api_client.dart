import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String _baseUrl = 'http://localhost:8089/app-backend';
  static const String _storageTokenKey = 'auth_token';
  
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
    _dio.interceptors.add(_loggingInterceptor());
    _dio.interceptors.add(_errorInterceptor());
  }

  // Auth interceptor to add Bearer token
  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: _storageTokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 errors - token expired
        if (error.response?.statusCode == 401) {
          await _storage.delete(key: _storageTokenKey);
          // You can navigate to login screen here if needed
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
  Future<void> saveToken(String token) async {
    await _storage.write(key: _storageTokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _storageTokenKey);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _storageTokenKey);
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
