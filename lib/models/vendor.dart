import 'package:flutter/widgets.dart';

/// Lightweight representation of a vendor for Pay actions.
class Vendor {
  final int id;
  final String name;
  final String category;
  final String location;
  final IconData icon;

  const Vendor({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.icon,
  });
}
