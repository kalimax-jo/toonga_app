import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/reel.dart';
import '../../models/reel_comment.dart';
import '../../services/reels_service.dart';
import '../../services/session_manager.dart';
import '../../services/api_config.dart';
import '../../theme/app_colors.dart';
import '../../services/cart_service.dart';
import '../cart/cart_screen.dart';
import 'reel_offer_placeholder.dart';

class ReelsScreen extends StatefulWidget {
  final List<Reel>? initialReels;
  final int initialIndex;

  const ReelsScreen({
    super.key,
    this.initialReels,
    this.initialIndex = 0,
  });

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final ReelsService _service = ReelsService();
  final PageController _pageController = PageController();
  final ValueNotifier<bool> _pauseNotifier = ValueNotifier<bool>(false);
  final CartService _cartService = CartService.instance;
  int _cartCount = 0;

  List<Reel> _reels = const [];
  bool _loading = true;
  String? _error;
  final Set<int> _viewed = <int>{};
  Timer? _viewTimer;
  int _currentIndex = 0;
  bool _isAuthed = false;

  @override
  void initState() {
    super.initState();
    _refreshAuth();
    _cartCount = _cartService.totalItems;
    _cartService.totalItemsNotifier.addListener(_handleCartCount);
    if (widget.initialReels != null && widget.initialReels!.isNotEmpty) {
      _reels = widget.initialReels!;
      _loading = false;
      _error = null;
      final startIndex = widget.initialIndex.clamp(0, _reels.length - 1);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pageController.jumpToPage(startIndex);
        _handlePageChanged(startIndex);
      });
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _viewTimer?.cancel();
    _pageController.dispose();
    _pauseNotifier.dispose();
    _cartService.totalItemsNotifier.removeListener(_handleCartCount);
    super.dispose();
  }

  Future<void> _load() async {
    // If we already have initial reels provided, skip refetch.
    if (widget.initialReels != null && widget.initialReels!.isNotEmpty) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _viewed.clear();
      _viewTimer?.cancel();
    });
    try {
      final result = await _service.fetchReels(activeOnly: true);
    if (!mounted) return;
    setState(() {
      _reels = result.reels;
      _error = result.reels.isEmpty ? (result.error ?? 'Reels not available') : null;
    });
    if (result.reels.isNotEmpty) {
      _cacheReelAssets(result.reels);
      _handlePageChanged(0);
    }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _refreshAuth() async {
    final token = await SessionManager.instance.getToken();
    if (!mounted) return;
    setState(() => _isAuthed = token != null && token.isNotEmpty);
  }

  void _handlePageChanged(int index) {
    _currentIndex = index;
    _viewTimer?.cancel();
    if (index < 0 || index >= _reels.length) return;
    final reel = _reels[index];
    if (_viewed.contains(reel.id)) return;
    _viewTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (_currentIndex != index) return;
      _viewed.add(reel.id);
      _service.sendView(reel.id);
    });
    _precacheThumbnailAt(index + 1);
    _ensureFollowState(index);
  }

  Future<void> _handleLike(int index) async {
    if (index < 0 || index >= _reels.length) return;
    if (!_isAuthed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to like')),
      );
      Navigator.pushNamed(context, '/login').then((_) => _refreshAuth());
      return;
    }
    final reel = _reels[index];
    try {
      final result = await _service.toggleLike(reel.id);
      if (!mounted) return;
      setState(() {
        _reels = List<Reel>.from(_reels)
          ..[index] = Reel(
            id: reel.id,
            title: reel.title,
            description: reel.description,
            videoUrl: reel.videoUrl,
            videoType: reel.videoType,
            thumbnail: reel.thumbnail,
            thumbnailUrl: reel.thumbnailUrl,
            viewsCount: reel.viewsCount,
            likesCount: result.likesCount,
            commentsCount: reel.commentsCount,
            savesCount: reel.savesCount,
            isSavedByUser: reel.isSavedByUser,
            isLikedByUser: result.isLiked,
            vendorId: reel.vendorId,
            vendorName: reel.vendorName,
            isFollowingVendor: reel.isFollowingVendor,
            productName: reel.productName,
            offer: reel.offer,
          );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _handleSave(int index) async {
    if (index < 0 || index >= _reels.length) return;
    if (!_isAuthed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save')),
      );
      Navigator.pushNamed(context, '/login').then((_) => _refreshAuth());
      return;
    }
    final reel = _reels[index];
    try {
      final result = await _service.toggleSave(reel.id);
      if (!mounted) return;
      setState(() {
        _reels = List<Reel>.from(_reels)
          ..[index] = Reel(
            id: reel.id,
            title: reel.title,
            description: reel.description,
            videoUrl: reel.videoUrl,
            videoType: reel.videoType,
            thumbnail: reel.thumbnail,
            thumbnailUrl: reel.thumbnailUrl,
            viewsCount: reel.viewsCount,
            likesCount: reel.likesCount,
            commentsCount: reel.commentsCount,
            savesCount: result.savesCount,
            isSavedByUser: result.isSaved,
            isLikedByUser: reel.isLikedByUser,
            vendorId: reel.vendorId,
            vendorName: reel.vendorName,
            isFollowingVendor: reel.isFollowingVendor,
            productName: reel.productName,
            offer: reel.offer,
          );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _handleFollow(Reel reel) async {
    if (!_isAuthed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to follow')),
      );
      Navigator.pushNamed(context, '/login').then((_) => _refreshAuth());
      return;
    }
    final idx = _reels.indexWhere((r) => r.id == reel.id);
    if (idx == -1) return;
    final next = !(reel.isFollowingVendor ?? false);
    setState(() {
      _reels = List<Reel>.from(_reels)
        ..[idx] = Reel(
          id: reel.id,
          title: reel.title,
          description: reel.description,
          videoUrl: reel.videoUrl,
          videoType: reel.videoType,
          viewsCount: reel.viewsCount,
          likesCount: reel.likesCount,
          commentsCount: reel.commentsCount,
          savesCount: reel.savesCount,
          isSavedByUser: reel.isSavedByUser,
          isLikedByUser: reel.isLikedByUser,
          vendorId: reel.vendorId,
          vendorName: reel.vendorName,
          isFollowingVendor: next,
          productName: reel.productName,
          offer: reel.offer,
        );
    });
    if (reel.vendorId == null) return;
    try {
      final result =
          await _service.toggleFollow(reel.vendorId!, isFollowing: reel.isFollowingVendor ?? false);
      if (!mounted) return;
      setState(() {
        _reels = List<Reel>.from(_reels)
          ..[idx] = Reel(
            id: reel.id,
            title: reel.title,
            description: reel.description,
            videoUrl: reel.videoUrl,
            videoType: reel.videoType,
            thumbnail: reel.thumbnail,
            thumbnailUrl: reel.thumbnailUrl,
            viewsCount: reel.viewsCount,
            likesCount: reel.likesCount,
            commentsCount: reel.commentsCount,
            savesCount: reel.savesCount,
            isSavedByUser: reel.isSavedByUser,
            isLikedByUser: reel.isLikedByUser,
            vendorId: reel.vendorId,
            vendorName: reel.vendorName,
            isFollowingVendor: result.isFollowing,
            productName: reel.productName,
            offer: reel.offer,
          );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _openComments(Reel reel) async {
    final token = await SessionManager.instance.getToken();
    final bool isAuthed = token != null && token.isNotEmpty;
    final controller = TextEditingController();
    List<ReelComment> comments = const [];
    bool loading = true;
    String? error;
    bool posting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        void loadComments(StateSetter setModalState) async {
          setModalState(() {
            loading = true;
            error = null;
          });
          try {
            final list = await _service.fetchComments(reel.id);
            setModalState(() => comments = list);
          } catch (e) {
            setModalState(() => error = e.toString());
          } finally {
            setModalState(() => loading = false);
          }
        }

        Future<void> postComment(StateSetter setModalState) async {
          if (!isAuthed) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please log in to comment')),
            );
            Navigator.pushNamed(context, '/login');
            return;
          }
          final text = controller.text.trim();
          if (text.isEmpty) return;
          setModalState(() => posting = true);
          try {
            final newComment =
                await _service.addComment(reel.id, comment: text);
            setModalState(() {
              comments = List<ReelComment>.from(comments)..insert(0, newComment);
              controller.clear();
            });
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString())),
            );
          } finally {
            setModalState(() => posting = false);
          }
        }

        return StatefulBuilder(
          builder: (context, setModalState) {
            if (loading && error == null && comments.isEmpty) {
              loadComments(setModalState);
            }
            final viewInsets = MediaQuery.of(context).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.only(bottom: viewInsets),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.65,
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Comments',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
                          ),
                          if (loading)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                error!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => loadComments(setModalState),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: comments.isEmpty && !loading
                          ? const Center(
                              child: Text(
                                'No comments yet',
                                style:
                                    TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              itemBuilder: (_, i) {
                                final c = comments[i];
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor:
                                              Colors.white.withOpacity(0.12),
                                          child: const Icon(
                                            Iconsax.user,
                                            size: 14,
                                            color: Colors.white70,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            c.userName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        if (c.createdAt != null)
                                          Text(
                                            _timeAgo(c.createdAt!),
                                            style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 11),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      c.comment,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                );
                              },
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 14),
                              itemCount: comments.length,
                            ),
                    ),
                    const Divider(color: Colors.white12, height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              enabled: isAuthed,
                              style: const TextStyle(color: Colors.white),
                              maxLines: 2,
                              minLines: 1,
                              decoration: InputDecoration(
                                hintText: isAuthed
                                    ? 'Add a comment...'
                                    : 'Sign in to comment',
                                hintStyle: const TextStyle(color: Colors.white54),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.08),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide:
                                      BorderSide(color: Colors.white.withOpacity(0.1)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide:
                                      BorderSide(color: Colors.white.withOpacity(0.1)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            onPressed: posting || !isAuthed
                                ? null
                                : () => postComment(setModalState),
                            icon: posting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.primary),
                                    ),
                                  )
                                : const Icon(Iconsax.send_2,
                                    color: AppColors.primary),
                          ),
                        ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        bottom: false,
        child: _buildBody(),
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
      return _ErrorView(message: _error!, onRetry: _load);
    }
    if (_reels.isEmpty) {
      return _ErrorView(
        message: 'No reels available',
        onRetry: _load,
      );
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          onPageChanged: _handlePageChanged,
          itemCount: _reels.length,
          itemBuilder: (context, index) {
            final reel = _reels[index];
            return _ReelItem(
              reel: reel,
              onLike: () => _handleLike(index),
              onComments: () => _openComments(reel),
              onSave: () => _handleSave(index),
              onFollow: () => _handleFollow(reel),
              pauseNotifier: _pauseNotifier,
            );
          },
        ),
        Positioned(
          top: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Image.asset(
                'assets/images/logo.png',
                height: 32,
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 12,
          child: SafeArea(
            top: false,
            child: _FooterNav(
              currentIndex: 2,
              onTap: _handleNavTap,
              cartCount: _cartCount,
            ),
          ),
        ),
      ],
    );
  }

  void _handleNavTap(int index) {
    if (index == 2) return; // Already on Reels
    _pauseNotifier.value = true;
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CartScreen()),
      );
      return;
    }
    if (index == 3) {
      if (_isAuthed) {
        Navigator.pushNamed(context, '/reels/saved');
      } else {
        Navigator.pushNamed(context, '/login').then((_) => _refreshAuth());
      }
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon')),
    );
  }

  void _handleCartCount() {
    if (!mounted) return;
    setState(() {
      _cartCount = _cartService.totalItems;
    });
  }

  Future<void> _ensureFollowState(int index) async {
    if (index < 0 || index >= _reels.length) return;
    final reel = _reels[index];
    if (reel.vendorId == null) return;
    if (!_isAuthed && reel.isFollowingVendor != null) return;
    if (_isAuthed && reel.isFollowingVendor != null) return;
    final status = await _service.fetchFollowStatus(reel.vendorId!);
    if (!mounted || status == null) return;
    setState(() {
      _reels = List<Reel>.from(_reels)
        ..[index] = Reel(
          id: reel.id,
          title: reel.title,
          description: reel.description,
          videoUrl: reel.videoUrl,
          videoType: reel.videoType,
          thumbnail: reel.thumbnail,
          thumbnailUrl: reel.thumbnailUrl,
          viewsCount: reel.viewsCount,
          likesCount: reel.likesCount,
          commentsCount: reel.commentsCount,
          savesCount: reel.savesCount,
          isSavedByUser: reel.isSavedByUser,
          isLikedByUser: reel.isLikedByUser,
          vendorId: reel.vendorId,
          vendorName: reel.vendorName,
          isFollowingVendor: status,
          productName: reel.productName,
          offer: reel.offer,
      );
    });
  }

  Future<void> _cacheReelAssets(List<Reel> reels) async {
    for (final reel in reels) {
      final thumb = reel.thumbnailUrl ?? reel.thumbnail;
      if (thumb != null && thumb.isNotEmpty) {
        await precacheImage(NetworkImage(thumb), context);
      }
    }
  }

  void _precacheThumbnailAt(int index) {
    if (index < 0 || index >= _reels.length) return;
    final thumb = _reels[index].thumbnailUrl ?? _reels[index].thumbnail;
    if (thumb != null && thumb.isNotEmpty) {
      precacheImage(NetworkImage(thumb), context);
    }
  }
}

