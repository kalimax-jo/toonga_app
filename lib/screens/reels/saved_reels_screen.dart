import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../models/reel.dart';
import '../../services/reels_service.dart';
import '../../services/session_manager.dart';
import '../../theme/app_colors.dart';
import 'reels_screen.dart';
import '../../services/api_config.dart';
import '../../services/cart_service.dart';
import '../cart/cart_screen.dart';

class SavedReelsScreen extends StatefulWidget {
  const SavedReelsScreen({super.key});

  @override
  State<SavedReelsScreen> createState() => _SavedReelsScreenState();
}

class _SavedReelsScreenState extends State<SavedReelsScreen> {
  final ReelsService _service = ReelsService();
  List<Reel> _saved = const [];
  String _query = '';
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  bool _isAuthed = false;
  final CartService _cartService = CartService.instance;
  int _cartCount = 0;

  @override
  void initState() {
    super.initState();
    _cartCount = _cartService.totalItems;
    _refreshAuth();
    _load();
    _cartService.totalItemsNotifier.addListener(_handleCartCount);
  }

  @override
  void dispose() {
    _cartService.totalItemsNotifier.removeListener(_handleCartCount);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _saved = const [];
    });
    try {
      final token = await SessionManager.instance.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _error = 'Please log in to view saved reels';
          _saved = const [];
        });
        return;
      }
      final saved = await _service.fetchSavedReels();
      if (!mounted) return;
      setState(() {
        _saved = saved;
        _error = saved.isEmpty ? 'No saved reels yet' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Saved Reels',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: _FooterNav(
            currentIndex: 3,
            onTap: _handleNavTap,
            cartCount: _cartCount,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
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
    final filtered = _query.isEmpty
        ? _saved
        : _saved
            .where((r) =>
                r.title.toLowerCase().contains(_query.toLowerCase()) ||
                r.description.toLowerCase().contains(_query.toLowerCase()) ||
                (r.vendorName?.toLowerCase().contains(_query.toLowerCase()) ??
                    false))
            .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            cursorColor: AppColors.primary,
            onChanged: (value) {
              setState(() => _query = value.trim());
            },
            decoration: InputDecoration(
              hintText: 'Search saved reels',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Iconsax.search_normal,
                  color: Colors.white70, size: 18),
              filled: true,
              fillColor: Colors.white10,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 9 / 16,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final reel = filtered[index];
              final originalIndex = _saved.indexOf(reel);
              return _SavedTile(
                reel: reel,
                onTap: () =>
                    _openReel(originalIndex >= 0 ? originalIndex : index),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openReel(int index) {
    if (_saved.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReelsScreen(
          initialReels: _saved,
          initialIndex: index,
        ),
      ),
    );
  }

  Future<void> _refreshAuth() async {
    final token = await SessionManager.instance.getToken();
    if (!mounted) return;
    setState(() => _isAuthed = token != null && token.isNotEmpty);
  }

  void _handleCartCount() {
    if (!mounted) return;
    setState(() {
      _cartCount = _cartService.totalItems;
    });
  }

  void _handleNavTap(int index) {
    if (index == 3) return; // already on Saved
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }
    if (index == 2) {
      Navigator.pushReplacementNamed(context, '/reels');
      return;
    }
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CartScreen()),
      );
      return;
    }
    if (index == 4) {
      if (_isAuthed) {
        Navigator.pushNamed(context, '/profile');
      } else {
        Navigator.pushNamed(context, '/login').then((_) => _refreshAuth());
      }
      return;
    }
  }
}

class _SavedTile extends StatelessWidget {
  final Reel reel;
  final VoidCallback? onTap;

  const _SavedTile({required this.reel, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: Colors.white10,
              child: _buildThumb(),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Iconsax.video, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Reel',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    reel.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Iconsax.eye, size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          _formatCount(reel.viewsCount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

  Widget _fallback() => Container(
        color: Colors.white12,
        alignment: Alignment.center,
        child: const Icon(Iconsax.gallery, color: Colors.white54),
      );

  Widget _buildThumb() {
    final raw = reel.thumbnailUrl?.isNotEmpty == true
        ? reel.thumbnailUrl
        : reel.thumbnail?.isNotEmpty == true
            ? reel.thumbnail
            : reel.videoUrl;
    if (raw == null || raw.isEmpty) return _fallback();
    final url = _resolveImageUrl(raw);
    // Debug hint: log once per tile for easier troubleshooting.
    // ignore: avoid_print
    print('Saved reel thumb -> $url');
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallback(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Colors.white12,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        );
      },
    );
  }

  String _formatCount(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }

  String _resolveImageUrl(String raw) {
    if (raw.startsWith('http')) return raw;
    final baseUri = Uri.parse(ApiConfig.baseUrl);
    final origin =
        '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}';

    // Already storage-relative
    if (raw.startsWith('/storage/')) return '$origin$raw';
    if (raw.startsWith('storage/')) return '$origin/$raw';

    // If the backend sends a reels/ path (e.g., reels/thumbs/...) prefix storage
    if (raw.startsWith('reels/')) return '$origin/storage/$raw';

    // Bare filename: assume it lives in reels/thumbs
    if (!raw.startsWith('/')) return '$origin/storage/reels/thumbs/$raw';

    // Fallback: prefix origin
    return '$origin$raw';
  }
}

class _FooterNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int cartCount;

  const _FooterNav({
    required this.currentIndex,
    required this.onTap,
    this.cartCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      Icons.home_rounded,
      Icons.shopping_bag_outlined,
      Icons.play_circle_fill,
      Icons.bookmark,
      Icons.person_outline,
    ];
    final labels = ['Home', 'Cart', 'Reels', 'Saved', 'Profile'];
    const bgColor = Color(0xFF0F0F0F);
    final borderColor = Colors.white.withOpacity(0.06);
    const activeColor = AppColors.primary;
    final inactiveColor = Colors.white.withOpacity(0.62);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
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
          return Expanded(
            child: InkWell(
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
                        child: Icon(
                          items[index],
                          size: 20,
                          color: color,
                        ),
                      ),
                      if (index == 1 && cartCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withOpacity(0.45),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
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
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
