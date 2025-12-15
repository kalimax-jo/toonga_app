import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../services/api_client.dart';
import '../../services/api_config.dart';
import '../../services/session_manager.dart';
import '../../theme/app_colors.dart';

class EndpointViewerScreen extends StatefulWidget {
  final String title;
  final String endpoint;

  const EndpointViewerScreen({
    super.key,
    required this.title,
    required this.endpoint,
  });

  @override
  State<EndpointViewerScreen> createState() => _EndpointViewerScreenState();
}

class _EndpointViewerScreenState extends State<EndpointViewerScreen> {
  final ApiClient _client = ApiClient();
  final SessionManager _sessionManager = SessionManager.instance;

  dynamic _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await _sessionManager.getToken();
      final headers =
          token != null ? {'Authorization': 'Bearer $token'} : null;
      final response = await _client.get(widget.endpoint, headers: headers);
      if (!mounted) return;
      setState(() => _data = response);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
              ? _ApiError(message: _error!, onRetry: _load)
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (widget.endpoint == '/auth/me' && _data is Map<String, dynamic>) {
      return _PersonalInfoView(data: _data as Map<String, dynamic>);
    }

    return _ApiDataView(data: _data);
  }
}

class _ApiDataView extends StatelessWidget {
  final dynamic data;

  const _ApiDataView({required this.data});

  @override
  Widget build(BuildContext context) {
    final display = const JsonEncoder.withIndent('  ').convert(data);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SelectableText(
        display,
        style: const TextStyle(color: Colors.white70, height: 1.4),
      ),
    );
  }
}

class _ApiError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ApiError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonalInfoView extends StatelessWidget {
  final Map<String, dynamic> data;

  const _PersonalInfoView({required this.data});

  String? _absoluteUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    if (path.startsWith('file://')) {
      final uri = Uri.parse(path);
      return uri.toFilePath();
    }
    final base = Uri.parse(ApiConfig.baseUrl);
    final origin = '${base.scheme}://${base.host}${base.hasPort ? ':${base.port}' : ''}';
    final clean = path.startsWith('/') ? path : '/$path';
    return '$origin$clean';
  }

  ImageProvider? _resolveImage(String? path) {
    final normalized = _absoluteUrl(path);
    if (normalized == null) return null;
    if (normalized.startsWith('/') || normalized.startsWith('C:\\') || normalized.startsWith('D:\\')) {
      return FileImage(File(normalized));
    }
    return NetworkImage(normalized);
  }

  @override
  Widget build(BuildContext context) {
    final name = data['name']?.toString() ?? 'Unknown';
    final email = data['email']?.toString() ?? 'No email';
    final phone = data['phone']?.toString() ?? 'No phone';
    final role = data['role']?.toString() ?? 'N/A';
    final avatar = data['avatar']?.toString();
    final createdAt = data['created_at']?.toString();
    final lastLogin = data['last_login_at']?.toString() ?? 'No record';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.card,
                  backgroundImage: _resolveImage(avatar),
                  child: avatar == null || avatar.isEmpty
                      ? const Icon(Iconsax.user, color: Colors.white54, size: 36)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 2),
                Text(
                  phone,
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _InfoTile(
            label: 'Role',
            value: role,
            icon: Iconsax.user_cirlce_add,
          ),
          _InfoTile(
            label: 'Provider',
            value: data['provider']?.toString() ?? 'Unknown',
            icon: Iconsax.shield_tick,
          ),
          _InfoTile(
            label: 'Account Created',
            value: createdAt ?? 'Unknown',
            icon: Iconsax.calendar,
          ),
          _InfoTile(
            label: 'Last Login',
            value: lastLogin,
            icon: Iconsax.clock,
          ),
          _InfoTile(
            label: 'Status',
            value: data['is_active'] == true ? 'Active' : 'Inactive',
            icon: Iconsax.toggle_on,
          ),
          if (data['email_verified_at'] != null)
            _InfoTile(
              label: 'Email Verified',
              value: data['email_verified_at'].toString(),
              icon: Iconsax.verify,
            ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
