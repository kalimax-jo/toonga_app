class Offer {
  final int id;
  final String title;
  final String description;
  final String? badge;
  final String? status;
  final String? theme;
  final String? imageUrl;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int? milesRequired;
  final num? value;
  final String? partnerName;
  final String? partnerLogo;
  final bool isExpiringSoon;
  final bool isExpired;
  final int? quantityAvailable;
  final int? quantityRedeemed;
  final bool isRedeemed;
  final DateTime? redeemedAt;
  final String? rewardCode;

  const Offer({
    required this.id,
    required this.title,
    required this.description,
    this.badge,
    this.status,
    this.theme,
    this.imageUrl,
    this.startsAt,
    this.endsAt,
    this.milesRequired,
    this.value,
    this.partnerName,
    this.partnerLogo,
    this.isExpiringSoon = false,
    this.isExpired = false,
    this.quantityAvailable,
    this.quantityRedeemed,
    this.isRedeemed = false,
    this.redeemedAt,
    this.rewardCode,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    String? stringValue(dynamic value) => value?.toString();

    int intValue(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    int? _intOrNull(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    bool boolValue(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      final normalized = value?.toString().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }

    num? numValue(dynamic value) {
      if (value == null) return null;
      if (value is num) return value;
      return num.tryParse(value.toString());
    }

    DateTime? dateValue(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    final description = stringValue(
          json['description'] ??
              json['subtitle'] ??
              json['summary'] ??
              json['body'],
        ) ??
        '';

    num? milesNum = numValue(
      json['miles_required'] ??
          json['required_miles'] ??
          json['miles'] ??
          json['points_required'] ??
          json['points'] ??
          json['cost'],
    );

    return Offer(
      id: intValue(json['id']),
      title: stringValue(json['title'] ?? json['name'] ?? 'Offer')!,
      description:
          description.isEmpty ? 'Limited time offer from Toonga' : description,
      badge: stringValue(
        json['badge'] ??
            json['label'] ??
            json['tag'] ??
            json['cta_label'] ??
            json['ctaLabel'] ??
            json['cta'] ??
            json['type'],
      ),
      status: stringValue(json['status']),
      theme: stringValue(json['theme'] ?? json['tone'] ?? json['accent']),
      imageUrl: stringValue(
        json['image_url'] ??
            json['image'] ??
            json['banner'] ??
            json['banner_url'] ??
            json['cover'],
      ),
      milesRequired: milesNum?.round() ?? _intOrNull(json['miles_required']),
      value: numValue(json['value'] ?? json['worth'] ?? json['amount']),
      partnerName: stringValue(
        json['partner_name'] ?? json['vendor_name'] ?? json['partner'],
      ),
      partnerLogo: stringValue(
        json['partner_logo'] ??
            json['logo'] ??
            json['partner']?['logo'] ??
            json['vendor']?['logo'] ??
            json['partner']?['logo_url'] ??
            json['vendor']?['logo_url'],
      ),
      isExpiringSoon: boolValue(json['is_expiring_soon']),
      isExpired: boolValue(json['is_expired']),
      quantityAvailable: _intOrNull(
        json['quantity_available'] ?? json['available'] ?? json['qty_available'],
      ),
      quantityRedeemed: _intOrNull(
        json['quantity_redeemed'] ?? json['redeemed_count'] ?? json['redeemed'],
      ),
      startsAt: dateValue(
        json['starts_at'] ??
            json['start_at'] ??
            json['start_date'] ??
            json['startsAt'],
      ),
      endsAt: dateValue(
        json['ends_at'] ??
            json['end_at'] ??
            json['end_date'] ??
            json['expires_at'] ??
            json['expiresAt'] ??
            json['valid_till'] ??
            json['valid_until'],
      ),
      isRedeemed: boolValue(
        json['is_redeemed'] ?? json['redeemed'] ?? json['already_redeemed'],
      ),
      redeemedAt: dateValue(json['redeemed_at']),
      rewardCode: stringValue(
        json['code'] ?? json['coupon_code'] ?? json['reward_code'],
      ),
    );
  }
}

class OfferRedeemResult {
  final bool success;
  final bool alreadyRedeemed;
  final String? message;
  final String? rewardCode;

  const OfferRedeemResult({
    required this.success,
    this.alreadyRedeemed = false,
    this.message,
    this.rewardCode,
  });
}
