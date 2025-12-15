import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../models/home_notification.dart';
import '../theme/app_colors.dart';

class NotificationCard extends StatelessWidget {
  final HomeNotification notification;

  const NotificationCard({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final visual = _NotificationVisual.fromKind(notification.kind);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: visual.background,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: visual.background.last.withOpacity(0.2),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: visual.iconBg,
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Icon(
              visual.icon,
              color: Colors.black,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    NotificationBadge(
                      label: visual.label,
                      color: visual.iconBg,
                      isNew: notification.isNew,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notification.message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time_filled,
                        color: Colors.white54, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      notification.timeLabel,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (notification.isNew) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool isNew;

  const NotificationBadge({
    super.key,
    required this.label,
    required this.color,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isNew) ...[
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationSkeleton extends StatelessWidget {
  const NotificationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: 140,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 10,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const NotificationMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      height: 1.35,
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
}

class _NotificationVisual {
  final IconData icon;
  final List<Color> background;
  final Color iconBg;
  final String label;

  const _NotificationVisual({
    required this.icon,
    required this.background,
    required this.iconBg,
    required this.label,
  });

  factory _NotificationVisual.fromKind(NotificationKind kind) {
    switch (kind) {
      case NotificationKind.promotion:
        return _NotificationVisual(
          icon: Icons.local_offer_rounded,
          background: [
            const Color(0xFF10302A),
            const Color(0xFF0E1C1A),
          ],
          iconBg: const Color(0xFF4FD1C5),
          label: 'Promotion',
        );
      case NotificationKind.orderUpdate:
        return _NotificationVisual(
          icon: Iconsax.shopping_bag,
          background: [
            const Color(0xFF1B1D2A),
            const Color(0xFF0B0D17),
          ],
          iconBg: const Color(0xFF7E70FF),
          label: 'Order',
        );
      case NotificationKind.payment:
        return _NotificationVisual(
          icon: Iconsax.wallet_2,
          background: [
            const Color(0xFF0D1C12),
            const Color(0xFF030905),
          ],
          iconBg: const Color(0xFF3DD1AB),
          label: 'Payment',
        );
      case NotificationKind.newProduct:
      default:
        return _NotificationVisual(
          icon: Icons.inventory_2_rounded,
          background: [
            const Color(0xFF2A1F0A),
            const Color(0xFF120D05),
          ],
          iconBg: AppColors.primary,
          label: 'New product',
        );
    }
  }
}
