class MilesOverview {
  final double total;
  final double available;
  final double used;
  final List<MilesHistory> history;

  MilesOverview({
    required this.total,
    required this.available,
    required this.used,
    this.history = const [],
  });

  factory MilesOverview.fromJson(Map<String, dynamic> json) {
    final historyRaw = json['history'] as List<dynamic>? ?? const <dynamic>[];
    return MilesOverview(
      total: _toDouble(json['total']) ?? 0,
      available: _toDouble(json['available']) ?? _toDouble(json['balance']) ?? 0,
      used: _toDouble(json['used']) ?? 0,
      history: historyRaw
          .whereType<Map<String, dynamic>>()
          .map(MilesHistory.fromJson)
          .toList(),
    );
  }
}

class MilesHistory {
  final int? id;
  final String? type;
  final double amount;
  final String? description;
  final double balanceAfter;
  final DateTime? createdAt;

  MilesHistory({
    this.id,
    this.type,
    required this.amount,
    this.description,
    required this.balanceAfter,
    this.createdAt,
  });

  factory MilesHistory.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic input) {
      if (input == null) return null;
      if (input is DateTime) return input;
      return DateTime.tryParse(input.toString());
    }

    return MilesHistory(
      id: _toInt(json['id']),
      type: json['type']?.toString(),
      amount: _toDouble(json['amount']) ?? 0,
      description: json['description']?.toString(),
      balanceAfter: _toDouble(json['balance_after']) ?? 0,
      createdAt: parseDate(json['created_at']),
    );
  }
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
