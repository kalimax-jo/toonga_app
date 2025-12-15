import '../models/home_response.dart';
import 'api_client.dart';

typedef TokenProvider = Future<String?> Function();

class HomeService {
  HomeService({
    ApiClient? client,
    TokenProvider? tokenProvider,
  })  : _client = client ?? ApiClient(),
        _tokenProvider = tokenProvider;

  final ApiClient _client;
  final TokenProvider? _tokenProvider;

  Future<HomeResponse> fetchHome({
    double? lat,
    double? lng,
    int? limit,
  }) async {
    final query = <String, dynamic>{};
    if (lat != null) query['lat'] = lat.toString();
    if (lng != null) query['lng'] = lng.toString();
    if (limit != null) query['limit'] = '$limit';

    final headers = <String, String>{};
    final token = await _tokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final json = await _client.get(
      '/home',
      queryParameters: query.isEmpty ? null : query,
      headers: headers.isEmpty ? null : headers,
    );

    return HomeResponse.fromJson(json);
  }
}
