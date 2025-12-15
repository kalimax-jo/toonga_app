import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

import '../../models/vendor.dart';
import '../../theme/app_colors.dart';

class PayVendorScreen extends StatefulWidget {
  const PayVendorScreen({super.key});

  @override
  State<PayVendorScreen> createState() => _PayVendorScreenState();
}

class _PayVendorScreenState extends State<PayVendorScreen> {
  final _searchController = TextEditingController();
  final _amountController = TextEditingController();
  final List<Vendor> _vendors = const [
    Vendor(
      id: 1,
      name: 'Urban Taproom',
      category: 'Nightlife',
      location: 'Kigali',
      icon: Iconsax.music_circle5,
    ),
    Vendor(
      id: 2,
      name: 'Rwanda Bites',
      category: 'Dining',
      location: 'Remera',
      icon: Iconsax.cup,
    ),
    Vendor(
      id: 3,
      name: 'Horizon Services',
      category: 'Lifestyle Services',
      location: 'Kimironko',
      icon: Iconsax.building,
    ),
    Vendor(
      id: 4,
      name: 'Solace Spa',
      category: 'Wellness',
      location: 'Nyarutarama',
      icon: Iconsax.health,
    ),
    Vendor(
      id: 5,
      name: 'Soko Moto',
      category: 'Transport',
      location: 'KN 10',
      icon: Iconsax.car,
    ),
    Vendor(
      id: 6,
      name: 'Glow Market',
      category: 'Lifestyle',
      location: 'City Centre',
      icon: Iconsax.shop,
    ),
  ];

  late List<Vendor> _filteredVendors;
  Vendor? _selectedVendor;
  bool _isPaying = false;

  @override
  void initState() {
    super.initState();
    _filteredVendors = _vendors;
    _searchController.addListener(_filterVendors);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_filterVendors)
      ..dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _filterVendors() {
    final query = _searchController.text.trim().toLowerCase();
    if (!mounted) return;
    setState(() {
      if (query.isEmpty) {
        _filteredVendors = _vendors;
      } else {
        _filteredVendors = _vendors
            .where(
              (vendor) =>
                  vendor.name.toLowerCase().contains(query) ||
                  vendor.category.toLowerCase().contains(query) ||
                  vendor.location.toLowerCase().contains(query),
            )
            .toList();
      }
    });
  }

  Future<void> _handlePay() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(
      amountText.replaceAll(',', '').replaceAll(' ', ''),
    );

    if (_selectedVendor == null) {
      _showMessage('Select a vendor to continue.');
      return;
    }

    if (amount == null || amount <= 0) {
      _showMessage('Enter a valid amount to pay.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isPaying = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _isPaying = false);

    _showMessage(
      'Payment request for RWF ${amount.toStringAsFixed(0)} sent to ${_selectedVendor!.name}.',
      isError: false,
    );
    _amountController.clear();
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError
            ? AppColors.primary
            : AppColors.primary.withOpacity(0.9),
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Pay Vendors'), centerTitle: false),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Send money to trusted partners instantly.',
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Search, select and confirm the amount to pay vendors within the Toonga network.',
                style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              _buildSearchField(theme),
              const SizedBox(height: 6),
              Text(
                'Nearby vendors (${_filteredVendors.length})',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _filteredVendors.isEmpty
                    ? Center(
                        child: Text(
                          'No vendors match your search. Try another keyword.',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _filteredVendors.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final vendor = _filteredVendors[index];
                          final isSelected = _selectedVendor?.id == vendor.id;
                          return _buildVendorTile(vendor, isSelected);
                        },
                      ),
              ),
              const SizedBox(height: 10),
              _buildAmountField(theme),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isPaying ? null : _handlePay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isPaying
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Iconsax.send_1, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _selectedVendor == null
                                  ? 'Select a vendor'
                                  : 'Pay ${_selectedVendor!.name}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        prefixIcon: const Icon(Iconsax.search_normal),
        hintText: 'Search vendors, category or location',
        filled: true,
        fillColor: theme.brightness == Brightness.dark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.04),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildVendorTile(Vendor vendor, bool isSelected) {
    final backgroundColor = isSelected
        ? AppColors.primary.withOpacity(0.15)
        : Colors.white.withOpacity(0.02);
    final circleColor = isSelected
        ? AppColors.primary.withOpacity(0.24)
        : Colors.white.withOpacity(0.08);
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _selectedVendor = vendor),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: circleColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  vendor.icon,
                  color: isSelected ? AppColors.primary : Colors.white70,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${vendor.category} - ${vendor.location}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? AppColors.primary : Colors.white54,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField(ThemeData theme) {
    return TextField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]+'))],
      decoration: InputDecoration(
        prefixIcon: const Icon(Iconsax.money),
        hintText: 'Enter amount (RWF)',
        filled: true,
        fillColor: theme.brightness == Brightness.dark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
