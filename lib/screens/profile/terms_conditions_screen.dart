import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../theme/app_colors.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  static const List<_Section> _sections = [
    _Section(
      title: 'Agreement to terms',
      description:
          'By accessing Toonga you agree to these terms. We may update them from time to time and will notify you when material changes occur.',
    ),
    _Section(
      title: 'Eligibility & account',
      description:
          'You must be 18+ and provide accurate account information. Keep your password safe and immediately inform us of unauthorized access.',
    ),
    _Section(
      title: 'Orders & payments',
      description:
          'Prices, promotions, and availability can change without notice. Payments are processed securely through our partners and may require identity verification.',
    ),
    _Section(
      title: 'Content & conduct',
      description:
          'You may not misuse the app, post abusive content, or interfere with service operation. We reserve the right to remove harmful content and suspend accounts.',
    ),
    _Section(
      title: 'Liability & updates',
      description:
          'Toonga is provided as-is. We are not liable for indirect damages. We may update or suspend features temporarily for maintenance.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Please read these terms before placing orders on Toonga. They are designed to keep every experience fair, transparent, and compliant.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 24),
          ..._sections.map(
            (section) => _SectionCard(section: section),
          ),
          const SizedBox(height: 24),
          const Text(
            'Questions about these terms can be directed to legal@toonga.com. Continued use after changes constitutes acceptance.',
            style: TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final _Section section;

  const _SectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              section.description,
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section {
  final String title;
  final String description;

  const _Section({required this.title, required this.description});
}
