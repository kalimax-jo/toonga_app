import 'dart:developer';

import '../models/home_notification.dart';
import 'api_client.dart';
import 'session_manager.dart';

class NotificationService {
  NotificationService();

  final ApiClient _apiClient = ApiClient();
  final SessionManager _sessionManager = SessionManager.instance;

  Future<List<HomeNotification>> fetchNotifications() async {
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) return const [];

      final response = await _apiClient.get(
        '/notifications',
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
    final token = await _sessionManager.getToken();
    
    log('[DEBUG] registerDevice invoked');
    log('[DEBUG] Auth token from SessionManager: ${token != null ? '${token.substring(0, 8)}...' : 'NULL'}');
    
    if (token == null || token.isEmpty) {
      log('[ERROR] Auth token is null/empty, cannot register device');
      return;
    }

    try {
      log('[INFO] Registering notification device:');
      log('  - deviceToken: $deviceToken');
      log('  - platform: $platform');
      log('  - appVersion: $appVersion');
      
      final requestBody = {
        'token': deviceToken,
        'platform': platform,
        'app_version': appVersion,
      };
      log('[DEBUG] Request body: $requestBody');
      log('[DEBUG] Headers: Authorization: Bearer ${token.substring(0, 8)}..., Content-Type: application/json');
      
      final response = await _apiClient.post(
        '/notification-device',
        headers: {'Authorization': 'Bearer $token'},
        body: requestBody,
      );
      log('[SUCCESS] Device registration response: $response');
    } catch (error, stackTrace) {
      log('[ERROR] Unable to register notification device: $error');
      log('[ERROR] Stack trace: $stackTrace');
    }
  }

  Future<void> registerGuestDevice({
    required String deviceToken,
    required String platform,
    required String appVersion,
  }) async {
    log('[DEBUG] registerGuestDevice invoked');
    try {
      log('[INFO] Registering guest notification device:');
      log('  - deviceToken: $deviceToken');
      log('  - platform: $platform');
      log('  - appVersion: $appVersion');
      final requestBody = {
        'token': deviceToken,
        'platform': platform,
        'app_version': appVersion,
      };
      log('[DEBUG] Guest request body: $requestBody');
      final response = await _apiClient.post(
        '/public/notification-device',
        body: requestBody,
      );
      log('[SUCCESS] Guest device registration response: $response');
    } catch (error, stackTrace) {
      log('[ERROR] Unable to register guest notification device: $error');
      log('[ERROR] Stack trace: $stackTrace');
    }
  }

  Future<void> markRead(List<int> ids) async {
    if (ids.isEmpty) return;
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) return;

    try {
      await _apiClient.post(
        '/notifications/mark-read',
        headers: {'Authorization': 'Bearer $token'},
        body: {'ids': ids},
      );
    } catch (error) {
      log('Failed to mark notifications as read: $error');
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
}
