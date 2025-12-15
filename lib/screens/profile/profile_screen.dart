import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../models/miles_overview.dart';
import '../../models/profile_data.dart';
import '../../services/api_client.dart';
import '../../services/api_config.dart';
import '../../services/profile_service.dart';
import '../../services/session_manager.dart';
import '../../theme/app_colors.dart';
import 'endpoint_viewer_screen.dart';
import '../cart/payment_method_screen.dart';
import 'profile_detail_screen.dart';
import 'profile_edit_screen.dart';
import 'account_overview_screen.dart';
import 'miles_screen.dart';
import 'permission_settings_screen.dart';
import 'about_toonga_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_conditions_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  ProfileData? _profile;
  bool _isLoading = true;
  String? _error;
  final ApiClient _apiClient = ApiClient();
  final SessionManager _sessionManager = SessionManager.instance;
  String _milesLabel = '0 Miles';
  MilesOverview? _milesOverview;
  List<MilesHistory> _milesHistory = const [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final profile = await _profileService.fetchProfile();
      final milesOverview = await _fetchMilesOverview();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _milesOverview = milesOverview;
        if (milesOverview != null) {
          _milesLabel = '${milesOverview.available.toStringAsFixed(0)} Miles';
          _milesHistory = milesOverview.history;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Unable to load profile. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    setState(() => _isLoading = true);
    try {
      await _profileService.logout();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Logout failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<MilesOverview?> _fetchMilesOverview() async {
    final token = await _sessionManager.getToken();
    final headers = token != null ? {'Authorization': 'Bearer $token'} : null;

    try {
      final json = await _apiClient.get('/account/overview', headers: headers);
      final data =
          json['miles'] ??
          (json['data'] is Map<String, dynamic>
              ? (json['data'] as Map<String, dynamic>)['miles']
              : null);
      if (data is Map<String, dynamic>) {
        return MilesOverview.fromJson(data);
      }
    } catch (_) {
      // ignore silently
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _error != null
            ? _ErrorView(message: _error!, onRetry: _loadProfile)
            : _ProfileBody(
                profile: _profile,
                theme: theme,
                onLogout: _logout,
                onProfileUpdated: _loadProfile,
                milesLabel: _milesLabel,
                milesHistory: _milesHistory,
              ),
      ),
    );
  }
}

class _ProfileBody extends StatefulWidget {
  final ProfileData? profile;
  final ThemeData theme;
  final VoidCallback onLogout;
  final VoidCallback onProfileUpdated;
  final String milesLabel;
  final List<MilesHistory> milesHistory;

  const _ProfileBody({
    required this.profile,
    required this.theme,
    required this.onLogout,
    required this.onProfileUpdated,
    required this.milesLabel,
    required this.milesHistory,
  });

  @override
  State<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<_ProfileBody> {
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    final name = widget.profile?.name ?? 'Guest';
    final email = widget.profile?.email ?? 'No email linked';
    final avatar = widget.profile?.avatarUrl;
    final avatarImage = _resolveAvatar(avatar);
    final isDark = widget.theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1B1B1B) : Colors.white;
    final accentColor = isDark
        ? const Color(0xFF2E2E2E)
        : Colors.grey[50] ?? const Color(0xFFF1F1F1);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Iconsax.arrow_left, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Text(
                'Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _ProfileHeroCard(
            name: name,
            email: email,
            avatar: avatarImage,
            milesLabel: widget.milesLabel,
          ),
          const SizedBox(height: 16),
          _QuickActionsCard(actions: _buildQuickActions(context)),
          if (widget.milesHistory.isNotEmpty) ...[
            const SizedBox(height: 16),
            _MilesHistoryCard(history: widget.milesHistory),
          ],
          const SizedBox(height: 24),
          ..._buildMenuItems(context).map(
            (section) =>
                _ProfileSection(title: section.title, items: section.items),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: widget.onLogout,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
            icon: const Icon(Iconsax.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditProfile(BuildContext context) async {
    if (widget.profile == null) return;
    final updated = await Navigator.push<ProfileData>(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileEditScreen(profile: widget.profile!),
      ),
    );
    if (updated != null) {
      widget.onProfileUpdated();
    }
  }

  List<_ProfileSectionData> _buildMenuItems(BuildContext context) {
    void openDetail({
      required String title,
      required String description,
      String? endpoint,
    }) {
      if (endpoint != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                EndpointViewerScreen(title: title, endpoint: endpoint),
          ),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ProfileDetailScreen(title: title, description: description),
        ),
      );
    }

    return [
      _ProfileSectionData(
        title: 'General',
        items: [
          _ProfileMenuItem(
            icon: Iconsax.user_edit,
            title: 'Personal Info',
            description: 'Update your info (/auth/update-profile)',
            endpoint: '/auth/me',
            onTap: (ctx) => _openEditProfile(ctx),
          ),
          _ProfileMenuItem(
            icon: Iconsax.receipt_1,
            title: 'My Orders',
            description: 'All bookings & purchases (/orders)',
            endpoint: '/orders',
            onTap: (ctx) {
              Navigator.pushNamed(ctx, '/orders');
            },
          ),
          _ProfileMenuItem(
            icon: Iconsax.wallet_3,
            title: 'My Payments',
            description: 'Balances & transactions (/account/overview)',
            endpoint: '/account/overview',
            onTap: (ctx) {
              Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => const AccountOverviewScreen(),
                ),
              );
            },
          ),
          _ProfileMenuItem(
            icon: Iconsax.card,
            title: 'Payment Methods',
            description: 'Saved cards & wallets',
            onTap: (ctx) async {
              final method = await Navigator.push<PaymentMethod>(
                ctx,
                MaterialPageRoute(builder: (_) => const PaymentMethodScreen()),
              );
              if (method != null) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(
                      method == PaymentMethod.momo
                          ? 'MTN MoMo set as preferred payment.'
                          : 'Card will be available soon.',
                    ),
                  ),
                );
              }
            },
          ),
          _ProfileMenuItem(
            icon: Iconsax.medal_star,
            title: 'Miles history',
            description: 'View reward activity',
            onTap: (ctx) {
              Navigator.push(
                ctx,
                MaterialPageRoute(builder: (_) => const MilesScreen()),
              );
            },
          ),
        ],
      ),
      _ProfileSectionData(
        title: 'App Settings',
        items: [
          _ProfileMenuItem(
            icon: Iconsax.security_safe,
            title: 'Permissions',
            description: 'Location, camera, microphone',
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => const PermissionSettingsScreen(),
              ),
            ),
          ),
          _ProfileMenuItem(
            icon: Iconsax.personalcard,
            title: 'About Us',
            description: 'Learn more about Toonga',
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const AboutToongaScreen()),
            ),
          ),
          _ProfileMenuItem(
            icon: Iconsax.document_text,
            title: 'Privacy Policy',
            description: 'How we protect your data',
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            ),
          ),
          _ProfileMenuItem(
            icon: Iconsax.document_code,
            title: 'Terms & Conditions',
            description: 'Legal information & service terms',
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const TermsConditionsScreen()),
            ),
          ),
          _ProfileMenuItem(
            icon: Iconsax.info_circle,
            title: 'Help Center',
            description: 'Support powered by Toonga',
            onTap: (ctx) => openDetail(
              title: 'Help Center',
              description: 'Get answers, contact support, or browse FAQs.',
            ),
          ),
        ],
      ),
    ];
  }

  List<_QuickAction> _buildQuickActions(BuildContext context) {
    void openOrders() => Navigator.pushNamed(context, '/orders');
    void openPayments() => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AccountOverviewScreen()),
    );
    void openPaymentMethods() => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaymentMethodScreen()),
    );

    return [
      _QuickAction(
        label: 'My Orders',
        icon: Iconsax.receipt_1,
        onTap: openOrders,
      ),
      _QuickAction(
        label: 'My Payments',
        icon: Iconsax.wallet,
        onTap: openPayments,
      ),
      _QuickAction(
        label: 'Payment Methods',
        icon: Iconsax.card,
        onTap: openPaymentMethods,
      ),
    ];
  }

  ImageProvider? _resolveAvatar(String? path) {
    if (path == null || path.isEmpty) return null;
    final absolute = _absoluteUrl(path);
    if (absolute == null) return null;
    if (absolute.startsWith('http')) {
      return NetworkImage(absolute);
    }
    return FileImage(File(absolute));
  }

  String? _absoluteUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    if (path.startsWith('file://')) {
      return Uri.parse(path).toFilePath();
    }
    final base = Uri.parse(ApiConfig.baseUrl);
    final origin =
        '${base.scheme}://${base.host}${base.hasPort ? ':${base.port}' : ''}';
    final clean = path.startsWith('/') ? path : '/$path';
    return '$origin$clean';
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  final String name;
  final String email;
  final ImageProvider? avatar;
  final String milesLabel;

  const _ProfileHeroCard({
    required this.name,
    required this.email,
    this.avatar,
    required this.milesLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF161616), Color(0xFF0F0F0F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.card,
            backgroundImage: avatar,
            child: avatar == null
                ? const Icon(Iconsax.user, color: Colors.white54, size: 32)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.amber,
                      child: Icon(
                        Iconsax.medal_star,
                        color: Colors.black,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Miles rewards',
                      style: TextStyle(color: Colors.white60),
                    ),
                    const Spacer(),
                    Text(
                      milesLabel,
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w700,
                      ),
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

class _ProfileSectionData {
  final String title;
  final List<_ProfileMenuItem> items;

  const _ProfileSectionData({required this.title, required this.items});
}

class _ProfileMenuItem {
  final IconData icon;
  final String title;
  final String description;
  final void Function(BuildContext context) onTap;
  final String? endpoint;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.endpoint,
  });
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<_ProfileMenuItem> items;

  const _ProfileSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => _ProfileMenuTile(item: item)),
        ],
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final _ProfileMenuItem item;

  const _ProfileMenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: () => item.onTap(context),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.white.withOpacity(0.08),
          child: Icon(item.icon, color: Colors.white),
        ),
        title: Text(
          item.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          item.description,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        trailing: const Icon(Iconsax.arrow_right_3, color: Colors.white54),
      ),
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class _QuickActionsCard extends StatelessWidget {
  final List<_QuickAction> actions;

  const _QuickActionsCard({required this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: actions.map((action) {
          return Expanded(
            child: InkWell(
              onTap: action.onTap,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(action.icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      action.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MilesHistoryCard extends StatelessWidget {
  final List<MilesHistory> history;

  const _MilesHistoryCard({required this.history});

  @override
  Widget build(BuildContext context) {
    final display = history.take(3).toList();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Miles history',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...display.map((entry) => _MilesHistoryTile(entry: entry)),
        ],
      ),
    );
  }
}

class _MilesHistoryTile extends StatelessWidget {
  final MilesHistory entry;

  const _MilesHistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = entry.type == 'redeemed'
        ? Colors.orangeAccent
        : entry.type == 'used'
        ? Colors.redAccent
        : Colors.greenAccent;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Icon(Iconsax.arrow_right_3, color: Colors.white54, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.description ?? entry.type ?? 'Miles',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(entry.createdAt) ?? '',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${entry.type == 'redeemed' ? '-' : '+'}${entry.amount.toStringAsFixed(0)}',
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

String? _formatDate(DateTime? date) {
  if (date == null) return null;
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
