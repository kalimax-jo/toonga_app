import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../theme/app_colors.dart';

class PermissionSettingsScreen extends StatefulWidget {
  const PermissionSettingsScreen({super.key});

  @override
  State<PermissionSettingsScreen> createState() =>
      _PermissionSettingsScreenState();
}

class _PermissionSettingsScreenState extends State<PermissionSettingsScreen> {
  static const List<_PermissionEntry> _permissionEntries = [
    _PermissionEntry(
      title: 'Notifications',
      description: 'Receive order updates, promotions, and reminders.',
      icon: Iconsax.notification,
      androidPermission: Permission.notification,
      iosPermission: Permission.notification,
    ),
    _PermissionEntry(
      title: 'Location',
      description: 'Suggest local stores and keep delivery addresses accurate.',
      icon: Iconsax.map,
      androidPermission: Permission.locationWhenInUse,
      iosPermission: Permission.locationWhenInUse,
    ),
    _PermissionEntry(
      title: 'Camera',
      description: 'Capture avatars, scan codes, or document proof.',
      icon: Iconsax.camera,
      androidPermission: Permission.camera,
      iosPermission: Permission.camera,
    ),
    _PermissionEntry(
      title: 'Gallery',
      description: 'Use saved photos for avatars, receipts, or uploads.',
      icon: Iconsax.gallery,
      androidPermission: Permission.photos,
      iosPermission: Permission.photos,
    ),
  ];

  final Map<Permission, PermissionStatus> _statusMap = {};
  final Set<Permission> _busyPermissions = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshStatuses(showLoading: true);
  }

  Future<void> _refreshStatuses({bool showLoading = false}) async {
    if (showLoading && mounted) {
      setState(() => _isLoading = true);
    }
    final statuses = <Permission, PermissionStatus>{};
    for (final entry in _permissionEntries) {
      final permission = entry.currentPlatformPermission;
      if (permission == null) continue;
      try {
        statuses[permission] = await permission.status;
      } catch (_) {
        statuses[permission] = PermissionStatus.denied;
      }
    }
    if (!mounted) return;
    setState(() {
      _statusMap
        ..clear()
        ..addAll(statuses);
      if (showLoading) _isLoading = false;
    });
  }

  Future<void> _togglePermission(_PermissionEntry entry, bool enable) async {
    final permission = entry.currentPlatformPermission;
    if (permission == null) return;
    if (!enable) {
      await _showSettingsPrompt(entry);
      return;
    }
    if (_busyPermissions.contains(permission)) return;
    _busyPermissions.add(permission);
    if (mounted) setState(() {});
    try {
      if (permission == Permission.notification) {
        await _requestNotificationPermission();
      } else {
        await permission.request();
      }
      final status = await permission.status;
      if (!_isStatusEnabled(status)) {
        _showPermissionDeniedSnack(entry.title);
      }
      await _refreshStatuses();
    } finally {
      _busyPermissions.remove(permission);
      if (mounted) setState(() {});
    }
  }

  bool _isStatusEnabled(PermissionStatus status) {
    return status == PermissionStatus.granted ||
        status == PermissionStatus.limited ||
        status == PermissionStatus.provisional;
  }

  String _statusLabel(PermissionStatus? status) {
    if (status == null) return 'Checking status...';
    switch (status) {
      case PermissionStatus.granted:
        return 'Enabled';
      case PermissionStatus.limited:
        return 'Limited access';
      case PermissionStatus.provisional:
        return 'Provisional access';
      case PermissionStatus.denied:
        return 'Tap to request';
      case PermissionStatus.restricted:
        return 'Restricted by OS';
      case PermissionStatus.permanentlyDenied:
        return 'Blocked in settings';
      default:
        return 'Status unknown';
    }
  }

  Future<void> _requestNotificationPermission() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _showSettingsPrompt(_PermissionEntry entry) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text('${entry.title} permission'),
          content: const Text(
            'Adjust this permission via your device settings.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDeniedSnack(String title) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title permission not granted.'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Permissions',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => _refreshStatuses(showLoading: true),
            icon: const Icon(Iconsax.refresh, color: Colors.white70),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _permissionEntries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
              final entry = _permissionEntries[index];
                final permission = entry.currentPlatformPermission;
                final status = permission != null ? _statusMap[permission] : null;
                final isOn = status != null && _isStatusEnabled(status);
                final isBusy = permission != null && _busyPermissions.contains(permission);
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(entry.icon, color: Colors.white70),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry.description,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _statusLabel(status),
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      isBusy
                          ? const SizedBox(
                              width: 40,
                              height: 40,
                              child: Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            )
                          : Switch(
                              value: isOn,
                              onChanged: (value) => _togglePermission(entry, value),
                              activeColor: AppColors.primary,
                              inactiveThumbColor: Colors.white54,
                            ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _PermissionEntry {
  final String title;
  final String description;
  final IconData icon;
  final Permission? androidPermission;
  final Permission? iosPermission;

  const _PermissionEntry({
    required this.title,
    required this.description,
    required this.icon,
    this.androidPermission,
    this.iosPermission,
  });

  Permission? get currentPlatformPermission {
    if (Platform.isIOS) {
      return iosPermission ?? androidPermission;
    }
    return androidPermission ?? iosPermission;
  }
}
