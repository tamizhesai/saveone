import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'database_service.dart';

class AuthService {
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyUserId = 'userId';
  static const String _keyUserName = 'userName';
  static const String _keyUserEmail = 'userEmail';
  static const String _keyUserPhone = 'userPhone';
  static const String _keyUserNominee = 'userNominee';

  final DatabaseService _dbService = DatabaseService();

  Future<bool> signUp({
    required String name,
    required String email,
    required String phoneNumber,
    required String password,
    required String nomineeNumber,
  }) async {
    try {
      final userId = await _dbService.createUser(
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
        nomineeNumber: nomineeNumber,
      );

      if (userId != null) {
        await _saveLoginState(
          userId: userId,
          name: name,
          email: email,
          phoneNumber: phoneNumber,
          nomineeNumber: nomineeNumber,
        );
        return true;
      }
      return false;
    } catch (e) {
      print('SignUp Error: $e');
      return false;
    }
  }

  Future<bool> signIn({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final user = await _dbService.authenticateUser(
        phoneNumber: phoneNumber,
        password: password,
      );

      if (user != null) {
        await _saveLoginState(
          userId: user.id!,
          name: user.name,
          email: user.email,
          phoneNumber: user.phoneNumber,
          nomineeNumber: user.nomineeNumber,
        );
        return true;
      }
      return false;
    } catch (e) {
      print('SignIn Error: $e');
      return false;
    }
  }

  Future<void> _saveLoginState({
    required int userId,
    required String name,
    required String email,
    required String phoneNumber,
    required String nomineeNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setInt(_keyUserId, userId);
    await prefs.setString(_keyUserName, name);
    await prefs.setString(_keyUserEmail, email);
    await prefs.setString(_keyUserPhone, phoneNumber);
    await prefs.setString(_keyUserNominee, nomineeNumber);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_keyUserId);
    final name = prefs.getString(_keyUserName);
    final email = prefs.getString(_keyUserEmail);
    final phone = prefs.getString(_keyUserPhone);
    final nominee = prefs.getString(_keyUserNominee);

    if (userId != null && name != null && email != null && phone != null && nominee != null) {
      return UserModel(
        id: userId,
        name: name,
        email: email,
        phoneNumber: phone,
        nomineeNumber: nominee,
      );
    }
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
