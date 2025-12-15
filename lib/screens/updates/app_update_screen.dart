import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/version_check_service.dart';

class AppUpdateScreen extends StatelessWidget {
  const AppUpdateScreen({
    required this.status,
    required this.message,
    required this.platform,
    this.storeUrl,
    required this.continueRoute,
    this.allowSkip = false,
    super.key,
  });

  static const String _androidStoreLink =
      'https://play.google.com/store/apps/details?id=com.toongapp';
  static const String _iosStoreLink = 'https://apps.apple.com/app/idYOUR_APP_ID';

  final AppVersionStatus status;
  final String message;
  final Uri? storeUrl;
  final String platform;
  final String continueRoute;
  final bool allowSkip;

  bool get _isForceUpdate => status == AppVersionStatus.forceUpdate;

  Uri? get _fallbackUri {
    final link = platform == 'ios' ? _iosStoreLink : _androidStoreLink;
    return Uri.tryParse(link);
  }

  Uri? get _resolvedUri => storeUrl ?? _fallbackUri;

  @override
  Widget build(BuildContext context) {
    final accent = _isForceUpdate ? Colors.redAccent : Colors.amberAccent;
    final title = _isForceUpdate ? 'Update Required' : 'New version available';
    final canLaunchUpdate = _resolvedUri != null;

    return WillPopScope(
      onWillPop: () async => !_isForceUpdate,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
            Container(color: Colors.black.withOpacity(0.7)),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Card(
                    elevation: 18,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.system_update_rounded,
                            color: accent,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w700,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            message,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.black54,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: canLaunchUpdate
                                  ? () => _handleStoreLaunch(context)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: const Text(
                                'Update Now',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          if (!_isForceUpdate && allowSkip) ...[
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => _handleSkip(context),
                              child: const Text('Maybe later'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleStoreLaunch(BuildContext context) async {
    final uri = _resolvedUri;
    if (uri == null) return;

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the store link.')),
      );
    }
  }

  void _handleSkip(BuildContext context) {
    Navigator.pushReplacementNamed(context, continueRoute);
  }
}
