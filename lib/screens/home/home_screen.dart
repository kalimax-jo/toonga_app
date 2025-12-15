import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';

import '../../models/featured_product.dart';
import '../../models/product.dart';
import '../../models/home_response.dart';
import '../../models/home_notification.dart';
import '../../services/api_config.dart';
import '../../services/category_service.dart';
import '../../services/profile_service.dart';
import '../../services/session_manager.dart';
import '../../services/cart_service.dart';
import '../../services/api_client.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/color_palette.dart';
import '../products/product_detail_screen.dart';
import '../products/category_products_screen.dart';
import '../cart/cart_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/notification_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final ScrollController _storyController;
  late final ScrollController _mainScrollController;
  late final AnimationController _swipeController;
  late final Animation<double> _swipeAnimation;
  Timer? _swipeHintTimer;
  bool _showSwipeHint = true;
  bool _isOpeningStory = false;
  int _selectedCategory = 0;
  int _currentNav = 0;
  double _storyProgress = 0;
  bool _isLoadingCategories = true;
  bool _isRefreshing = false;
  String? _categoryError;
  List<HomeCategory> _categories = const [];
  final Map<String, List<FeaturedProduct>> _featuredBySlug = {};
  final Set<String> _featuredLoading = <String>{};
  List<_StoryItem> _storyItems = const [];
  final CategoryService _categoryService = CategoryService();
  final ProfileService _profileService = ProfileService();
  final SessionManager _sessionManager = SessionManager.instance;
  final CartService _cartService = CartService.instance;
  final ApiClient _apiClient = ApiClient();
  final NotificationService _notificationService = NotificationService();
  String? _userName;
  String? _avatarUrl;
  bool _isAuthenticated = false;
  int _cartCount = 0;
  double? _availableMiles;
  final GlobalKey _profileKey = GlobalKey();
  final GlobalKey _categoriesKey = GlobalKey();
  final GlobalKey _reelsNavKey = GlobalKey();
  // Refresh control variables
  double _refreshIndicatorOffset = 0;
  bool _showRefreshIndicator = false;

  // Notifications placeholder (to be wired to API later)
  List<HomeNotification> _notifications = const [];
  final ValueNotifier<List<HomeNotification>> _notificationListNotifier =
      ValueNotifier(const []);
  final ValueNotifier<bool> _notificationLoadingNotifier = ValueNotifier(false);
  final ValueNotifier<String?> _notificationErrorNotifier = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _storyController = ScrollController()..addListener(_handleStoryScroll);
    _mainScrollController = ScrollController()..addListener(_handleMainScroll);
    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
    _swipeAnimation = Tween<double>(
      begin: 0,
      end: -8,
    ).chain(CurveTween(curve: Curves.easeInOut)).animate(_swipeController);
    _swipeHintTimer = Timer(const Duration(seconds: 15), () {
      if (mounted) {
        setState(() {
          _showSwipeHint = false;
        });
      }
    });
    _loadCategories();
    _loadUserProfile();
    _loadNotifications();
    _cartService.totalItemsNotifier.addListener(_handleCartCount);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _storyController
      ..removeListener(_handleStoryScroll)
      ..dispose();
    _mainScrollController
      ..removeListener(_handleMainScroll)
      ..dispose();
    _swipeController.dispose();
    _swipeHintTimer?.cancel();
    _cartService.totalItemsNotifier.removeListener(_handleCartCount);
    _notificationListNotifier.dispose();
    _notificationLoadingNotifier.dispose();
    _notificationErrorNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final isCompact = screenWidth < 360;
    final horizontalPadding = isCompact ? 14.0 : 20.0;
    final storySize = isCompact ? 60.0 : 68.0;
    final headerSpacing = isCompact ? 6.0 : 10.0;
    final sectionSpacing = isCompact ? 12.0 : 18.0;
    final cardSidePadding = isCompact ? 12.0 : 16.0;
    final cardHeight = (screenHeight * 0.43).clamp(300.0, 420.0);

    final List<_StoryItem> storyItems = _storyItems;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Refresh Indicator
            if (_showRefreshIndicator)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 80 + _refreshIndicatorOffset,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primary.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Transform.translate(
                      offset: Offset(0, _refreshIndicatorOffset * 0.5),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _isRefreshing
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black,
                                ),
                                strokeWidth: 3,
                              )
                            : const Icon(
                                Iconsax.refresh,
                                color: Colors.black,
                                size: 20,
                              ),
                      ),
                    ),
                  ),
                ),
              ),

            // Main Content with pull-to-refresh
            RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: theme.scaffoldBackgroundColor,
              displacement: 60,
              onRefresh: _triggerRefresh,
              child: NotificationListener<ScrollNotification>(
                onNotification: _handleScrollNotification,
                child: SingleChildScrollView(
                  controller: _mainScrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 70),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section with gradient background
                      Container(
                        decoration: BoxDecoration(
                          image: isDark
                              ? null
                              : const DecorationImage(
                                  image: AssetImage(
                                    'assets/images/yellow_bg.png',
                                  ),
                                  fit: BoxFit.cover,
                                  opacity: 0.9,
                                ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(context).scaffoldBackgroundColor
                                  .withOpacity(isDark ? 0.8 : 0.95),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.7],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SocialHeader(
                                  storyController: _storyController,
                                  storyProgress: _storyProgress,
                                  storySize: storySize,
                                  stories: storyItems,
                                  isLoadingStories:
                                      (_isLoadingCategories ||
                                          _featuredLoading.isNotEmpty) &&
                                      storyItems.isEmpty,
                                  userName: _userName,
                                  isAuthenticated: _isAuthenticated,
                                  avatarUrl: _avatarUrl,
                                  profileKey: _profileKey,
                                  categoriesKey: _categoriesKey,
                                  onStoryTap: _handleStoryTap,
                                  availableMiles: _availableMiles,
                                  notificationCount: _unreadNotificationCount,
                                  onNotificationTap: _showNotificationsPanel,
                                ),
                                SizedBox(height: headerSpacing),
                                Text(
                                  'Plan a premium experience',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontSize: isCompact ? 20 : 22,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.25,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Select a category that suits your mood today.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 14,
                                    height: 1.35,
                                    color: theme.textTheme.bodyMedium?.color
                                        ?.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (_showSwipeHint)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: AnimatedBuilder(
                                      animation: _swipeAnimation,
                                      builder: (context, _) {
                                        return Transform.translate(
                                          offset: Offset(
                                            _swipeAnimation.value,
                                            0,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 22,
                                                height: 22,
                                                child: Image.asset(
                                                  'assets/images/hand.png',
                                                  color: AppColors.primary,
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              const Text(
                                                'Swipe left for more categories.',
                                                style: TextStyle(
                                                  color: AppColors.primary,
                                                  fontSize: 16,
                                                  height: 1.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Main Content Area
                      if (_isLoadingCategories)
                        _buildLoadingState(
                          context,
                          horizontalPadding,
                          sectionSpacing,
                          cardHeight,
                        )
                      else if (_categoryError != null)
                        _buildErrorState(
                          context,
                          horizontalPadding,
                          sectionSpacing,
                        )
                      else if (_categories.isEmpty)
                        _buildEmptyState(
                          context,
                          horizontalPadding,
                          sectionSpacing,
                        )
                      else
                        _buildMainContent(
                          horizontalPadding,
                          sectionSpacing,
                          cardHeight,
                          cardSidePadding,
                          isCompact,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentNav,
        onTap: (index) {
          _handleNavTap(index);
        },
        reelsNavKey: _reelsNavKey,
        cartCount: _cartCount,
      ),
    );
  }

  Widget _buildLoadingState(
    BuildContext context,
    double horizontalPadding,
    double sectionSpacing,
    double cardHeight,
  ) {
    final viewportHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        sectionSpacing,
        horizontalPadding,
        0,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: viewportHeight),
        child: const _HomeShimmerPlaceholder(),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    double horizontalPadding,
    double sectionSpacing,
  ) {
    final viewportHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        sectionSpacing,
        horizontalPadding,
        0,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: viewportHeight),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(0.03),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.orange[300],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Unable to load categories',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _categoryError ?? '',
                style: const TextStyle(color: Colors.white60, height: 1.4),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onPressed: _loadCategories,
                child: const Text(
                  'Try Again',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    double horizontalPadding,
    double sectionSpacing,
  ) {
    final viewportHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        sectionSpacing,
        horizontalPadding,
        0,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: viewportHeight),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(0.03),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[300], size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'No categories available yet. Please check back soon.',
                  style: TextStyle(color: Colors.white54, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(
    double horizontalPadding,
    double sectionSpacing,
    double cardHeight,
    double cardSidePadding,
    bool isCompact,
  ) {
    return Column(
      children: [
        SizedBox(height: isCompact ? 10 : 14),

        // Category Cards with overlay content
        SizedBox(
          height: cardHeight,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: cardSidePadding),
            child: PageView.builder(
              controller: _pageController,
              padEnds: true,
              onPageChanged: (value) {
                setState(() => _selectedCategory = value);
              },
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return AnimatedPadding(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  padding: EdgeInsets.only(
                    top: index == _selectedCategory ? 0 : 18,
                    bottom: index == _selectedCategory ? 0 : 18,
                  ),
                  child: Transform(
                    transform: Matrix4.identity()
                      ..scale(index == _selectedCategory ? 1.0 : 0.95),
                    child: _CategoryCard(
                      category: category,
                      fallbackAsset: _categoryFallbackAsset(category, index),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Dots
        const Padding(
          padding: EdgeInsets.only(top: 16),
          child: SizedBox(), // replaced by _DotsIndicator below
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: _DotsIndicator(
            count: _categories.length,
            activeIndex: _selectedCategory,
          ),
        ),
        SizedBox(height: isCompact ? 24 : 32),
      ],
    );
  }

  void _handleStoryScroll() {
    if (!_storyController.hasClients) return;
    final position = _storyController.position;
    final max = position.maxScrollExtent;
    final double progress = max <= 0
        ? 0
        : (position.pixels / max).clamp(0.0, 1.0).toDouble();
    if (progress != _storyProgress) {
      setState(() => _storyProgress = progress);
    }
  }

  void _handleMainScroll() {
    if (!_mainScrollController.hasClients) return;

    final position = _mainScrollController.position;
    final pixels = position.pixels;

    // Show refresh indicator when pulling down from top
    if (pixels < -80 && !_isRefreshing && !_showRefreshIndicator) {
      setState(() {
        _showRefreshIndicator = true;
        _refreshIndicatorOffset = -pixels - 80;
      });
    } else if (pixels >= -80 && _showRefreshIndicator && !_isRefreshing) {
      setState(() {
        _showRefreshIndicator = false;
        _refreshIndicatorOffset = 0;
      });
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification) {
      // Trigger refresh when user releases after pulling down enough
      if (_showRefreshIndicator &&
          _refreshIndicatorOffset > 40 &&
          !_isRefreshing) {
        _triggerRefresh();
      } else {
        // Reset if not pulled enough
        setState(() {
          _showRefreshIndicator = false;
          _refreshIndicatorOffset = 0;
        });
      }
    }
    return false;
  }

  Future<void> _triggerRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    // Simulate refresh delay
    await Future.delayed(const Duration(milliseconds: 1500));

    // Reload data
    await Future.wait([_loadCategories(), _loadNotifications()]);

    setState(() {
      _isRefreshing = false;
      _showRefreshIndicator = false;
      _refreshIndicatorOffset = 0;
    });
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _categoryError = null;
    });
    try {
      final categoriesFuture = _categoryService.fetchCategories();
      final landingFuture = _categoryService.fetchLandingCategories();
      final results = await Future.wait([categoriesFuture, landingFuture]);
      final categoriesResponse = results[0] as List<HomeCategory>;
      final landingResponse = results[1] as List<HomeCategory>;

      final landingMap = <String, List<FeaturedProduct>>{};
      for (final landingCategory in landingResponse) {
        final slug = landingCategory.slug;
        if (slug != null && slug.isNotEmpty) {
          landingMap[slug] = landingCategory.featuredItems;
        }
      }

      final filtered =
          categoriesResponse.where((category) => category.isActive).toList()
            ..sort(
              (a, b) => (a.sortOrder ?? 999).compareTo(b.sortOrder ?? 999),
            );

      if (!mounted) return;
      setState(() {
        _categories = filtered;
        _featuredBySlug
          ..clear()
          ..addAll(landingMap);
        _selectedCategory = 0;
      });

      if (_pageController.hasClients && filtered.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _pageController.hasClients) {
            _pageController.jumpToPage(0);
          }
        });
      }

      for (final category in filtered) {
        final slug = category.slug;
        if (slug == null || slug.isEmpty) continue;
        final hasLanding = _featuredBySlug[slug]?.isNotEmpty == true;
        if (!hasLanding) {
          _ensureFeaturedForSlug(slug);
        }
      }

      _updateStoryItems();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _categoryError = error.toString();
        _categories = const [];
      });
    } finally {
      if (!mounted) return;
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _loadNotifications() async {
    _notificationLoadingNotifier.value = true;
    _notificationErrorNotifier.value = null;

    try {
      final notifications = await _notificationService.fetchNotifications();

      if (!mounted) return;
      setState(() {
        _notifications = notifications;
      });
      _notificationListNotifier.value = notifications;
      _notificationErrorNotifier.value = null;

      final unreadIds = notifications
          .where((notification) => notification.isNew)
          .map((notification) => notification.id)
          .whereType<int>()
          .toList();
      unawaited(_notificationService.markRead(unreadIds));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _notifications = const [];
      });
      _notificationListNotifier.value = const [];
      _notificationErrorNotifier.value = error.toString();
    } finally {
      if (!mounted) return;
      _notificationLoadingNotifier.value = false;
    }
  }

  int get _unreadNotificationCount =>
      _notifications.where((notification) => notification.isNew).length;

  void _showNotificationsPanel() {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _NotificationSheet(
          notifications: _notificationListNotifier,
          isLoading: _notificationLoadingNotifier,
          error: _notificationErrorNotifier,
          onRetry: _loadNotifications,
        );
      },
    );
  }

  String _categoryFallbackAsset(HomeCategory category, int index) {
    switch (category.slug) {
      case 'night-life':
        return 'assets/images/yellow_bg.png';
      case 'beverage':
        return 'assets/images/background.png';
      default:
        return index.isEven
            ? 'assets/images/background.png'
            : 'assets/images/yellow_bg.png';
    }
  }

  Future<void> _ensureFeaturedForSlug(String slug) async {
    if (slug.isEmpty || _featuredLoading.contains(slug)) return;
    if (_featuredBySlug[slug]?.isNotEmpty == true) return;
    // Trigger rebuilds while we wait for featured items so the skeleton shows/hides correctly.
    if (mounted) {
      setState(() {
        _featuredLoading.add(slug);
      });
    } else {
      _featuredLoading.add(slug);
    }
    try {
      final items = await _categoryService.fetchFeatured(slug);
      if (!mounted) return;
      setState(() {
        _featuredBySlug[slug] = items;
      });
      _updateStoryItems();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _featuredBySlug[slug] = const [];
      });
      _updateStoryItems();
    } finally {
      if (mounted) {
        setState(() {
          _featuredLoading.remove(slug);
        });
      } else {
        _featuredLoading.remove(slug);
      }
    }
  }

  void _updateStoryItems() {
    final List<_StoryItem> items = [];
    for (var i = 0; i < _categories.length; i++) {
      final category = _categories[i];
      final slug = category.slug ?? '';
      final featured = slug.isNotEmpty
          ? _featuredBySlug[slug] ?? const []
          : const [];
      if (featured.isEmpty) {
        continue;
      }
      for (final product in featured) {
        final price =
            product.priceText ??
            (product.price != null
                ? 'RWF ${product.price!.toStringAsFixed(0)}'
                : null);
        items.add(
          _StoryItem(
            title: product.name ?? category.name,
            price: price,
            imageUrl: product.imageUrl ?? category.featuredImage,
            fallbackAsset: _categoryFallbackAsset(category, items.length),
            isLoading: false,
            categoryName: category.name,
            categorySlug: category.slug,
            heroTag: 'product-${product.productId ?? product.id}',
            featured: product,
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _storyItems = items;
    });
  }

  Future<void> _loadUserProfile() async {
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isAuthenticated = false;
        _userName = null;
        _avatarUrl = null;
        _availableMiles = null;
      });
      return;
    }

    setState(() => _isAuthenticated = true);

    try {
      final profile = await _profileService.fetchProfile();
      final name = profile.name?.trim();
      final avatar = profile.avatarUrl?.trim();
      if (!mounted) return;
      setState(() {
        _userName = (name != null && name.isNotEmpty) ? name : null;
        _avatarUrl = avatar;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _userName = _userName;
        _avatarUrl = _avatarUrl;
      });
    }
    await _loadMiles(token);
  }

  Future<void> _loadMiles(String token) async {
    try {
      final headers = {'Authorization': 'Bearer $token'};
      final json = await _apiClient.get('/account/overview', headers: headers);
      final data =
          json['miles'] ??
          (json['data'] is Map<String, dynamic>
              ? (json['data'] as Map<String, dynamic>)['miles']
              : null);
      if (data is Map<String, dynamic>) {
        final available = _parseMilesValue(data);
        if (!mounted) return;
        setState(() {
          _availableMiles = available;
        });
      }
    } catch (_) {
      if (!mounted) return;
    }
  }

  double? _parseMilesValue(Map<String, dynamic> payload) {
    final keys = ['available', 'balance', 'total', 'miles'];
    for (final key in keys) {
      final value = payload[key];
      if (value == null) continue;
      final parsed = _tryParseDouble(value);
      if (parsed != null) return parsed;
    }
    return null;
  }

  double? _tryParseDouble(dynamic input) {
    if (input == null) return null;
    if (input is num) return input.toDouble();
    return double.tryParse(input.toString());
  }

  Future<void> _handleNavTap(int index) async {
    if (index == 0) {
      setState(() => _currentNav = 0);
      return;
    }

    // Reels is public; other tabs may require auth.
    if (index == 2) {
      setState(() => _currentNav = 2);
      if (!mounted) return;
      Navigator.pushNamed(context, '/reels');
      return;
    }

    final authed = await _ensureAuthenticated();
    if (!authed) return;

    setState(() => _currentNav = index);
    if (!mounted) return;

    if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => CartScreen()));
      return;
    }
    if (index == 3) {
      Navigator.pushNamed(context, '/pay');
      return;
    }
    if (index == 4) {
      Navigator.pushNamed(context, '/profile');
    }
  }

  Future<bool> _ensureAuthenticated() async {
    final token = await _sessionManager.getToken();
    if (token != null && token.isNotEmpty) return true;
    if (!mounted) return false;

    setState(() {
      _isAuthenticated = false;
      _userName = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please sign in to continue.')),
    );
    Navigator.pushNamed(context, '/login');
    return false;
  }

  void _handleCartCount() {
    if (!mounted) return;
    setState(() {
      _cartCount = _cartService.totalItems;
    });
  }

  Future<void> _handleStoryTap(_StoryItem item) async {
    if (_isOpeningStory) return;
    if (item.featured == null) return;
    _isOpeningStory = true;
    final productId = item.featured!.productId ?? item.featured!.id;
    Product prod = Product(
      id: productId,
      name: item.featured!.name,
      description: item.featured!.description ?? item.title,
      imageUrl: item.featured!.imageUrl ?? item.imageUrl,
      vendorName: item.featured!.vendorName,
      price: item.featured!.price,
      priceText: item.featured!.priceText ?? item.price,
      tags: [item.categoryName],
      extras: {'category_slug': item.categorySlug ?? ''},
    );
    if (!mounted) {
      _isOpeningStory = false;
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: prod)),
    );
    _isOpeningStory = false;
  }
}

