import 'dart:convert';
import 'dart:developer' as developer;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import '../../services/session_manager.dart';
import '../../services/api_config.dart';

/// Standalone test to manually test device registration
Future<void> testDeviceRegistrationManual() async {
  developer.log('========== MANUAL DEVICE REGISTRATION TEST ==========');

  // Step 1: Get tokens
  final authToken = await SessionManager.instance.getToken();
  final fcmToken = await FirebaseMessaging.instance.getToken();

  developer.log('[TEST] Auth Token: ${authToken ?? 'NULL'}');
  developer.log('[TEST] FCM Token: ${fcmToken ?? 'NULL'}');

  if (authToken == null || authToken.isEmpty) {
    developer.log('[ERROR] No auth token. Please login first!');
    return;
  }

  if (fcmToken == null || fcmToken.isEmpty) {
    developer.log('[ERROR] No FCM token available');
    return;
  }

  // Step 2: Build request
  final url = ApiConfig.uri('/api/notification-device');
  developer.log('[TEST] URL: $url');

  final body = {
    'token': fcmToken,
    'platform': 'android', // or ios
    'app_version': '1.0.0',
  };

  final headers = {
    'Authorization': 'Bearer $authToken',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  developer.log('[TEST] Request Headers:');
  headers.forEach((key, value) {
    final displayValue = key == 'Authorization' 
        ? 'Bearer ${authToken.substring(0, 8)}...'
        : value;
    developer.log('  $key: $displayValue');
  });

  developer.log('[TEST] Request Body: ${jsonEncode(body)}');

  // Step 3: Make request
  try {
    developer.log('[TEST] Sending POST request...');
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 10));

    developer.log('[TEST] Response Status: ${response.statusCode}');
    developer.log('[TEST] Response Headers: ${response.headers}');
    developer.log('[TEST] Response Body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      developer.log('[SUCCESS] Device registration successful!');
    } else {
      developer.log('[ERROR] Registration failed with status ${response.statusCode}');
      try {
        final decoded = jsonDecode(response.body);
        developer.log('[ERROR] Error details: $decoded');
      } catch (e) {
        developer.log('[ERROR] Could not parse error response');
      }
    }
  } catch (e, stackTrace) {
    developer.log('[ERROR] Request failed: $e');
    developer.log('[ERROR] Stack trace: $stackTrace');
  }

  developer.log('========== TEST COMPLETED ==========');
}
