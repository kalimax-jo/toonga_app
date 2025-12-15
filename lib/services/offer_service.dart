import '../models/offer.dart';
import 'api_client.dart';
import 'session_manager.dart';

class OfferService {
  OfferService({
    ApiClient? client,
    SessionManager? sessionManager,
  })  : _client = client ?? ApiClient(),
        _sessionManager = sessionManager ?? SessionManager.instance;

  final ApiClient _client;
  final SessionManager _sessionManager;

  Future<List<Offer>> fetchOffers({
    int perPage = 12,
    String? search,
  }) async {
    final resp = await _client.get(
      '/store/offers',
      queryParameters: {
        'per_page': perPage,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );

    final dynamic container = resp['offers'] ?? resp;
    final dynamic data = container is Map<String, dynamic>
        ? (container['data'] ?? container['offers'] ?? container['results'])
        : (resp['data'] ?? container);
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
        .map(Offer.fromJson)
        .toList();
  }

  Future<OfferRedeemResult> redeemOffer(int id) async {
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(message: 'Authentication required');
    }

    final resp = await _client.post(
      '/store/offers/$id/redeem',
      headers: {'Authorization': 'Bearer $token'},
    );

    final bool success = _boolValue(resp['success']) ??
        _boolValue(resp['redeemed']) ??
        _boolValue(resp['is_redeemed']) ??
        true;

    final bool alreadyRedeemed =
        _boolValue(resp['already_redeemed']) ?? _boolValue(resp['is_redeemed']) ?? false;

    final String? rewardCode = _stringValue(
      resp['code'] ?? resp['coupon_code'] ?? resp['reward_code'],
    );

    return OfferRedeemResult(
      success: success,
      alreadyRedeemed: alreadyRedeemed,
      message: _stringValue(resp['message']),
      rewardCode: rewardCode,
    );
  }

  String? _stringValue(dynamic value) => value?.toString();

  bool? _boolValue(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value.toString().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
    return null;
  }
}
