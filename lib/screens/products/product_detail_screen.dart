import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../models/product.dart';
import '../../theme/app_colors.dart';
import '../../services/cart_service.dart';
import '../cart/cart_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/product_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final CartService _cartService = CartService.instance;
  final ProductService _productService = ProductService();
  late Product _product;
  int _qty = 1;
  bool _loadingDetail = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _maybeFetchDetail();
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    final priceText =
        product.priceText ?? (product.price != null ? 'RWF ${product.price!.toStringAsFixed(0)}' : null);
    final attributes = _resolveAttributes(product, _qty);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_loadingDetail)
              const LinearProgressIndicator(
                minHeight: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                backgroundColor: Colors.black26,
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.black, Color(0xFF0b0b0b)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: SizedBox(
                          height: 320,
                          child: Hero(
                            tag: 'product-${product.id}',
                            child: Transform.rotate(
                              angle: 0.15,
                              child: _DetailImage(
                                imageUrl: product.imageUrl,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (product.vendorName != null && product.vendorName!.isNotEmpty)
                      Text(
                        product.vendorName!,
                        style: const TextStyle(color: Colors.white60),
                      ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: product.tags
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    if (product.description != null && product.description!.isNotEmpty)
                      Text(
                        product.description!,
                        style: const TextStyle(
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                    if (attributes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _AttributeSection(items: attributes),
                    ],
                    const SizedBox(height: 18),
                    if (priceText != null)
                      Text(
                        priceText,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    const SizedBox(height: 18),
                    _buildQuantity(),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _addToCart(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Add to cart',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          ),
          const Spacer(),
          ValueListenableBuilder(
            valueListenable: _cartService.totalItemsNotifier,
            builder: (context, count, _) {
              return _CartAction(count: count, onTap: _openCart);
            },
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.06),
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Iconsax.heart, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantity() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Quantity',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _qty > 1
                    ? () => setState(() {
                          _qty--;
                        })
                    : null,
                icon: const Icon(Iconsax.minus, color: Colors.white),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '$_qty',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() {
                  _qty++;
                }),
                icon: const Icon(Iconsax.add, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _addToCart(BuildContext context) {
    _cartService.addProduct(_product, quantity: _qty);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${_product.name} (x$_qty) to cart'),
      ),
    );
  }

  void _openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CartScreen()),
    );
  }

  List<_AttributeItem> _resolveAttributes(Product product, int quantity) {
    final extras = product.extras;
    final List<_AttributeItem> items = [];
    final Set<String> seen = {};
    void addItem(String name, dynamic value) {
      final label = name.trim();
      final val = value == null ? '' : value.toString().trim();
      if (label.isEmpty || val.isEmpty) return;
      items.add(_AttributeItem(label: label, value: val));
    }

    dynamic _findCountry() {
      // from direct field
      if (extras['country'] != null) return extras['country'];
      // from attribute_values list
      final attrValues = extras['attribute_values'];
      if (attrValues is List) {
        for (final entry in attrValues) {
          if (entry is Map) {
            final slug = entry['slug'] ?? entry['attribute'] ?? entry['name'];
            if (slug != null && slug.toString().toLowerCase() == 'country') {
              final raw = entry['value'] ?? entry['label'];
              // Try to map value code to label from options
              final attr = entry['attribute'];
              if (attr is Map && attr['options'] is List) {
                final opts = attr['options'] as List;
                for (final opt in opts.whereType<Map>()) {
                  if (opt['value']?.toString() == raw?.toString()) {
                    return opt['label'] ?? raw;
                  }
                }
              }
              return raw;
            }
          }
        }
      }
      // from attributes list
      final attrs = extras['attributes'];
      if (attrs is List) {
        for (final entry in attrs) {
          if (entry is Map) {
            final slug = entry['slug'] ?? entry['name'];
            if (slug != null && slug.toString().toLowerCase() == 'country') {
              final selected = entry['selected'] ?? entry['value'];
              return selected ?? entry['label'];
            }
          }
        }
      }
      return null;
    }

    double? _findMiles() {
      if (extras['can_have_miles'] != true) return null;
      final rewards = extras['rewards'];
      if (rewards is Map) {
        final miles = rewards['miles'];
        if (miles is Map) {
          if (miles['amount'] != null) return double.tryParse(miles['amount'].toString());
          if (miles['enabled'] == true && extras['estimated_earned_miles'] != null) {
            return double.tryParse(extras['estimated_earned_miles'].toString());
          }
        }
      }
      if (extras['estimated_earned_miles'] != null) {
        return double.tryParse(extras['estimated_earned_miles'].toString());
      }
      if (extras['miles_reward'] != null) {
        return double.tryParse(extras['miles_reward'].toString());
      }
      if (extras['reward_type']?.toString() == 'miles' && extras['reward_amount'] != null) {
        return double.tryParse(extras['reward_amount'].toString());
      }
      if (extras['miles'] != null) {
        return double.tryParse(extras['miles'].toString());
      }
      return null;
    }

    double? _findCashback() {
      final rewards = extras['rewards'];
      if (rewards is Map) {
        final cash = rewards['cashback'];
        if (cash is Map && cash['amount'] != null) {
          return double.tryParse(cash['amount'].toString());
        }
      }
      if (extras['cashback_percentage'] != null) {
        return double.tryParse(extras['cashback_percentage'].toString());
      }
      if (extras['reward_type']?.toString() == 'cashback' && extras['reward_amount'] != null) {
        return double.tryParse(extras['reward_amount'].toString());
      }
      if (extras['cashback'] != null) {
        return double.tryParse(extras['cashback'].toString());
      }
      return null;
    }

    double? miles = _findMiles();
    if (miles != null) miles *= quantity;
    if (miles != null) addItem('Miles reward', _formatNumber(miles));

    final cashbackCurrency = _computeCashbackAmount(product, quantity);
    if (cashbackCurrency != null) {
      addItem('Cashback', '${_formatNumber(cashbackCurrency)} RWF');
    }

    final country = _findCountry();
    if (country != null) addItem('Country', country);

    // Selected attribute values (e.g., ABV, Volume, Brand)
    final attrValues = extras['attribute_values'];
    if (attrValues is List) {
      for (final entry in attrValues) {
        if (entry is! Map) continue;
        final attr = entry['attribute'];
        final name = entry['name'] ??
            entry['label'] ??
            (attr is Map ? attr['name'] ?? attr['label'] : null);
        if (name == null) continue;
        final slug = (entry['slug'] ??
                entry['attribute'] ??
                (attr is Map ? attr['slug'] : null) ??
                name)
            .toString()
            .toLowerCase();
        if (slug == 'country') continue; // already handled separately

        final rawValue = entry['value'] ?? entry['label'] ?? entry['option'];
        String? mapped = rawValue?.toString();
        if (attr is Map && attr['options'] is List && rawValue != null) {
          for (final opt in (attr['options'] as List).whereType<Map>()) {
            if (opt['value']?.toString() == rawValue.toString()) {
              mapped = opt['label']?.toString() ?? mapped;
              break;
            }
          }
        }
        final key = '${name.toString().trim()}:${mapped ?? ''}';
        if (mapped != null && mapped.trim().isNotEmpty && !seen.contains(key)) {
          seen.add(key);
          addItem(name.toString(), mapped);
        }
      }
    }

    return items;
  }

  String _formatNumber(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  }

  double? _computeCashbackAmount(Product product, int quantity) {
    final price = product.price;
    if (price == null) return null;

    // Prefer explicit amount
    final rewards = product.extras['rewards'];
    if (rewards is Map) {
      final cash = rewards['cashback'];
      if (cash is Map && cash['amount'] != null) {
        final amt = double.tryParse(cash['amount'].toString());
        if (amt != null) {
          final total = amt * quantity;
          if (total > 0) return total;
        }
      }
      if (cash is Map && cash['percentage'] != null) {
        final pct = double.tryParse(cash['percentage'].toString());
        if (pct != null) {
          final total = (price * quantity) * (pct / 100);
          if (total > 0) return total;
        }
      }
    }

    // Fallbacks
    if (product.extras['cashback'] != null) {
      final amt = double.tryParse(product.extras['cashback'].toString());
      if (amt != null) {
        final total = amt * quantity;
        if (total > 0) return total;
      }
    }

    if (product.extras['cashback_percentage'] != null) {
      final pct = double.tryParse(product.extras['cashback_percentage'].toString());
      if (pct != null) {
        final total = (price * quantity) * (pct / 100);
        if (total > 0) return total;
      }
    }

    if (product.extras['reward_type']?.toString() == 'cashback' &&
        product.extras['reward_amount'] != null) {
      final amt = double.tryParse(product.extras['reward_amount'].toString());
      if (amt != null) {
        final total = amt * quantity;
        if (total > 0) return total;
      }
    }

    return null;
  }

  Future<void> _maybeFetchDetail() async {
    final extras = _product.extras;
    final hasDetailData = extras.containsKey('rewards') ||
        extras.containsKey('attribute_values') ||
        extras.containsKey('attributes');
    if (hasDetailData) return;

    final slug = (extras['category_slug'] ?? '').toString();
    setState(() => _loadingDetail = true);
    try {
      if (slug.isNotEmpty) {
        final list = await _productService.fetchCategoryProducts(
          slug: slug,
          search: _product.name,
          limit: 50,
        );
        final match = list.firstWhere(
          (p) => p.id == _product.id || p.name.toLowerCase() == _product.name.toLowerCase(),
          orElse: () => _product,
        );
        if (mounted) {
          setState(() => _product = match);
        }
      } else {
        final detail = await _productService.fetchProductDetail(_product.id);
        if (!mounted) return;
        if (detail != null) {
          setState(() => _product = detail);
        }
      }
    } catch (_) {
      // ignore; keep existing data
    } finally {
      if (mounted) {
        setState(() => _loadingDetail = false);
      }
    }
  }
}

class _DetailImage extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  const _DetailImage({this.imageUrl, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final imageUrl = this.imageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return Image.asset('assets/images/background.png', fit: fit);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      placeholder: (_, __) => const _ImageShimmerPlaceholder(),
      errorWidget: (_, __, ___) =>
          Image.asset('assets/images/background.png', fit: fit),
    );
  }
}

class _ImageShimmerPlaceholder extends StatefulWidget {
  const _ImageShimmerPlaceholder();

  @override
  State<_ImageShimmerPlaceholder> createState() => _ImageShimmerPlaceholderState();
}

class _ImageShimmerPlaceholderState extends State<_ImageShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final shimmer = (_controller.value * 2) - 1;
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1 + shimmer, -0.3),
              end: Alignment(1 + shimmer, 0.3),
              stops: const [0.2, 0.5, 0.8],
              colors: [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.28),
                Colors.white.withOpacity(0.08),
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        );
      },
    );
  }
}

class _CartAction extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _CartAction({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.06),
            ),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Iconsax.shopping_bag, color: Colors.white70),
            ),
          ),
          if (count > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AttributeSection extends StatelessWidget {
  final List<_AttributeItem> items;

  const _AttributeSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Details',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      item.label,
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Text(
                      item.value,
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttributeItem {
  final String label;
  final String value;

  const _AttributeItem({required this.label, required this.value});
}
