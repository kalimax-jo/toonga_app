import 'api_client.dart';

class AuthApi {
  AuthApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final json = await _client.post(
      '/auth/login',
      body: {'email': email, 'password': password},
    );

    return AuthResponse.fromJson(json);
  }

  Future<String> requestPasswordReset({required String email}) async {
    final response = await _client.post(
      '/auth/password/forgot',
      body: {'email': email},
    );
    return response['message']?.toString() ?? 'Password reset link sent';
  }

  Future<AuthResponse> loginWithGoogle({required String idToken}) async {
    final json = await _client.post(
      '/auth/google/mobile',
      body: {'id_token': idToken},
    );
    return AuthResponse.fromJson(json);
  }
}

class AuthResponse {
  final String? token;
  final Map<String, dynamic>? user;

  const AuthResponse({this.token, this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token']?.toString(),
      user: json['user'] is Map<String, dynamic>
          ? json['user'] as Map<String, dynamic>
          : null,
    );
  }

  @override
  String toString() => 'AuthResponse(token: $token, user: $user)';
}
