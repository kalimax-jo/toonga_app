import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  SessionManager._();

  static final SessionManager instance = SessionManager._();

  static String? token;

  static const _tokenKey = 'auth_token';
  static const _momoMsisdnKey = 'momo_msisdn';

  Future<void> saveToken(String token) async {
    SessionManager.token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveMomoMsisdn(String msisdn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_momoMsisdnKey, msisdn);
  }

  Future<String?> getMomoMsisdn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_momoMsisdnKey);
  }

  Future<void> clearMomoMsisdn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_momoMsisdnKey);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_momoMsisdnKey);
    SessionManager.token = null;
  }
}
