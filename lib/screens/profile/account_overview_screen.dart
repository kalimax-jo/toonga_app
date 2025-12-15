import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../models/order_summary.dart';
import '../../services/api_client.dart';
import '../../services/session_manager.dart';
import '../../models/miles_overview.dart';
import '../../theme/app_colors.dart';
import '../orders/order_detail_screen.dart';

class AccountOverviewScreen extends StatefulWidget {
  const AccountOverviewScreen({super.key});

  @override
  State<AccountOverviewScreen> createState() => _AccountOverviewScreenState();
}

class _AccountOverviewScreenState extends State<AccountOverviewScreen> {
  final ApiClient _client = ApiClient();
  final SessionManager _session = SessionManager.instance;

  bool _loading = true;
  String? _error;
  _OverviewData? _data;

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
      final container = json['data'] ?? json;
      final user = container['user'] as Map<String, dynamic>? ?? const <String, dynamic>{};
      final orders = container['orders'] as Map<String, dynamic>? ?? const <String, dynamic>{};
      final countsMap = orders['counts'] as Map<String, dynamic>? ?? const <String, dynamic>{};
      final recentList = orders['recent'] as List<dynamic>? ?? const <dynamic>[];
      final milesBlock = container['miles'] as Map<String, dynamic>?;
      MilesOverview? miles;
      if (milesBlock != null) {
        miles = MilesOverview.fromJson(milesBlock);
      } else {
        final legacy = _double(
              container['miles'] ??
                  container['miles_balance'] ??
                  container['reward_miles'] ??
                  container['points'] ??
                  container['loyalty_points'] ??
                  user['miles'] ??
                  user['miles_balance'],
            ) ??
            _double(orders['miles'] ?? orders['miles_balance']);
        if (legacy != null) {
          miles = MilesOverview(total: legacy, available: legacy, used: 0);
        }
      }

      final counts = _OverviewCounts(
        total: _int(countsMap['total']),
        delivered: _int(countsMap['delivered']),
        open: _int(countsMap['open']),
      );

      final recent = recentList
          .whereType<Map<String, dynamic>>()
          .map(_RecentOrder.fromJson)
          .toList();

      _data = _OverviewData(
        user: _OverviewUser.fromJson(user),
        counts: counts,
        recent: recent,
        miles: miles,
      );
    } catch (e) {
      _error = e.toString();
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
          'Account Overview',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.primary,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          _ErrorCard(message: _error!, onRetry: _load),
        ],
      );
    }
    final data = _data;
    if (data == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          _ErrorCard(
            message: 'No overview data available.',
            onRetry: null,
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        _UserCard(user: data.user),
        if (data.miles != null) ...[
          const SizedBox(height: 12),
          _MilesCard(miles: data.miles!),
        ],
        const SizedBox(height: 12),
        _CountsCard(counts: data.counts),
        const SizedBox(height: 16),
        if (data.recent.isNotEmpty) ...[
          const Text(
            'Recent Orders',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          ...data.recent.map((order) => _RecentOrderCard(order: order, onTap: () {
                if (order.id != null) {
                  final summary = OrderSummary(
                    id: order.id,
                    title: order.orderNumber ?? 'Order',
                    status: order.status ?? 'pending',
                    vendorName: order.vendorName ?? '-',
                    createdAt: order.createdAt,
                    amount: order.totalAmount,
                    currency: order.currency,
                    itemsCount: order.itemsCount,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailScreen(order: summary),
                    ),
                  );
                }
              })),
        ],
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  final _OverviewUser user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.profile_circle, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                user.name ?? 'User',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _infoRow('Email', user.email ?? '-'),
          _infoRow('Phone', user.phone ?? '-'),
          _infoRow('Role', user.role ?? '-'),
          _infoRow('Joined', _formatDate(user.joinedAt) ?? '-'),
        ],
      ),
    );
  }
}

