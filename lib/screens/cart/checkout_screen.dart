import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../models/momo_account.dart';
import '../../models/saved_card.dart';
import '../../services/cart_service.dart';
import '../../services/orders_service.dart';
import '../../services/payment_method_service.dart';
import '../../services/session_manager.dart';
import '../../theme/app_colors.dart';
import '../../widgets/payment_polling_dialog.dart';
import 'payment_method_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CartService _cartService = CartService.instance;
  final OrdersService _ordersService = OrdersService();
  final PaymentMethodService _paymentService = PaymentMethodService.instance;
  final SessionManager _sessionManager = SessionManager.instance;

  PaymentMethod? _method;
  MomoAccount? _momo;
  SavedCard? _card;
  bool _isPaying = false;

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  Future<void> _loadDefaults() async {
    final defaultMomo = await _paymentService.getDefaultMomoAccount();
    final cards = await _paymentService.getCards();
    final defaultCardId = await _paymentService.getDefaultCardId();
    SavedCard? defaultCard;
    if (defaultCardId != null && cards.isNotEmpty) {
      defaultCard = cards.firstWhere(
        (c) => c.id == defaultCardId,
        orElse: () => cards.first,
      );
    } else if (cards.isNotEmpty) {
      defaultCard = cards.first;
    }

    setState(() {
      _momo = defaultMomo;
      _card = defaultCard;
      _method = defaultCard != null
          ? PaymentMethod.card
          : (defaultMomo != null ? PaymentMethod.momo : null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _cartService.totalPrice;
    final count = _cartService.totalItems;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('10m', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryCard(total: total, count: count),
                    const SizedBox(height: 14),
                    _paymentMethodCard(context),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.06)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'RWF ${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 180,
                    child: ElevatedButton(
                      onPressed: _isPaying || _method == null
                          ? null
                          : _handlePay,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _isPaying ? 'Processing...' : 'Pay',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentMethodCard(BuildContext context) {
    final hasMethod = _method != null;
    final isCard = _method == PaymentMethod.card;
    final title = isCard ? 'Card' : 'Mobile Money';
    final subtitle = isCard
        ? (_card != null ? '${_card!.brand} •••• ${_card!.last4}' : 'No card')
        : (_momo != null
              ? '${_momo!.provider} • ${_momo!.msisdn}'
              : 'No number');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payment Method',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton.icon(
                onPressed: _changeMethod,
                icon: const Icon(
                  Iconsax.edit,
                  color: AppColors.primary,
                  size: 18,
                ),
                label: const Text(
                  'Change',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withOpacity(hasMethod ? 0.4 : 0.1),
              ),
            ),
            child: Row(
              children: [
                _LogoAvatar(
                  label: subtitle,
                  asset: isCard
                      ? _brandAsset(_card?.brand ?? '')
                      : _providerAsset(_momo?.provider ?? ''),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            hasMethod
                ? (isCard
                      ? 'We will charge your saved card.'
                      : 'We will request MoMo payment.')
                : 'Please add a payment method to continue.',
            style: TextStyle(
              color: hasMethod ? Colors.white60 : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeMethod() async {
    final selected = await Navigator.push<PaymentMethod>(
      context,
      MaterialPageRoute(builder: (_) => const PaymentMethodScreen()),
    );
    if (!mounted) return;
    await _loadDefaults();
    if (selected != null) {
      setState(() => _method = selected);
    }
  }

  Future<void> _handlePay() async {
    final items = _cartService.items;
    final amount = _cartService.totalPrice;
    if (items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cart is empty.')));
      return;
    }

    setState(() => _isPaying = true);
    try {
      final authed = await _ensureLoggedIn();
      if (!authed) return;

      if (_method == PaymentMethod.card) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card payments coming soon')),
        );
        return;
      }

      final account = _momo ?? await _paymentService.getDefaultMomoAccount();
      if (account == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add a MoMo number to pay.')),
        );
        return;
      }

      final orderId = await _ordersService.createOrder(items);
      final initiation = await _ordersService.payOrder(
        orderId: orderId,
        msisdn: account.msisdn,
        amount: amount,
      );

      final success = await _awaitPaymentConfirmation(initiation.id);
      if (!mounted) return;
      if (success) {
        _cartService.clear();
        Navigator.pop(context, true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Payment successful')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment not completed yet. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  Future<bool> _ensureLoggedIn() async {
    final token = await _sessionManager.getToken();
    if (token != null && token.isNotEmpty) return true;
    await Navigator.pushNamed(context, '/login');
    final refreshed = await _sessionManager.getToken();
    if (refreshed == null || refreshed.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to continue.')),
        );
      }
      return false;
    }
    return true;
  }

  Future<bool> _pollPayment(
    int paymentId, {
    ValueChanged<String>? onStatus,
    required PaymentPollingToken token,
  }) async {
    int attempt = 0;
    const maxAttempts = 30;
    onStatus?.call('Waiting for MTN MoMo...');
    while (!token.isCancelled && attempt < maxAttempts) {
      attempt++;
      String status;
      try {
        status = (await _ordersService.paymentStatus(paymentId)).toLowerCase();
      } catch (_) {
        onStatus?.call('Unable to reach server, retrying...');
        await Future.delayed(const Duration(seconds: 3));
        continue;
      }

      if (status == 'successful' || status == 'success') {
        onStatus?.call('MoMo confirmed success');
        return true;
      }
      if (status == 'failed') {
        onStatus?.call('MTN MoMo reported failure');
        return false;
      }

      onStatus?.call(
        status.isEmpty
            ? 'Checking payment status...'
            : _statusLabel(status, attempt),
      );

      await Future.delayed(const Duration(seconds: 3));
    }

    if (token.isCancelled) {
      onStatus?.call('Payment check cancelled');
    } else {
      onStatus?.call(
        'Still waiting for MTN MoMo. Marking payment as failed after 30 attempts.',
      );
    }
    return false;
  }

  String _statusLabel(String status, int attempt) {
    final normalized = status.toLowerCase();
    switch (normalized) {
      case 'pending':
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

  Future<bool> _awaitPaymentConfirmation(int paymentId) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PaymentPollingDialog(
        poller: (onStatus, token) =>
            _pollPayment(paymentId, onStatus: onStatus, token: token),
      ),
    ).then((value) => value ?? false);
  }
}

class _SummaryCard extends StatelessWidget {
  final double total;
  final int count;

  const _SummaryCard({required this.total, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Iconsax.receipt_1, color: Colors.white70),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cart summary',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$count item${count == 1 ? '' : 's'} • RWF ${total.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoAvatar extends StatelessWidget {
  final String label;
  final String? asset;

  const _LogoAvatar({required this.label, this.asset});

  @override
  Widget build(BuildContext context) {
    if (asset != null && asset!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset(asset!, width: 36, height: 36, fit: BoxFit.contain),
      );
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.1),
      ),
      alignment: Alignment.center,
      child: Text(
        label.isNotEmpty ? label[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String? _brandAsset(String brand) {
  final normalized = brand.toLowerCase();
  if (normalized.contains('visa')) return 'assets/images/visa.png';
  if (normalized.contains('master')) return 'assets/images/mastercard.png';
  if (normalized.contains('amex')) return 'assets/images/amex.png';
  if (normalized.contains('discover')) return 'assets/images/discover.png';
  return null;
}

String? _providerAsset(String provider) {
  final normalized = provider.toLowerCase();
  if (normalized.contains('mtn')) return 'assets/images/mtn.png';
  if (normalized.contains('airtel')) return 'assets/images/airtel.png';
  return null;
}
