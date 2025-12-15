import 'package:flutter/foundation.dart';

import '../models/product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });
}

class CartService {
  CartService._internal();

  static final CartService instance = CartService._internal();

  final ValueNotifier<List<CartItem>> itemsNotifier =
      ValueNotifier<List<CartItem>>(<CartItem>[]);
  final ValueNotifier<int> totalItemsNotifier = ValueNotifier<int>(0);

  List<CartItem> get items => List<CartItem>.unmodifiable(itemsNotifier.value);

  int get totalItems => totalItemsNotifier.value;

  void addProduct(Product product, {int quantity = 1}) {
    if (quantity <= 0) return;
    final current = List<CartItem>.from(itemsNotifier.value);
    final index = current.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      current[index].quantity += quantity;
    } else {
      current.add(CartItem(product: product, quantity: quantity));
    }
    _emit(current);
  }

  void setQuantity(int productId, int quantity) {
    if (quantity < 0) return;
    final current = List<CartItem>.from(itemsNotifier.value);
    final index = current.indexWhere((item) => item.product.id == productId);
    if (index < 0) return;
    if (quantity == 0) {
      current.removeAt(index);
    } else {
      current[index].quantity = quantity;
    }
    _emit(current);
  }

  void removeProduct(int productId) {
    final current = itemsNotifier.value
        .where((item) => item.product.id != productId)
        .toList();
    _emit(current);
  }

  double get totalPrice {
    return itemsNotifier.value.fold<double>(
      0,
      (sum, item) => sum + (item.product.price ?? 0) * item.quantity,
    );
  }

  void clear() {
    _emit(<CartItem>[]);
  }

  void _emit(List<CartItem> items) {
    itemsNotifier.value = List<CartItem>.unmodifiable(items);
    totalItemsNotifier.value =
        items.fold<int>(0, (sum, item) => sum + item.quantity);
  }
}
