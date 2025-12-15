import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';

class _WishlistEntry {
  final Product product;
  final DateTime addedAt;

  const _WishlistEntry({
    required this.product,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'addedAt': addedAt.toIso8601String(),
      'product': product.toJson(),
    };
  }

  static _WishlistEntry? fromJson(Map<String, dynamic> json) {
    final addedAtString = json['addedAt']?.toString();
    if (addedAtString == null) return null;
    final addedAt = DateTime.tryParse(addedAtString);
    if (addedAt == null) return null;
    final productData = json['product'];
    if (productData is! Map<String, dynamic>) return null;
    return _WishlistEntry(product: Product.fromJson(productData), addedAt: addedAt);
  }
}

class WishlistService extends ChangeNotifier {
  WishlistService._internal() {
    _load();
  }

  static final WishlistService instance = WishlistService._internal();

  static const _prefsKey = 'wishlist_items';

  final List<_WishlistEntry> _entries = [];

  bool _loaded = false;

  List<Product> get items => List.unmodifiable(_entries.map((entry) => entry.product));

  int get count => _entries.length;

  bool contains(Product product) {
    return _entries.any((entry) => entry.product.id == product.id);
  }

  void toggle(Product product) {
    final existingIndex = _entries.indexWhere((entry) => entry.product.id == product.id);
    if (existingIndex >= 0) {
      _entries.removeAt(existingIndex);
    } else {
      _entries.add(_WishlistEntry(product: product, addedAt: DateTime.now().toUtc()));
    }
    notifyListeners();
    _persist();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) {
      _loaded = true;
      return;
    }
    final List<_WishlistEntry> loadedEntries = [];
    final cutoff = DateTime.now().toUtc().subtract(const Duration(days: 5));
    bool changed = false;
    try {
      final data = jsonDecode(raw);
      if (data is List) {
        for (final element in data) {
          if (element is Map<String, dynamic>) {
            final entry = _WishlistEntry.fromJson(element);
            if (entry == null) continue;
            if (entry.addedAt.isBefore(cutoff)) {
              changed = true;
              continue;
            }
            loadedEntries.add(entry);
          }
        }
      }
    } catch (_) {
      changed = true;
    }
    _entries
      ..clear()
      ..addAll(loadedEntries);
    _loaded = true;
    if (changed) {
      await _persist();
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    if (!_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final payload = _entries.map((entry) => entry.toJson()).toList();
    await prefs.setString(_prefsKey, jsonEncode(payload));
  }

  void clear() {
    _entries.clear();
    notifyListeners();
    _persist();
  }
}
