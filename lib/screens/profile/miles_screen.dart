import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../models/miles_overview.dart';
import '../../services/api_client.dart';
import '../../services/session_manager.dart';
import '../../theme/app_colors.dart';

class MilesScreen extends StatefulWidget {
  const MilesScreen({super.key});

  @override
  State<MilesScreen> createState() => _MilesScreenState();
}

class _MilesScreenState extends State<MilesScreen> {
  final ApiClient _client = ApiClient();
  final SessionManager _session = SessionManager.instance;
  bool _loading = true;
  String? _error;
  MilesOverview? _miles;

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
      final token = await _session.getToken();
      final headers = token != null ? {'Authorization': 'Bearer $token'} : null;
      final json = await _client.get('/account/overview', headers: headers);
      final data = json['miles'] ??
          (json['data'] is Map<String, dynamic> ? (json['data'] as Map<String, dynamic>)['miles'] : null);
      if (data is Map<String, dynamic>) {
        _miles = MilesOverview.fromJson(data);
      } else {
        _miles = null;
      }
    } catch (error) {
      _error = error.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Miles History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.primary,
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _ErrorCard(message: _error!, onRetry: _load),
        ],
      );
    }
    if (_miles == null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _ErrorCard(
            message: 'Miles data is not available yet.',
            onRetry: _load,
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _MilesSummary(miles: _miles!),
        const SizedBox(height: 16),
        const Text(
          'Recent activity',
          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ..._miles!.history.map((entry) => _MilesHistoryRow(entry: entry)),
      ],
    );
  }
}

class _MilesSummary extends StatelessWidget {
  final MilesOverview miles;

  const _MilesSummary({required this.miles});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Miles summary',
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(label: 'Available', value: miles.available, color: Colors.amber),
              _StatItem(label: 'Used', value: miles.used, color: Colors.orangeAccent),
              _StatItem(label: 'Total', value: miles.total, color: Colors.white),
            ],
          ),
        ],
      ),
    );
  }
}

class _MilesHistoryRow extends StatelessWidget {
  final MilesHistory entry;

  const _MilesHistoryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = entry.type == 'redeemed'
        ? Colors.orangeAccent
        : entry.type == 'used'
            ? Colors.redAccent
            : Colors.greenAccent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Iconsax.arrow_right_3, color: Colors.white54, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.description ?? entry.type ?? 'Miles',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(entry.createdAt) ?? '',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${entry.type == 'redeemed' ? '-' : '+'}${entry.amount.toStringAsFixed(0)}',
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toStringAsFixed(0),
          style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorCard({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: const TextStyle(color: Colors.white)),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
              ),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

String? _formatDate(DateTime? date) {
  if (date == null) return null;
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
