class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = 'https://toonga.app/api';

  static Uri uri(String path, [Map<String, dynamic>? queryParameters]) {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final base = Uri.parse(baseUrl);
    final normalizedBasePath = base.path.endsWith('/')
        ? base.path
        : '${base.path}/';
    return base.replace(
      path: '$normalizedBasePath$cleanPath',
      queryParameters: queryParameters,
    );
  }
}