class _ReelItem extends StatefulWidget {
  final Reel reel;
  final VoidCallback onLike;
  final VoidCallback onComments;
  final VoidCallback onSave;
  final VoidCallback onFollow;
  final ValueNotifier<bool> pauseNotifier;

  const _ReelItem({
    required this.reel,
    required this.onLike,
    required this.onComments,
    required this.onSave,
    required this.onFollow,
    required this.pauseNotifier,
  });

  @override
  State<_ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<_ReelItem> {
  VideoPlayerController? _controller;
  bool _isReady = false;
  bool _isPaused = false;
  bool _isMuted = false;
  bool _inlinePlayable = false;
  bool _unsupported = false;
  bool _missing = false;
  VoidCallback? _pauseListener;

  @override
  void initState() {
    super.initState();
    _pauseListener = () {
      if (widget.pauseNotifier.value) {
        _forcePause();
      }
    };
    widget.pauseNotifier.addListener(_pauseListener!);
    _initPlayer();
  }

  @override
  void didUpdateWidget(covariant _ReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pauseNotifier != widget.pauseNotifier) {
      oldWidget.pauseNotifier.removeListener(_pauseListener!);
      widget.pauseNotifier.addListener(_pauseListener!);
    }
    if (oldWidget.reel.videoUrl != widget.reel.videoUrl ||
        oldWidget.reel.videoType != widget.reel.videoType) {
      _disposePlayer();
      _initPlayer();
    }
  }

