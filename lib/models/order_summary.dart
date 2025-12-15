import 'package:flutter/foundation.dart';

@immutable
class OrderSummary {
  final int? id;
  final String title;
  final String status;
  final String vendorName;
  final String? orderNumber;
  final String? paymentStatus;
  final double? totalAmount;
  final int? itemsCount;
  final double? subtotal;
  final double? shippingFee;
  final String? rewardType;
  final double? rewardAmount;
  final DateTime? scheduledAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double? amount;
  final String? currency;
  final List<OrderTimelineEntry> timeline;
  final List<OrderItem> items;
  final OrderPayment? payment;
  final OrderVendor? vendor;
  final ShippingAddress? shippingAddress;

  const OrderSummary({
    this.id,
    required this.title,
    required this.status,
    required this.vendorName,
    this.orderNumber,
    this.paymentStatus,
    this.totalAmount,
    this.itemsCount,
    this.subtotal,
    this.shippingFee,
    this.rewardType,
    this.rewardAmount,
    this.scheduledAt,
    this.createdAt,
    this.updatedAt,
    this.amount,
    this.currency,
    this.timeline = const [],
    this.items = const [],
    this.payment,
    this.vendor,
    this.shippingAddress,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    final schedule = json['scheduled_at'] ?? json['schedule'];
    DateTime? parseDate(dynamic input) {
      if (input == null) return null;
      if (input is DateTime) return input;
      return DateTime.tryParse(input.toString());
    }

    final timeline = <OrderTimelineEntry>[];
    _extractTimeline(json['timeline']).forEach(timeline.add);

    final items = _extractItems(json['items']);
    final payment =
        json['payment'] is Map<String, dynamic> ? OrderPayment.fromJson(json['payment'] as Map<String, dynamic>) : null;
    final vendor =
        json['vendor'] is Map<String, dynamic> ? OrderVendor.fromJson(json['vendor'] as Map<String, dynamic>) : null;
    final shippingAddress = json['shipping_address'] is Map<String, dynamic>
        ? ShippingAddress.fromJson(json['shipping_address'] as Map<String, dynamic>)
        : null;

    final orderNumber = json['order_number']?.toString();
    final partnerName = json['vendor_name']?.toString() ??
        json['vendor']?['business_name']?.toString() ??
        json['vendor']?['name']?.toString() ??
        json['assigned_to']?.toString() ??
        vendor?.name ??
        '-';

    return OrderSummary(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      title: json['title']?.toString() ??
          orderNumber ??
          json['service']?.toString() ??
          json['category']?.toString() ??
          partnerName,
      status: json['status']?.toString() ?? json['order_status']?.toString() ?? 'requested',
      vendorName: partnerName,
      orderNumber: orderNumber,
      paymentStatus: json['payment_status']?.toString(),
      totalAmount: _toDouble(json['total_amount']) ?? _toDouble(json['total']),
      itemsCount: json['items_count'] is int
          ? json['items_count'] as int
          : int.tryParse(json['items_count']?.toString() ?? ''),
      subtotal: _toDouble(json['subtotal']),
      shippingFee: _toDouble(json['shipping_fee']),
      rewardType: json['reward_type']?.toString(),
      rewardAmount: _toDouble(json['reward_amount']),
      scheduledAt: parseDate(schedule),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      amount: json['amount'] is num ? (json['amount'] as num).toDouble() : null,
      currency: json['currency']?.toString(),
      timeline: timeline.isNotEmpty
          ? timeline
          : _statusFallbackTimeline(json),
      items: items,
      payment: payment,
      vendor: vendor,
      shippingAddress: shippingAddress,
    );
  }

  static List<OrderTimelineEntry> _statusFallbackTimeline(
    Map<String, dynamic> json,
  ) {
    final status = json['status']?.toString() ?? '';
    final created = DateTime.tryParse(json['created_at']?.toString() ?? '');
    final updated = DateTime.tryParse(json['updated_at']?.toString() ?? '');
    final paymentMap = json['payment'] as Map<String, dynamic>?;
    final paymentStatus = json['payment_status']?.toString().toLowerCase() ??
        paymentMap?['status']?.toString().toLowerCase();
    final paymentCompletedAt = paymentMap != null
        ? DateTime.tryParse(paymentMap['completed_at']?.toString() ?? '')
        : null;
    final paymentPaid = paymentStatus == 'paid' || paymentStatus == 'completed';
    final steps = [
      OrderTimelineEntry(
        title: 'Order Placed',
        timestamp: created,
        description: json['created_at']?.toString(),
      ),
      if (paymentPaid)
        OrderTimelineEntry(
          title: 'Order Payment',
          timestamp: paymentCompletedAt ?? created,
          description: json['payment_status']?.toString(),
        ),
      OrderTimelineEntry(
        title: 'Order Accepted',
        timestamp: updated,
      ),
      OrderTimelineEntry(
        title: 'Processing',
        timestamp: status.contains('processing') ? updated : null,
      ),
      OrderTimelineEntry(
        title: 'Completed',
        timestamp: status.contains('completed') ? updated : null,
      ),
    ];
    return steps;
  }
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

List<OrderTimelineEntry> _extractTimeline(dynamic raw) {
  final entries = <OrderTimelineEntry>[];
  if (raw is List) {
    for (final entry in raw) {
      if (entry is Map<String, dynamic>) {
        entries.add(OrderTimelineEntry.fromJson(entry));
      }
    }
  }
  return entries;
}

List<OrderItem> _extractItems(dynamic raw) {
  if (raw is List) {
    return raw.whereType<Map<String, dynamic>>().map(OrderItem.fromJson).toList();
  }
  return const [];
}

@immutable
class OrderTimelineEntry {
  final String title;
  final String? description;
  final DateTime? timestamp;

  const OrderTimelineEntry({
    required this.title,
    this.description,
    this.timestamp,
  });

  factory OrderTimelineEntry.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic input) {
      if (input == null) return null;
      if (input is DateTime) return input;
      return DateTime.tryParse(input.toString());
    }

    return OrderTimelineEntry(
      title: json['title']?.toString() ?? json['status']?.toString() ?? 'Update',
      description: json['description']?.toString(),
      timestamp: parseDate(json['timestamp'] ?? json['at']),
    );
  }
}

