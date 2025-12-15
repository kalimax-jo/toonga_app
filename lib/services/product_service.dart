import '../models/product.dart';
import 'api_client.dart';

class ProductService {
  ProductService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<Product?> fetchProductDetail(int id) async {
    final response = await _client.get('/store/products/$id');
    final dynamic data = response['data'] ?? response['product'] ?? response['item'];
    if (data is Map<String, dynamic>) {
      return Product.fromJson(data);
    }
    return null;
  }

  Future<List<Product>> fetchProducts({
    String? categorySlug,
    String? search,
    int? page,
    int? limit,
  }) async {
    final query = <String, dynamic>{};
    if (categorySlug != null && categorySlug.isNotEmpty) {
      query['category'] = categorySlug;
      // Provide multiple parameter names to match backend expectations
      query['category_slug'] = categorySlug;
    }
    if (search != null && search.isNotEmpty) {
      query['q'] = search;
    }
    if (page != null) query['page'] = '$page';
    if (limit != null) query['limit'] = '$limit';

    final response = await _client.get(
      '/store/products',
      queryParameters: query.isEmpty ? null : query,
    );

    final dynamic data =
        response['data'] ?? response['items'] ?? response['results'] ?? response['products'];
    final List<dynamic> items;
    if (data is List<dynamic>) {
      items = data;
    } else if (data is Map<String, dynamic> && data['data'] is List<dynamic>) {
      items = data['data'] as List<dynamic>;
    } else {
      items = const [];
    }

    return items.whereType<Map<String, dynamic>>().map(Product.fromJson).toList();
  }

  Future<List<Product>> fetchBeverageProducts({
    String? q,
    List<String>? subIds,
    List<String>? brandIds,
    Map<String, List<String>>? attributes,
    String? sort,
    int? page,
    int? limit,
  }) async {
    return fetchCategoryProducts(
      slug: 'beverage',
      search: q,
      subIds: subIds,
      brandIds: brandIds,
      attributes: attributes,
      sort: sort,
      page: page,
      limit: limit,
    );
  }

  Future<List<Product>> fetchCategoryProducts({
    required String slug,
    String? search,
    List<String>? subIds,
    List<String>? brandIds,
    Map<String, List<String>>? attributes,
    String? sort,
    String? vendorId,
    double? minPrice,
    double? maxPrice,
    bool? featured,
    int? page,
    int? limit,
  }) async {
    final query = <String, dynamic>{};
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (sort != null && sort.isNotEmpty) query['sort'] = sort;
    if (vendorId != null && vendorId.isNotEmpty) query['vendor_id'] = vendorId;
    if (minPrice != null) query['min_price'] = minPrice.toString();
    if (maxPrice != null) query['max_price'] = maxPrice.toString();
    if (featured != null) query['featured'] = featured ? '1' : '0';
    if (page != null) query['page'] = '$page';
    if (limit != null) query['per_page'] = '$limit';
    query['ajax'] = '1';
    if (subIds != null && subIds.isNotEmpty) {
      // Backend accepts sub or sub[]
      query['sub'] = subIds.first;
    }
    if (brandIds != null && brandIds.isNotEmpty) {
      query['brand[]'] = brandIds;
    }
    if (attributes != null && attributes.isNotEmpty) {
      for (final entry in attributes.entries) {
        final attrSlug = entry.key;
        final values = entry.value;
        if (values.isEmpty) continue;
        query['attr[$attrSlug][]'] = values;
      }
    }

    final response = await _client.get(
      '/categories/$slug/products',
      queryParameters: query,
    );

    final dynamic data =
        response['data'] ?? response['products'] ?? response['items'] ?? response['results'];
    final List<dynamic> items;
    if (data is List<dynamic>) {
      items = data;
    } else if (data is Map<String, dynamic> && data['data'] is List<dynamic>) {
      items = data['data'] as List<dynamic>;
    } else {
      items = const [];
    }

    return items.whereType<Map<String, dynamic>>().map(Product.fromJson).toList();
  }

