import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'api_client.dart';

enum AppVersionStatus {
  allowed,
  optionalUpdate,
  forceUpdate,
}

class AppVersionCheckResult {
  const AppVersionCheckResult({
    required this.status,
    required this.message,
    required this.storeUrl,
    required this.platform,
  });

  factory AppVersionCheckResult.allowed(String platform) =>
      AppVersionCheckResult(
        status: AppVersionStatus.allowed,
        message: 'App is up to date',
        storeUrl: null,
        platform: platform,
      );

  factory AppVersionCheckResult.fromMap(
    Map<String, dynamic> map,
    String platform,
  ) {
    final statusRaw = (map['status'] as String?)?.toLowerCase();
    final status = _parseStatus(statusRaw);
    final message = (map['message'] as String?)?.trim() ??
        (status == AppVersionStatus.forceUpdate
            ? 'Update required to continue'
            : 'A newer version is available');
    final storeUrlRaw = map['store_url'] as String?;
    final storeUrl = storeUrlRaw == null ? null : Uri.tryParse(storeUrlRaw);

    return AppVersionCheckResult(
      status: status,
      message: message,
      storeUrl: storeUrl,
      platform: platform,
    );
  }

  final AppVersionStatus status;
  final String message;
  final Uri? storeUrl;
  final String platform;
}

AppVersionStatus _parseStatus(String? statusRaw) {
  switch (statusRaw) {
    case 'force_update':
      return AppVersionStatus.forceUpdate;
    case 'optional_update':
      return AppVersionStatus.optionalUpdate;
    default:
      return AppVersionStatus.allowed;
  }
}

class VersionCheckService {
  VersionCheckService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AppVersionCheckResult> checkVersion() async {
    final platform = _detectPlatformIdentifier();

    try {
      final info = await PackageInfo.fromPlatform();
      final response = await _apiClient.post(
        'app/version-check',
        body: <String, dynamic>{
          'platform': platform,
          'version': info.version,
        },
      );
      return AppVersionCheckResult.fromMap(response, platform);
    } catch (error, stackTrace) {
      debugPrint('App version check failed: $error');
      debugPrintStack(label: 'version_check', stackTrace: stackTrace);
      return AppVersionCheckResult.allowed(platform);
    }
  }

  String _detectPlatformIdentifier() {
    if (kIsWeb) {
      return 'android';
    }
    if (Platform.isIOS) {
      return 'ios';
    }
    return 'android';
  }
}
