import '../models/featured_product.dart';
import '../models/home_response.dart';
import 'api_client.dart';

class CategoryService {
  CategoryService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<HomeCategory>> fetchCategories() async {
    final response = await _client.get('/categories');
    final dynamic data =
        response['data'] ?? response['categories'] ?? response['results'];

    final List<dynamic> items;
    if (data is List<dynamic>) {
      items = data;
    } else if (data is Map<String, dynamic> && data['data'] is List<dynamic>) {
      items = data['data'] as List<dynamic>;
    } else {
      items = const [];
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map(HomeCategory.fromJson)
        .toList();
  }

  Future<List<HomeCategory>> fetchLandingCategories() async {
    final response = await _client.get('/categories/landing');
    final dynamic data =
        response['categories'] ?? response['data'] ?? response['results'];

    final List<dynamic> items;
    if (data is List<dynamic>) {
      items = data;
    } else if (data is Map<String, dynamic> && data['data'] is List<dynamic>) {
      items = data['data'] as List<dynamic>;
    } else {
      items = const [];
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map(HomeCategory.fromJson)
        .toList();
  }

  Future<List<FeaturedProduct>> fetchFeatured(String slug) async {
    if (slug.isEmpty) return const [];
    final response = await _client.get('/categories/$slug/featured');
    final List<dynamic> items;
    if (response['items'] is List<dynamic>) {
      items = response['items'] as List<dynamic>;
    } else if (response['data'] is List<dynamic>) {
      items = response['data'] as List<dynamic>;
    } else {
      items = const [];
    }

    final featured = items
        .whereType<Map<String, dynamic>>()
        .map(FeaturedProduct.fromJson)
        .toList();
    featured.sort(
      (a, b) => (a.orderIndex ?? 999).compareTo(b.orderIndex ?? 999),
    );
    return featured;
  }
}
