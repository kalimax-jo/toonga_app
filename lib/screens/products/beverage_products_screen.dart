import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../models/product.dart';
import '../../models/featured_product.dart';
import '../../services/product_service.dart';
import '../../services/wishlist_service.dart';
import '../../theme/app_colors.dart';
import 'product_detail_screen.dart';
import '../cart/cart_screen.dart';
import '../../services/cart_service.dart';

class BeverageProductsScreen extends StatefulWidget {
  const BeverageProductsScreen({super.key});

  @override
  State<BeverageProductsScreen> createState() => _BeverageProductsScreenState();
}

class _BeverageProductsScreenState extends State<BeverageProductsScreen>
    with SingleTickerProviderStateMixin {
  final ProductService _service = ProductService();
  final CartService _cartService = CartService.instance;
  final WishlistService _wishlistService = WishlistService.instance;
  bool _ageWarningShown = false;
  OverlayEntry? _ageBannerEntry;

  List<String> _filters = const ['All'];
  List<CategoryFilterOption> _subcategories = const [];
  Map<String, List<CategoryAttribute>> _attributesBySub = const {};
  Map<String, List<String>> _selectedAttrValues = {};
  List<Product> _products = const [];
  List<Product> _visible = const [];
  bool _isLoading = true;
  bool _isListView = false;
  String? _error;
  String? _errorDetails;
  String _selectedFilter = 'All';
  String? _selectedSubId;
  String _search = '';
  double? _minPrice;
  double? _maxPrice;

  @override
  void initState() {
    super.initState();
    _wishlistService.addListener(_handleWishlistChanged);
    _load();
    _scheduleAgeWarning();
  }

  @override
  void dispose() {
    _wishlistService.removeListener(_handleWishlistChanged);
    super.dispose();
  }

  void _handleWishlistChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _errorDetails = null;
    });
    try {
      final listing = await _tryLoadProducts();
      final items = listing.products;
      if (!mounted) return;
      setState(() {
        _products = items;
        _visible = items;
        _subcategories = listing.subcategories;
        _filters = ['All', ..._subcategories.map((e) => e.name)];
        if (listing.attributesBySubcategory.isNotEmpty) {
          _attributesBySub = listing.attributesBySubcategory;
        }
      });
    } catch (error, stackTrace) {
      developer.log('Product load failed', error: error, stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load products. Please try again.';
        _errorDetails = error.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _scheduleAgeWarning() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_ageWarningShown) {
        _showAgeWarning();
      }
    });
  }

  Future<void> _showAgeWarning() async {
    if (_ageBannerEntry != null) return;
    _ageWarningShown = true;
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutBack,
    );

    _ageBannerEntry = OverlayEntry(
      builder: (context) {
        final topInset = MediaQuery.of(context).padding.top;
        return Positioned(
          top: topInset + 8,
          left: 16,
          right: 16,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -1),
              end: Offset.zero,
            ).animate(animation),
            child: Material(
              color: const Color(0xFFF9C528),
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: const [
                    Icon(Iconsax.warning_2, color: Colors.black),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You must be 18+ to purchase alcohol. Please drink responsibly.',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_ageBannerEntry!);
    controller.forward();
    await Future.delayed(const Duration(seconds: 5));
    await controller.reverse();

    _ageBannerEntry?.remove();
    _ageBannerEntry = null;
    controller.dispose();
  }

  void _openWishlist() {
    Navigator.pushNamed(context, '/wishlist');
  }

  void _toggleWishlist(Product product) {
    final alreadyFavorite = _wishlistService.contains(product);
    _wishlistService.toggle(product);
    final message = alreadyFavorite
        ? 'Removed ${product.name} from wishlist'
        : 'Saved ${product.name} to wishlist';
    _showFeedbackModal(message);
  }

  Future<void> _showFeedbackModal(String message) async {
    if (!mounted) return;
    bool active = true;
    final sheet = showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF171717),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Iconsax.heart5, color: AppColors.primary, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
    Future.delayed(const Duration(seconds: 1), () {
      if (active && mounted) {
        Navigator.of(context).pop();
      }
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (active && mounted) {
        Navigator.of(context).pop();
      }
    });
    await sheet;
    active = false;
  }

  Future<ProductListing> _tryLoadProducts() async {
    try {
      // Only use the typed search term; subcategory filtering is handled via IDs.
      final filterQuery = _search.isNotEmpty ? _search : null;
      final items = await _fetchAllPagesForCategory(
        slug: 'beverage',
        search: filterQuery,
        subId: _selectedSubId,
        attributes: _selectedAttrValues.isNotEmpty ? _selectedAttrValues : null,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
      );
      if (items.products.isNotEmpty || items.subcategories.isNotEmpty) return items;
    } catch (error, stackTrace) {
      developer.log(
        'Failed to fetch beverage products',
        error: error,
        stackTrace: stackTrace,
      );
    }

    return const ProductListing(products: [], subcategories: []);
  }

  String? _resolveSubcategoryId(String filter) {
    final match = _subcategories.firstWhere(
      (sub) => sub.name.toLowerCase() == filter.toLowerCase(),
      orElse: () => const CategoryFilterOption(name: ''),
    );
    if (match.name.isEmpty) return null;
    return match.id?.toString();
  }

  Future<ProductListing> _fetchAllPagesForCategory({
    required String slug,
    String? search,
    String? subId,
    Map<String, List<String>>? attributes,
    double? minPrice,
    double? maxPrice,
  }) async {
    const int pageSize = 20;
    const int maxPages = 1; // the API already paginates; avoid duplicates
    final List<Product> all = [];
    List<CategoryFilterOption> subcats = const [];
    Map<String, List<CategoryAttribute>> attrsBySub = const {};
    for (int page = 1; page <= maxPages; page++) {
      final listing = await _service.fetchCategoryListing(
        slug: slug,
        search: search,
        subIds: subId != null ? [subId] : null,
        attributes: attributes,
        minPrice: minPrice,
        maxPrice: maxPrice,
        page: page,
        limit: pageSize,
      );
      all.addAll(listing.products);
      if (page == 1 && listing.subcategories.isNotEmpty) {
        subcats = listing.subcategories;
        if (listing.attributesBySubcategory.isNotEmpty) {
          attrsBySub = listing.attributesBySubcategory;
        }
      }
      if (listing.products.length < pageSize) break; // last page
    }
    return ProductListing(
      products: all,
      subcategories: subcats,
      attributesBySubcategory: attrsBySub,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: Colors.black,
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.background,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Iconsax.arrow_left, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text(
                  'Beverages',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: _load,
                    icon: const Icon(Iconsax.refresh, color: Colors.white70),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _isListView = !_isListView);
                    },
                    icon: Icon(
                      _isListView ? Iconsax.element_4 : Iconsax.row_horizontal,
                      color: Colors.white70,
                    ),
                  ),
                  _WishlistButton(
                    service: _wishlistService,
                    onTap: _openWishlist,
                  ),
                  ValueListenableBuilder(
                    valueListenable: _cartService.totalItemsNotifier,
                    builder: (context, count, _) {
                      return _CartIcon(
                        count: count,
                        onTap: _openCart,
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Discover curated bottles',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Fine wines, champagnes, and premium drinks.',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      _buildFilters(),
                      const SizedBox(height: 12),
                      _buildSearch(),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: _ShimmerGrid()),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ErrorState(
                    message: _error!,
                    details: _errorDetails,
                    onRetry: _load,
                  ),
                )
              else if (_visible.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: const _EmptyState(),
                )
              else if (_isListView)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  sliver: SliverList.separated(
                    itemCount: _visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final product = _visible[index];
                      return _ProductRowCard(
                        product: product,
                        onTap: () => _openDetail(product),
                        onAdd: () => _addToCart(product),
                      );
                    },
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 18,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = _visible[index];
                      return _ProductCard(
                        product: product,
                        index: index,
                        onTap: () => _openDetail(product),
                        onAdd: () => _addToCart(product),
                        onFavorite: () => _toggleWishlist(product),
                        isFavorite: _wishlistService.contains(product),
                      );
                  },
                      childCount: _visible.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final selected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(
                filter,
                style: TextStyle(
                  color: selected ? Colors.black : Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _selectedFilter = filter;
                  _selectedSubId = _resolveSubcategoryId(filter);
                  _selectedAttrValues.clear();
                });
                _load();
              },
              backgroundColor: Colors.white.withOpacity(0.06),
              selectedColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: selected
                      ? AppColors.primary.withOpacity(0.8)
                      : Colors.white.withOpacity(0.12),
                ),
              ),
              elevation: selected ? 2 : 0,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.search_normal, color: Colors.white70, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Search beverages',
                hintStyle: TextStyle(color: Colors.white54),
              ),
              onChanged: (value) {
                setState(() => _search = value);
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: _showFilterSheet,
              icon: const Icon(Icons.tune_rounded, color: Colors.white70, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    String? localSubId = _selectedSubId;
    final Map<String, List<String>> localAttr = {
      ..._selectedAttrValues.map((k, v) => MapEntry(k, List<String>.from(v))),
    };
    final minController =
        TextEditingController(text: _minPrice != null ? _minPrice!.toStringAsFixed(0) : '');
    final maxController =
        TextEditingController(text: _maxPrice != null ? _maxPrice!.toStringAsFixed(0) : '');
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F0F0F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final attrs = _collectAttributesForModal(localSubId);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filters',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              localAttr.clear();
                              localSubId = null;
                              minController.text = '';
                              maxController.text = '';
                            });
                          },
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _PriceField(
                            controller: minController,
                            label: 'Min price',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PriceField(
                            controller: maxController,
                            label: 'Max price',
                          ),
                        ),
                      ],
                    ),
                    if (_subcategories.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildSubChip(
                              label: 'All',
                              selected: localSubId == null,
                              onTap: () => setModalState(() => localSubId = null),
                            ),
                            ..._subcategories.map(
                              (sub) => _buildSubChip(
                                label: sub.name,
                                selected: localSubId == sub.id?.toString(),
                                onTap: () => setModalState(() => localSubId = sub.id?.toString()),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (attrs.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'No filters available for this selection.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          children: attrs
                              .map((attr) => _buildAttributeGroup(
                                    attr,
                                    localAttr[attr.slug] ?? const [],
                                    (slug, values) {
                                      setModalState(() {
                                        if (values.isEmpty) {
                                          localAttr.remove(slug);
                                        } else {
                                          localAttr[slug] = values;
                                        }
                                      });
                                    },
                                  ))
                              .toList(),
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _selectedSubId = localSubId;
                            _selectedFilter = _labelForSub(localSubId) ?? 'All';
                            _selectedAttrValues
                              ..clear()
                              ..addAll(localAttr);
                            _minPrice = double.tryParse(minController.text.trim());
                            _maxPrice = double.tryParse(maxController.text.trim());
                          });
                          _load();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(
                          'Apply filters',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAttributeGroup(
    CategoryAttribute attr,
    List<String> selectedValues,
    void Function(String slug, List<String> values) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            attr.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: attr.options.map((opt) {
              final isSelected = selectedValues.contains(opt.value);
              return FilterChip(
                label: Text(opt.label),
                selected: isSelected,
                onSelected: (_) {
                  final list = List<String>.from(selectedValues);
                  if (isSelected) {
                    list.remove(opt.value);
                  } else {
                    list.add(opt.value);
                  }
                  onChanged(attr.slug, list);
                },
                selectedColor: AppColors.primary,
                checkmarkColor: Colors.black,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: Colors.white.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.1),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<CategoryAttribute> _collectAttributesForModal(String? subId) {
    final attrs = <CategoryAttribute>[];
    if (_attributesBySub.isNotEmpty) {
      final general = _attributesBySub['general'];
      if (general != null) attrs.addAll(general);
      if (subId != null) {
        final subAttrs = _attributesBySub[subId];
        if (subAttrs != null && subAttrs.isNotEmpty) {
          attrs.addAll(subAttrs);
        } else {
          attrs.addAll(_attributesBySub.values.expand((e) => e));
        }
      } else {
        attrs.addAll(_attributesBySub.values.expand((e) => e));
      }
    }
    return attrs;
  }

  Widget _buildSubChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary,
        backgroundColor: Colors.white.withOpacity(0.08),
        labelStyle: TextStyle(
          color: selected ? Colors.black : Colors.white70,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String? _labelForSub(String? subId) {
    if (subId == null) return 'All';
    final match = _subcategories.firstWhere(
      (sub) => sub.id?.toString() == subId,
      orElse: () => const CategoryFilterOption(name: ''),
    );
    return match.name.isNotEmpty ? match.name : 'All';
  }

  void _openDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product),
      ),
    );
  }

  void _addToCart(Product product) {
    _cartService.addProduct(product);
    _showFeedbackModal('Added ${product.name} to cart');
  }

  void _openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CartScreen()),
    );
  }
}

