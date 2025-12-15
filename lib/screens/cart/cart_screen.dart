import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../services/cart_service.dart';
import '../../services/session_manager.dart';
import '../../theme/app_colors.dart';
import '../../services/orders_service.dart';
import 'payment_method_screen.dart';
import '../../services/payment_method_service.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService.instance;
  final SessionManager _sessionManager = SessionManager.instance;
  final OrdersService _ordersService = OrdersService();
  final PaymentMethodService _paymentMethodService =
      PaymentMethodService.instance;
  final TextEditingController _phoneController = TextEditingController();
  String _selectedProvider = 'MTN';
  bool _isCheckingOut = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: _cartService.itemsNotifier,
                builder: (context, items, _) {
                  if (items.isEmpty) {
                    return const Center(
                      child: Text(
                        'Your cart is empty',
                        style: TextStyle(color: Colors.white60),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final product = item.product;
                      final priceText =
                          product.priceText ??
                          (product.price != null
                              ? 'RWF ${product.price!.toStringAsFixed(0)}'
                              : 'RWF 0');
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 64,
                                height: 64,
                                child: _CartImage(imageUrl: product.imageUrl),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    priceText,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _QuantityStepper(
                              quantity: item.quantity,
                              onChanged: (value) {
                                _cartService.setQuantity(product.id, value);
                              },
                              onRemove: () =>
                                  _cartService.removeProduct(product.id),
                            ),
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: items.length,
                  );
                },
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              'Cart',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          IconButton(
            onPressed: _cartService.clear,
            icon: const Icon(Iconsax.trash, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _cartService.itemsNotifier,
      builder: (context, items, _) {
        final total = _cartService.totalPrice;
        final count = _cartService.totalItems;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.06)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: count == 0 || _isCheckingOut
                      ? null
                      : () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CheckoutScreen(),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _isCheckingOut
                        ? 'Checking session...'
                        : count == 0
                        ? 'Add items to checkout'
                        : 'Checkout ($count item${count > 1 ? 's' : ''})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _promptPhone(BuildContext context) async {
    if (_phoneController.text.isEmpty) {
      final defaultMomo = await _paymentMethodService.getDefaultMomoAccount();
      if (defaultMomo != null) {
        _phoneController.text = defaultMomo.msisdn;
        _selectedProvider = defaultMomo.provider;
      } else {
        _phoneController.text = await _sessionManager.getMomoMsisdn() ?? '';
      }
    } else {
      _phoneController.text = _phoneController.text.trim();
    }
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF0F0F0F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter MTN number',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '07xxxxxxxx',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final value = _phoneController.text.trim();
                    if (value.length < 8) return;
                    _sessionManager.saveMomoMsisdn(value);
                    Navigator.pop(context, value);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _pollPayment(int paymentId) async {
    const attempts = 10;
    for (int i = 0; i < attempts; i++) {
      final status = (await _ordersService.paymentStatus(
        paymentId,
      )).toLowerCase();
      if (status == 'successful' || status == 'success') return true;
      if (status == 'failed') return false;
      await Future.delayed(const Duration(seconds: 2));
    }
    return false;
  }

  Future<PaymentMethod?> _selectPaymentMethod(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaymentMethodScreen()),
    );
  }
}

class _CartImage extends StatelessWidget {
  final String? imageUrl;

  const _CartImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    Widget fallback() =>
        Image.asset('assets/images/background.png', fit: BoxFit.contain);

    final image = imageUrl == null || imageUrl!.isEmpty
        ? fallback()
        : Image.network(
            imageUrl!,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => fallback(),
          );

    return Container(
      color: const Color(0xFF0D0D0D),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(width: 56, height: 56, child: image),
          ),
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;
  final VoidCallback onRemove;

  const _QuantityStepper({
    required this.quantity,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _roundButton(
          icon: Iconsax.minus,
          onTap: quantity > 1 ? () => onChanged(quantity - 1) : onRemove,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            '$quantity',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _roundButton(icon: Iconsax.add, onTap: () => onChanged(quantity + 1)),
      ],
    );
  }

  Widget _roundButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.08),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
