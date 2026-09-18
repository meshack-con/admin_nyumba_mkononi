import 'package:shared_preferences/shared_preferences.dart';

/// Kuhifadhi session ya admin (token na jina) kwenye kifaa.
///
/// Tunatumia `shared_preferences` badala ya `flutter_secure_storage` kwa
/// makusudi: hii ni admin app ya ndani inayoendeshwa localhost na
/// operator mmoja, hivyo encryption ya ziada haihitajiki, na
/// shared_preferences haihitaji usanidi wowote wa ziada kwenye desktop.
class AuthService {
  static const _tokenKey = 'access_token';
  static const _nameKey = 'admin_name';

  Future<void> saveSession({required String token, required String name}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_nameKey, name);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_nameKey);
  }
}
