import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class AboutToongaScreen extends StatelessWidget {
  const AboutToongaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'About Toonga',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About Toonga',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Discover our story, mission, and premium partners.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            _buildFeatureCard(
              title: 'Our Mission',
              body:
                  'Toonga delivers curated premium beverages and hospitality experiences by connecting discerning guests with trusted partners.',
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              title: 'What We Value',
              body:
                  'Responsibility, craft, and modern convenience guide every neighborhood pick-up, delivery, or celebration.',
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              title: 'Beyond the Bottle',
              body:
                  'We support local hospitality crews, celebrate storytellers, and build loyalty through thoughtful curation and rewards.',
            ),
            const SizedBox(height: 24),
            const Text(
              'More to come',
              style: TextStyle(
                color: Colors.white60,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign up for early access to new drops via the newsletter or follow us on social channels.',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({required String title, required String body}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(color: Colors.white70, height: 1.45),
          ),
        ],
      ),
    );
  }
}
