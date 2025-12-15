import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../theme/app_colors.dart';
import 'product_detail_screen.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String slug;
  final String title;

  const CategoryProductsScreen({
    super.key,
    required this.slug,
    required this.title,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final ProductService _service = ProductService();
  bool _isLoading = true;
  String? _error;
  List<Product> _products = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await _service.fetchCategoryProducts(
        slug: widget.slug,
        limit: 40,
      );
      if (!mounted) return;
      setState(() {
        _products = items;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load ${widget.title} products. Please try again.';
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
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Iconsax.refresh, color: Colors.white70),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: Colors.black,
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Something went wrong',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error ?? '',
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _load,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_products.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Center(
            child: Text(
              'No products available yet.',
              style: TextStyle(color: Colors.white60),
            ),
          ),
        ],
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 16,
        childAspectRatio: 0.74,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return _ProductTile(
          product: product,
          onTap: () => _openDetail(product),
        );
      },
    );
  }

  void _openDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductTile({required this.product, required this.onTap});

  String? _priceText(Product product) {
    if (product.priceText != null && product.priceText!.isNotEmpty) {
      return product.priceText;
    }
    if (product.price != null) {
      return 'RWF ${product.price!.toStringAsFixed(0)}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final priceText = _priceText(product);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.32),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(
                  color: Colors.white.withOpacity(0.04),
                  child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: Colors.white.withOpacity(0.06),
                            alignment: Alignment.center,
                            child: const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Image.asset(
                            'assets/images/background.png',
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          'assets/images/background.png',
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (priceText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      priceText,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
