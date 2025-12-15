import 'package:flutter/material.dart';
import 'onboarding_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController controller = PageController();
  final List<_OnboardingItem> _pages = const [
    _OnboardingItem(
      title: 'Welcome to Toonga',
      subtitle:
          'Your all-in-one lifestyle app for shopping, Beverage, travel, and secure payments,  built for modern living.',
      icon: Icons.waving_hand_rounded,
      illustration: 'assets/images/onbording1.svg',
    ),
    _OnboardingItem(
      title: 'Save while spending',
      subtitle: 'Every purchase earns you rewards',
      icon: Icons.savings_rounded,
      illustration: 'assets/images/onbording2.svg',
    ),
    _OnboardingItem(
      title: 'Earn miles',
      subtitle: 'Miles for every purchase',
      icon: Icons.flight_takeoff_rounded,
      illustration: 'assets/images/onbording3.svg',
    ),
    _OnboardingItem(
      title: 'Redeem gifts',
      subtitle: 'Use miles to get rewards',
      icon: Icons.card_giftcard_rounded,
      illustration: 'assets/images/onbording4.svg',
    ),
  ];
  int current = 0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _pages.length;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/yellow_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.05),
                    Colors.black.withOpacity(0.35),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                Expanded(
                  child: PageView.builder(
                    controller: controller,
                    physics: const BouncingScrollPhysics(),
                    itemCount: total,
                    onPageChanged: (index) {
                      setState(() => current = index);
                    },
                    itemBuilder: (context, index) {
                      final item = _pages[index];
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: OnboardingPage(
                            title: item.title,
                            subtitle: item.subtitle,
                            icon: item.icon,
                            illustrationAsset: item.illustration,
                            pageIndex: index,
                            total: total,
                            isActive: index == current,
                            isLast: index == total - 1,
                            onNext: _handleNext,
                            onSkip: _handleSkip,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleNext() {
    final isLast = current == _pages.length - 1;
    if (!isLast) {
      controller.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _handleSkip() {
    Navigator.pushReplacementNamed(context, '/home');
  }
}

class _OnboardingItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? illustration;

  const _OnboardingItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.illustration,
  });
}
