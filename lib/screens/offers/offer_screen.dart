import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../models/offer.dart';
import '../../services/api_client.dart';
import '../../services/api_config.dart';
import '../../services/offer_service.dart';
import '../../theme/app_colors.dart';

class OfferScreen extends StatefulWidget {
  const OfferScreen({super.key});

  @override
  State<OfferScreen> createState() => _OfferScreenState();
}

class _OfferScreenState extends State<OfferScreen> {
  final OfferService _offerService = OfferService();
  List<Offer> _offers = const <Offer>[];
  bool _isLoading = true;
  String? _error;
  final Set<int> _redeeming = <int>{};
  final Set<int> _redeemed = <int>{};
  final Map<int, String> _rewardCodes = <int, String>{};

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final offers = await _offerService.fetchOffers(perPage: 12);
      if (!mounted) return;
      final rewardMap = <int, String>{};
      for (final item in offers) {
        final code = item.rewardCode;
        if (code != null && code.isNotEmpty) {
          rewardMap[item.id] = code;
        }
      }

      setState(() {
        _offers = offers;
        _rewardCodes
          ..removeWhere(
            (key, _) => !offers.any((offer) => offer.id == key),
          )
          ..addAll(rewardMap);
        _redeemed
          ..removeWhere((id) => !offers.any((offer) => offer.id == id))
          ..addAll(
            offers.where((offer) => offer.isRedeemed).map((offer) => offer.id),
          );
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _offers = const <Offer>[];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load offers. Please try again.';
        _offers = const <Offer>[];
      });
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Offers',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadOffers,
        color: AppColors.primary,
        backgroundColor: Colors.black,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Iconsax.gift, size: 14, color: Colors.white70),
                        SizedBox(width: 6),
                        Text(
                          'Curated offers',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                    onPressed: _loadOffers,
                    child: const Text(
                      'Refresh',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Column(
        children: const [
          _OfferSkeleton(),
          SizedBox(height: 12),
          _OfferSkeleton(),
        ],
      );
    }

    if (_error != null) {
      return _OfferMessage(
        icon: Icons.error_outline,
        title: 'Couldn\'t load offers',
        subtitle: 'Check your connection and try again.',
        onTap: _loadOffers,
      );
    }

    if (_offers.isEmpty) {
      return const _OfferMessage(
        icon: Icons.check_circle_outline,
        title: 'No offers yet',
        subtitle: 'We will display curated offers here once available.',
      );
    }

    final now = DateTime.now();
    return Column(
      children: List.generate(_offers.length, (index) {
        final offer = _offers[index];
        final isExpired =
            offer.isExpired || (offer.endsAt != null && offer.endsAt!.isBefore(now));
        final isExpiringSoon = offer.isExpiringSoon;
        final isRedeemed = _redeemed.contains(offer.id) || offer.isRedeemed;
        final tone = _toneFor(
          offer,
          index,
          isRedeemed: isRedeemed,
          isExpired: isExpired,
          isExpiringSoon: isExpiringSoon,
        );
        final palette = _OfferPalette.fromTone(tone);
        final badge = _badgeFor(
          offer,
          isRedeemed: isRedeemed,
          isExpired: isExpired,
          isExpiringSoon: isExpiringSoon,
        );
        final timeLabel = _timeLabelFor(
          offer,
          now,
          isRedeemed: isRedeemed,
          isExpired: isExpired,
          isExpiringSoon: isExpiringSoon,
        );
        final rewardCode = _rewardCodes[offer.id] ?? offer.rewardCode;
        return Padding(
          padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
          child: _OfferCard(
            offer: offer,
            palette: palette,
            badgeLabel: badge,
            timeLabel: timeLabel,
            isRedeeming: _redeeming.contains(offer.id),
            isRedeemed: isRedeemed,
            isExpired: isExpired,
            isExpiringSoon: isExpiringSoon,
            rewardCode: rewardCode,
            onRedeem: () => _handleRedeem(offer),
          ),
        );
      }),
    );
  }

  Future<void> _handleRedeem(Offer offer) async {
    if (_redeeming.contains(offer.id)) return;
    setState(() => _redeeming.add(offer.id));

    try {
      final result = await _offerService.redeemOffer(offer.id);
      if (!mounted) return;

      if (result.success) {
        setState(() {
          _redeemed.add(offer.id);
          if (result.rewardCode != null && result.rewardCode!.isNotEmpty) {
            _rewardCodes[offer.id] = result.rewardCode!;
          }
        });
        _showMessage(
          result.message ??
              (result.alreadyRedeemed ? 'Offer already redeemed' : 'Offer redeemed'),
        );
      } else {
        _showMessage(
          result.message ?? 'Unable to redeem this offer right now.',
          isError: true,
        );
      }
    } on ApiException catch (error) {
      _showMessage(error.message, isError: true);
    } catch (_) {
      _showMessage('Something went wrong. Please try again.', isError: true);
    } finally {
      if (mounted) {
        setState(() => _redeeming.remove(offer.id));
      }
    }
  }

  String _badgeFor(
    Offer offer, {
    required bool isRedeemed,
    required bool isExpired,
    required bool isExpiringSoon,
  }) {
    if (isExpired) return 'Expired';
    if (isExpiringSoon) return 'Expiring soon';
    if (isRedeemed) return 'Redeemed';
    if (offer.startsAt != null && offer.startsAt!.isAfter(DateTime.now())) {
      return 'Upcoming';
    }
    return offer.badge ??
        offer.partnerName ??
        offer.status ??
        (offer.milesRequired != null ? 'Miles' : 'Offer');
  }

  String _timeLabelFor(
    Offer offer,
    DateTime now, {
    required bool isRedeemed,
    required bool isExpired,
    required bool isExpiringSoon,
  }) {
    final startsAt = offer.startsAt;
    final endsAt = offer.endsAt;

    if (isRedeemed) return 'Redeemed';
    if (isExpired) return 'Expired';
    if (isExpiringSoon) return 'Expiring soon';

    if (startsAt != null && startsAt.isAfter(now)) {
      return _formatDelta(startsAt.difference(now), prefix: 'Starts in');
    }

    if (endsAt != null) {
      final diff = endsAt.difference(now);
      if (diff.isNegative) return 'Expired';
      return _formatDelta(diff, prefix: 'Ends in');
    }

    return 'Live now';
  }

  String _formatDelta(Duration diff, {required String prefix}) {
    if (diff.inDays >= 1) return '$prefix ${diff.inDays}d';
    if (diff.inHours >= 1) return '$prefix ${diff.inHours}h';
    if (diff.inMinutes >= 1) return '$prefix ${diff.inMinutes}m';
    return '$prefix few min';
  }

  _OfferTone _toneFor(
    Offer offer,
    int index, {
    required bool isRedeemed,
    required bool isExpired,
    required bool isExpiringSoon,
  }) {
    if (isRedeemed) return _OfferTone.teal;
    if (isExpiringSoon || isExpired) return _OfferTone.gold;

    final marker = (offer.theme ?? offer.badge ?? offer.status ?? '').toLowerCase();
    if (marker.contains('vip') ||
        marker.contains('limited') ||
        marker.contains('gold') ||
        marker.contains('premium')) {
      return _OfferTone.gold;
    }
    if (marker.contains('new') ||
        marker.contains('fresh') ||
        marker.contains('launch') ||
        marker.contains('teal')) {
      return _OfferTone.teal;
    }

    return index.isEven ? _OfferTone.gold : _OfferTone.teal;
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.black87,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final Offer offer;
  final _OfferPalette palette;
  final String badgeLabel;
  final String timeLabel;
  final bool isRedeeming;
  final bool isRedeemed;
  final bool isExpired;
  final bool isExpiringSoon;
  final String? rewardCode;
  final VoidCallback onRedeem;

  const _OfferCard({
    required this.offer,
    required this.palette,
    required this.badgeLabel,
    required this.timeLabel,
    required this.isRedeeming,
    required this.isRedeemed,
    required this.isExpired,
    required this.isExpiringSoon,
    required this.onRedeem,
    this.rewardCode,
  });

  @override
  Widget build(BuildContext context) {
    final disableRedeem = isRedeeming || isRedeemed || isExpired;
    final quantityAvailable = offer.quantityAvailable;
    final quantityRedeemed = offer.quantityRedeemed;
    final partnerName = offer.partnerName;
    final showCounts = quantityAvailable != null || quantityRedeemed != null;
    final int? miles = offer.milesRequired ?? offer.value?.round();
    final bool showMiles = miles != null;
    final heroImage = offer.imageUrl != null && offer.imageUrl!.isNotEmpty
        ? _resolveImageUrl(offer.imageUrl!)
        : null;
    final partnerLogo = offer.partnerLogo;
    final String? partnerLogoUrl = (partnerLogo != null && partnerLogo.isNotEmpty)
        ? _resolveImageUrl(partnerLogo)
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.background,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: palette.background.last.withOpacity(0.28),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (heroImage != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  heroImage,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.white.withOpacity(0.06),
                    alignment: Alignment.center,
                    child: Icon(Iconsax.gallery_slash, color: Colors.white54),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.iconBg,
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                  image: partnerLogoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(partnerLogoUrl),
                          fit: BoxFit.cover,
                          onError: (_, __) {},
                        )
                      : null,
                ),
                child: partnerLogoUrl != null
                    ? null
                    : Icon(palette.icon, color: Colors.black, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeLabel,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _OfferBadge(
                label: badgeLabel,
                color: palette.iconBg,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            offer.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          if (partnerName != null && partnerName.isNotEmpty) ...[
            const SizedBox(height: 10),
            _OfferMetaChip(
              icon: Iconsax.shop,
              label: partnerName,
              filled: true,
            ),
          ],
          if (rewardCode != null && rewardCode!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _OfferMetaChip(
              icon: Iconsax.card_pos,
              label: 'Code: ${rewardCode!}',
              filled: true,
            ),
          ],
          if (offer.value != null) ...[
            // Value intentionally hidden when miles are the primary requirement.
          ] else if (showCounts) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (quantityAvailable != null)
                  _OfferMetaChip(
                    icon: Iconsax.box,
                    label: 'Available: $quantityAvailable',
                  ),
                if (quantityRedeemed != null)
                  _OfferMetaChip(
                    icon: Iconsax.tick_circle,
                    label: 'Redeemed: $quantityRedeemed',
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _OfferMetaChip(
                      icon: Iconsax.clock,
                      label: timeLabel,
                    ),
                    if (showMiles)
                      _OfferMetaChip(
                        icon: Iconsax.coin,
                        label: '$miles miles required',
                        filled: true,
                      ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: disableRedeem ? null : onRedeem,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      disableRedeem ? Colors.white.withOpacity(0.2) : Colors.white,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: disableRedeem ? 0 : 2,
                ),
                child: isRedeeming
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : Text(
                        isExpired
                            ? 'Expired'
                            : isRedeemed
                                ? 'Redeemed'
                                : 'Redeem',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: -0.1,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OfferBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _OfferBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _OfferMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;

  const _OfferMetaChip({
    required this.icon,
    required this.label,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? Colors.white.withOpacity(0.14) : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.92),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferSkeleton extends StatelessWidget {
  const _OfferSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              Column(
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
                  const SizedBox(height: 6),
                  Container(
                    height: 10,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                height: 10,
                width: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _OfferMessage({
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

class _OfferPalette {
  final List<Color> background;
  final Color iconBg;
  final IconData icon;

  const _OfferPalette({
    required this.background,
    required this.iconBg,
    required this.icon,
  });

  factory _OfferPalette.fromTone(_OfferTone tone) {
    switch (tone) {
      case _OfferTone.teal:
        return const _OfferPalette(
          background: [Color(0xFF10302A), Color(0xFF0E1C1A)],
          iconBg: Color(0xFF4FD1C5),
          icon: Iconsax.discount_shape,
        );
      case _OfferTone.gold:
      default:
        return const _OfferPalette(
          background: [Color(0xFF2A1F0A), Color(0xFF120D05)],
          iconBg: AppColors.primary,
          icon: Iconsax.gift,
        );
    }
  }
}

enum _OfferTone { gold, teal }

String _resolveImageUrl(String raw) {
  if (raw.startsWith('http')) return raw;
  final baseUri = Uri.parse(ApiConfig.baseUrl);
  final origin =
      '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}';
  if (raw.startsWith('/')) return '$origin$raw';
  return '$origin/$raw';
}