Product _productFromFeatured(FeaturedProduct item) {
  return Product(
    id: item.productId ?? item.id,
    name: item.name,
    description: item.description,
    imageUrl: item.imageUrl,
    vendorName: item.vendorName,
    price: item.price,
    priceText: item.priceText,
    tags: const ['Featured'],
  );
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final int index;
  final VoidCallback onFavorite;
  final bool isFavorite;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onAdd,
    required this.index,
    required this.onFavorite,
    required this.isFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final priceText = product.priceText ??
        (product.price != null ? 'RWF ${_formatWithCommas(product.price!)}' : null);
    final hasReward = _hasReward(product);
    final double angle = 0.1; // consistent tilt left
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.36),
              blurRadius: 24,
              spreadRadius: 1,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: AppColors.primary.withOpacity(0.18),
              blurRadius: 28,
              spreadRadius: -10,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      top: -10, // let the bottle escape the card modestly
                      child: Center(
                        child: Hero(
                          tag: 'product-${product.id}',
                          child: Transform.rotate(
                            angle: angle,
                            child: _ProductImage(
                              imageUrl: product.imageUrl,
                              fit: BoxFit.contain,
                              heightFactor: 1.05,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        iconSize: 22,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onFavorite,
                        icon: Icon(
                          isFavorite ? Iconsax.heart5 : Iconsax.heart,
                          color: isFavorite ? AppColors.primary : Colors.white38,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.05,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (priceText != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          priceText,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            letterSpacing: -0.15,
                          ),
                        ),
                        if (hasReward)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Iconsax.medal, size: 12, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text(
                                  'Get rewards',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  GestureDetector(
                    onTap: onAdd,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                      child: const Icon(
                        Iconsax.shopping_bag,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasReward(Product product) {
    final extras = product.extras;
    bool hasMiles() {
      if (extras['can_have_miles'] != true) return false;
      if (extras['estimated_earned_miles'] != null) {
        final miles = double.tryParse(extras['estimated_earned_miles'].toString());
        if (miles != null && miles > 0) return true;
      }
      if (extras['miles_reward'] != null) {
        final miles = double.tryParse(extras['miles_reward'].toString());
        if (miles != null && miles > 0) return true;
      }
      if (extras['reward_type']?.toString() == 'miles' && extras['reward_amount'] != null) {
        final miles = double.tryParse(extras['reward_amount'].toString());
        if (miles != null && miles > 0) return true;
      }
      return false;
    }

    bool hasCashback() {
      if (extras['can_have_cashback'] == true) return true;
      if (extras['cashback_percentage'] != null) {
        final pct = double.tryParse(extras['cashback_percentage'].toString());
        if (pct != null && pct > 0) return true;
      }
      if (extras['cashback'] != null) {
        final amt = double.tryParse(extras['cashback'].toString());
        if (amt != null && amt > 0) return true;
      }
      if (extras['reward_type']?.toString() == 'cashback' && extras['reward_amount'] != null) {
        final amt = double.tryParse(extras['reward_amount'].toString());
        if (amt != null && amt > 0) return true;
      }
      return false;
    }

    return hasMiles() || hasCashback();
  }

  String _formatWithCommas(double value) {
    final parts = value.toStringAsFixed(0).split('.');
    final digits = parts.first;
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

class _ProductRowCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _ProductRowCard({
    required this.product,
    required this.onTap,
    required this.onAdd,
  });

  String _formatWithCommas(double value) {
    final parts = value.toStringAsFixed(0).split('.');
    final digits = parts.first;
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final priceText = product.priceText ??
        (product.price != null ? 'RWF ${_formatWithCommas(product.price!)}' : null);
    final hasReward = _hasReward(product);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.36),
              blurRadius: 18,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 90,
                height: 90,
                child: _ProductImage(
                  imageUrl: product.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (priceText != null)
                    Row(
                      children: [
                        Text(
                          priceText,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (hasReward) ...[
                          const SizedBox(width: 8),
                          const Icon(Iconsax.medal, size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          const Text(
                            'Get rewards',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.shopping_bag, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasReward(Product product) {
    final extras = product.extras;
    bool hasMiles() {
      if (extras['can_have_miles'] != true) return false;
      if (extras['estimated_earned_miles'] != null) {
        final miles = double.tryParse(extras['estimated_earned_miles'].toString());
        if (miles != null && miles > 0) return true;
      }
      if (extras['miles_reward'] != null) {
        final miles = double.tryParse(extras['miles_reward'].toString());
        if (miles != null && miles > 0) return true;
      }
      if (extras['reward_type']?.toString() == 'miles' && extras['reward_amount'] != null) {
        final miles = double.tryParse(extras['reward_amount'].toString());
        if (miles != null && miles > 0) return true;
      }
      return false;
    }

    bool hasCashback() {
      if (extras['can_have_cashback'] == true) return true;
      if (extras['cashback_percentage'] != null) {
        final pct = double.tryParse(extras['cashback_percentage'].toString());
        if (pct != null && pct > 0) return true;
      }
      if (extras['cashback'] != null) {
        final amt = double.tryParse(extras['cashback'].toString());
        if (amt != null && amt > 0) return true;
      }
      if (extras['reward_type']?.toString() == 'cashback' && extras['reward_amount'] != null) {
        final amt = double.tryParse(extras['reward_amount'].toString());
        if (amt != null && amt > 0) return true;
      }
      return false;
    }

    return hasMiles() || hasCashback();
  }
}

class _CartIcon extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _CartIcon({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Iconsax.shopping_bag, color: Colors.white70),
          ),
          if (count > 0)
            Positioned(
              right: 4,
              top: 4,
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

class _WishlistButton extends StatelessWidget {
  final WishlistService service;
  final VoidCallback onTap;

  const _WishlistButton({
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        final count = service.count;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: onTap,
              icon: const Icon(Iconsax.heart, color: Colors.white70),
            ),
            if (count > 0)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PriceField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _PriceField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF101010),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final double heightFactor;
  const _ProductImage({this.imageUrl, this.fit = BoxFit.cover, this.heightFactor = 1});

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Image.asset(
        'assets/images/background.png',
        fit: fit,
      );
    }
    return FractionallySizedBox(
      heightFactor: heightFactor,
      child: Image.network(
        imageUrl!,
        fit: fit,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/background.png',
          fit: fit,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
    this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          if (details != null) ...[
            Text(
              details!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
          ],
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No beverages yet. Check back soon.',
        style: TextStyle(color: Colors.white60),
      ),
    );
  }
}

class _ShimmerGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const _ShimmerPlaceholder();
  }
}

class _ShimmerPlaceholder extends StatefulWidget {
  const _ShimmerPlaceholder();

  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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
        final shimmerPosition = (_controller.value * 2) - 1;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              _shimmerBlock(
                shimmerPosition: shimmerPosition,
                height: 160,
                borderRadius: 22,
              ),
              const SizedBox(height: 16),
              _shimmerBlock(
                shimmerPosition: shimmerPosition,
                height: 14,
                width: 220,
                borderRadius: 10,
              ),
              const SizedBox(height: 10),
              _shimmerBlock(
                shimmerPosition: shimmerPosition,
                height: 12,
                width: 120,
                borderRadius: 8,
              ),
              const SizedBox(height: 18),
              _shimmerRow(shimmerPosition),
              const SizedBox(height: 14),
              _shimmerRow(shimmerPosition),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerRow(double shimmerPosition) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _shimmerBlock(
          shimmerPosition: shimmerPosition,
          height: 54,
          width: 54,
          borderRadius: 16,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _shimmerBlock(
                shimmerPosition: shimmerPosition,
                height: 14,
                width: double.infinity,
                borderRadius: 10,
              ),
              const SizedBox(height: 8),
              _shimmerBlock(
                shimmerPosition: shimmerPosition,
                height: 12,
                width: 140,
                borderRadius: 8,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _shimmerBlock({
    required double shimmerPosition,
    required double height,
    double? width,
    double borderRadius = 12,
  }) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment(-1 + shimmerPosition, -0.3),
          end: Alignment(1 + shimmerPosition, 0.3),
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
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
