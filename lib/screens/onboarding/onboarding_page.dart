import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_colors.dart';

class OnboardingPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final int pageIndex;
  final int total;
  final bool isActive;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final String? illustrationAsset;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.pageIndex,
    required this.total,
    required this.isActive,
    required this.isLast,
    required this.onNext,
    required this.onSkip,
    this.illustrationAsset,
  });

  String _formatStep(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedScale(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      scale: isActive ? 1 : 0.96,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: isActive ? 1 : 0.6,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420, minHeight: 420),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.55),
                blurRadius: 35,
                offset: const Offset(0, 28),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isLast ? onNext : onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  child: Text(isLast ? 'Done' : 'Skip'),
                ),
              ),
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 34),
              ),
              const SizedBox(height: 28),
              Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
              if (illustrationAsset != null) ...[
                const SizedBox(height: 18),
                SvgPicture.asset(
                  illustrationAsset!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  semanticsLabel: 'Onboarding illustration',
                ),
              ],
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatStep(pageIndex + 1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '/ ${_formatStep(total)}',
                      style: const TextStyle(color: Colors.white38),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: List.generate(total, (index) {
                  final active = index == pageIndex;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      margin: EdgeInsets.only(
                        right: index == total - 1 ? 0 : 8,
                      ),
                      height: 6,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primary
                            : Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLast ? 'Get Started' : 'Continue',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(isLast ? Icons.check : Icons.arrow_forward_rounded),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
