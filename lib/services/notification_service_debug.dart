import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/home_notification.dart';
import 'api_client.dart';
import 'session_manager.dart';

/// Debug version of NotificationService with enhanced logging
class NotificationServiceDebug {
  NotificationServiceDebug();

  final ApiClient _apiClient = ApiClient();
  final SessionManager _sessionManager = SessionManager.instance;

  Future<List<HomeNotification>> fetchNotifications() async {
    final token = await _sessionManager.getToken();
    developer.log('[DEBUG] fetchNotifications: token=$token');
    if (token == null || token.isEmpty) return const [];

    final response = await _apiClient.get(
      '/api/notifications',
      headers: {'Authorization': 'Bearer $token'},
    );
    final records = _extractItems(response);
    return records.map(HomeNotification.fromJson).toList();
  }

  Future<void> registerDevice({
    required String deviceToken,
    required String platform,
    required String appVersion,
  }) async {
    developer.log('[DEBUG] registerDevice called with:');
    developer.log('  - deviceToken: $deviceToken');
    developer.log('  - platform: $platform');
    developer.log('  - appVersion: $appVersion');

    final token = await _sessionManager.getToken();
    developer.log('[DEBUG] Auth token from SessionManager: ${token != null ? '${token.substring(0, 8)}...' : 'NULL'}');
    
    if (token == null || token.isEmpty) {
      developer.log('[ERROR] No auth token found! Device registration skipped.');
      return;
    }

    try {
      developer.log('[DEBUG] Attempting to POST to /api/notification-device');
      final response = await _apiClient.post(
        '/api/notification-device',
        headers: {'Authorization': 'Bearer $token'},
        body: {
          'token': deviceToken,
          'platform': platform,
          'app_version': appVersion,
        },
      );
      developer.log('[SUCCESS] Device registration response: $response');
    } catch (error) {
      developer.log('[ERROR] Device registration failed: $error');
      developer.log('[ERROR] Stack trace: $error');
    }
  }

  Future<void> markRead(List<int> ids) async {
    if (ids.isEmpty) return;
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) return;

    try {
      await _apiClient.post(
        '/api/notifications/mark-read',
        headers: {'Authorization': 'Bearer $token'},
        body: {'ids': ids},
      );
    } catch (error) {
      developer.log('[ERROR] Failed to mark notifications as read: $error');
    }
  }

  List<Map<String, dynamic>> _extractItems(Map<String, dynamic> response) {
    final raw =
        response['data'] ??
        response['notifications'] ??
        response['items'] ??
        response['records'];
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList();
    }
    return const [];
  }

  /// Test method to verify device registration prerequisites
  Future<void> testDeviceRegistration() async {
    developer.log('========== DEVICE REGISTRATION DEBUG TEST ==========');
    
    // Check auth token
    final authToken = await _sessionManager.getToken();
    developer.log('[TEST] Auth token exists: ${authToken != null && authToken.isNotEmpty}');
    if (authToken != null) {
      developer.log('[TEST] Auth token (first 20 chars): ${authToken.substring(0, 20)}');
    }

    // Check FCM token
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      developer.log('[TEST] FCM token exists: ${fcmToken != null && fcmToken.isNotEmpty}');
      developer.log('[TEST] FCM token: $fcmToken');
    } catch (e) {
      developer.log('[TEST] Failed to get FCM token: $e');
    }

    // Test API connectivity
    try {
      developer.log('[TEST] Testing API connectivity...');
      final response = await _apiClient.get('/api/notifications', headers: {
        'Authorization': 'Bearer ${authToken ?? 'NO_TOKEN'}'
      });
      developer.log('[TEST] API is reachable. Response keys: ${response.keys}');
    } catch (e) {
      developer.log('[TEST] API is not reachable: $e');
    }

    developer.log('========== END DEBUG TEST ==========');
  }
}
