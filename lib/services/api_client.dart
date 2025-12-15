import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class ApiClient {
  ApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final response = await _httpClient.get(
      uri,
      headers: _buildHeaders(headers),
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final response = await _httpClient.post(
      ApiConfig.uri(path),
      headers: _buildHeaders(headers),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, String>? headers,
  }) async {
    final response = await _httpClient.delete(
      ApiConfig.uri(path),
      headers: _buildHeaders(headers),
    );
    return _decodeResponse(response);
  }

  Map<String, String> _buildHeaders(Map<String, String>? overrides) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?overrides,
    };
  }

  Uri _buildUri(String path, Map<String, dynamic>? query) {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final base = Uri.parse(ApiConfig.baseUrl);
    final normalizedBasePath =
        base.path.endsWith('/') ? base.path : '${base.path}/';

    final queryParts = <String>[];
    query?.forEach((key, value) {
      if (value == null) return;
      if (value is Iterable) {
        for (final item in value) {
          if (item == null) continue;
          queryParts.add(
            '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(item.toString())}',
          );
        }
      } else {
        queryParts.add(
          '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value.toString())}',
        );
      }
    });

    final queryString = queryParts.join('&');
    final full = '$normalizedBasePath$cleanPath';
    final uriString =
        '${base.scheme}://${base.authority}$full${queryString.isEmpty ? '' : '?$queryString'}';
    return Uri.parse(uriString);
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final statusCode = response.statusCode;
    Map<String, dynamic> data = {};
    if (response.body.isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        } else {
          data = {'data': decoded};
        }
      } on FormatException {
        final preview = response.body.length > 120
            ? '${response.body.substring(0, 120)}...'
            : response.body;
        throw ApiException(
          message: 'Invalid JSON response (${response.statusCode}): $preview',
          statusCode: statusCode,
        );
      }
    }

    if (statusCode < 200 || statusCode >= 300) {
      final message =
          data['message']?.toString() ?? 'Unexpected error ($statusCode)';
      throw ApiException(message: message, statusCode: statusCode);
    }

    return data;
  }
  Future<Map<String, dynamic>> upload(
    String path, {
    Map<String, String>? fields,
    File? file,
    String fileField = 'file',
    Map<String, String>? headers,
  }) async {
    final uri = ApiConfig.uri(path);
    final request = http.MultipartRequest('POST', uri);
    final baseHeaders = <String, String>{
      'Accept': 'application/json',
      ...?headers,
    };
    request.headers.addAll(baseHeaders);
    if (fields != null) {
      request.fields.addAll(fields);
    }
    if (file != null) {
      request.files.add(await http.MultipartFile.fromPath(fileField, file.path));
    }
    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    final response = http.Response(
      body,
      streamed.statusCode,
      headers: streamed.headers,
    );
    return _decodeResponse(response);
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException({required this.message, this.statusCode});

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message)';
}
