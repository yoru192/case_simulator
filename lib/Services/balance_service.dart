import 'package:hive/hive.dart';
import 'package:case_simulator/services/auth_service.dart';

class BalanceService {
  static const double _startBalance = 0;

  static String _getBalanceKey() {
    final user = AuthService.getCurrentUser();
    if (user == null) return 'balance_guest';
    return 'balance_${user.id}';
  }

  // Отримати баланс
  static double getBalance() {
    final box = Hive.box('settings');
    final key = _getBalanceKey();
    return box.get(key, defaultValue: _startBalance) as double;
  }

  // Встановити баланс
  static void setBalance(double amount) {
    final box = Hive.box('settings');
    final key = _getBalanceKey();
    box.put(key, amount); // ← Hive автоматично тригерить listeners
  }

  // Додати гроші
  static void addMoney(double amount) {
    final currentBalance = getBalance();
    setBalance(currentBalance + amount);
  }

  // Зняти гроші (повертає true якщо вдалося)
  static bool removeMoney(double amount) {
    final currentBalance = getBalance();
    if (currentBalance >= amount) {
      setBalance(currentBalance - amount);
      return true;
    }
    return false;
  }
}
