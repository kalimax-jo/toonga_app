import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../models/momo_account.dart';
import '../../services/payment_method_service.dart';
import '../../theme/app_colors.dart';

class MomoNumberScreen extends StatefulWidget {
  const MomoNumberScreen({super.key});

  @override
  State<MomoNumberScreen> createState() => _MomoNumberScreenState();
}

class _MomoNumberScreenState extends State<MomoNumberScreen> {
  final PaymentMethodService _paymentService = PaymentMethodService.instance;
  final TextEditingController _controller = TextEditingController();
  String _provider = 'MTN';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final saved = await _paymentService.getDefaultMomoAccount();
    if (!mounted) return;
    if (saved != null) {
      _controller.text = saved.msisdn;
      _provider = saved.provider;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
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
          'MTN MoMo number',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This number will be used for mobile money checkout.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _provider,
              dropdownColor: const Color(0xFF1A1A1A),
              decoration: InputDecoration(
                labelText: 'Provider',
                labelStyle: const TextStyle(color: Colors.white70),
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
              ),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              items: const [
                DropdownMenuItem(value: 'MTN', child: Text('MTN')),
                DropdownMenuItem(value: 'Airtel', child: Text('Airtel')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _provider = value);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
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
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _isSaving ? 'Saving...' : 'Save number',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final value = _controller.text.trim();
    if (value.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid mobile money number')),
      );
      return;
    }
    setState(() => _isSaving = true);
    final account = MomoAccount(
      id: 'momo_${DateTime.now().millisecondsSinceEpoch}',
      provider: _provider,
      msisdn: value,
    );
    await _paymentService.saveMomoAccount(account);
    await _paymentService.setDefaultMomoAccount(account.id);
    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context, account);
  }
}
