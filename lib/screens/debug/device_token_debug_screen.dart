import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import '../../services/session_manager.dart';
import '../../services/fcm_service.dart';
import '../../services/api_config.dart';

/// Debug screen to test device token registration
class DeviceTokenDebugScreen extends StatefulWidget {
  const DeviceTokenDebugScreen({super.key});

  @override
  State<DeviceTokenDebugScreen> createState() => _DeviceTokenDebugScreenState();
}

class _DeviceTokenDebugScreenState extends State<DeviceTokenDebugScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<String> _logs = [];
  bool _isLoading = false;

  void _addLog(String message) {
    setState(() {
      final timestamp = DateTime.now().toString().split('.')[0];
      _logs.add('[$timestamp] $message');
    });
    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _testDeviceTokenFlow() async {
    setState(() => _isLoading = true);
    _logs.clear();

    try {
      _addLog('========== STARTING DEVICE TOKEN DEBUG TEST ==========');

      // Step 1: Check auth token
      _addLog('\n[STEP 1] Checking Authentication Token');
      final authToken = await SessionManager.instance.getToken();
      _addLog('Auth token from SharedPrefs: ${authToken != null ? '✓ Found (${authToken.substring(0, 20)}...)' : '✗ NULL/EMPTY'}');
      _addLog('Static SessionManager.token: ${SessionManager.token != null ? '✓ Found' : '✗ NULL'}');

      if (authToken == null || authToken.isEmpty) {
        _addLog('⚠️  WARNING: No auth token found. Please login first!');
        _addLog('========== TEST FAILED ==========');
        return;
      }

      // Step 2: Check FCM token
      _addLog('\n[STEP 2] Checking FCM Token');
      try {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        _addLog('FCM token: ${fcmToken != null ? '✓ Found' : '✗ NULL'}');
        if (fcmToken != null) {
          _addLog('FCM token value: $fcmToken');
        } else {
          _addLog('⚠️  WARNING: FCM token is null!');
          _addLog('========== TEST FAILED ==========');
          return;
        }
      } catch (e) {
        _addLog('✗ Error getting FCM token: $e');
        return;
      }

      // Step 3: Test FCM permissions
      _addLog('\n[STEP 3] Checking FCM Permissions');
      try {
        final settings = await FirebaseMessaging.instance.getNotificationSettings();
        _addLog('Authorization status: ${settings.authorizationStatus}');
      } catch (e) {
        _addLog('✗ Error checking permissions: $e');
      }

      // Step 4: Test direct HTTP call to API
      _addLog('\n[STEP 4] Testing Direct HTTP Request to Backend');
      try {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        final url = ApiConfig.uri('/api/notification-device');
        _addLog('URL: $url');

        final body = {
          'token': fcmToken,
          'platform': 'android',
          'app_version': '1.0.0',
        };

        _addLog('Request body: ${jsonEncode(body)}');
        _addLog('Authorization: Bearer ${authToken.substring(0, 8)}...');

        final response = await http.post(
          url,
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 10));

        _addLog('Response status: ${response.statusCode}');
        _addLog('Response headers: ${response.headers}');
        _addLog('Response body: ${response.body}');

        if (response.statusCode >= 200 && response.statusCode < 300) {
          _addLog('✓ Direct HTTP call SUCCEEDED');
        } else {
          _addLog('✗ Direct HTTP call FAILED (${response.statusCode})');
        }
      } catch (e, st) {
        _addLog('✗ Direct HTTP error: $e');
        _addLog('Stack: $st');
      }

      // Step 5: Attempt through FcmService
      _addLog('\n[STEP 5] Attempting Device Registration via FcmService');
      try {
        await FcmService.instance.ensureDeviceRegistered();
        _addLog('✓ ensureDeviceRegistered() completed');
      } catch (e) {
        _addLog('✗ Error during registration: $e');
      }

      _addLog('\n========== TEST COMPLETED ==========');
    } catch (e, stackTrace) {
      _addLog('✗ Unexpected error: $e');
      _addLog('Stack trace: $stackTrace');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestFCMPermissions() async {
    _addLog('\n[ACTION] Requesting FCM Permissions...');
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      _addLog('✓ Permission request completed: ${settings.authorizationStatus}');
    } catch (e) {
      _addLog('✗ Error requesting permissions: $e');
    }
  }

  Future<void> _clearLogs() async {
    setState(() => _logs.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Token Debug'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Control buttons
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[900],
            child: Column(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testDeviceTokenFlow,
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Run Full Debug Test'),
                ),
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _requestFCMPermissions,
                        icon: const Icon(Icons.notifications),
                        label: const Text('Request FCM Perms'),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _clearLogs,
                        icon: const Icon(Icons.delete),
                        label: const Text('Clear Logs'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Log display
          Expanded(
            child: Container(
              color: Colors.black87,
              child: _logs.isEmpty
                  ? const Center(
                      child: Text(
                        'No logs yet. Tap "Run Full Debug Test" to start.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        final isError = log.contains('✗') || log.contains('ERROR');
                        final isSuccess = log.contains('✓') || log.contains('SUCCESS');
                        final isWarning = log.contains('⚠️') || log.contains('WARNING');

                        Color textColor = Colors.grey[400]!;
                        if (isError) textColor = Colors.red;
                        if (isSuccess) textColor = Colors.green;
                        if (isWarning) textColor = Colors.orange;

                        return Text(
                          log,
                          style: TextStyle(
                            color: textColor,
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
