import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import 'package:case_simulator/Models/user.dart';

class AuthService {
  static String? _currentUserId;

  // Хешування пароля
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  // Реєстрація
  static Future<bool> register(String email, String password, String nickname) async {
    final usersBox = Hive.box('users');

    // Перевірка чи email вже існує
    try {
      usersBox.values.firstWhere((user) => user.email == email);
      return false;
    } catch (e) {
      // Email не знайдено
    }

    // Створення нового користувача
    final newUser = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      passwordHash: _hashPassword(password),
      nickname: nickname,
      createdAt: DateTime.now(),
    );

    await usersBox.put(newUser.id, newUser);
    await _setCurrentUser(newUser.id);
    return true;
  }

  // Вхід
  static Future<bool> login(String email, String password) async {
    final usersBox = Hive.box('users');
    final hashedPassword = _hashPassword(password);

    try {
      final user = usersBox.values.firstWhere(
            (user) => user.email == email && user.passwordHash == hashedPassword,
      );
      await _setCurrentUser(user.id);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Вихід
  static Future<void> logout() async {
    final settingsBox = Hive.box('settings');
    await settingsBox.delete('current_user_id');
    _currentUserId = null;
  }

  // Отримати поточного користувача
  static UserModel? getCurrentUser() {
    if (_currentUserId == null) {
      final settingsBox = Hive.box('settings');
      _currentUserId = settingsBox.get('current_user_id');
    }

    if (_currentUserId == null) return null;

    final usersBox = Hive.box('users');
    return usersBox.get(_currentUserId);
  }

  // Встановити поточного користувача
  static Future<void> _setCurrentUser(String userId) async {
    _currentUserId = userId;
    final settingsBox = Hive.box('settings');
    await settingsBox.put('current_user_id', userId);
  }

  // Перевірка чи користувач авторизований
  static bool isLoggedIn() {
    return getCurrentUser() != null;
  }
}
