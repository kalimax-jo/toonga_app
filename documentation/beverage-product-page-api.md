# Beverage Product Page API (Mobile)

Endpoint (preferred for mobile): `GET /api/categories/beverage/products`
Legacy web endpoint (HTML by default, JSON when `ajax=1` or `Accept: application/json`): `GET /categories/beverage/products`

Purpose: Returns products under the Beverage category (including its subcategories), filtered to approved + active items.

## Query Parameters
- `q` — search in `name`, `description`, `sku`.
- `sub[]` — one or many subcategory IDs (only beverage subcategories).
- `brand[]` — one or many vendor IDs.
- `min_price`, `max_price` — numeric price bounds.
- `attr[<attribute_slug>][]` — attribute filters. Values can be option labels/values or numeric option IDs. Definitions come from `category_attributes` for this category where `is_active` + `is_filterable` are true.
- `sort` — `price_asc` | `price_desc` | `newest` (default).
- `page` — paginator page (default 12 per page).
- `ajax` — optional; JSON is forced on the `/api/...` route. Needed only on the legacy web path.

## Response (suggested JSON shape)
```jsonc
{
  "data": [ /* products with appends */ ],
  "links": {
    "next": "https://.../categories/beverage/products?page=2",
    "prev": null
  },
  "meta": {
    "current_page": 1,
    "last_page": 5,
    "per_page": 12,
    "total": 60,
    "category": { "id": 1, "name": "Beverage", "slug": "beverage" }
  },
  "filters": {
    "subcategories": [ { "id": 10, "name": "Sodas" }, ... ],
    "brands": [ { "id": 3, "business_name": "Coke" }, ... ],
    "attributes": {
      "general": [ { "slug": "size", "name": "Size", "options": [ ... ] }, ... ],
      "12": [ { "slug": "flavor", "name": "Flavor", "options": [ ... ] } ] // keyed by subcategory_id
    }
  }
}
```

### Flutter decoding hints
- `data` is a list of products; map to `List<Product>`.
- `links.next` is nullable; check before paging.
- `filters.attributes` is an object keyed by `"general"` or `subcategory_id` strings; decode as `Map<String, List<AttributeDef>>`.
- `options` inside attributes can be plain strings or `{label, value, id}` objects; normalize to `{label, value, id?}`.

Product fields (from model + appends):
- Core: `id`, `name`, `description`, `price`, `sale_price`, `featured_image_url`, `vendor_name`, `category_name`, `subcategory_id`.
- Status/stock: `status`/`approval_status`, `product_status`/`is_active`, `stock_quantity` (or `quantity` accessor).
- Rewards: `can_have_miles`, `miles_reward` (computed via `rewards.miles_conversion_rate`), `can_have_cashback`, `cashback_percentage`.
- Attributes: `attribute_values` each with `attribute.slug/name` and optional `option.label/value/id`.

## Example Mobile Request
```http
GET /api/categories/beverage/products?q=cola&sub[]=12&brand[]=3&attr[size][]=500ml&min_price=1000&max_price=5000&sort=price_desc&page=1
Accept: application/json
```

### Flutter `http` example
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> fetchBeverages() async {
  final uri = Uri.parse(
    'https://toonga.app/api/categories/beverage/products'
  ).replace(queryParameters: {
    'q': 'cola',
    'sub[]': '12',
    'brand[]': '3',
    'attr[size][]': '500ml',
    'min_price': '1000',
    'max_price': '5000',
    'sort': 'price_desc',
    'page': '1',
  });

  final res = await http.get(uri, headers: {'Accept': 'application/json'});
  if (res.statusCode != 200) throw Exception('Failed: ${res.statusCode}');

  final json = jsonDecode(res.body) as Map<String, dynamic>;
  // json['data'] => List of products
  // json['meta'] => pagination info
  // json['filters'] => subcategories/brands/attributes for UI
}
```

## Notes / Implementation
- Use the mobile-first endpoint `/api/categories/{slug}/products` to always get JSON. The legacy web path still returns HTML unless `Accept: application/json` or `ajax=1` is set.
- Attribute filters match by attribute slug and accept both raw values and option IDs/labels when checking `product_attribute_values`.
- Flutter pagination: use `meta.current_page`, `meta.last_page`, and `links.next` to decide when to stop; pass `page` on subsequent requests.
