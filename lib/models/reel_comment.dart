class ReelComment {
  final int id;
  final String comment;
  final String userName;
  final String? userEmail;
  final DateTime? createdAt;

  const ReelComment({
    required this.id,
    required this.comment,
    required this.userName,
    this.userEmail,
    this.createdAt,
  });

  factory ReelComment.fromJson(Map<String, dynamic> json) {
    String? stringValue(dynamic v) => v?.toString();
    int intValue(dynamic v) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    DateTime? parseDate(dynamic v) {
      final raw = stringValue(v);
      if (raw == null) return null;
      return DateTime.tryParse(raw);
    }

    final user = json['user'] as Map<String, dynamic>?;
    final guestName = stringValue(json['guest_name']);
    final name =
        stringValue(user?['name']) ?? guestName ?? stringValue(json['name']) ?? 'Guest';

    return ReelComment(
      id: intValue(json['id']),
      comment: stringValue(json['comment']) ?? '',
      userName: name ?? 'Guest',
      userEmail: stringValue(user?['email']),
      createdAt: parseDate(json['created_at']),
    );
  }
}
