import 'package:flutter/foundation.dart';

@immutable
class SavedCard {
  final String id;
  final String brand;
  final String last4;
  final String holder;
  final int expMonth;
  final int expYear;

  const SavedCard({
    required this.id,
    required this.brand,
    required this.last4,
    required this.holder,
    required this.expMonth,
    required this.expYear,
  });

  String get masked => '•••• $last4';
  String get expiry => '${expMonth.toString().padLeft(2, '0')}/$expYear';

  Map<String, dynamic> toJson() => {
        'id': id,
        'brand': brand,
        'last4': last4,
        'holder': holder,
        'exp_month': expMonth,
        'exp_year': expYear,
      };

  factory SavedCard.fromJson(Map<String, dynamic> json) {
    return SavedCard(
      id: json['id']?.toString() ?? '',
      brand: json['brand']?.toString() ?? 'Card',
      last4: json['last4']?.toString() ?? '',
      holder: json['holder']?.toString() ?? '',
      expMonth: int.tryParse('${json['exp_month']}') ?? 1,
      expYear: int.tryParse('${json['exp_year']}') ?? DateTime.now().year,
    );
  }
}
