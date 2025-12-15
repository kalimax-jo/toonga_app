import 'package:flutter/foundation.dart';

@immutable
class FeaturedProduct {
  final int id;
  final int? productId;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? vendorName;
  final String? vendorLogoUrl;
  final double? price;
  final String? priceText;
  final int? orderIndex;

  const FeaturedProduct({
    required this.id,
    this.productId,
    required this.name,
    this.description,
    this.imageUrl,
    this.vendorName,
    this.vendorLogoUrl,
    this.price,
    this.priceText,
    this.orderIndex,
  });

  factory FeaturedProduct.fromJson(Map<String, dynamic> json) {
    double? parsePrice(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return FeaturedProduct(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      productId: json['product_id'] is int
          ? json['product_id'] as int
          : int.tryParse('${json['product_id']}'),
      name: json['name']?.toString() ?? 'Featured experience',
      description: json['description']?.toString(),
      imageUrl: json['image_url']?.toString(),
      vendorName: json['vendor_name']?.toString(),
      vendorLogoUrl: json['vendor_logo_url']?.toString(),
      price: parsePrice(json['price']),
      priceText: json['price_text']?.toString(),
      orderIndex: json['order_index'] is int
          ? json['order_index'] as int
          : int.tryParse('${json['order_index']}'),
    );
  }
}
