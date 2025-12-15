import 'package:flutter/foundation.dart';

import '../models/reel.dart';
import '../models/reel_comment.dart';
import 'api_client.dart';
import 'session_manager.dart';

class ReelsService {
  ReelsService({
    ApiClient? client,
    SessionManager? sessionManager,
  })  : _client = client ?? ApiClient(),
        _sessionManager = sessionManager ?? SessionManager.instance;

  final ApiClient _client;
  final SessionManager _sessionManager;

  Future<ReelsFetchResult> fetchReels({bool activeOnly = true}) async {
    String containerType = 'unknown';
    int rawCount = 0;
    String? error;

    try {
      final token = await _sessionManager.getToken();
      final headers = token != null && token.isNotEmpty
          ? {'Authorization': 'Bearer $token'}
          : null;
      final json = await _client.get(
        '/reels',
        queryParameters: {'active_only': activeOnly ? '1' : '0'},
        headers: headers,
      );

      final dynamic container =
          json is Map<String, dynamic> ? (json['data'] ?? json['reels'] ?? json) : json;

      containerType = container.runtimeType.toString();

      List<dynamic>? list = _extractList(container);
      containerType = list == null ? containerType : '$containerType->list';

      if (list == null) {
        debugPrint('Reels parse: unexpected container $containerType, value=$container');
        return ReelsFetchResult(
          reels: const <Reel>[],
          containerType: containerType,
          rawCount: rawCount,
          error: 'Unexpected container: $containerType',
        );
      }

      rawCount = list.length;
      try {
        final reels = list
            .whereType<Map<String, dynamic>>()
            .map(Reel.fromJson)
            .toList();
        debugPrint('Reels parse ok: $rawCount items, type=$containerType');
        return ReelsFetchResult(
          reels: reels,
          containerType: '$containerType (list)',
          rawCount: rawCount,
          error: error,
        );
      } catch (e) {
        debugPrint('Reels item parse failed: $e');
        return ReelsFetchResult(
          reels: const <Reel>[],
          containerType: '$containerType (list)',
          rawCount: rawCount,
          error: 'Item parse failed: $e',
        );
      }
    } catch (e, st) {
      error = e.toString();
      debugPrint('Reels fetch error: $error\n$st');
      return ReelsFetchResult(
        reels: const <Reel>[],
        containerType: containerType,
        rawCount: rawCount,
        error: error,
      );
    }
  }

  Future<void> sendView(int reelId) async {
    try {
      await _client.post('/reels/$reelId/view');
    } catch (_) {
      // Ignore view failures silently.
    }
  }

  Future<LikeResult> toggleLike(int reelId) async {
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(message: 'Authentication required');
    }

    final resp = await _client.post(
      '/reels/$reelId/like',
      headers: {'Authorization': 'Bearer $token'},
    );

    final isLiked =
        resp['is_liked'] == true || resp['is_liked_by_user'] == true;
    final likes = resp['likes_count'] is int
        ? resp['likes_count'] as int
        : int.tryParse('${resp['likes_count']}') ?? 0;

    return LikeResult(isLiked: isLiked, likesCount: likes);
  }

  Future<SaveResult> toggleSave(int reelId) async {
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(message: 'Authentication required');
    }

    final resp = await _client.post(
      '/reels/$reelId/save',
      headers: {'Authorization': 'Bearer $token'},
    );

    final isSaved =
        resp['saved'] == true || resp['is_saved'] == true || resp['is_saved_by_user'] == true;
    final saves = resp['saves_count'] is int
        ? resp['saves_count'] as int
        : int.tryParse('${resp['saves_count']}') ?? 0;

    return SaveResult(isSaved: isSaved, savesCount: saves);
  }

  Future<List<ReelComment>> fetchComments(int reelId) async {
    try {
      final resp = await _client.get('/public/reels/$reelId/comments');
      final dynamic data = resp['data'] ?? resp;
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().map(ReelComment.fromJson).toList();
      }
      return const <ReelComment>[];
    } catch (e) {
      debugPrint('Reel comments fetch failed: $e');
      rethrow;
    }
  }

  Future<ReelComment> addComment(
    int reelId, {
    required String comment,
    String? guestName,
  }) async {
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(message: 'Authentication required');
    }
    final resp = await _client.post(
      '/reels/$reelId/comments',
      headers: {
        'Authorization': 'Bearer $token',
      },
      body: {'comment': comment, if (guestName != null) 'guest_name': guestName},
    );
    final dynamic data = resp['data'] ?? resp;
    if (data is Map<String, dynamic>) {
      return ReelComment.fromJson(data);
    }
    throw const ApiException(message: 'Unexpected response when adding comment');
  }

  Future<FollowResult> toggleFollow(int vendorId, {required bool isFollowing}) async {
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(message: 'Authentication required');
    }

    final path = '/public/vendors/$vendorId/follow';
    final resp = isFollowing
        ? await _client.delete(
            path,
            headers: {'Authorization': 'Bearer $token'},
          )
        : await _client.post(
            path,
            headers: {'Authorization': 'Bearer $token'},
          );

    final nextState =
        resp['is_following'] == true || resp['following'] == true || resp['followed'] == true;
    return FollowResult(isFollowing: nextState);
  }

  Future<bool?> fetchFollowStatus(int vendorId) async {
    try {
      final token = await _sessionManager.getToken();
      final headers = token != null && token.isNotEmpty
          ? {'Authorization': 'Bearer $token'}
          : null;
      final resp = await _client.get(
        '/public/vendors/$vendorId/follow',
        headers: headers,
      );
      final val = resp['is_following'] ?? resp['following'] ?? resp['followed'];
      return val == true;
    } catch (_) {
      return null;
    }
  }

  Future<List<Reel>> fetchSavedReels() async {
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(message: 'Authentication required');
    }
    final resp = await _client.get(
      '/reels/saved',
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    final dynamic data = resp['data'] ?? resp['reels'] ?? resp;
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map(Reel.fromJson).toList();
    }
    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(Reel.fromJson)
          .toList();
    }
    return const <Reel>[];
  }
}

class LikeResult {
  final bool isLiked;
  final int likesCount;

  const LikeResult({required this.isLiked, required this.likesCount});
}

class SaveResult {
  final bool isSaved;
  final int savesCount;

  const SaveResult({required this.isSaved, required this.savesCount});
}

class FollowResult {
  final bool isFollowing;

  const FollowResult({required this.isFollowing});
}

class ReelsFetchResult {
  final List<Reel> reels;
  final String containerType;
  final int rawCount;
  final String? error;

  const ReelsFetchResult({
    required this.reels,
    required this.containerType,
    required this.rawCount,
    this.error,
  });
}

List<dynamic>? _extractList(dynamic container) {
  try {
    if (container is List) return container;
    if (container is Iterable) return container.toList();
    if (container is Map<String, dynamic>) {
      final data = container['data'];
      final reels = container['reels'];
      if (data is List) return data;
      if (reels is List) return reels;
      if (data is Map<String, dynamic>) {
        final nested = data['data'];
        if (nested is List) return nested;
      }
      if (container['id'] != null || container['video_url'] != null) {
        return <dynamic>[container];
      }
    }
    return null;
  } catch (_) {
    return null;
  }
}
