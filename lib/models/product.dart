import 'package:flutter/foundation.dart';

@immutable
class Product {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? vendorName;
  final double? price;
  final String? priceText;
  final List<String> tags;
  final Map<String, dynamic> extras;

  const Product({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.vendorName,
    this.price,
    this.priceText,
    this.tags = const [],
    this.extras = const {},
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    double? parsePrice(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    List<String> parseTags(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      if (value is String && value.isNotEmpty) {
        return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      return const [];
    }

    final id = json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0;
    final imageUrl = json['image_url']?.toString() ??
        json['image']?.toString() ??
        json['featured_image_url']?.toString() ??
        json['featured_image']?.toString();

    return Product(
      id: id,
      name: json['name']?.toString() ?? 'Product',
      description: json['description']?.toString(),
      imageUrl: imageUrl,
      vendorName: json['vendor_name']?.toString(),
      price: parsePrice(json['price']),
      priceText: json['price_text']?.toString(),
      tags: parseTags(json['tags'] ?? json['categories']),
      extras: json,
    );
  }

  Map<String, dynamic> toJson() {
    final data = Map<String, dynamic>.from(extras);
    data.addAll({
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'vendor_name': vendorName,
      'price': price,
      'price_text': priceText,
      'tags': tags,
    });
    return data;
  }
}
