import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../theme/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String _introduction =
      'Your privacy matters. This policy explains what information we collect, how we use it, and the controls you have.';

  static const List<_Section> _sections = [
    _Section(
      title: 'Scope & consent',
      description:
          'By using Toonga you agree to this policy and consent to the practices described here, including updates published in the app.',
    ),
    _Section(
      title: 'Information we collect',
      description:
          'We gather data you provide directly (profile details, payment info) and information automatically (device identifiers, usage patterns, IP address).',
    ),
    _Section(
      title: 'How we use information',
      description:
          'Data keeps the service running: processing orders, personalizing recommendations, preventing fraud, honoring age checks, and improving delivery.',
    ),
    _Section(
      title: 'Sharing & retention',
      description:
          'We share data with payment processors, logistics partners, and analytics tools only as needed. We retain the minimum information required by law or to keep your account safe.',
    ),
    _Section(
      title: 'Your choices',
      description:
          'You can update your profile, disable notifications, or request account and deletion via support@toonga.com. Manage cookies through your browser settings.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            _introduction,
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 24),
          ..._sections.map(
            (section) => _PolicySectionCard(section: section),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: const Text(
              'Need more help? Contact support@toonga.com for data requests or clarification.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicySectionCard extends StatelessWidget {
  final _Section section;

  const _PolicySectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
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
