import 'dart:math';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../models/saved_card.dart';
import '../../services/payment_method_service.dart';
import '../../theme/app_colors.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _holderController = TextEditingController();
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  bool _isSaving = false;
  String _brandLabel = 'Card';

  @override
  void initState() {
    super.initState();
    _numberController.addListener(_handleNumberChanged);
  }

  @override
  void dispose() {
    _numberController.removeListener(_handleNumberChanged);
    _holderController.dispose();
    _numberController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          'Add card',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildField(
              label: 'Card holder',
              controller: _holderController,
              hint: 'Name on card',
              keyboard: TextInputType.name,
            ),
            const SizedBox(height: 12),
            _buildField(
              label: 'Card number',
              controller: _numberController,
              hint: '1234 5678 9012 3456',
              keyboard: TextInputType.number,
              trailing: _brandLabel.isEmpty
                  ? null
                  : Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _brandLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            _buildField(
              label: 'Expiry (MM/YY)',
              controller: _expiryController,
              hint: '08/28',
              keyboard: TextInputType.datetime,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveCard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _isSaving ? 'Saving...' : 'Save card',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required TextInputType keyboard,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            suffixIcon: trailing != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: trailing,
                  )
                : null,
            suffixIconConstraints:
                const BoxConstraints(minHeight: 0, minWidth: 0),
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
      ],
    );
  }

  Future<void> _saveCard() async {
    final holder = _holderController.text.trim();
    final number = _numberController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final expiry = _expiryController.text.trim();

    final expiryParts = _parseExpiry(expiry);
    final error = _validateInput(
      holder: holder,
      number: number,
      expiry: expiry,
      parsedExpiry: expiryParts,
    );
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final last4 = number.substring(number.length - 4);
    final brand = _detectBrand(number);
    final expMonth = expiryParts!.$1;
    final expYear = expiryParts.$2;
    final yearFull = expYear < 100 ? 2000 + expYear : expYear;

    setState(() => _isSaving = true);
    final card = SavedCard(
      id: _generateId(),
      brand: brand,
      last4: last4,
      holder: holder,
      expMonth: expMonth,
      expYear: yearFull,
    );
    await PaymentMethodService.instance.saveCard(card);
    await PaymentMethodService.instance.setDefaultCard(card.id);
    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context, card);
  }

  String _detectBrand(String number) {
    if (number.startsWith('4')) return 'Visa';
    if (RegExp(r'^(5[1-5]|2(2[2-9]|[3-6]|7[01]|720))').hasMatch(number)) {
      return 'Mastercard';
    }
    if (RegExp(r'^3[47]').hasMatch(number)) return 'Amex';
    if (RegExp(r'^(6011|65|64[4-9])').hasMatch(number)) return 'Discover';
    if (RegExp(r'^(352[89]|35[3-8])').hasMatch(number)) return 'JCB';
    if (RegExp(r'^9792').hasMatch(number)) return 'Troy';
    return 'Card';
  }

  String _generateId() =>
      'card_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';

  void _handleNumberChanged() {
    final digits = _numberController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final brand = _detectBrand(digits);
    if (brand != _brandLabel) {
      setState(() => _brandLabel = brand);
    }
  }

  String? _validateInput({
    required String holder,
    required String number,
    required String expiry,
    required (int, int)? parsedExpiry,
  }) {
    if (holder.isEmpty) return 'Card holder name is required';
    if (number.length < 12) return 'Card number is too short';
    if (!_luhnValid(number)) return 'Card number is invalid';
    if (parsedExpiry == null) return 'Expiry must be MM/YY';
    final (expMonth, expYear) = parsedExpiry;
    if (expMonth < 1 || expMonth > 12) return 'Invalid expiry month';
    final yearFull = expYear < 100 ? 2000 + expYear : expYear;
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final cardMonth = DateTime(yearFull, expMonth);
    if (cardMonth.isBefore(currentMonth)) return 'Card is expired';
    return null;
  }

  /// Returns (month, yearTwoDigitsOrFull) if valid format, else null.
  (int, int)? _parseExpiry(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9/]'), '');
    if (cleaned.contains('/')) {
      final parts = cleaned.split('/');
      if (parts.length != 2) return null;
      final m = int.tryParse(parts[0]) ?? -1;
      final y = int.tryParse(parts[1]) ?? -1;
      if (m <= 0 || y < 0) return null;
      return (m, y);
    }
    if (cleaned.length == 4) {
      final m = int.tryParse(cleaned.substring(0, 2)) ?? -1;
      final y = int.tryParse(cleaned.substring(2)) ?? -1;
      if (m <= 0 || y < 0) return null;
      return (m, y);
    }
    return null;
  }

  bool _luhnValid(String number) {
    int sum = 0;
    bool alt = false;
    for (int i = number.length - 1; i >= 0; i--) {
      int n = int.parse(number[i]);
      if (alt) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alt = !alt;
    }
    return sum % 10 == 0;
  }
}
