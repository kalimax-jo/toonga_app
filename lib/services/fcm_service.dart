import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../app_constants.dart';
import 'notification_service.dart';
import 'session_manager.dart';

final FirebaseMessaging _messaging = FirebaseMessaging.instance;

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Top-level background handler for FCM.
  log('FCM background message: ${message.messageId}');
}

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final SessionManager _session = SessionManager.instance;
  final NotificationService _notificationService = NotificationService();
  bool _guestTokenRegistered = false;

  Future<void> init() async {
    if (Firebase.apps.isEmpty) {
      debugPrint('[FcmService] Firebase not initialized; skipping messaging setup.');
      return;
    }

    await _requestPermission();

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedAppMessage);

    _messaging.onTokenRefresh.listen((token) {
      log('FCM token refreshed: $token');
      _sendTokenToBackend(token);
    });

    final initialToken = await _messaging.getToken();
    if (initialToken != null) {
      log('FCM token: $initialToken');
      await _sendGuestToken(initialToken);
      await _sendTokenToBackend(initialToken);
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    debugPrint('FCM permission status: ${settings.authorizationStatus}');
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint(
      'FCM foreground message: ${message.messageId} - ${message.notification?.title}',
    );
  }

  void _handleOpenedAppMessage(RemoteMessage message) {
    debugPrint('FCM opened app message: ${message.messageId}');
  }

  Future<void> _sendTokenToBackend(String token) async {
    final bearer = await _session.getToken();
    if (bearer == null || bearer.isEmpty) {
      debugPrint('[ERROR] Skip sending FCM token, no auth token found.');
      debugPrint(
        '[DEBUG] SessionManager.token (static): ${SessionManager.token}',
      );
      return;
    }

    debugPrint(
      '[INFO] Sending FCM token to backend (token=$token, bearer=${bearer.substring(0, 8)}...)',
    );

    final platform = _resolvePlatform();
    debugPrint('[INFO] Platform: $platform');
    await _notificationService.registerDevice(
      deviceToken: token,
      platform: platform,
      appVersion: kAppVersion,
    );
  }

  Future<void> _sendGuestToken(String token) async {
    if (_guestTokenRegistered) return;
    debugPrint('[INFO] Sending guest FCM token to backend (token=$token)');
    final platform = _resolvePlatform();
    await _notificationService.registerGuestDevice(
      deviceToken: token,
      platform: platform,
      appVersion: kAppVersion,
    );
    _guestTokenRegistered = true;
  }

  /// Ensure the current FCM token is registered once there is a saved auth token.
  Future<void> ensureDeviceRegistered() async {
    debugPrint('[INFO] ensureDeviceRegistered() called');
    final fcmToken = await _messaging.getToken();
    final authToken = await _session.getToken();

    debugPrint('[DEBUG] FCM TOKEN: $fcmToken');
    debugPrint(
      '[DEBUG] Auth TOKEN: ${authToken != null ? '${authToken.substring(0, 8)}...' : 'NULL'}',
    );
    debugPrint(
      '[DEBUG] SessionManager.token (static): ${SessionManager.token}',
    );

    if (fcmToken == null || fcmToken.isEmpty) {
      debugPrint('[WARN] FCM token is null or empty, skipping registration');
      return;
    }

    if (authToken == null || authToken.isEmpty) {
      debugPrint('[ERROR] Auth token is null or empty, cannot register device');
      return;
    }

    debugPrint('[INFO] Both tokens available, proceeding with registration');
    debugPrint(
      '[DEBUG] About to call _sendTokenToBackend with FCM token: $fcmToken',
    );
    await _sendTokenToBackend(fcmToken);
    debugPrint('[DEBUG] _sendTokenToBackend completed');
  }

  String _resolvePlatform() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      default:
        return 'unknown';
    }
  }
}