class _CountsCard extends StatelessWidget {
  final _OverviewCounts counts;
  const _CountsCard({required this.counts});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _countItem('Total', counts.total, AppColors.primary),
          _countItem('Delivered', counts.delivered, Colors.greenAccent),
          _countItem('Open', counts.open, Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _countItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

class _MilesCard extends StatelessWidget {
  final MilesOverview miles;

  const _MilesCard({required this.miles});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Iconsax.medal_star, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Miles',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _countItem('Available', miles.available, AppColors.primary),
              _countItem('Used', miles.used, Colors.orangeAccent),
              _countItem('Total', miles.total, Colors.white),
            ],
          ),
          if (miles.history.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Recent miles activity',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...miles.history.take(3).map((h) => _MilesHistoryRow(entry: h)),
          ],
        ],
      ),
    );
  }

  Widget _countItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          _formatMoney(value, 'miles'),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }
}

class _MilesHistoryRow extends StatelessWidget {
  final MilesHistory entry;
  const _MilesHistoryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = entry.type == 'earned'
        ? Colors.greenAccent
        : entry.type == 'redeemed'
            ? Colors.orangeAccent
            : Colors.redAccent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.description ?? entry.type ?? '',
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.type == 'redeemed' ? '-' : '+'}${entry.amount.toStringAsFixed(0)} miles',
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
              Text(
                'Balance: ${_formatMoney(entry.balanceAfter, 'miles')}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentOrderCard extends StatelessWidget {
  final _RecentOrder order;
  final VoidCallback onTap;

  const _RecentOrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  order.orderNumber ?? 'Order',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  order.status ?? '-',
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _infoRow('Payment', order.paymentStatus ?? '-'),
          _infoRow('Vendor', order.vendorName ?? '-'),
          _infoRow('Total', order.totalAmount != null ? _formatMoney(order.totalAmount!, order.currency) : '-'),
          _infoRow('Items', order.itemsCount != null ? '${order.itemsCount}' : '-'),
          _infoRow('Date', _formatDate(order.createdAt) ?? '-'),
          if (order.id != null) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.14)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('View Details'),
            ),
          ],
        ],
      ),
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
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 10),
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

class _OverviewData {
  final _OverviewUser user;
  final _OverviewCounts counts;
  final List<_RecentOrder> recent;
  final MilesOverview? miles;

  _OverviewData({
    required this.user,
    required this.counts,
    required this.recent,
    this.miles,
  });
}

class _OverviewUser {
  final int? id;
  final String? name;
  final String? email;
  final String? phone;
  final String? role;
  final DateTime? joinedAt;

  _OverviewUser({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.role,
    this.joinedAt,
  });

  factory _OverviewUser.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic input) {
      if (input == null) return null;
      if (input is DateTime) return input;
      return DateTime.tryParse(input.toString());
    }

    return _OverviewUser(
      id: _int(json['id']),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      role: json['role']?.toString(),
      joinedAt: parseDate(json['joined_at']),
    );
  }
}

class _OverviewCounts {
  final int total;
  final int delivered;
  final int open;

  _OverviewCounts({
    this.total = 0,
    this.delivered = 0,
    this.open = 0,
  });
}

class _RecentOrder {
  final int? id;
  final String? orderNumber;
  final String? status;
  final String? paymentStatus;
  final double? totalAmount;
  final String? currency;
  final DateTime? createdAt;
  final String? vendorName;
  final int? itemsCount;

  const _RecentOrder({
    this.id,
    this.orderNumber,
    this.status,
    this.paymentStatus,
    this.totalAmount,
    this.currency,
    this.createdAt,
    this.vendorName,
    this.itemsCount,
  });

  factory _RecentOrder.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic input) {
      if (input == null) return null;
      if (input is DateTime) return input;
      return DateTime.tryParse(input.toString());
    }

    return _RecentOrder(
      id: _int(json['id']),
      orderNumber: json['order_number']?.toString(),
      status: json['status']?.toString(),
      paymentStatus: json['payment_status']?.toString(),
      totalAmount: _double(json['total_amount']),
      currency: json['currency']?.toString(),
      createdAt: parseDate(json['created_at']),
      vendorName: json['vendor']?.toString() ??
          json['vendor_name']?.toString() ??
          json['vendor']?['business_name']?.toString(),
      itemsCount: json['items'] is List
          ? (json['items'] as List).length
          : _int(json['items_count']),
    );
  }
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double? _double(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

String? _formatDate(DateTime? date) {
  if (date == null) return null;
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _formatMoney(double value, String? currency) {
  final intPart = value.floor();
  final withCommas = intPart.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  return '$withCommas ${currency ?? 'RWF'}';
}

Widget _infoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.white.withOpacity(0.08)),
  );
}
