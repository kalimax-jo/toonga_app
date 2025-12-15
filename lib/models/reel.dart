class Reel {
  final int id;
  final String title;
  final String description;
  final String? videoUrl;
  final String? videoType;
  final String? thumbnail;
  final String? thumbnailUrl;
  final int viewsCount;
  final int likesCount;
  final int commentsCount;
  final bool isLikedByUser;
  final ReelOffer? offer;
  final int savesCount;
  final bool isSavedByUser;
  final int? vendorId;
  final String? vendorName;
  final bool? isFollowingVendor;
  final String? productName;

  const Reel({
    required this.id,
    required this.title,
    required this.description,
    this.videoUrl,
    this.videoType,
    this.thumbnail,
    this.thumbnailUrl,
    this.viewsCount = 0,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLikedByUser = false,
    this.offer,
    this.savesCount = 0,
    this.isSavedByUser = false,
    this.vendorId,
    this.vendorName,
    this.isFollowingVendor,
    this.productName,
  });

  factory Reel.fromJson(Map<String, dynamic> json) {
    String? stringValue(dynamic value) => value?.toString();
    int intValue(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    bool boolValue(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      final normalized = value?.toString().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }

    return Reel(
      id: intValue(json['id']),
      title: stringValue(json['title']) ?? 'Reel',
      description: stringValue(json['description']) ?? '',
      videoUrl: stringValue(json['video_url']),
      videoType: stringValue(json['video_type']),
      thumbnailUrl: stringValue(
        json['thumbnail_url'] ??
            json['thumbnailUrl'] ??
            json['thumb_url'] ??
            json['thumbnail_path'] ??
            json['thumbnailPath'] ??
            json['thumb'] ??
            json['preview'] ??
            json['preview_image'] ??
            json['poster'] ??
            json['poster_url'] ??
            json['thumbnail'] ??
            json['image_url'],
      ),
      thumbnail: stringValue(json['thumbnail'] ?? json['image_url']),
      viewsCount: intValue(json['views_count']),
      likesCount: intValue(json['likes_count']),
      commentsCount: intValue(json['comments_count']),
      isLikedByUser: boolValue(json['is_liked_by_user']),
      offer: json['offer'] is Map<String, dynamic>
          ? ReelOffer.fromJson(json['offer'] as Map<String, dynamic>)
          : null,
      savesCount: intValue(json['saves_count']),
      isSavedByUser: boolValue(json['is_saved_by_user']),
      vendorId: intValue(json['vendor_id'] ?? json['vendor']?['id']),
      vendorName: stringValue(json['vendor']?['name'] ?? json['vendor_name']),
      isFollowingVendor: json.containsKey('is_following_vendor')
          ? boolValue(json['is_following_vendor'])
          : null,
      productName: stringValue(json['product']?['name'] ?? json['product_name']),
    );
  }

  bool get playsInline =>
      (videoType?.toLowerCase() == 'local') ||
      (videoUrl != null && _looksLikeMp4(videoUrl!));

  bool get isExternal =>
      videoUrl != null &&
      videoUrl!.isNotEmpty &&
      !playsInline;

  static bool _looksLikeMp4(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') || lower.contains('.mp4?');
  }
}

class ReelOffer {
  final int? id;
  final String? title;
  final String? subtitle;
  final String? description;
  final String? ctaLabel;
  final String? currency;
  final num? price;
  final int? productId;
  final String? productType;
  final int? vendorId;

  const ReelOffer({
    this.id,
    this.title,
    this.subtitle,
    this.description,
    this.ctaLabel,
    this.currency,
    this.price,
    this.productId,
    this.productType,
    this.vendorId,
  });

  factory ReelOffer.fromJson(Map<String, dynamic> json) {
    String? stringValue(dynamic v) => v?.toString();
    int? intValue(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    num? numValue(dynamic v) {
      if (v == null) return null;
      if (v is num) return v;
      return num.tryParse(v.toString());
    }

    return ReelOffer(
      id: intValue(json['id']),
      title: stringValue(json['title']),
      subtitle: stringValue(json['subtitle']),
      description: stringValue(json['description']),
      ctaLabel: stringValue(json['cta_label']),
      currency: stringValue(json['currency']),
      price: numValue(json['price']),
      productId: intValue(json['product_id']),
      productType: stringValue(json['product_type']),
      vendorId: intValue(json['vendor_id']),
    );
  }
}
