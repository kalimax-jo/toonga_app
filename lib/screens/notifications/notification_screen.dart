import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../models/home_notification.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/notification_card.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  List<HomeNotification> _notifications = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final notifications = await _notificationService.fetchNotifications();
      if (!mounted) return;
      setState(() => _notifications = notifications);

      final unreadIds = notifications
          .where((notification) => notification.isNew)
          .map((notification) => notification.id)
          .whereType<int>()
          .toList();
      unawaited(_notificationService.markRead(unreadIds));
    } catch (error, stackTrace) {
      debugPrint('[DEBUG] Notification load failed: $error');
      debugPrintStack(label: 'Notification error stack', stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _notifications = const [];
      });
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        color: AppColors.primary,
        backgroundColor: Colors.black,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Iconsax.notification,
                            size: 14, color: Colors.white70),
                        SizedBox(width: 6),
                        Text(
                          'Home feed',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                    onPressed: _loadNotifications,
                    child: const Text(
                      'Refresh',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Column(
        children: const [
          NotificationSkeleton(),
          SizedBox(height: 12),
          NotificationSkeleton(),
        ],
      );
    }

    if (_error != null) {
      return NotificationMessage(
        icon: Icons.error_outline,
        title: 'Couldn\'t load notifications',
        subtitle: _error ??
            'Check your connection and try again.',
        onTap: _loadNotifications,
      );
    }

    if (_notifications.isEmpty) {
      return const NotificationMessage(
        icon: Icons.check_circle_outline,
        title: 'You\'re all caught up',
        subtitle: 'New product drops and promos will appear here.',
      );
    }

    return Column(
      children: List.generate(_notifications.length, (index) {
        final item = _notifications[index];
        return Padding(
          padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
          child: NotificationCard(notification: item),
        );
      }),
    );
  }
}