  Future<ProductListing> fetchCategoryListing({
    required String slug,
    String? search,
    List<String>? subIds,
    List<String>? brandIds,
    Map<String, List<String>>? attributes,
    String? sort,
    String? vendorId,
    double? minPrice,
    double? maxPrice,
    bool? featured,
    int? page,
    int? limit,
  }) async {
    final query = <String, dynamic>{};
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (sort != null && sort.isNotEmpty) query['sort'] = sort;
    if (vendorId != null && vendorId.isNotEmpty) query['vendor_id'] = vendorId;
    if (minPrice != null) query['min_price'] = minPrice.toString();
    if (maxPrice != null) query['max_price'] = maxPrice.toString();
    if (featured != null) query['featured'] = featured ? '1' : '0';
    if (page != null) query['page'] = '$page';
    if (limit != null) query['per_page'] = '$limit';
    query['ajax'] = '1';
    if (subIds != null && subIds.isNotEmpty) {
      query['sub'] = subIds.first;
    }
    if (brandIds != null && brandIds.isNotEmpty) {
      query['brand[]'] = brandIds;
    }
    if (attributes != null && attributes.isNotEmpty) {
      for (final entry in attributes.entries) {
        final attrSlug = entry.key;
        final values = entry.value;
        if (values.isEmpty) continue;
        query['attr[$attrSlug][]'] = values;
      }
    }

    final response = await _client.get(
      '/categories/$slug/products',
      queryParameters: query,
    );

    final dynamic data =
        response['data'] ?? response['products'] ?? response['items'] ?? response['results'];
    final dynamic filters = response['filters'] ?? data?['filters'];
    final subcats = <CategoryFilterOption>[];
    final attributesBySub = <String, List<CategoryAttribute>>{};
    if (filters is Map<String, dynamic>) {
      final subs = filters['subcategories'];
      if (subs is List) {
        subcats.addAll(
          subs.whereType<Map<String, dynamic>>().map(CategoryFilterOption.fromJson),
        );
      }
      final attrs = filters['attributes'];
      if (attrs is Map<String, dynamic>) {
        attrs.forEach((key, value) {
          if (value is List) {
            attributesBySub[key.toString()] = value
                .whereType<Map<String, dynamic>>()
                .map(CategoryAttribute.fromJson)
                .toList();
          }
        });
      }
    }

    final List<dynamic> items;
    if (data is List<dynamic>) {
      items = data;
    } else if (data is Map<String, dynamic> && data['data'] is List<dynamic>) {
      items = data['data'] as List<dynamic>;
    } else {
      items = const [];
    }

    final products = items.whereType<Map<String, dynamic>>().map(Product.fromJson).toList();

    // If no subcategories yet, attempt to fetch filter metadata from category endpoint.
    List<CategoryFilterOption> mergedSubcats = subcats;
    final mergedAttrs = attributesBySub.isNotEmpty
        ? attributesBySub
        : await _fetchFilterAttributes(slug);
    if (mergedSubcats.isEmpty) {
      try {
        mergedSubcats = await _fetchFilterSubcategories(slug);
      } catch (_) {
        // ignore metadata failures
      }
    }

    return ProductListing(
      products: products,
      subcategories: mergedSubcats,
      attributesBySubcategory: mergedAttrs,
    );
  }

  Future<List<CategoryFilterOption>> _fetchFilterSubcategories(String slug) async {
    try {
      final resp = await _client.get(
        '/categories/$slug/products',
        queryParameters: {'per_page': '1', 'ajax': '1'},
      );
      final dynamic filters = resp['filters'] ?? resp['data']?['filters'];
      if (filters is Map<String, dynamic>) {
        final subs = filters['subcategories'];
        if (subs is List) {
          return subs
              .whereType<Map<String, dynamic>>()
              .map(CategoryFilterOption.fromJson)
              .toList();
        }
      }
    } catch (_) {
      // silently ignore filter fetch issues
    }
    return const <CategoryFilterOption>[];
  }

  Future<Map<String, List<CategoryAttribute>>> _fetchFilterAttributes(String slug) async {
    try {
      final resp = await _client.get(
        '/categories/$slug/products',
        queryParameters: {'per_page': '1', 'ajax': '1'},
      );
      final dynamic filters = resp['filters'] ?? resp['data']?['filters'];
      if (filters is Map<String, dynamic>) {
        final attrs = filters['attributes'];
        if (attrs is Map<String, dynamic>) {
          final result = <String, List<CategoryAttribute>>{};
          attrs.forEach((key, value) {
            if (value is List) {
              result[key.toString()] = value
                  .whereType<Map<String, dynamic>>()
                  .map(CategoryAttribute.fromJson)
                  .toList();
            }
          });
          return result;
        }
      }
    } catch (_) {
      // ignore
    }
    return const <String, List<CategoryAttribute>>{};
  }
}

class ProductListing {
  final List<Product> products;
  final List<CategoryFilterOption> subcategories;
  final Map<String, List<CategoryAttribute>> attributesBySubcategory;

  const ProductListing({
    required this.products,
    required this.subcategories,
    this.attributesBySubcategory = const {},
  });
}

class CategoryFilterOption {
  final String name;
  final String? slug;
  final int? id;

  const CategoryFilterOption({required this.name, this.slug, this.id});

  factory CategoryFilterOption.fromJson(Map<String, dynamic> json) {
    return CategoryFilterOption(
      name: json['name']?.toString() ?? json['title']?.toString() ?? 'Option',
      slug: json['slug']?.toString(),
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
    );
  }
}

class CategoryAttribute {
  final int? id;
  final String name;
  final String slug;
  final List<CategoryAttributeOption> options;

  const CategoryAttribute({
    this.id,
    required this.name,
    required this.slug,
    this.options = const [],
  });

  factory CategoryAttribute.fromJson(Map<String, dynamic> json) {
    final opts = json['options'];
    return CategoryAttribute(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      name: json['name']?.toString() ?? 'Attribute',
      slug: json['slug']?.toString() ?? '',
      options: opts is List
          ? opts.whereType<Map<String, dynamic>>().map(CategoryAttributeOption.fromJson).toList()
          : const [],
    );
  }
}

class CategoryAttributeOption {
  final String label;
  final String value;
  final String? id;

  const CategoryAttributeOption({
    required this.label,
    required this.value,
    this.id,
  });

  factory CategoryAttributeOption.fromJson(Map<String, dynamic> json) {
    final val = json['value']?.toString() ?? json['label']?.toString() ?? json['id']?.toString() ?? '';
    return CategoryAttributeOption(
      label: json['label']?.toString() ?? val,
      value: val,
      id: json['id']?.toString(),
    );
  }
}
