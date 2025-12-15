import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../models/saved_card.dart';
import '../../models/momo_account.dart';
import '../../services/payment_method_service.dart';
import '../../theme/app_colors.dart';
import '../../services/session_manager.dart';
import 'add_card_screen.dart';
import 'momo_number_screen.dart';

enum PaymentMethod { momo, card }

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  final SessionManager _sessionManager = SessionManager.instance;
  final PaymentMethodService _paymentMethodService =
      PaymentMethodService.instance;
  bool _checkingAuth = false;
  String? _savedMsisdn;
  List<MomoAccount> _momoAccounts = const [];
  String? _defaultMomoId;
  List<SavedCard> _cards = const [];
  String? _defaultCardId;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final saved = await _sessionManager.getMomoMsisdn();
    final momoAccounts = await _paymentMethodService.getMomoAccounts();
    final defaultMomo = await _paymentMethodService.getDefaultMomoAccount();
    final cards = await _paymentMethodService.getCards();
    final defaultId = await _paymentMethodService.getDefaultCardId();
    if (!mounted) return;
    setState(() {
      _savedMsisdn = saved;
      _momoAccounts = momoAccounts;
      _defaultMomoId = defaultMomo?.id;
      _cards = cards;
      _defaultCardId = defaultId;
    });
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
        title: const Text(
          'Choose payment',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MomoSection(
            accounts: _momoAccounts,
            defaultId: _defaultMomoId,
            fallbackMsisdn: _savedMsisdn,
            onSelect: (account) async {
              if (!await _ensureLoggedIn()) return;
              await _paymentMethodService.setDefaultMomoAccount(account.id);
              if (!mounted) return;
              setState(() {
                _defaultMomoId = account.id;
                _savedMsisdn = account.msisdn;
              });
              Navigator.pop(context, PaymentMethod.momo);
            },
            onAdd: () async {
              if (!await _ensureLoggedIn()) return;
              final account = await Navigator.push<MomoAccount>(
                context,
                MaterialPageRoute(
                  builder: (_) => const MomoNumberScreen(),
                ),
              );
              if (account != null) {
                await _loadSaved();
                if (mounted) {
                  Navigator.pop(context, PaymentMethod.momo);
                }
              }
            },
            onDelete: (account) async {
              if (!await _ensureLoggedIn()) return;
              await _paymentMethodService.deleteMomoAccount(account.id);
              if (!mounted) return;
              await _loadSaved();
            },
          ),
          const SizedBox(height: 12),
          _CardSection(
            cards: _cards,
            defaultCardId: _defaultCardId,
            onSelect: (card) async {
              if (!await _ensureLoggedIn()) return;
              await _paymentMethodService.setDefaultCard(card.id);
              if (!mounted) return;
              setState(() => _defaultCardId = card.id);
              Navigator.pop(context, PaymentMethod.card);
            },
            onDelete: (card) async {
              if (!await _ensureLoggedIn()) return;
              await _paymentMethodService.deleteCard(card.id);
              if (!mounted) return;
              await _loadSaved();
            },
            onAdd: () async {
              if (!await _ensureLoggedIn()) return;
              final card = await Navigator.push<SavedCard>(
                context,
                MaterialPageRoute(builder: (_) => const AddCardScreen()),
              );
              if (card != null) {
                await _loadSaved();
              }
            },
          ),
          const SizedBox(height: 12),
          _MethodTile(
            icon: Iconsax.card,
            title: 'Pay with card',
            subtitle: _cards.isEmpty
                ? 'Add a card to enable'
                : 'Use your saved card',
            onTap: _cards.isEmpty
                ? null
                : () {
                    _ensureLoggedIn().then((ok) {
                      if (ok) Navigator.pop(context, PaymentMethod.card);
                    });
                  },
            disabled: _cards.isEmpty,
          ),
        ],
      ),
    );
  }

  Future<bool> _ensureLoggedIn() async {
    if (_checkingAuth) return false;
    _checkingAuth = true;
    final token = await _sessionManager.getToken();
    if (token != null && token.isNotEmpty) {
      _checkingAuth = false;
      return true;
    }
    if (!mounted) {
      _checkingAuth = false;
      return false;
    }
    await Navigator.pushNamed(context, '/login');
    final newToken = await _sessionManager.getToken();
    _checkingAuth = false;
    return newToken != null && newToken.isNotEmpty;
  }
}

class _CardSection extends StatelessWidget {
  final List<SavedCard> cards;
  final String? defaultCardId;
  final ValueChanged<SavedCard> onSelect;
  final ValueChanged<SavedCard> onDelete;
  final VoidCallback onAdd;

  const _CardSection({
    required this.cards,
    required this.defaultCardId,
    required this.onSelect,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Saved cards',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Iconsax.add, color: AppColors.primary),
              label: const Text(
                'Add',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        if (cards.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 4, bottom: 12),
            child: Text(
              'No cards saved yet.',
              style: TextStyle(color: Colors.white54),
            ),
          )
        else
          ...cards.map(
            (card) => _SavedCardTile(
              card: card,
              isDefault: card.id == defaultCardId,
              onTap: () => onSelect(card),
              onDelete: () => onDelete(card),
            ),
          ),
      ],
    );
  }
}

