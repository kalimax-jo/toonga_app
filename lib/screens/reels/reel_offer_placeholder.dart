import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';

import '../../theme/app_colors.dart';
import '../../services/api_config.dart';

class ReelOfferPlaceholderScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? price;
  final String? imageUrl;

  const ReelOfferPlaceholderScreen({
    super.key,
    required this.title,
    required this.subtitle,
    this.price,
    this.imageUrl,
  });

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
          'Experience',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroCard(
              title: title,
              subtitle: subtitle,
              price: price,
              imageUrl: imageUrl,
            ),
            const SizedBox(height: 16),
            const _PillRow(),
            const SizedBox(height: 16),
            _PlaceholderBlock(
              title: 'About this experience',
              lines: const [
                'Get tickets, products, or bundles from this reel.',
                'Checkout details will appear once this goes live.',
              ],
            ),
            const SizedBox(height: 12),
            _PlaceholderBlock(
              title: 'What you will get',
              lines: const [
                'Secure checkout with Toonga.',
                'Access to tickets and product bundles.',
                'Rewards and perks apply when available.',
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Coming soon',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? price;
  final String? imageUrl;

  const _HeroCard({
    required this.title,
    required this.subtitle,
    this.price,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF121212), Color(0xFF1E1E1E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: _HeroImage(imageUrl: imageUrl),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.05),
                          Colors.black.withOpacity(0.35),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Row(
                    children: [
                      _CircleButton(
                        icon: Iconsax.heart,
                        onPressed: () {},
                      ),
                      const SizedBox(width: 10),
                      _CircleButton(
                        icon: Iconsax.share,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.14),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Icon(Iconsax.video, color: Colors.white70, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Reels offer',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (price != null && price!.isNotEmpty) ...[
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Text(
                    price!,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PillRow extends StatelessWidget {
  const _PillRow();

  @override
  Widget build(BuildContext context) {
    const chips = ['Concerts'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips
          .map(
            (c) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(c == 'My feed' ? 0.18 : 0.08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withOpacity(0.14),
                ),
              ),
              child: Text(
                c,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PlaceholderBlock extends StatelessWidget {
  final String title;
  final List<String> lines;

  const _PlaceholderBlock({required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.circle, size: 6, color: Colors.white38),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  final String? imageUrl;
  const _HeroImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      final resolved = _resolveImageUrl(imageUrl!);
      return CachedNetworkImage(
        imageUrl: resolved,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: Colors.white.withOpacity(0.06),
        ),
        errorWidget: (_, __, ___) => Container(
          color: Colors.white.withOpacity(0.06),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CircleButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.6),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

String _resolveImageUrl(String raw) {
  if (raw.startsWith('http')) return raw;
  final baseUri = Uri.parse(ApiConfig.baseUrl);
  final origin =
      '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}';
  if (raw.startsWith('/')) return '$origin$raw';
  return '$origin/$raw';
}
