import 'dart:math';

enum NotificationKind { newProduct, promotion, orderUpdate, payment }

class HomeNotification {
  final int? id;
  final String title;
  final String message;
  final String timeLabel;
  final NotificationKind kind;
  final bool isNew;
  final DateTime? createdAt;

  const HomeNotification({
    this.id,
    required this.title,
    required this.message,
    required this.timeLabel,
    required this.kind,
    this.isNew = false,
    this.createdAt,
  });

  factory HomeNotification.fromJson(Map<String, dynamic> json) {
    final createdAt = _parseDate(json['created_at']?.toString());
    final rawTimeLabel = json['time_label']?.toString();
    final timeLabel = rawTimeLabel?.isNotEmpty == true
        ? rawTimeLabel!
        : _formatRelativeDate(createdAt);
    final type = json['type']?.toString();
    return HomeNotification(
      id: _parseId(json['id']),
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ??
          json['body']?.toString() ??
          '',
      timeLabel: timeLabel,
      kind: _mapKind(type),
      isNew: (json['is_new'] == true ||
          json['read'] == false ||
          json['read'] == 0),
      createdAt: createdAt,
    );
  }

  static int? _parseId(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static NotificationKind _mapKind(String? type) {
    final normalized = type?.toLowerCase();
    if (normalized == 'order' || normalized == 'order_update') {
      return NotificationKind.orderUpdate;
    }
    if (normalized == 'payment') return NotificationKind.payment;
    if (normalized == 'promotion') return NotificationKind.promotion;
    if (normalized == 'promo') return NotificationKind.promotion;
    if (normalized == 'new_product') return NotificationKind.newProduct;
    return NotificationKind.promotion;
  }

  static String _formatRelativeDate(DateTime? dateTime) {
    if (dateTime == null) return 'Just now';
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    final days = min(diff.inDays, 7);
    if (days == 1) return 'Yesterday';
    if (days < 7) return '$days days ago';
    return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
  }
}