class _SocialHeader extends StatelessWidget {
  final ScrollController storyController;
  final double storyProgress;
  final double storySize;
  final List<_StoryItem> stories;
  final bool isLoadingStories;
  final String? userName;
  final bool isAuthenticated;
  final String? avatarUrl;
  final double? availableMiles;
  final Key? profileKey;
  final Key? categoriesKey;
  final Future<void> Function(_StoryItem item)? onStoryTap;
  final int notificationCount;
  final VoidCallback onNotificationTap;

  const _SocialHeader({
    required this.storyController,
    required this.storyProgress,
    required this.storySize,
    required this.stories,
    this.isLoadingStories = false,
    this.userName,
    this.isAuthenticated = false,
    this.avatarUrl,
    this.profileKey,
    this.categoriesKey,
    this.onStoryTap,
    this.availableMiles,
    required this.notificationCount,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final showPlaceholder = stories.isEmpty && isLoadingStories;
    final palette =
        Theme.of(context).extension<AppPalette>() ??
        (isDark ? AppPalette.dark : AppPalette.light);
    final defaultNames = ['Beverage', 'Nightlife', 'Gourmet', 'Wellness'];

    final placeholders = List<_StoryItem>.generate(
      defaultNames.length,
      (index) => _StoryItem(
        title: defaultNames[index],
        price: null,
        fallbackAsset: index.isEven
            ? 'assets/images/background.png'
            : 'assets/images/yellow_bg.png',
        isLoading: true,
        categoryName: 'Featured',
        categorySlug: null,
      ),
    );

    final displayStories = showPlaceholder ? placeholders : stories;
    final resolvedName = userName?.isNotEmpty == true ? userName! : 'Guest';
    final greeting = _timeGreeting();
    final subtitle = isAuthenticated
        ? greeting
        : 'Sign in to unlock your rewards';
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Header row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ProfileAvatar(
                      key: profileKey,
                      avatarUrl: avatarUrl,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            resolvedName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: palette.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: palette.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ToongaLogo(),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: palette.navBackground.withOpacity(
                                  isDark ? 0.12 : 0.28,
                                ),
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  IconButton(
                                    padding: const EdgeInsets.all(8),
                                    onPressed: onNotificationTap,
                                    icon: Icon(
                                      Iconsax.notification,
                                      color: palette.icon,
                                      size: 22,
                                    ),
                                  ),
                                  if (notificationCount > 0)
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: palette.navBackground,
                                            width: 1.2,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: palette.navBackground.withOpacity(
                                  isDark ? 0.12 : 0.28,
                                ),
                              ),
                              child: IconButton(
                                padding: const EdgeInsets.all(8),
                                onPressed: () {
                                  Navigator.pushNamed(context, '/offers');
                                },
                                icon: Icon(
                                  Iconsax.gift,
                                  color: palette.icon,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _MilesStatusRow(
                  availableMiles: availableMiles,
                  isAuthenticated: isAuthenticated,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Stories row with enhanced design (Instagram-style)
          KeyedSubtree(
            key: categoriesKey,
            child: SizedBox(
              height: storySize + 60, // extra space for circle + name + price
              child: ListView.builder(
                controller: storyController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: displayStories.length,
                itemBuilder: (context, index) {
                  final item = displayStories[index];
                  final highlight = !showPlaceholder;
                  final heroTag = item.heroTag;
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _StoryChip(
                      title: item.title,
                      price: item.price,
                      imageUrl: showPlaceholder ? null : item.imageUrl,
                      fallbackAsset: item.fallbackAsset,
                      highlight: highlight,
                      size: storySize,
                      isLoading: showPlaceholder || item.isLoading,
                      heroTag: showPlaceholder ? null : heroTag,
                      onTap: showPlaceholder || item.isLoading
                          ? null
                          : () => onStoryTap?.call(item),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _MilesStatusRow extends StatelessWidget {
  final double? availableMiles;
  final bool isAuthenticated;

  const _MilesStatusRow({
    super.key,
    this.availableMiles,
    required this.isAuthenticated,
  });

  @override
  Widget build(BuildContext context) {
    final display = availableMiles != null
        ? '${availableMiles!.toStringAsFixed(0)} Miles'
        : isAuthenticated
        ? '0 Miles'
        : 'Sign in to view';
    final theme = Theme.of(context);
    final textColor =
        theme.textTheme.bodyLarge?.color ??
        (theme.brightness == Brightness.dark ? Colors.white : Colors.black);
    final iconBg = theme.brightness == Brightness.dark
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.04);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(shape: BoxShape.circle, color: iconBg),
          child: const Icon(Iconsax.medal_star, color: Colors.amber, size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          display,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _ToongaLogo extends StatelessWidget {
  const _ToongaLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: 30,
          height: 30,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 6),
        const Text(
          'Toonga',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }
}

class _NotificationSection extends StatelessWidget {
  final List<HomeNotification> notifications;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;

  const _NotificationSection({
    required this.notifications,
    required this.isLoading,
    required this.onRetry,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (isLoading) {
      content = Column(
        children: const [
          NotificationSkeleton(),
          SizedBox(height: 10),
          NotificationSkeleton(),
        ],
      );
    } else if (error != null) {
      content = NotificationMessage(
        icon: Icons.error_outline,
        title: 'Couldn\'t load notifications',
        subtitle: 'We\'ll keep trying. Tap to retry now.',
        onTap: onRetry,
      );
    } else if (notifications.isEmpty) {
      content = const NotificationMessage(
        icon: Icons.check_circle_outline,
        title: 'You\'re all caught up',
        subtitle: 'New product drops and promos will appear here.',
      );
    } else {
      content = Column(
        children: List.generate(notifications.length, (index) {
          final item = notifications[index];
          return Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : 10),
            child: NotificationCard(notification: item),
          );
        }),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Iconsax.notification, size: 14, color: Colors.white70),
                  SizedBox(width: 4),
                  Text(
                    'Home feed',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              onPressed: onRetry,
              child: const Text(
                'Refresh',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }
}

class _NotificationSheet extends StatelessWidget {
  final ValueListenable<List<HomeNotification>> notifications;
  final ValueListenable<bool> isLoading;
  final ValueListenable<String?> error;
  final VoidCallback onRetry;

  const _NotificationSheet({
    required this.notifications,
    required this.isLoading,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: 0.94,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 60,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Activity',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Orders & payments',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pushNamed('/notifications');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                        child: const Text('View all'),
                      ),
                      IconButton(
                        padding: const EdgeInsets.all(6),
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ValueListenableBuilder<List<HomeNotification>>(
                      valueListenable: notifications,
                      builder: (context, list, _) {
                        return ValueListenableBuilder<bool>(
                          valueListenable: isLoading,
                          builder: (context, loading, __) {
                            return ValueListenableBuilder<String?>(
                              valueListenable: error,
                              builder: (context, errorMessage, ___) {
                                return SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: _NotificationSection(
                                    notifications: list,
                                    isLoading: loading,
                                    error: errorMessage,
                                    onRetry: onRetry,
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  final VoidCallback? onTap;

  const _ProfileAvatar({Key? key, this.avatarUrl, this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(32),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          width: 56,
          height: 56,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
            ),
            child: CircleAvatar(
              backgroundColor: Colors.black,
              backgroundImage: hasAvatar
                  ? NetworkImage(_resolveImageUrl(avatarUrl!))
                  : null,
              child: hasAvatar
                  ? null
                  : const Icon(Iconsax.user, color: Colors.white70, size: 26),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryItem {
  final String title;
  final String? price;
  final String? imageUrl;
  final String fallbackAsset;
  final bool isLoading;
  final String categoryName;
  final String? categorySlug;
  final String? heroTag;
  final FeaturedProduct? featured;

  const _StoryItem({
    required this.title,
    required this.fallbackAsset,
    required this.categoryName,
    this.categorySlug,
    this.price,
    this.imageUrl,
    this.isLoading = false,
    this.heroTag,
    this.featured,
  });
}

class _StoryChip extends StatelessWidget {
  final String title;
  final String? price;
  final String? imageUrl;
  final String fallbackAsset;
  final bool highlight;
  final double size;
  final bool isLoading;
  final VoidCallback? onTap;
  final String? heroTag;

  const _StoryChip({
    required this.title,
    required this.fallbackAsset,
    this.price,
    this.imageUrl,
    this.highlight = false,
    this.size = 72,
    this.isLoading = false,
    this.onTap,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final ringWidth = size * 0.06;
    final textWidth = size + 20;
    final fontSize = size <= 60 ? 11.0 : 12.0;
    final palette =
        Theme.of(context).extension<AppPalette>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? AppPalette.dark
            : AppPalette.light);

    Widget imageChild;
    if (isLoading) {
      imageChild = Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              palette.storyGradientStart.withOpacity(0.3),
              palette.storyGradientEnd.withOpacity(0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      final resolved = _resolveImageUrl(imageUrl!);
      imageChild = CachedNetworkImage(
        imageUrl: resolved,
        width: size,
        height: size,
        filterQuality: FilterQuality.high,
        fit: BoxFit.cover,
        imageBuilder: (_, imageProvider) => ClipOval(
          child: FittedBox(
            fit: BoxFit.cover,
            child: Image(image: imageProvider, width: size, height: size),
          ),
        ),
        placeholder: (_, __) => ClipOval(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  palette.storyGradientStart.withOpacity(0.3),
                  palette.storyGradientEnd.withOpacity(0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => ClipOval(
          child: Image.asset(
            fallbackAsset,
            fit: BoxFit.cover,
            width: size,
            height: size,
          ),
        ),
      );
    } else {
      imageChild = ClipOval(
        child: Image.asset(
          fallbackAsset,
          fit: BoxFit.cover,
          width: size,
          height: size,
        ),
      );
    }

    Widget avatar = Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(ringWidth / 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: highlight
            ? const LinearGradient(
                colors: [
                  Color(0xFFFFC107),
                  Color(0xFFFF6B00),
                  Color(0xFFFA00A1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  palette.storyGradientStart.withOpacity(0.4),
                  palette.storyGradientEnd.withOpacity(0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.all(ringWidth / 2),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
        ),
        child: ClipOval(child: imageChild),
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(size * 0.5),
        splashColor: Colors.white12,
        highlightColor: Colors.white10,
        child: Container(
          margin: const EdgeInsets.only(right: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              avatar,
              const SizedBox(height: 8),
              Container(
                width: textWidth,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (price != null && price!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          price!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: fontSize - 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final HomeCategory category;
  final String fallbackAsset;

  const _CategoryCard({required this.category, required this.fallbackAsset});

  @override
  Widget build(BuildContext context) {
    final categoryDescription = category.description?.trim();
    final subtitle =
        (categoryDescription != null && categoryDescription.isNotEmpty)
        ? categoryDescription
        : 'Curated experiences from Toonga';

    final palette =
        Theme.of(context).extension<AppPalette>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? AppPalette.dark
            : AppPalette.light);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: -6,
          ),
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 38,
            offset: const Offset(0, 16),
            spreadRadius: -12,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox.expand(
          child: InkWell(
            onTap: () {
              final slug = (category.slug ?? '').toLowerCase();
              if (slug == 'beverage') {
                Navigator.pushNamed(context, '/products/beverage');
              } else if (slug == 'night-life' || slug == 'nightlife') {
                Navigator.pushNamed(context, '/reels');
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryProductsScreen(
                      slug: slug,
                      title: category.name,
                    ),
                  ),
                );
              }
            },
            child: Stack(
              children: [
                // Soft glow tint behind content
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.14),
                          Colors.transparent,
                        ],
                        center: const Alignment(0, -0.6),
                        radius: 1.2,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Theme.of(context).brightness == Brightness.light
                      ? Image.asset(
                          'assets/images/yellow_bg.png',
                          fit: BoxFit.cover,
                          color: Colors.black.withOpacity(0.04),
                          colorBlendMode: BlendMode.darken,
                        )
                      : _buildImage(),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).brightness == Brightness.light
                              ? Colors.white.withOpacity(0.22)
                              : Colors.black.withOpacity(0.08),
                          Theme.of(context).brightness == Brightness.light
                              ? Colors.white.withOpacity(0.32)
                              : Colors.black.withOpacity(0.65),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                category.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.18),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Explore',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    final primary = category.featuredImage ?? category.iconUrl;

    if (primary != null && primary.isNotEmpty) {
      final resolved = _resolveImageUrl(primary);
      return CachedNetworkImage(
        imageUrl: resolved,
        fit: BoxFit.cover,
        placeholder: (context, _) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white10, Colors.white12],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => _fallbackImage(),
      );
    }
    return _fallbackImage();
  }

  Widget _fallbackImage() => Image.asset(
    fallbackAsset,
    fit: BoxFit.cover,
    alignment: Alignment.center,
  );
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Key? reelsNavKey;
  final int cartCount;

  const _BottomNav({
    required this.currentIndex,
    required this.onTap,
    this.reelsNavKey,
    this.cartCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final palette =
        Theme.of(context).extension<AppPalette>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? AppPalette.dark
            : AppPalette.light);
    final items = [
      Icons.home_rounded,
      Icons.shopping_bag_outlined,
      Icons.play_circle_fill,
      Icons.account_balance_wallet_outlined,
      Icons.person_outline,
    ];
    final labels = ['Home', 'Cart', 'Reels', 'Pay', 'Profile'];
    final bgColor = palette.navBackground;
    final borderColor = palette.navBorder;
    const activeColor = AppColors.primary;
    final inactiveColor = palette.navText.withOpacity(0.62);

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(10, 0, 10, 4),
      bottom: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final selected = currentIndex == index;
            final color = selected ? activeColor : inactiveColor;

            Widget content = InkWell(
              onTap: () => onTap(index),
              borderRadius: BorderRadius.circular(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected
                              ? activeColor.withOpacity(0.16)
                              : Colors.transparent,
                        ),
                        child: Icon(items[index], size: 20, color: color),
                      ),
                      if (index == 1 && cartCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.45),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              cartCount > 99 ? '99+' : '$cartCount',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[index],
                    style: TextStyle(
                      color: color,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            );

            if (reelsNavKey != null && index == 2) {
              content = KeyedSubtree(key: reelsNavKey, child: content);
            }

            return Expanded(child: content);
          }),
        ),
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final int count;
  final int activeIndex;

  const _DotsIndicator({required this.count, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [AppColors.primary, Colors.orange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isActive ? null : Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(999),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

String _resolveImageUrl(String raw) {
  if (raw.startsWith('http')) return raw;
  final baseUri = Uri.parse(ApiConfig.baseUrl);
  final origin =
      '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}';
  if (raw.startsWith('/')) return '$origin$raw';
  return '$origin/$raw';
}

class _HomeShimmerPlaceholder extends StatefulWidget {
  const _HomeShimmerPlaceholder();

  @override
  State<_HomeShimmerPlaceholder> createState() =>
      _HomeShimmerPlaceholderState();
}

class _HomeShimmerPlaceholderState extends State<_HomeShimmerPlaceholder>
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
        final shimmer = (_controller.value * 2) - 1;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _shimmerBlock(
              shimmerPosition: shimmer,
              height: 200,
              borderRadius: 22,
            ),
            const SizedBox(height: 16),
            _shimmerBlock(
              shimmerPosition: shimmer,
              height: 14,
              width: 220,
              borderRadius: 10,
            ),
            const SizedBox(height: 10),
            _shimmerBlock(
              shimmerPosition: shimmer,
              height: 12,
              width: 140,
              borderRadius: 8,
            ),
            const SizedBox(height: 18),
            _shimmerRow(shimmer),
            const SizedBox(height: 14),
            _shimmerRow(shimmer),
            const SizedBox(height: 14),
            _shimmerRow(shimmer),
            const SizedBox(height: 14),
            _shimmerRow(shimmer),
            const SizedBox(height: 14),
            _shimmerRow(shimmer),
          ],
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
