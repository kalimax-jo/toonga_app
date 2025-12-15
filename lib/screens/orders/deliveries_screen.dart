import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../theme/app_colors.dart';

class DeliveriesScreen extends StatelessWidget {
  const DeliveriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Delivering',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Iconsax.truck_fast, color: AppColors.primary, size: 48),
            SizedBox(height: 12),
            Text(
              'No active deliveries',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6),
            Text(
              'We’ll show live deliveries and tracking here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
