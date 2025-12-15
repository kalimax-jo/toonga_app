import 'package:flutter/foundation.dart';

import 'featured_product.dart';

@immutable
class HomeResponse {
  final DateTime? timestamp;
  final HomeUser? user;
  final HomeSearch? search;
  final List<HomeCategory> categories;
  final List<HomeFeatured> featured;
  final HomeNotifications? notifications;

  const HomeResponse({
    this.timestamp,
    this.user,
    this.search,
    this.categories = const [],
    this.featured = const [],
    this.notifications,
  });

  factory HomeResponse.fromJson(Map<String, dynamic> json) {
    return HomeResponse(
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : null,
      user: json['user'] is Map<String, dynamic>
          ? HomeUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      search: json['search'] is Map<String, dynamic>
          ? HomeSearch.fromJson(json['search'] as Map<String, dynamic>)
          : null,
      categories: (json['categories'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(HomeCategory.fromJson)
          .toList(),
      featured: (json['featured'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(HomeFeatured.fromJson)
          .toList(),
      notifications: json['notifications'] is Map<String, dynamic>
          ? HomeNotifications.fromJson(
              json['notifications'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

@immutable
class HomeUser {
  final int? id;
  final String? name;
  final String? greeting;

  const HomeUser({this.id, this.name, this.greeting});

  factory HomeUser.fromJson(Map<String, dynamic> json) {
    return HomeUser(
      id: json['id'] as int?,
      name: json['name']?.toString(),
      greeting: json['greeting']?.toString(),
    );
  }
}

@immutable
class HomeSearch {
  final String? placeholder;
  final List<String> recentTerms;
  final String? suggestionsUrl;

  const HomeSearch({
    this.placeholder,
    this.recentTerms = const [],
    this.suggestionsUrl,
  });

  factory HomeSearch.fromJson(Map<String, dynamic> json) {
    return HomeSearch(
      placeholder: json['placeholder']?.toString(),
      recentTerms: (json['recent_terms'] as List<dynamic>? ?? const [])
          .map((dynamic item) => item.toString())
          .toList(),
      suggestionsUrl: json['suggestions_url']?.toString(),
    );
  }
}

@immutable
class HomeCategory {
  final int id;
  final String name;
  final String? slug;
  final String? description;
  final bool isActive;
  final String? iconUrl;
  final int? sortOrder;
  final String? colorHex;
  final Map<String, dynamic>? settings;
  final String? featuredImage;
  final List<FeaturedProduct> featuredItems;

  const HomeCategory({
    required this.id,
    required this.name,
    this.slug,
    this.description,
    this.isActive = true,
    this.iconUrl,
    this.sortOrder,
    this.colorHex,
    this.settings,
    this.featuredImage,
    this.featuredItems = const [],
  });

  factory HomeCategory.fromJson(Map<String, dynamic> json) {
    final settings = json['settings'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['settings'] as Map<String, dynamic>)
        : null;
    final iconUrl = json['icon_url']?.toString();
    final featuredImage = json['featured_image']?.toString() ??
        settings?['featured_image']?.toString() ??
        iconUrl;
    final items = (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(FeaturedProduct.fromJson)
        .toList();

    return HomeCategory(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString(),
      description: json['description']?.toString(),
      isActive: json['is_active'] != null
          ? json['is_active'] == true || json['is_active'] == 1
          : true,
      iconUrl: iconUrl,
      sortOrder: json['sort_order'] as int?,
      colorHex: json['color']?.toString(),
      settings: settings,
      featuredImage: featuredImage,
      featuredItems: items,
    );
  }
}

@immutable
class HomeFeatured {
  final int? id;
  final String? title;
  final String? subtitle;
  final String? availableText;
  final int? milesAward;
  final String? imageUrl;
  final int? categoryId;
  final int? vendorId;
  final HomeCta? cta;

  const HomeFeatured({
    this.id,
    this.title,
    this.subtitle,
    this.availableText,
    this.milesAward,
    this.imageUrl,
    this.categoryId,
    this.vendorId,
    this.cta,
  });

  factory HomeFeatured.fromJson(Map<String, dynamic> json) {
    return HomeFeatured(
      id: json['id'] as int?,
      title: json['title']?.toString(),
      subtitle: json['subtitle']?.toString(),
      availableText: json['available_text']?.toString(),
      milesAward: json['miles_award'] is int
          ? json['miles_award'] as int
          : int.tryParse('${json['miles_award']}'),
      imageUrl: json['image_url']?.toString(),
      categoryId: json['category_id'] as int?,
      vendorId: json['vendor_id'] as int?,
      cta: json['cta'] is Map<String, dynamic>
          ? HomeCta.fromJson(json['cta'] as Map<String, dynamic>)
          : null,
    );
  }

  String? get milesLabel =>
      milesAward != null ? '+$milesAward miles on booking' : null;
}

@immutable
class HomeCta {
  final String? text;
  final String? targetType;
  final int? targetId;

  const HomeCta({this.text, this.targetType, this.targetId});

  factory HomeCta.fromJson(Map<String, dynamic> json) {
    return HomeCta(
      text: json['text']?.toString(),
      targetType: json['target_type']?.toString(),
      targetId: json['target_id'] as int?,
    );
  }
}

@immutable
class HomeNotifications {
  final int unreadCount;

  const HomeNotifications({this.unreadCount = 0});

  factory HomeNotifications.fromJson(Map<String, dynamic> json) {
    final count = json['unread_count'];
    return HomeNotifications(
      unreadCount: count is int ? count : int.tryParse('$count') ?? 0,
    );
  }
}