class _SavedCardTile extends StatelessWidget {
  final SavedCard card;
  final bool isDefault;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SavedCardTile({
    required this.card,
    required this.isDefault,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDefault
              ? AppColors.primary.withOpacity(0.6)
              : Colors.white.withOpacity(0.06),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Colors.white.withOpacity(0.08),
          child: _LogoAvatar(
            label: card.brand,
            asset: _brandAsset(card.brand),
          ),
        ),
        title: Text(
          '${card.brand} ${card.masked}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '${card.holder} • Expires ${card.expiry}',
          style: const TextStyle(color: Colors.white54),
        ),
        trailing: IconButton(
          icon: const Icon(Iconsax.trash, color: Colors.white54),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _LogoAvatar extends StatelessWidget {
  final String label;
  final String? asset;

  const _LogoAvatar({required this.label, this.asset});

  @override
  Widget build(BuildContext context) {
    final normalized = label.toLowerCase();
    final color = _badgeColor(normalized);
    final text = label.isNotEmpty ? label[0].toUpperCase() : '?';

    if (asset != null && asset!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset(
          asset!,
          width: 36,
          height: 36,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _badge(text, color),
        ),
      );
    }
    return _badge(text, color);
  }

  Widget _badge(String text, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String? _brandAsset(String brand) {
  final normalized = brand.toLowerCase();
  if (normalized.contains('visa')) return 'assets/images/visa.png';
  if (normalized.contains('master')) return 'assets/images/mastercard.png';
  if (normalized.contains('amex')) return 'assets/images/amex.png';
  if (normalized.contains('discover')) return 'assets/images/discover.png';
  if (normalized.contains('jcb')) return 'assets/images/jcb.png';
  return null;
}

String? _providerAsset(String provider) {
  final normalized = provider.toLowerCase();
  if (normalized.contains('mtn')) return 'assets/images/mtn.png';
  if (normalized.contains('airtel')) return 'assets/images/airtel.png';
  return null;
}

Color _badgeColor(String normalizedLabel) {
  if (normalizedLabel.contains('visa')) return const Color(0xFF1a1f71);
  if (normalizedLabel.contains('master')) return const Color(0xFFeb001b);
  if (normalizedLabel.contains('amex')) return const Color(0xFF2e77bc);
  if (normalizedLabel.contains('discover')) return const Color(0xFFf57c00);
  if (normalizedLabel.contains('jcb')) return const Color(0xFF007b5f);
  if (normalizedLabel.contains('mtn')) return const Color(0xFFffd100);
  if (normalizedLabel.contains('airtel')) return const Color(0xFFe4002b);
  return Colors.white.withOpacity(0.8);
}

class _MethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool disabled;

  const _MethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = disabled ? Colors.white38 : Colors.white;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(disabled ? 0.02 : 0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              disabled ? Iconsax.lock : Iconsax.arrow_right_1,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

class _MomoSection extends StatelessWidget {
  final List<MomoAccount> accounts;
  final String? defaultId;
  final String? fallbackMsisdn;
  final ValueChanged<MomoAccount> onSelect;
  final ValueChanged<MomoAccount> onDelete;
  final VoidCallback onAdd;

  const _MomoSection({
    required this.accounts,
    required this.defaultId,
    required this.fallbackMsisdn,
    required this.onSelect,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mobile Money',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Iconsax.add, color: AppColors.primary),
              label: const Text(
                'Add',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        if (accounts.isEmpty)
          _MethodTile(
            icon: Iconsax.wallet_money,
            title: 'Add MTN or Airtel number',
            subtitle: (fallbackMsisdn?.isNotEmpty ?? false)
                ? 'Tap to add your MoMo line'
                : 'Tap to add your MoMo line',
            onTap: onAdd,
          )
        else
          ...accounts.map(
            (account) => _SavedMomoTile(
              account: account,
              isDefault: account.id == defaultId,
              onTap: () => onSelect(account),
              onDelete: () => onDelete(account),
            ),
          ),
      ],
    );
  }
}

class _SavedMomoTile extends StatelessWidget {
  final MomoAccount account;
  final bool isDefault;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SavedMomoTile({
    required this.account,
    required this.isDefault,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDefault
              ? AppColors.primary.withOpacity(0.6)
              : Colors.white.withOpacity(0.06),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Colors.white.withOpacity(0.08),
          child: _LogoAvatar(
            label: account.provider,
            asset: _providerAsset(account.provider),
          ),
        ),
        title: Text(
          '${account.provider} • ${account.msisdn}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          isDefault ? 'Default' : 'Tap to use',
          style: TextStyle(
            color: isDefault ? AppColors.primary : Colors.white54,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Iconsax.trash, color: Colors.white54),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
