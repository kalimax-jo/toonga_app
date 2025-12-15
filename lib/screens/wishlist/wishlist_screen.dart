import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../models/product.dart';
import '../../services/cart_service.dart';
import '../../services/wishlist_service.dart';
import '../../theme/app_colors.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final WishlistService _wishlistService = WishlistService.instance;
  final CartService _cartService = CartService.instance;

  @override
  void initState() {
    super.initState();
    _wishlistService.addListener(_onWishlistChange);
  }

  void _onWishlistChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _wishlistService.removeListener(_onWishlistChange);
    super.dispose();
  }

  void _remove(Product product) {
    _wishlistService.toggle(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed ${product.name} from wishlist')),
    );
  }

  void _addToCart(Product product) {
    _cartService.addProduct(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${product.name} to cart')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _wishlistService.items;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Wishlist',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        elevation: 0,
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Iconsax.heart, color: AppColors.primary, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'Wishlist is empty',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Save items you love to see them here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final product = items[index];
                return _WishlistTile(
                  product: product,
                  onRemove: () => _remove(product),
                  onAddToCart: () => _addToCart(product),
                );
              },
            ),
    );
  }
}

class _WishlistTile extends StatelessWidget {
  final Product product;
  final VoidCallback onRemove;
  final VoidCallback onAddToCart;

  const _WishlistTile({
    required this.product,
    required this.onRemove,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final priceText = product.priceText ??
        (product.price != null ? 'RWF ${product.price!.toStringAsFixed(0)}' : 'Price hidden');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          _WishlistImage(imageUrl: product.imageUrl),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  priceText,
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: onAddToCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      ),
                      child: const Text(
                        'Add to cart',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onRemove,
                      icon: const Icon(Iconsax.trash, color: Colors.white54),
                    ),
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

class _WishlistImage extends StatelessWidget {
  final String? imageUrl;

  const _WishlistImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 70,
        height: 90,
        child: imageUrl == null || imageUrl!.isEmpty
            ? Image.asset('assets/images/background.png', fit: BoxFit.contain)
            : Image.network(imageUrl!, fit: BoxFit.contain),
      ),
    );
  }
}