  @override
  void dispose() {
    if (_pauseListener != null) {
      widget.pauseNotifier.removeListener(_pauseListener!);
    }
    _disposePlayer();
    super.dispose();
  }

  @override
  void deactivate() {
    // Pause when the widget is removed from the tree (navigating away).
    if (_controller != null && _controller!.value.isPlaying) {
      _controller!.pause();
      _isPaused = true;
    }
    super.deactivate();
  }

  Future<void> _initPlayer() async {
    final reel = widget.reel;
    final url = reel.videoUrl;
    if (url == null || url.isEmpty) {
      setState(() {
        _missing = true;
        _isReady = true;
      });
      return;
    }
    _inlinePlayable = reel.playsInline;
    if (!_inlinePlayable) {
      setState(() {
        _unsupported = true;
        _isReady = true;
      });
      return;
    }
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _controller = controller;
      await controller.initialize();
      controller
        ..setLooping(true)
        ..setVolume(_isMuted ? 0 : 1)
        ..play();
      if (mounted) {
        setState(() => _isReady = true);
      }
    } catch (_) {
      _disposePlayer();
      if (mounted) {
        setState(() {
          _unsupported = true;
          _isReady = true;
        });
      }
    }
  }

  void _disposePlayer() {
    _controller?.dispose();
    _controller = null;
    _isReady = false;
    _isPaused = false;
    _isMuted = false;
    _inlinePlayable = false;
    _unsupported = false;
    _missing = false;
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null) return;
    if (controller.value.isPlaying) {
      controller.pause();
      setState(() => _isPaused = true);
    } else {
      controller.play();
      setState(() => _isPaused = false);
    }
  }

  void _forcePause() {
    final controller = _controller;
    if (controller == null) return;
    if (controller.value.isPlaying) {
      controller.pause();
      setState(() => _isPaused = true);
    }
  }

  void _toggleMute() {
    final controller = _controller;
    if (controller == null) return;
    final nextMuted = !_isMuted;
    controller.setVolume(nextMuted ? 0 : 1);
    setState(() => _isMuted = nextMuted);
  }

  void _handleSave() {
    widget.onSave();
  }

  static const String _androidPlayStoreUrl =
      'https://play.google.com/store/apps/details?id=com.toongapp';
  static const String _iosAppStoreUrl = 'https://apps.apple.com/app/toonga';

  String _deepLink(int reelId) => 'toonga://reels/$reelId';

  void _handleShare() {
    final reel = widget.reel;
    final text = '${reel.title}\n${reel.description}'.trim();
    final webLink = _shareLink(reel.id);
    final deepLink = _deepLink(reel.id);
    final storeLink = Platform.isIOS ? _iosAppStoreUrl : _androidPlayStoreUrl;
    final messageParts = <String>[
      if (text.isNotEmpty) text,
      'Open this reel in Toonga: $deepLink',
      'Install Toonga: $storeLink',
      'Or view online: $webLink',
    ];
    Share.share(
      messageParts.join('\n\n').trim(),
      subject: reel.title,
    );
  }

  Future<void> _openExternal() async {
    final url = widget.reel.videoUrl;
    if (url == null || url.isEmpty) return;
    try {
      await launchUrlString(
        url,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;
    return GestureDetector(
      onTap: _inlinePlayable ? _togglePlay : null,
      onDoubleTap: widget.onLike,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildMedia(reel),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.65),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 80,
            bottom: 99,
            child: _ReelInfo(
              reel: reel,
              onFollow: widget.onFollow,
            ),
          ),
          Positioned(
            right: 16,
            bottom: 99,
            child: _ActionRail(
              reel: reel,
              isPaused: _controller != null && !_controller!.value.isPlaying,
              isExternal: reel.isExternal,
              isMuted: _isMuted,
              onLike: widget.onLike,
              onOpenExternal: _openExternal,
              onToggleMute: _toggleMute,
              onSave: _handleSave,
              onShare: _handleShare,
              onComments: widget.onComments,
            ),
          ),
          if (_controller != null && !_isReady)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          if (_isPaused && _controller != null)
            const Center(
              child: Icon(Iconsax.play, color: Colors.white70, size: 72),
            ),
        ],
      ),
    );
  }

  Widget _buildMedia(Reel reel) {
    if (_missing) {
      return _fallbackMessage('No video found for this reel');
    }
    if (_unsupported && reel.isExternal) {
      return _fallbackMessage(
        'This reel opens externally',
        action: ElevatedButton(
          onPressed: _openExternal,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
          ),
          child: const Text('Open'),
        ),
      );
    }
    if (_unsupported) {
      return _fallbackMessage('Unsupported video format');
    }
    if (reel.videoUrl != null && _controller != null && _isReady) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() => Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: const Icon(Iconsax.gallery, color: Colors.white30, size: 48),
      );

  Widget _fallbackMessage(String message, {Widget? action}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _fallback(),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              if (action != null) ...[
                const SizedBox(height: 12),
                action,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ReelInfo extends StatelessWidget {
  final Reel reel;
  final VoidCallback? onFollow;

  const _ReelInfo({required this.reel, this.onFollow});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (reel.vendorName != null && reel.vendorName!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '@${reel.vendorName}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(width: 10),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    backgroundColor: reel.isFollowingVendor == true
                        ? AppColors.primary
                        : Colors.white.withOpacity(0.12),
                    foregroundColor:
                        reel.isFollowingVendor == true ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: onFollow,
                  child: Text(
                    reel.isFollowingVendor == true ? 'Following' : 'Follow',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Text(
          reel.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        if (reel.description.isNotEmpty)
          Text(
            reel.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        const SizedBox(height: 12),
        _buildCta(reel, context),
      ],
    );
  }

  Widget _buildCta(Reel reel, BuildContext context) {
    final offer = reel.offer;
    if (offer == null || (offer.title == null && offer.ctaLabel == null)) {
      return const SizedBox.shrink();
    }
    final label = offer.ctaLabel ?? 'View offer';
    final subtitle = offer.subtitle ?? offer.title ?? '';
    final priceText = _formatOfferPrice(offer);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReelOfferPlaceholderScreen(
              title: offer.title ?? label,
              subtitle: subtitle.isNotEmpty
                  ? subtitle
                  : 'Enjoy a curated experience with Toonga.',
              price: priceText,
              imageUrl: reel.thumbnailUrl ?? reel.thumbnail,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.2),
                ),
                child: Icon(
                Iconsax.bag,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                if (subtitle.isNotEmpty || priceText != null)
                  Text(
                    subtitle.isNotEmpty
                        ? subtitle
                        : (priceText ?? ''),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white70, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _pill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }
}

class _ActionRail extends StatelessWidget {
  final Reel reel;
  final bool isPaused;
  final bool isExternal;
  final bool isMuted;
  final VoidCallback onLike;
  final VoidCallback onComments;
  final VoidCallback onToggleMute;
  final VoidCallback onOpenExternal;
  final VoidCallback onSave;
  final VoidCallback onShare;

  const _ActionRail({
    required this.reel,
    required this.isPaused,
    required this.isExternal,
    required this.isMuted,
    required this.onLike,
    required this.onComments,
    required this.onToggleMute,
    required this.onOpenExternal,
    required this.onSave,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CircleButton(
          icon: reel.isLikedByUser ? Iconsax.heart5 : Iconsax.heart,
          color: reel.isLikedByUser ? accent : Colors.white,
          label: _format(reel.likesCount),
          onTap: onLike,
        ),
        const SizedBox(height: 10),
        _CircleButton(
          icon: Iconsax.message,
          color: Colors.white,
          label: _format(reel.commentsCount),
          onTap: onComments,
        ),
        const SizedBox(height: 10),
        _CircleButton(
          icon: Iconsax.export_1,
          color: Colors.white,
          label: 'Share',
          onTap: onShare,
        ),
        const SizedBox(height: 10),
        _CircleButton(
          icon: reel.isSavedByUser ? Icons.bookmark : Icons.bookmark_border,
          color: reel.isSavedByUser ? accent : Colors.white,
          label: reel.isSavedByUser ? 'Saved' : 'Save',
          onTap: onSave,
        ),
        const SizedBox(height: 10),
        _CircleButton(
          icon: isExternal
              ? Iconsax.link
              : isMuted
                  ? Icons.volume_off
                  : Icons.volume_up,
          color: Colors.white,
          label: isExternal
              ? 'Open'
              : isMuted
                  ? 'Unmute'
                  : 'Mute',
          onTap: isExternal ? onOpenExternal : onToggleMute,
        ),
      ],
    );
  }

  String _format(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double visualSize = 44;
    const double hitSize = 64;
    return Column(
      children: [
        SizedBox(
          width: hitSize,
          height: hitSize,
          child: Center(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onTap,
              child: Container(
                width: visualSize,
                height: visualSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.35),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: color, size: 20),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
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
                                  color: AppColors.primary.withOpacity(0.45),
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
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Unable to load reels',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
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

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Iconsax.gallery, color: Colors.white38, size: 48),
          SizedBox(height: 12),
          Text(
            'No reels yet',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

String _timeAgo(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${(diff.inDays / 7).floor()}w';
}

String _shareLink(int reelId) {
  final baseUri = Uri.parse(ApiConfig.baseUrl);
  final origin =
      '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}';
  return '$origin/reels/$reelId';
}

String? _formatOfferPrice(ReelOffer offer) {
  if (offer.price == null) return null;
  final currency = offer.currency ?? '';
  final price = offer.price!;
  final formatted = price % 1 == 0 ? price.toStringAsFixed(0) : price.toStringAsFixed(2);
  return '${currency.isNotEmpty ? '$currency ' : ''}$formatted';
}
