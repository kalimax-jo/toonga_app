import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../theme/app_colors.dart';

class VendorsScreen extends StatelessWidget {
  const VendorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Vendors',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Iconsax.shop, color: AppColors.primary, size: 48),
            SizedBox(height: 12),
            Text(
              'Vendor directory coming soon',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6),
            Text(
              'Discover and follow your favorite vendors here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
