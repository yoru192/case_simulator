import 'package:hive/hive.dart';
import 'package:case_simulator/services/auth_service.dart';

class BalanceService {
  // Отримати баланс
  static double getBalance() {
    final user = AuthService.getCurrentUser();
    if (user == null) return 0.0;

    final settingsBox = Hive.box('settings');
    return settingsBox.get('balance_${user.id}', defaultValue: 0.0);
  }

  // Встановити баланс
  static void setBalance(double amount) {
    final user = AuthService.getCurrentUser();
    if (user == null) return;

    final settingsBox = Hive.box('settings');
    settingsBox.put('balance_${user.id}', amount);
  }

  // Додати гроші
  static void addMoney(double amount) {
    final currentBalance = getBalance();
    setBalance(currentBalance + amount);
  }

  // Зняти гроші
  static bool removeMoney(double amount) {
    final currentBalance = getBalance();
    if (currentBalance >= amount) {
      setBalance(currentBalance - amount);
      return true;
    }
    return false;
  }
}
