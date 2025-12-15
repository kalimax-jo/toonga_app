import 'package:flutter/foundation.dart';

@immutable
class MomoAccount {
  final String id;
  final String provider; // e.g., MTN, Airtel
  final String msisdn;

  const MomoAccount({
    required this.id,
    required this.provider,
    required this.msisdn,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'provider': provider,
        'msisdn': msisdn,
      };

  factory MomoAccount.fromJson(Map<String, dynamic> json) {
    return MomoAccount(
      id: json['id']?.toString() ?? '',
      provider: json['provider']?.toString() ?? 'MTN',
      msisdn: json['msisdn']?.toString() ?? '',
    );
  }
}
