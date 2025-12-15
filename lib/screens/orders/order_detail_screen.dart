import 'package:flutter/material.dart';

import '../../models/order_summary.dart';
import '../../services/orders_service.dart';
import '../../theme/app_colors.dart';
import '../home/home_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderSummary order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrdersService _service = OrdersService();
  OrderSummary? _order;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _load();
  }

  Future<void> _load() async {
    final id = widget.order.id;
    if (id == null) {
      setState(() => _loading = false);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final detail = await _service.fetchOrderDetail(id);
      if (!mounted) return;
      setState(() {
        _order = detail;
      });
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
    final order = _order ?? widget.order;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Order Summary',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _error != null
                ? _OrdersError(message: _error!, onRetry: _load)
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _HeaderCard(order: order),
                      const SizedBox(height: 16),
                      _TimelineSection(entries: order.timeline),
                      const SizedBox(height: 16),
                      _ItemsSection(order: order),
                      const SizedBox(height: 16),
                      _SummarySection(order: order),
                      const SizedBox(height: 16),
                      if (order.shippingAddress != null)
                        _ShippingCard(address: order.shippingAddress!),
                      if (order.shippingAddress != null) const SizedBox(height: 16),
                      if (order.payment != null)
                        _PaymentCard(payment: order.payment!, currency: order.currency),
                      if (order.vendor != null) const SizedBox(height: 16),
                      if (order.vendor != null) _VendorCard(vendor: order.vendor!),
                    ],
                  ),
      ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  final List<OrderTimelineEntry> entries;

  const _TimelineSection({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...entries.map((entry) => _TimelineTile(entry: entry)),
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final OrderTimelineEntry entry;

  const _TimelineTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final active = entry.timestamp != null;
    final subtitle = entry.timestamp != null
        ? '${entry.timestamp!.day}/${entry.timestamp!.month}/${entry.timestamp!.year}'
        : entry.description;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active ? AppColors.primary : Colors.white24,
                    width: 2,
                  ),
                ),
              ),
              Container(
                width: 2,
                height: 32,
                color: Colors.white10,
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: TextStyle(
                    color: active ? Colors.white : Colors.white54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _OrdersError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            child: const Text('Retry'),
          )
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final OrderSummary order;

  const _HeaderCard({required this.order});

  String _statusLabel(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('deliver')) return 'Delivered';
    if (lower.contains('cancel')) return 'Cancelled';
    if (lower.contains('process')) return 'Processing';
    if (lower.contains('pending')) return 'Pending';
    return status;
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusLabel(order.status);
    final amount = order.totalAmount ??
        order.amount ??
        order.subtotal ??
        0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber ?? '#${order.id ?? ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.title,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white60, size: 16),
              const SizedBox(width: 8),
              Text(
                order.createdAt?.toLocal().toString().split('.').first ??
                    'Pending',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${amount.toStringAsFixed(0)} ${order.currency ?? ''}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (order.rewardAmount != null && order.rewardAmount! > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.card_giftcard, color: AppColors.primary, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${order.rewardAmount!.toStringAsFixed(0)} ${order.rewardType ?? 'reward'}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ItemsSection extends StatelessWidget {
  final OrderSummary order;

  const _ItemsSection({required this.order});

  @override
  Widget build(BuildContext context) {
    if (order.items.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Items',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        item.imageUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 56,
                          height: 56,
                          color: Colors.white10,
                          child: const Icon(Icons.image_not_supported, color: Colors.white38),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.inventory_2, color: Colors.white38),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (item.sku != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              item.sku!,
                              style:
                                  const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Qty ${item.quantity} • ${item.unitPrice?.toStringAsFixed(0) ?? '-'} ${order.currency ?? ''}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    item.lineTotal?.toStringAsFixed(0) ?? '-',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final OrderSummary order;

  const _SummarySection({required this.order});

  @override
  Widget build(BuildContext context) {
    final rows = <_SummaryRow>[
      _SummaryRow('Subtotal', order.subtotal),
      _SummaryRow('Shipping fee', order.shippingFee),
      _SummaryRow('Total', order.totalAmount ?? order.amount, highlight: true),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...rows.map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      row.label,
                      style: TextStyle(
                        color: row.highlight ? Colors.white : Colors.white70,
                        fontWeight: row.highlight ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    Text(
                      row.value != null
                          ? '${row.value!.toStringAsFixed(0)} ${order.currency ?? ''}'
                          : '-',
                      style: TextStyle(
                        color: row.highlight ? Colors.white : Colors.white,
                        fontWeight: row.highlight ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _SummaryRow {
  final String label;
  final double? value;
  final bool highlight;

  _SummaryRow(this.label, this.value, {this.highlight = false});
}

class _ShippingCard extends StatelessWidget {
  final ShippingAddress address;

  const _ShippingCard({required this.address});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shipping address',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            address.name ?? 'Recipient',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          if (address.phone != null) ...[
            const SizedBox(height: 4),
            Text(
              address.phone!,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            [
              address.line1,
              address.line2,
              address.city,
              address.country,
            ].where((e) => e != null && e!.isNotEmpty).join(', '),
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final OrderPayment payment;
  final String? currency;

  const _PaymentCard({required this.payment, this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _Row(
            label: 'Method',
            value: payment.paymentMethod ?? '-',
          ),
          const SizedBox(height: 8),
          _Row(
            label: 'Reference',
            value: payment.referenceNumber ?? '-',
          ),
          const SizedBox(height: 8),
          _Row(
            label: 'Status',
            value: payment.status ?? '-',
          ),
          const SizedBox(height: 8),
          _Row(
            label: 'Amount',
            value:
                '${payment.amount?.toStringAsFixed(0) ?? '-'} ${currency ?? ''}',
          ),
        ],
      ),
    );
  }
}

class _VendorCard extends StatelessWidget {
  final OrderVendor vendor;

  const _VendorCard({required this.vendor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vendor',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            vendor.name ?? 'Vendor',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          if (vendor.phone != null) ...[
            const SizedBox(height: 4),
            Text(
              vendor.phone!,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
