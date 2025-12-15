import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_card.dart';
import '../models/momo_account.dart';

class PaymentMethodService {
  PaymentMethodService._();

  static final PaymentMethodService instance = PaymentMethodService._();

  static const _cardsKey = 'saved_cards';
  static const _defaultCardKey = 'default_card_id';
  static const _momoKey = 'momo_accounts';
  static const _defaultMomoKey = 'default_momo_id';

  Future<List<SavedCard>> getCards() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cardsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(SavedCard.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveCard(SavedCard card) async {
    final cards = await getCards();
    final updated = <SavedCard>[
      ...cards.where((c) => c.id != card.id),
      card,
    ];
    await _persist(updated);
  }

  Future<void> deleteCard(String id) async {
    final cards = await getCards();
    final updated = cards.where((c) => c.id != id).toList();
    await _persist(updated);
    final prefs = await SharedPreferences.getInstance();
    final defaultId = prefs.getString(_defaultCardKey);
    if (defaultId == id) {
      await prefs.remove(_defaultCardKey);
    }
  }

  Future<void> setDefaultCard(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultCardKey, id);
  }

  Future<String?> getDefaultCardId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultCardKey);
  }

  Future<void> _persist(List<SavedCard> cards) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = cards.map((c) => c.toJson()).toList();
    await prefs.setString(_cardsKey, jsonEncode(jsonList));
  }

  // MoMo accounts
  Future<List<MomoAccount>> getMomoAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_momoKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(MomoAccount.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveMomoAccount(MomoAccount account) async {
    final accounts = await getMomoAccounts();
    final updated = <MomoAccount>[
      ...accounts.where((a) => a.id != account.id),
      account,
    ];
    await _persistMomo(updated);
  }

  Future<void> deleteMomoAccount(String id) async {
    final accounts = await getMomoAccounts();
    final updated = accounts.where((a) => a.id != id).toList();
    await _persistMomo(updated);
    final prefs = await SharedPreferences.getInstance();
    final defaultId = prefs.getString(_defaultMomoKey);
    if (defaultId == id) {
      await prefs.remove(_defaultMomoKey);
    }
  }

  Future<void> setDefaultMomoAccount(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultMomoKey, id);
  }

  Future<MomoAccount?> getDefaultMomoAccount() async {
    final accounts = await getMomoAccounts();
    if (accounts.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final defaultId = prefs.getString(_defaultMomoKey);
    if (defaultId != null) {
      final found = accounts.firstWhere(
        (a) => a.id == defaultId,
        orElse: () => accounts.first,
      );
      return found;
    }
    return accounts.first;
  }

  Future<void> _persistMomo(List<MomoAccount> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = accounts.map((a) => a.toJson()).toList();
    await prefs.setString(_momoKey, jsonEncode(jsonList));
  }
}
