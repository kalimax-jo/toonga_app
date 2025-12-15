import '../models/order_summary.dart';
import 'cart_service.dart';
import 'api_client.dart';
import 'session_manager.dart';

class OrdersService {
  OrdersService({ApiClient? apiClient, SessionManager? sessionManager})
    : _client = apiClient ?? ApiClient(),
      _sessionManager = sessionManager ?? SessionManager.instance;

  final ApiClient _client;
  final SessionManager _sessionManager;

  Future<int> createOrder(List<CartItem> items) async {
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(message: 'Authentication required');
    }

    final body = {
      'items': items
          .map(
            (item) => {
              'product_id': item.product.id,
              'quantity': item.quantity,
            },
          )
          .toList(),
    };

    final json = await _client.post(
      '/orders',
      body: body,
      headers: {'Authorization': 'Bearer $token'},
    );

    return _extractId(json, keys: ['order', 'data', 'id']);
  }

  Future<PaymentInitiationResult> payOrder({
    required int orderId,
    required String msisdn,
    required double amount,
    String? currency,
  }) async {
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(message: 'Authentication required');
    }

    final json = await _client.post(
      '/orders/$orderId/pay',
      body: {
        'msisdn': msisdn,
        if (currency != null) 'currency': currency,
        if (amount > 0) 'amount': amount,
        'metadata': {'source': 'mobile_app', 'platform': 'flutter'},
      },
      headers: {'Authorization': 'Bearer $token'},
    );

    final paymentJson = json['payment'] is Map<String, dynamic>
        ? json['payment'] as Map<String, dynamic>
        : json;
    return PaymentInitiationResult(
      id: _extractId(paymentJson, keys: ['id', 'payment_id']),
      referenceId: _extractReference(paymentJson),
    );
  }

  Future<String> paymentStatus(int paymentId) async {
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(message: 'Authentication required');
    }

    final json = await _client.get(
      '/payments/$paymentId/status',
      headers: {'Authorization': 'Bearer $token'},
    );

    return _extractStatus(json);
  }

  Future<List<OrderSummary>> fetchOrders({int perPage = 20}) async {
    final token = await _sessionManager.getToken();
    final headers = token != null ? {'Authorization': 'Bearer $token'} : null;
    final json = await _client.get(
      '/orders',
      headers: headers,
      queryParameters: {'per_page': perPage},
    );

    final dynamic container = json['orders'] ?? json;
    final dynamic data = container is Map<String, dynamic>
        ? (container['data'] ?? container['orders'] ?? container['results'])
        : (json['data'] ?? container);

    final List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map<String, dynamic> && data['data'] is List) {
      list = data['data'] as List<dynamic>;
    } else {
      list = const [];
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map(OrderSummary.fromJson)
        .toList();
  }

  Future<OrderSummary> fetchOrderDetail(int id) async {
    final token = await _sessionManager.getToken();
    final headers = token != null ? {'Authorization': 'Bearer $token'} : null;
    final json = await _client.get('/orders/$id', headers: headers);

    final dynamic data = json['order'] ?? json['data'] ?? json;
    if (data is Map<String, dynamic>) {
      return OrderSummary.fromJson(data);
    }
    throw const ApiException(message: 'Unexpected order detail response');
  }

  Future<String> fetchInvoiceUrl(int id) async {
    final token = await _sessionManager.getToken();
    final headers = token != null ? {'Authorization': 'Bearer $token'} : null;
    final json = await _client.get('/orders/$id/invoice', headers: headers);
    final dynamic data = json['data'] ?? json['invoice'] ?? json;
    final url =
        (data is Map<String, dynamic>
            ? data['url'] ?? data['download_url']
            : null) ??
        json['url'] ??
        json['download_url'];
    if (url is String && url.isNotEmpty) return url;
    throw const ApiException(message: 'Unable to fetch invoice link');
  }

  int _extractId(Map<String, dynamic> json, {required List<String> keys}) {
    for (final key in keys) {
      final data = json[key];
      if (data is Map<String, dynamic>) {
        final id = data['id'];
        if (id is int) return id;
        if (id is String) {
          final parsed = int.tryParse(id);
          if (parsed != null) return parsed;
        }
      } else if (data is int) {
        return data;
      }
    }
    throw const ApiException(message: 'Unable to create payment/order id');
  }

  String _extractReference(Map<String, dynamic> json) {
    final ref = json['reference_id'] ?? json['reference'] ?? json['id'];
    if (ref is String && ref.isNotEmpty) return ref;
    if (ref is int) return ref.toString();
    throw const ApiException(message: 'Unable to create payment/reference id');
  }

  String _extractStatus(Map<String, dynamic> json) {
    String? fromPayment;
    final payment = json['payment'];
    if (payment is Map<String, dynamic>) {
      fromPayment = _normalizeStatus(payment['status']);
    }

    final body = json['body'];
    final fromBody = body is Map<String, dynamic>
        ? _normalizeStatus(body['status'])
        : null;

    final direct = _normalizeStatus(json['status']);

    return fromBody ?? fromPayment ?? direct ?? 'unknown';
  }

  String? _normalizeStatus(dynamic raw) {
    if (raw == null || raw is num) return null;
    final value = raw.toString().trim();
    if (value.isEmpty) return null;
    return value.toLowerCase();
  }
}

/// Represents the result returned when initiating a payment.
class PaymentInitiationResult {
  final int id;
  final String referenceId;

  PaymentInitiationResult({required this.id, required this.referenceId});
}
