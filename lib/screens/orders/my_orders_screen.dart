import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../models/order_summary.dart';
import '../../services/orders_service.dart';
import '../../services/payment_method_service.dart';
import '../../services/session_manager.dart';
import '../../theme/app_colors.dart';
import '../../widgets/payment_polling_dialog.dart';
import 'order_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

enum OrderFilter { completed, cancelled, requested }

enum OrderTab { all, pending, completed, cancelled }

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final OrdersService _service = OrdersService();
  OrderTab _tab = OrderTab.all;
  OrderFilter _filter = OrderFilter.completed;
  bool _loading = true;
  String? _error;
  List<OrderSummary> _orders = const [];
  final Set<int> _downloadingInvoices = <int>{};
  final Set<int> _processingPayments = {};
  final SessionManager _sessionManager = SessionManager.instance;
  final PaymentMethodService _paymentMethodService =
      PaymentMethodService.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _downloadInvoice(OrderSummary order) async {
    final id = order.id;
    if (id == null) {
      _showSnack('Order id missing');
      return;
    }
    setState(() => _downloadingInvoices.add(id));
    try {
      final url = await _service.fetchInvoiceUrl(id);
      final ok = await launchUrlString(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!ok) {
        _showSnack('Could not open invoice link');
      }
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() => _downloadingInvoices.remove(id));
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await _service.fetchOrders();
      if (!mounted) return;
      setState(() => _orders = orders);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _handleOrderPayment(OrderSummary order) async {
    final orderId = order.id;
    if (orderId == null) {
      _showSnack('Order ID missing');
      return;
    }

    final authed = await _ensureLoggedIn();
    if (!authed) return;

    final account = await _paymentMethodService.getDefaultMomoAccount();
    if (account == null) {
      _showSnack('Add a MoMo number to pay.');
      return;
    }

    final amount = order.totalAmount ?? order.amount ?? 0.0;
    setState(() => _processingPayments.add(orderId));
    try {
      final initiation = await _service.payOrder(
        orderId: orderId,
        msisdn: account.msisdn,
        amount: amount,
      );
      final success = await _showPaymentPolling(initiation.id);
      if (success) {
        _showSnack('Payment successful');
        await _load();
      } else {
        _showSnack('Payment pending. Check your MTN MoMo prompt.');
      }
    } catch (error) {
      _showSnack(error.toString());
    } finally {
      if (mounted) {
        setState(() => _processingPayments.remove(orderId));
      }
    }
  }

  Future<bool> _showPaymentPolling(int paymentId) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PaymentPollingDialog(
        poller: (onStatus, token) =>
            _pollPaymentStatus(paymentId, onStatus, token),
      ),
    ).then((value) => value ?? false);
  }

  Future<bool> _pollPaymentStatus(
    int paymentId,
    ValueChanged<String> onStatus,
    PaymentPollingToken token,
  ) async {
    const maxAttempts = 30;
    int attempt = 0;
    onStatus('Waiting for MTN MoMo...');

    while (!token.isCancelled && attempt < maxAttempts) {
      attempt++;
      String status;
      try {
        status = (await _service.paymentStatus(paymentId)).toLowerCase();
      } catch (_) {
        onStatus('Unable to reach server, retrying...');
        await Future.delayed(const Duration(seconds: 3));
        continue;
      }

      if (status == 'successful' || status == 'success') {
        onStatus('MoMo confirmed success');
        return true;
      }
      if (status == 'failed') {
        onStatus('MTN MoMo reported failure');
        return false;
      }

      onStatus(
        status.isEmpty
            ? 'Checking payment status...'
            : _statusLabel(status, attempt),
      );
      await Future.delayed(const Duration(seconds: 3));
    }

    if (token.isCancelled) {
      onStatus('Payment check cancelled');
    } else {
      onStatus(
        'Still waiting for MTN MoMo. Marking payment as failed after $maxAttempts attempts.',
      );
    }
    return false;
  }

  String _statusLabel(String status, int attempt) {
    final normalized = status.toLowerCase();
    switch (normalized) {
      case 'pending':
      case 'processing':
        return 'Waiting for MTN MoMo (attempt $attempt)...';
      case 'successful':
      case 'success':
        return 'MoMo confirmed success';
      case 'failed':
        return 'MTN MoMo reported failure';
      case 'unknown':
        return 'Still checking payment status...';
      default:
        return 'Status: ${normalized.toUpperCase()} (attempt $attempt)';
    }
  }

  bool _paymentStatusIsPending(String? status) {
    if (status == null || status.isEmpty) return false;
    final lower = status.toLowerCase();
    return lower.contains('pending') ||
        lower.contains('process') ||
        lower.contains('request');
  }

  Future<bool> _ensureLoggedIn() async {
    final token = await _sessionManager.getToken();
    if (token != null && token.isNotEmpty) return true;
    await Navigator.pushNamed(context, '/login');
    final refreshed = await _sessionManager.getToken();
    if (refreshed == null || refreshed.isEmpty) {
      if (mounted) {
        _showSnack('Please sign in to continue.');
      }
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _orders.where((order) {
      final status = order.status.toLowerCase();
      switch (_tab) {
        case OrderTab.all:
          return true;
        case OrderTab.pending:
          return status.contains('pending') ||
              status.contains('request') ||
              status.contains('process') ||
              status.contains('new');
        case OrderTab.completed:
          return status.contains('complete') || status.contains('delivered');
        case OrderTab.cancelled:
          return status.contains('cancel') || status.contains('void');
      }
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'My Orders',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: _loading
            ? const _OrdersShimmer()
            : _error != null
            ? _OrdersError(message: _error!, onRetry: _load)
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _OrderTabs(
                      selected: _tab,
                      onChanged: (tab) => setState(() => _tab = tab),
                    ),
                    const SizedBox(height: 16),
                    if (filtered.isEmpty)
                      _EmptyOrders(
                        onDiscover: () => Navigator.popUntil(
                          context,
                          (route) => route.isFirst,
                        ),
                      )
                    else
                      ...filtered.map((order) {
                        final isPending = _paymentStatusIsPending(
                          order.paymentStatus,
                        );
                        final isPaying =
                            order.id != null &&
                            _processingPayments.contains(order.id);
                        return _OrderCard(
                          order: order,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrderDetailScreen(order: order),
                              ),
                            );
                          },
                          onDownloadInvoice: () => _downloadInvoice(order),
                          downloadingInvoice:
                              order.id != null &&
                              _downloadingInvoices.contains(order.id),
                          showPayButton: isPending,
                          isPaying: isPaying,
                          onPay: isPending
                              ? () => _handleOrderPayment(order)
                              : null,
                        );
                      }).toList(),
                  ],
                ),
              ),
      ),
    );
  }
}

