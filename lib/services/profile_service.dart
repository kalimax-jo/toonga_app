import 'dart:io';

import '../models/profile_data.dart';
import 'api_client.dart';
import 'session_manager.dart';

class ProfileService {
  ProfileService({
    ApiClient? apiClient,
    SessionManager? sessionManager,
  })  : _client = apiClient ?? ApiClient(),
        _sessionManager = sessionManager ?? SessionManager.instance;

  final ApiClient _client;
  final SessionManager _sessionManager;

  Future<ProfileData> fetchProfile() async {
    final token = await _sessionManager.getToken();
    final headers = token != null ? {'Authorization': 'Bearer $token'} : null;
    final json = await _client.get('/auth/me', headers: headers);
    return ProfileData.fromJson(json);
  }

  Future<ProfileData> updateProfile(
    Map<String, String> fields, {
    File? avatarFile,
  }) async {
    final token = await _sessionManager.getToken();
    final headers = token != null ? {'Authorization': 'Bearer $token'} : null;
    Map<String, dynamic> json;
    if (avatarFile != null) {
      json = await _client.upload(
        '/auth/update-profile',
        headers: headers,
        fields: fields,
        file: avatarFile,
        fileField: 'avatar',
      );
    } else {
      json = await _client.post(
        '/auth/update-profile',
        headers: headers,
        body: fields,
      );
    }
    return ProfileData.fromJson(json);
  }

  Future<void> logout() async {
    final token = await _sessionManager.getToken();
    final headers = token != null ? {'Authorization': 'Bearer $token'} : null;
    try {
      await _client.post('/auth/logout', headers: headers);
    } finally {
      await _sessionManager.clear();
    }
  }
}
