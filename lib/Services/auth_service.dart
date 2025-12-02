import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:case_simulator/Models/user.dart';

class AuthService {
  static const String _currentUserKey = 'current_user_id';

  // Хешування пароля
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  // Реєстрація
  static Future<bool> register(String email, String password, String nickname) async {
    final usersBox = Hive.box<UserModel>('users');

    // Перевірка чи email вже існує
    try {
      usersBox.values.firstWhere(
            (user) => user.email == email,
      );
      // Якщо знайшов - email вже існує
      return false;
    } catch (e) {
      // Email не знайдено - можна реєструвати
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

    // Автоматичний вхід після реєстрації
    await _setCurrentUser(newUser.id);

    return true;
  }

  // Авторизація
  static Future<bool> login(String email, String password) async {
    final usersBox = Hive.box<UserModel>('users');
    final passwordHash = _hashPassword(password);

    try {
      final user = usersBox.values.firstWhere(
            (user) => user.email == email && user.passwordHash == passwordHash,
      );

      await _setCurrentUser(user.id);
      return true;
    } catch (e) {
      return false; // Невірний email або пароль
    }
  }

  // Вихід
  static Future<void> logout() async {
    final settingsBox = Hive.box('settings');
    await settingsBox.delete(_currentUserKey);
  }

  // Перевірка чи користувач авторизований
  static bool isLoggedIn() {
    final settingsBox = Hive.box('settings');
    return settingsBox.containsKey(_currentUserKey);
  }

  // Отримати поточного користувача
  static UserModel? getCurrentUser() {
    if (!isLoggedIn()) return null;

    final settingsBox = Hive.box('settings');
    final userId = settingsBox.get(_currentUserKey);

    if (userId == null) return null;

    final usersBox = Hive.box<UserModel>('users');
    return usersBox.get(userId);
  }

  // Зберегти ID поточного користувача
  static Future<void> _setCurrentUser(String userId) async {
    final settingsBox = Hive.box('settings');
    await settingsBox.put(_currentUserKey, userId);
  }
}