@immutable
class OrderItem {
  final int? productId;
  final String name;
  final String? sku;
  final int quantity;
  final double? unitPrice;
  final double? lineTotal;
  final String? imageUrl;

  const OrderItem({
    this.productId,
    required this.name,
    this.sku,
    this.quantity = 1,
    this.unitPrice,
    this.lineTotal,
    this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id'] is int ? json['product_id'] as int : int.tryParse('${json['product_id']}'),
      name: json['name']?.toString() ?? 'Item',
      sku: json['sku']?.toString(),
      quantity: json['quantity'] is int ? json['quantity'] as int : int.tryParse('${json['quantity']}') ?? 1,
      unitPrice: _toDouble(json['unit_price']),
      lineTotal: _toDouble(json['line_total']),
      imageUrl: json['image_url']?.toString(),
    );
  }
}

@immutable
class OrderPayment {
  final int? id;
  final String? referenceNumber;
  final String? paymentMethod;
  final double? amount;
  final String? status;
  final DateTime? completedAt;

  const OrderPayment({
    this.id,
    this.referenceNumber,
    this.paymentMethod,
    this.amount,
    this.status,
    this.completedAt,
  });

  factory OrderPayment.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic input) {
      if (input == null) return null;
      if (input is DateTime) return input;
      return DateTime.tryParse(input.toString());
    }

    return OrderPayment(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      referenceNumber: json['reference_number']?.toString(),
      paymentMethod: json['payment_method']?.toString(),
      amount: _toDouble(json['amount']),
      status: json['status']?.toString(),
      completedAt: parseDate(json['completed_at']),
    );
  }
}

@immutable
class OrderVendor {
  final int? id;
  final String? name;
  final String? businessName;
  final String? phone;

  const OrderVendor({this.id, this.name, this.businessName, this.phone});

  factory OrderVendor.fromJson(Map<String, dynamic> json) {
    return OrderVendor(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      name: json['name']?.toString() ?? json['business_name']?.toString(),
      businessName: json['business_name']?.toString(),
      phone: json['phone']?.toString(),
    );
  }
}

@immutable
class ShippingAddress {
  final String? name;
  final String? phone;
  final String? line1;
  final String? line2;
  final String? city;
  final String? country;

  const ShippingAddress({
    this.name,
    this.phone,
    this.line1,
    this.line2,
    this.city,
    this.country,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      name: json['name']?.toString(),
      phone: json['phone']?.toString(),
      line1: json['line1']?.toString(),
      line2: json['line2']?.toString(),
      city: json['city']?.toString(),
      country: json['country']?.toString(),
    );
  }
}
