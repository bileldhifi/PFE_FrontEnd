import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:travel_diary_frontend/core/network/api_client.dart';
import 'package:travel_diary_frontend/notifications/data/dtos/notification_response.dart';

class NotificationRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<NotificationResponse>> getNotifications() async {
    try {
      log('Fetching notifications');
      final response = await _apiClient.get('/notifications');
      final List<dynamic> data = response.data;
      return data
          .map((json) => NotificationResponse.fromJson(json))
          .toList();
    } on DioException catch (e) {
      log('Error fetching notifications: $e');
      if (e.response?.statusCode == 403) {
        throw Exception('Access forbidden. Please login again.');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Authentication required. Please login again.');
      }
      rethrow;
    } catch (e) {
      log('Error fetching notifications: $e');
      rethrow;
    }
  }

  Future<List<NotificationResponse>> getUnreadNotifications() async {
    try {
      log('Fetching unread notifications');
      final response = await _apiClient.get('/notifications/unread');
      final List<dynamic> data = response.data;
      return data
          .map((json) => NotificationResponse.fromJson(json))
          .toList();
    } on DioException catch (e) {
      log('Error fetching unread notifications: $e');
      rethrow;
    } catch (e) {
      log('Error fetching unread notifications: $e');
      rethrow;
    }
  }

  Future<int> getUnreadCount() async {
    try {
      log('Fetching unread notification count');
      final response = await _apiClient.get('/notifications/unread/count');
      return response.data as int;
    } on DioException catch (e) {
      log('Error fetching unread count: $e');
      rethrow;
    } catch (e) {
      log('Error fetching unread count: $e');
      rethrow;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      log('Marking notification as read: $notificationId');
      await _apiClient.put('/notifications/$notificationId/read');
    } on DioException catch (e) {
      log('Error marking notification as read: $e');
      rethrow;
    } catch (e) {
      log('Error marking notification as read: $e');
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      log('Marking all notifications as read');
      await _apiClient.put('/notifications/read-all');
    } on DioException catch (e) {
      log('Error marking all notifications as read: $e');
      rethrow;
    } catch (e) {
      log('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      log('Deleting notification: $notificationId');
      await _apiClient.delete('/notifications/$notificationId');
    } on DioException catch (e) {
      log('Error deleting notification: $e');
      rethrow;
    } catch (e) {
      log('Error deleting notification: $e');
      rethrow;
    }
  }
}