class _OrderTabs extends StatelessWidget {
  final OrderTab selected;
  final ValueChanged<OrderTab> onChanged;

  const _OrderTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget buildChip(String label, OrderTab tab) {
      final isSelected = selected == tab;
      return GestureDetector(
        onTap: () => onChanged(tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : Colors.white.withOpacity(0.15),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          buildChip('All', OrderTab.all),
          buildChip('Pending', OrderTab.pending),
          buildChip('Completed', OrderTab.completed),
          buildChip('Cancelled', OrderTab.cancelled),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderSummary order;
  final VoidCallback onTap;
  final VoidCallback onDownloadInvoice;
  final bool downloadingInvoice;
  final bool showPayButton;
  final bool isPaying;
  final VoidCallback? onPay;

  const _OrderCard({
    required this.order,
    required this.onTap,
    required this.onDownloadInvoice,
    this.downloadingInvoice = false,
    this.showPayButton = false,
    this.isPaying = false,
    this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final created = order.createdAt;
    final scheduleText = created != null
        ? '${created.day}/${created.month}/${created.year}'
        : 'Pending';
    final status = order.status.isNotEmpty ? order.status : 'Status';
    final paymentStatus =
        order.paymentStatus != null && order.paymentStatus!.isNotEmpty
        ? order.paymentStatus!
        : '—';
    final count = order.itemsCount;
    final total = order.totalAmount ?? order.amount;
    final statusColor = _statusColor(status);
    final paymentColor = _statusColor(paymentStatus);
    String _formatMoney(double value, String? currency) {
      final intPart = value.floor();
      final withCommas = intPart.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
      return '$withCommas ${currency ?? 'RWF'}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF101010), Color(0xFF151515)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    order.orderNumber ?? '#${order.id ?? ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _InfoPair(
                    label: 'Total amount',
                    value: total != null
                        ? _formatMoney(total, order.currency)
                        : '-',
                  ),
                ),
                Expanded(
                  child: _InfoPair(label: 'Created', value: scheduleText),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _InfoPair(
                    label: 'Vendor',
                    value: order.vendorName.isNotEmpty ? order.vendorName : '-',
                  ),
                ),
                Expanded(
                  child: _InfoPair(
                    label: 'Items',
                    value: count != null ? '$count' : '-',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoPair(
              label: 'Payment',
              value: paymentStatus,
              valueColor: paymentColor,
              bold: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(label: 'Order Details', onTap: onTap),
                ),
                if (showPayButton) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      label: 'Pay now',
                      onTap: onPay,
                      loading: isPaying,
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Re-Order',
                    onTap: () => _showToast(context, 'Re-order coming soon'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    label: 'Download Invoice',
                    onTap: downloadingInvoice ? null : onDownloadInvoice,
                    loading: downloadingInvoice,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('deliver') || lower.contains('complete'))
      return Colors.greenAccent;
    if (lower.contains('cancel')) return Colors.redAccent;
    if (lower.contains('process') || lower.contains('pending'))
      return Colors.orangeAccent;
    return Colors.white70;
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _InfoPair extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _InfoPair({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _OrdersError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _OrdersError({required this.message, required this.onRetry});

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
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const _ActionButton({
    required this.label,
    required this.onTap,
    this.loading = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: loading ? null : onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: foregroundColor ?? Colors.white,
        side: BorderSide(color: Colors.white.withOpacity(0.14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: backgroundColor ?? Colors.white.withOpacity(0.06),
      ),
      child: loading
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  final VoidCallback? onDiscover;

  const _EmptyOrders({this.onDiscover});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.box, color: AppColors.primary, size: 30),
          ),
          const SizedBox(height: 18),
          const Text(
            'No orders found in this category.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Start exploring premium experiences and add them to your itinerary.',
            style: TextStyle(color: Colors.white60, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onDiscover,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('Discover experiences'),
          ),
        ],
      ),
    );
  }
}

class _OrdersShimmer extends StatefulWidget {
  const _OrdersShimmer();

  @override
  State<_OrdersShimmer> createState() => _OrdersShimmerState();
}

class _OrdersShimmerState extends State<_OrdersShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final shimmer = (_controller.value * 2) - 1;
        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (_, __) => _shimmerCard(shimmer),
        );
      },
    );
  }

  Widget _shimmerCard(double shimmer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmerBlock(shimmer, height: 18, width: 200, radius: 10),
          const SizedBox(height: 12),
          Row(
            children: [
              _shimmerBlock(shimmer, height: 14, width: 120, radius: 8),
              const SizedBox(width: 12),
              _shimmerBlock(shimmer, height: 14, width: 80, radius: 8),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _shimmerBlock(shimmer, height: 14, width: 100, radius: 8),
              const SizedBox(width: 12),
              _shimmerBlock(shimmer, height: 14, width: 60, radius: 8),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shimmerBlock(
    double shimmer, {
    required double height,
    double? width,
    double radius = 12,
  }) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment(-1 + shimmer, -0.3),
          end: Alignment(1 + shimmer, 0.3),
          stops: const [0.2, 0.5, 0.8],
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.28),
            Colors.white.withOpacity(0.08),
          ],
        ).createShader(bounds);
      },
      blendMode: BlendMode.srcATop,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
