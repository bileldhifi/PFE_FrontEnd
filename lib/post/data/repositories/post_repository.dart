import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/post.dart';

/// Repository for post-related API calls
class PostRepository {
  final ApiClient _apiClient;

  PostRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  /// Create a new post with images
  /// 
  /// Sends multipart form-data to backend
  /// Returns created post with media URLs
  Future<Post> createPost({
    required String tripId,
    int? trackPointId,
    required double latitude,
    required double longitude,
    String? caption,
    required String visibility,
    String? city,
    String? country,
    required List<File> images,
  }) async {
    try {
      // Prepare multipart form data
      final formData = FormData();
      
      // Add parameters
      if (trackPointId != null) {
        formData.fields.add(
          MapEntry('trackPointId', trackPointId.toString()),
        );
      }
      formData.fields.add(
        MapEntry('latitude', latitude.toString()),
      );
      formData.fields.add(
        MapEntry('longitude', longitude.toString()),
      );
      if (caption != null && caption.isNotEmpty) {
        formData.fields.add(MapEntry('text', caption));
      }
      formData.fields.add(MapEntry('visibility', visibility));
      if (city != null && city.isNotEmpty) {
        formData.fields.add(MapEntry('city', city));
      }
      if (country != null && country.isNotEmpty) {
        formData.fields.add(MapEntry('country', country));
      }

      // Add images
      for (final image in images) {
        final fileName = image.path.split('/').last;
        formData.files.add(
          MapEntry(
            'images',
            await MultipartFile.fromFile(
              image.path,
              filename: fileName,
            ),
          ),
        );
      }

      log('Creating post for trip: $tripId with ${images.length} images');

      // ApiClient automatically adds Authorization header
      final response = await _apiClient.post(
        '/posts/$tripId',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      log('Post created successfully: ${response.data['id']}');
      return Post.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      log('Error creating post: ${e.message}', error: e);
      if (e.response?.statusCode == 401) {
        throw Exception('Authentication failed');
      }
      throw Exception(
        'Failed to create post: ${e.response?.data ?? e.message}',
      );
    } catch (e) {
      log('Unexpected error creating post', error: e);
      throw Exception('Failed to create post: $e');
    }
  }

  /// Get posts for a trip
  Future<List<Post>> getPostsByTrip(String tripId) async {
    try {
      // ApiClient automatically adds Authorization header
      final response = await _apiClient.get('/posts/trip/$tripId');

      final posts = (response.data as List)
          .map((json) => Post.fromJson(json as Map<String, dynamic>))
          .toList();

      log('Fetched ${posts.length} posts for trip: $tripId');
      return posts;
    } catch (e) {
      log('Error fetching posts: $e', error: e);
      throw Exception('Failed to fetch posts: $e');
    }
  }

  /// Get posts by track point
  /// Used for displaying media on map markers
  Future<List<Post>> getPostsByTrackPoint(String trackPointId) async {
    try {
      final response = await _apiClient.get(
        '/posts/track-point/$trackPointId',
      );

      final posts = (response.data as List)
          .map((json) => Post.fromJson(json as Map<String, dynamic>))
          .toList();

      log('Fetched ${posts.length} posts for track point: $trackPointId');
      return posts;
    } catch (e) {
      log('Error fetching posts by track point: $e', error: e);
      throw Exception('Failed to fetch posts: $e');
    }
  }
}

