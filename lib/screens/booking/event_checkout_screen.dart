import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../theme/app_colors.dart';
import '../products/product_detail_screen.dart';
import '../../models/product.dart';

class EventCheckoutScreen extends StatefulWidget {
  const EventCheckoutScreen({super.key});

  @override
  State<EventCheckoutScreen> createState() => _EventCheckoutScreenState();
}

class _EventCheckoutScreenState extends State<EventCheckoutScreen> {
  int _selectedTier = 0;
  int _ticketCount = 1;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final payload = args is Map ? args : <String, dynamic>{};

    final title = (payload['title'] as String?) ?? 'Premium Experience';
    final description = (payload['description'] as String?) ??
        'Enjoy a curated night with premium selections, live music, and VIP treatment.';
    final location = (payload['location'] as String?) ?? 'Kigali Convention Centre';
    final dateText = (payload['date'] as String?) ?? 'Sat, 08:00 PM';
    final product = payload['product'] as Product?;

    final tiers = <_TicketTier>[
      const _TicketTier(name: 'VIP', priceLabel: 'RWF 50,000', perks: 'Fast lane · Lounge · Drinks'),
      const _TicketTier(name: 'Regular', priceLabel: 'RWF 20,000', perks: 'Standard entry'),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Book & Buy',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeadlineCard(
              title: title,
              location: location,
              dateText: dateText,
              description: description,
            ),
            const SizedBox(height: 16),
            const Text(
              'Select category',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 10),
            Column(
              children: List.generate(tiers.length, (index) {
                final tier = tiers[index];
                final selected = _selectedTier == index;
                return Padding(
                  padding: EdgeInsets.only(top: index == 0 ? 0 : 10),
                  child: _TierTile(
                    tier: tier,
                    selected: selected,
                    onTap: () => setState(() => _selectedTier = index),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quantity',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                _QtyPicker(
                  value: _ticketCount,
                  onChanged: (v) => setState(() => _ticketCount = v),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (product != null) ...[
              _SecondaryButton(
                label: 'View product',
                icon: Iconsax.box,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: product),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
            _PrimaryButton(
              label: 'Continue',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Placeholder action: connect API later.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HeadlineCard extends StatelessWidget {
  final String title;
  final String location;
  final String dateText;
  final String description;

  const _HeadlineCard({
    required this.title,
    required this.location,
    required this.dateText,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF1B1B1B), Color(0xFF0F0F0F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.12),
                ),
                child: const Icon(Iconsax.ticket, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
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
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateText,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Iconsax.location, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  location,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _TierTile extends StatelessWidget {
  final _TicketTier tier;
  final bool selected;
  final VoidCallback onTap;

  const _TierTile({
    required this.tier,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selected ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.03),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.white.withOpacity(0.08),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.primary.withOpacity(0.18) : Colors.white.withOpacity(0.08),
                border: Border.all(
                  color: selected ? AppColors.primary : Colors.white.withOpacity(0.12),
                ),
              ),
              child: Icon(
                tier.icon,
                color: selected ? Colors.black : Colors.white70,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tier.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tier.perks,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  tier.priceLabel,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    selected ? 'Selected' : 'Choose',
                    style: TextStyle(
                      color: selected ? Colors.black : Colors.white70,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _QtyPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyButton(
            icon: Icons.remove,
            onTap: value > 1 ? () => onChanged(value - 1) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$value',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          _QtyButton(
            icon: Icons.add,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QtyButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: onTap != null ? Colors.white.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: onTap != null ? Colors.white : Colors.white30,
          size: 18,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withOpacity(0.12)),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketTier {
  final String name;
  final String priceLabel;
  final String perks;
  final IconData icon;

  const _TicketTier({
    required this.name,
    required this.priceLabel,
    required this.perks,
    this.icon = Iconsax.star,
  });
}
